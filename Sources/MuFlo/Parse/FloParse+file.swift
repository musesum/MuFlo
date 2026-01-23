//  created by musesum on 9/11/19.

import Foundation

public extension FloParse {

    func read(_ filename: String, _ ext: String) -> String {

        let path = BundleResource(name: filename, type: ext).path
        do {
            return try String(contentsOfFile: path) }
        catch {
            print("⁉️ Parsin::\(#function) error:\(error) loading contents of:\(path)")
        }
        return ""
    }

    func parseFlo(_ root: Flo,
                  _ filename: String,
                  _ ext: String = "flo.h") -> Bool {
                      
        let script = read(filename, ext)
        print(filename, terminator: " ")
        let success = parseRoot(root, script)
        print(success ? "✓" : "⁉️ parse failed")
        return success
    }

}
