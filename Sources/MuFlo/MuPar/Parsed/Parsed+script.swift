// created by musesum on 1/7/25

import Foundation

extension Parsed { // + script

    public func makeScript() -> String {
        var script = parser.pattern
        if let result {
            switch parser.type {
            case .regx,.quote: break
            default:
                if script.count > 0  {
                    script += ":"
                }
                 script += result
            }
        }

        switch subParse.count {
        case 0: break
        case 1: script += "." + subParse[0].makeScript()
        default:
            var del = " {"
            for subParse in subParse {
                script += del + subParse.makeScript()
                del = ", "
            }
            script += "}"
        }
        return script
    }
}
