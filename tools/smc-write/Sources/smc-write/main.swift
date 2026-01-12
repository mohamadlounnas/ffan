import Foundation
import SMCKit

func usage() {
    print("Usage: smc-write <KEY> <TYPE> <VALUE>")
    print("TYPE: flt | fpe2 | sp78 | ui8 | ui16 | ui32")
}

@main
struct SMCWriteCLI {
    static func main() async {
        let args = CommandLine.arguments
        guard args.count >= 4 else {
            usage()
            exit(1)
        }

        let key = args[1]
        let type = args[2]
        let valueStr = args[3]

        guard let valueDouble = Double(valueStr) else {
            print("Invalid value: \(valueStr)")
            exit(1)
        }

        do {
            switch type {
            case "flt":
                let v = Float(valueDouble)
                try await SMCKit.shared.write(key, v)

            case "fpe2":
                // fpe2 is usually unsigned 14.2; use UInt16
                let v = UInt16(valueDouble)
                try await SMCKit.shared.write(key, v)

            case "sp78":
                // signed fixed 7.8 - use Int16 representation; but SMCKit supports Float so write as Float
                let v = Float(valueDouble)
                try await SMCKit.shared.write(key, v)

            case "ui8":
                let v = UInt8(valueDouble)
                try await SMCKit.shared.write(key, v)

            case "ui16":
                let v = UInt16(valueDouble)
                try await SMCKit.shared.write(key, v)

            case "ui32":
                let v = UInt32(valueDouble)
                try await SMCKit.shared.write(key, v)

            default:
                // Try to infer: default to UInt16
                let v = UInt16(valueDouble)
                try await SMCKit.shared.write(key, v)
            }

            print("Success")
            exit(0)
        } catch SMCKit.SMCKitError.notPrivileged {
            print("Error: not privileged (need root)")
            exit(2)
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }
}
