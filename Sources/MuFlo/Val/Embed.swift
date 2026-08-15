//  FloValEmbed.swift
//  created by musesum on 4/25/19.

import Foundation

public class Embed: FloVal {

    var embed = ""
    var dflt: String? /// parse-time source, delta baseline
    /// `@<file.ext>` naming the template that supplies the body, when declared
    public private(set) var fileRef: String?
    /// declared inside the exprs parens, so it scripts back inside them
    var inExprs = false

    init(_ flo: Flo, str: String?) {
        super.init(flo, "embed")
        let (ref, body) = Self.splitRef(str ?? "??")
        fileRef = ref
        embed = body
        // a referenced body arrives from the template, not the script, so the
        // delta baseline stays unknown until setTemplate seeds it
        dflt = ref == nil ? body : nil
    }
    init(_ flo: Flo, copy: Embed) {
        super.init(flo, "embed")
        embed = copy.embed
        dflt = copy.dflt
        fileRef = copy.fileRef
        inExprs = copy.inExprs
    }
    /// peel a leading `@<file.ext>`; the remainder is a tweaked body, if any
    static func splitRef(_ str: String) -> (String?, String) {
        let scan = str.drop { $0 == " " || $0 == "\t" }
        guard scan.hasPrefix("@<"),
              let close = scan.firstIndex(of: ">")
        else { return (nil, str) }
        let ref = String(scan[scan.index(scan.startIndex, offsetBy: 2) ..< close])
        let body = String(scan[scan.index(after: close)...])
        return (ref, body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "" : body)
    }
    /// seed the template body read from `fileRef`; a parsed body stays the delta
    public func setTemplate(_ body: String) {
        dflt = body
        if embed.isEmpty { embed = body }
    }
    func copy(_ flo: Flo) -> Embed {
        return Embed(flo, copy: self)
    }
    /// unseeded reference: any body at all is a tweak
    public override func hasDelta() -> Bool {
        guard let dflt else { return fileRef != nil && !embed.isEmpty }
        return embed != dflt
    }

    public static func == (lhs: Embed, rhs: Embed) -> Bool {
        return lhs.embed == rhs.embed
    }

    public override func getVal() -> Any {
        return embed
    }

    @discardableResult
    public override func setVal(_ any: Any?) -> Bool {

        if let v = any as? Embed {
            embed = v.embed
            return true
        }
        if let v = any as? String {
            embed = v
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
        // body ending in `}` would fuse into `}}}` and truncate on reparse
        let gap = embed.hasSuffix("}") ? "\n" : ""
        if let fileRef {
            // static: the reference alone; tweaked: reference keeps provenance
            return hasDelta()
            ? " {{ @<" + fileRef + ">" + embed + gap + "}}"
            : " {{ @<" + fileRef + "> }}"
        }
        return " {{" + embed + gap + "}}"
    }

}
