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
        lintPlugOps(filename, script)
        print(filename, terminator: " ")
        let success = parseRoot(root, script)
        print(success ? "✓" : "⁉️ parse failed")
        return success
    }

    /// A `^-` that does not follow `,` or `(` is not read as an operator: the
    /// preceding dispatch clause swallows it and the plug def never exists, so
    /// the host animates nothing and the parse says nothing. Name it here
    func lintPlugOps(_ filename: String, _ script: String) {

        var line = 1
        var quoted = false
        var lastReal: Character? = nil
        let chars = Array(script)
        var i = 0

        while i < chars.count {
            let char = chars[i]
            if char == "\n" { line += 1 }
            if char == "'" { quoted.toggle() }
            if !quoted, char == "^", i + 1 < chars.count, chars[i + 1] == "-" {
                if lastReal != ",", lastReal != "(" {
                    let seen = lastReal.map { String($0) } ?? "start"
                    PrintLog("⁉️ \(filename).flo.h:\(line) `^-` follows `\(seen)`, not `,` — plug def ignored")
                }
                i += 2
                lastReal = "-"
                continue
            }
            if !char.isWhitespace { lastReal = char }
            i += 1
        }
    }
}
