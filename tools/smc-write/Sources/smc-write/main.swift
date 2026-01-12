import Foundation
import SMCKit

func usage() {
    print("Usage: smc-write <KEY> <TYPE> <VALUE>")
    print("       smc-write info <KEY>")
    print("TYPE: flt | fpe2 | sp78 | ui8 | ui16 | ui32")
}

@main
struct SMCWriteCLI {
    static func main() async {
        let args = CommandLine.arguments
        guard args.count >= 2 else {
            usage()
            exit(1)
        }

        let cmd = args[1]
        func fourCharCodeFromString(_ string: String) -> FourCharCode {
            var result: UInt32 = 0
            for (index, byte) in string.utf8.prefix(4).enumerated() {
                result |= UInt32(byte) << (8 * (3 - index))
            }
            return FourCharCode(result)
        }

        if cmd == "info" {
            guard args.count >= 3 else { usage(); exit(1) }
            let key = args[2]
            let keyCode = fourCharCodeFromString(key)
            do {
                let info = try await SMCKit.shared.getKeyInformation(keyCode)
                print("Key: \(key)")
                print("Type: \(info.type.toString()) Size: \(info.size)")
                // attempt to read value
                do {
                    if info.size == 4 && info.type.toString() == "flt " {
                        let v: Float = try await SMCKit.shared.read(keyCode)
                        print("Value: \(v)")
                    } else if info.size == 2 {
                        let v: UInt16 = try await SMCKit.shared.read(keyCode)
                        print("Value: \(v)")
                    } else if info.size == 1 {
                        let v: UInt8 = try await SMCKit.shared.read(keyCode)
                        print("Value: \(v)")
                    } else if info.size == 4 {
                        let v: UInt32 = try await SMCKit.shared.read(keyCode)
                        print("Value: \(v)")
                    }
                } catch {
                    print("Note: Could not read value: \(error)")
                }
                exit(0)
            } catch {
                print("Error: \(error)")
                exit(1)
            }
        }

        let key = args[1]
        _ = args[2]  // type parameter (unused but required for CLI compatibility)
        let valueStr = args[3]

        guard let valueDouble = Double(valueStr) else {
            print("Invalid value: \(valueStr)")
            exit(1)
        }

        func fourCharCodeFrom(_ string: String) -> FourCharCode {
            var result: UInt32 = 0
            for (index, byte) in string.utf8.prefix(4).enumerated() {
                result |= UInt32(byte) << (8 * (3 - index))
            }
            return FourCharCode(result)
        }

        do {
            let keyCode = fourCharCodeFrom(key)

            // Query key info to know exact data type expected
            let info = try await SMCKit.shared.getKeyInformation(keyCode)
            let expectedType = info.type.toString()

            switch expectedType {
            case "flt ":
                let v = Float(valueDouble)
                try await SMCKit.shared.write(keyCode, v)

            case "sp78", "fpe2":
                // both are fixed-point sizes stored in 2 bytes - use UInt16
                let v = UInt16(valueDouble)
                try await SMCKit.shared.write(keyCode, v)

            case "ui8":
                let v = UInt8(valueDouble)
                try await SMCKit.shared.write(keyCode, v)

            case "ui16":
                let v = UInt16(valueDouble)
                try await SMCKit.shared.write(keyCode, v)

            case "ui32":
                let v = UInt32(valueDouble)
                try await SMCKit.shared.write(keyCode, v)

            default:
                // Fallback to UInt16
                let v = UInt16(valueDouble)
                try await SMCKit.shared.write(keyCode, v)
            }

            // read back and print current value for verification
            do {
                let info = try await SMCKit.shared.getKeyInformation(keyCode)
                if info.size == 4 && info.type.toString() == "flt " {
                    let v: Float = try await SMCKit.shared.read(keyCode)
                    print("Success: new value=\(v)")
                } else if info.size == 2 {
                    let v: UInt16 = try await SMCKit.shared.read(keyCode)
                    print("Success: new value=\(v)")
                } else if info.size == 1 {
                    let v: UInt8 = try await SMCKit.shared.read(keyCode)
                    print("Success: new value=\(v)")
                } else if info.size == 4 {
                    let v: UInt32 = try await SMCKit.shared.read(keyCode)
                    print("Success: new value=\(v)")
                } else {
                    print("Success")
                }
            } catch {
                print("Success (write reported OK, but readback failed: \(error))")
            }
            exit(0)
        } catch {
            let errDesc = String(describing: error).lowercased()
            if errDesc.contains("priv") || errDesc.contains("not privileged") {
                print("Error: not privileged (need root): \(error)")
                exit(2)
            }
            print("Error: \(error)")
            exit(1)
        }
    }
}
