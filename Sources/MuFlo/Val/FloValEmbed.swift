//  FloValEmbed.swift
//  created by musesum on 4/25/19.

import Foundation

public class FloValEmbed: FloVal {

    var embed = ""

    init(_ flo: Flo, str: String?) {
        super.init(flo, "embed")
        embed = str ?? "??"
    }
    public static func == (lhs: FloValEmbed, rhs: FloValEmbed) -> Bool {
        return lhs.embed == rhs.embed
    }

    public override func getVal() -> Any {
        return embed
    }

    @discardableResult
    public override func setVal(_ any: Any?,
                                _ visit: Visitor) -> Bool {
        
        if let v = any as? FloValEmbed {
            embed = v.embed
            return true
        }
        return false
    }

    public override func printVal() -> String {
        return embed
    }
    
    public override func scriptVal(_ scriptOps: FloScriptOps = [.parens],
                                   _ viaEdge: Bool,
                                   noParens: Bool = false) -> String {
        return " {{\n" + embed +  "}}\n"
    }

}
