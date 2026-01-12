
import Foundation
import IOKit

// MARK: - SMC Definitions

typealias SMCBytes = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                      UInt8, UInt8, UInt8, UInt8)

struct SMCKeyData_vers_t {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

struct SMCKeyData_pLimitData_t {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

struct SMCKeyData_keyInfo_t {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

struct SMCParamStruct {
    var key: UInt32 = 0
    var vers = SMCKeyData_vers_t()
    var pLimitData = SMCKeyData_pLimitData_t()
    var keyInfo = SMCKeyData_keyInfo_t()
    var padding: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: SMCBytes = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

let KERNEL_INDEX_SMC: UInt32 = 2
let SMC_CMD_READ_KEYINFO: UInt8 = 9
let SMC_CMD_WRITE_BYTES: UInt8 = 6

// MARK: - Helpers

func fourCharCodeFrom(_ string: String) -> UInt32 {
    var result: UInt32 = 0
    for (index, char) in string.utf8.prefix(4).enumerated() {
        result |= UInt32(char) << (8 * (3 - index))
    }
    return result
}

func parseDataType(_ typeStr: String) -> UInt32 {
    // Ensure 4 chars padded with space
    var str = typeStr
    while str.count < 4 { str += " " }
    return fourCharCodeFrom(str)
}

// MARK: - Main Logic

func main() {
    let args = CommandLine.arguments
    guard args.count >= 4 else {
        print("Usage: smc-write <key> <type> <value>")
        exit(1)
    }
    
    let keyStr = args[1]
    let typeStr = args[2]
    guard let value = Double(args[3]) else {
        print("Error: Invalid value")
        exit(1)
    }
    
    let key = fourCharCodeFrom(keyStr)
    // We don't strictly need type passed if we read key info, 
    // but the app passes it to be explicit or if we want to override.
    // Actually, let's use the stored key info from SMC to be safe,
    // matching the typeStr passed.
    
    // Connect to SMC
    var conn: io_connect_t = 0
    let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleSMC"))
    guard service != 0 else {
        print("Error: AppleSMC service not found")
        exit(1)
    }
    
    let result = IOServiceOpen(service, mach_task_self_, 0, &conn)
    IOObjectRelease(service)
    
    guard result == kIOReturnSuccess else {
        print("Error: Failed to open SMC connection (need root?)")
        exit(1)
    }
    defer { IOServiceClose(conn) }
    
    // Get Key Info
    var input = SMCParamStruct()
    input.key = key
    input.data8 = SMC_CMD_READ_KEYINFO
    
    var output = SMCParamStruct()
    var outputSize = MemoryLayout<SMCParamStruct>.size
    
    var kpResult = IOConnectCallStructMethod(conn, KERNEL_INDEX_SMC, &input, MemoryLayout<SMCParamStruct>.size, &output, &outputSize)
    
    guard kpResult == kIOReturnSuccess && output.result == 0 else {
        print("Error: Key not found or read failed")
        exit(1)
    }
    
    let keyInfo = output.keyInfo
    
    // Prepare Write
    input = SMCParamStruct()
    input.key = key
    input.keyInfo = keyInfo
    input.data8 = SMC_CMD_WRITE_BYTES
    
    // Convert Value
    // We trust the typeStr passed OR the keyInfo.dataType.
    // Let's use keyInfo.dataType to be safe as that's what hardware expects.
    
    switch typeStr {
    case "flt":
        // Float 32
        var floatVal = Float32(value)
        withUnsafeBytes(of: &floatVal) { buffer in
            if buffer.count >= 4 {
                input.bytes.0 = buffer[0]
                input.bytes.1 = buffer[1]
                input.bytes.2 = buffer[2]
                input.bytes.3 = buffer[3]
            }
        }
        
    case "fpe2":
        // Fixed 14.2
        let intVal = Int(value)
        input.bytes.0 = UInt8(intVal >> 6)
        input.bytes.1 = UInt8((intVal & 0x3F) << 2)
        
    case "sp78":
        // Fixed 7.8
        let intVal = Int16(value * 256.0)
        let uintVal = UInt16(bitPattern: intVal)
        input.bytes.0 = UInt8((uintVal >> 8) & 0xFF)
        input.bytes.1 = UInt8(uintVal & 0xFF)
        
    case "ui8":
        input.bytes.0 = UInt8(value)
        
    case "ui16":
        let intVal = UInt16(value)
        input.bytes.0 = UInt8((intVal >> 8) & 0xFF)
        input.bytes.1 = UInt8(intVal & 0xFF)
        
    case "ui32":
        let intVal = UInt32(value)
        input.bytes.0 = UInt8((intVal >> 24) & 0xFF)
        input.bytes.1 = UInt8((intVal >> 16) & 0xFF)
        input.bytes.2 = UInt8((intVal >> 8) & 0xFF)
        input.bytes.3 = UInt8(intVal & 0xFF)
        
    default:
        // Try fallback based on size
        if keyInfo.dataSize == 4 {
            // Assume Float if requested or uint32
            // But if typeStr is unknown, maybe print error?
            // For now, assume user knows best?
            print("Warning: Unknown type \(typeStr), treating as ui32 logic")
            let intVal = UInt32(value)
            input.bytes.0 = UInt8((intVal >> 24) & 0xFF)
            input.bytes.1 = UInt8((intVal >> 16) & 0xFF)
            input.bytes.2 = UInt8((intVal >> 8) & 0xFF)
            input.bytes.3 = UInt8(intVal & 0xFF)
        } else if keyInfo.dataSize == 2 {
            let intVal = UInt16(value)
            input.bytes.0 = UInt8((intVal >> 8) & 0xFF)
            input.bytes.1 = UInt8(intVal & 0xFF)
        } else {
            input.bytes.0 = UInt8(value)
        }
    }
    
    // Execute Write
    output = SMCParamStruct()
    outputSize = MemoryLayout<SMCParamStruct>.size
    
    let writeResult = IOConnectCallStructMethod(conn, KERNEL_INDEX_SMC, &input, MemoryLayout<SMCParamStruct>.size, &output, &outputSize)
    
    if writeResult == kIOReturnSuccess {
        print("Success")
    } else {
        print("Error: Write failed (code \(writeResult))")
        exit(1)
    }
}

main()
