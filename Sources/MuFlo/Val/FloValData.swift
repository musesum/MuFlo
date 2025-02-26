//  FloValData.swift
//  created by musesum on 4/4/19.

import Foundation


public class FloValData: FloVal {

    var data: UnsafeMutablePointer<UInt8>? = nil
    var size = 0

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, name)
    }
    init(with: FloValData) {
        super.init(with.flo, with.name)
        size = with.size
        data = with.data //TODO: allocate new memory and copy}
    }
    override func copy() -> FloVal {
        return FloValData(with: self)
    }
    public static func == (lhs: FloValData, rhs: FloValData) -> Bool {

        if rhs.size == 0 || rhs.size != lhs.size {
            return false
        }
        let lbuf = lhs.data
        let rbuf = rhs.data

        for i in 0 ..< lhs.size {
            if lbuf![i] != rbuf![i] {
                return false
            }
        }
        return true
    }

    public override func scriptVal(_ from: Flo,
                                   _ scriptOps: FloScriptOps = [.parens,.expand],
                                   viaEdge: Bool,
                                   noParens: Bool = false) -> String {
        return "[data]"
    }

}
