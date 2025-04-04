//  FloValEmbed.swift
//  created by musesum on 4/25/19.

import Foundation

@MainActor //_____
public class Embed: FloVal {

    var embed = ""

    init(_ flo: Flo, str: String?) {
        super.init(flo, "embed")
        embed = str ?? "??"
    }
    public static func == (lhs: Embed, rhs: Embed) -> Bool {
        return lhs.embed == rhs.embed
    }

    public override func getVal() -> Any {
        return embed
    }

    @discardableResult
    public override func setVal(_ any: Any?,
                                _ visit: Visitor) -> Bool {
        
        if let v = any as? Embed {
            embed = v.embed
            return true
        }
        return false
    }

    public override func printVal(_ flo: Flo) -> String {
        return embed
    }
    
    public override func scriptVal(_ from: Flo,
                                   _ scriptOps: FloScriptOps = [.parens],
                                   viaEdge: Bool,
                                   noParens: Bool = false) -> String {
        return " {{\n" + embed +  "}}\n"
    }

}
