// created by musesum on 1/5/25

import Foundation
extension Parsin { // + trace

    func traceMatch(_ parser: Parser?, _ any: Any?, _ level: Int) {

        // ignore if not tracing
        if !Parsin.traceMatch { return }

        func getName(_ parser: Parser) -> String? {
            let suffix =  parser.isName ?  parser.pattern : ""

            if let nodeParent = parser.uberParser,
               let name = getName(nodeParent) {
                return suffix.isEmpty ? name : name + "." + suffix
            }
            return suffix
        }

        // add a value if there is one
        if let parsed = any as? Parsed,
           let parValue = parsed.result,
           let parser {
            // indent predecessors based on level
            let pad = " ".padding(toLength: level*2, withPad: " ", startingAt: 0)
            let slice = makeSlice(sub) + pad
            let repeats = parser.repeats.makeScript()
            let val = parValue.replacingOccurrences(of: "\n", with: "")
            let title = getName(parser) ?? parser.pattern
            print(slice + " \(title).\(parser.id) \(repeats) \(val)")
        }
        func makeSlice(_ sub: Substring, del: String = "⦙", length: Int = 10) -> String {

            if sub.count <= 0 {
                return del.padding(toLength: length, withPad: " ", startingAt: 0) + del + " "
            } else {
                let endIndex = min(length, sub.count)
                let subEnd = sub.index(sub.startIndex, offsetBy: endIndex)
                let subStr = sub.count > 0 ? String(sub[sub.startIndex ..< subEnd]) : " "
                let result = del + subStr
                    .replacingOccurrences(of: "\n", with: "↲")
                    .padding(toLength: length, withPad: " ", startingAt: 0) + del + " "
                return result
            }
        }
    }
}
