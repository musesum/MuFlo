//  FloValTern.swift
//
//  Created by warren on 3/10/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public typealias CallTern = ((FloValTern)->())

public enum FloAct { case
    activate, // activate and pass values when condition is true
    sneak     // set values and adjust connections w/o activation
}

public enum FloTernState { case
    ifVal,     // `a` in `a ? b : c`
    thenVal,   // `b` in `a ? b : c`
    elseVal,   // `c` in `a ? b : c`
    radioVal,  // … in (… | …) exclusive switch, like 'radio' button 
    noVal // deactivated sub-Tern in Radio
}

/// bidirection switched flow ternary with radio-button style extension
///
///     w << (a == b) // receive bang to w with no value
///     w << (a == b : 1) // recv value 1 to w
///     w << (a == b ? c : d) // recv c or d to w
///     w << (a ? 1 : b ? 2 : c ? 3) // recv 1 if a, 2 if a&b, 3 if a & b & c
///     w << (a ? a1 : a2 | b ? b1 : b2 | c ? c1 : c2) // recv a1 if , else recv a2, b block b1, b2, c1, c2
///
///     w >> (a == b) // not a ternary, is a FloValExprs
///     w >> (a == b : 1) / not a ternary, is a FloValExprs
///     
///     w >> (a == b ? c : d) // if a==b, send w to c, else send w to d
///     w >> (a ? 1 : b ? 2 : c ? 3) // recv 1 if a, 2 if a&b, 3 if a & b & c
///     w >> (a ? a1 : a2 | b ? b1 : b2 | c ? c1 : c2) // if a, recv a1, else recv a2, b block b1, b2, c1, c2
///
///     w << (a ? 1 | b ? b1 : b2 | c ? c1 ? c2 | d ? d1 : d2)
///     w << (a ? a1 : a2 ) | (b ? b2 : b2) | (c ? c1 : c2)
///     w << (a ? a1 : a2   |  b ? b1 : b2  |  c ? c1 : c2)
///     w <<  a ? a1 : a2   |  b ? b1 : b2  |  c ? c1 : c2

public class FloValTern: FloValPath {
    
    static var ternStack = [FloValTern]() // only single threaded parse allowed

    var parseLevel = 0 // a, b, c are at different levels in (a ? b ? c ? 3 : 2 : 1 )
    var ternState = FloTernState.ifVal
    var compareRight: FloValPath?   // b in `(a == b ? c : d)`, FloValPath.path contains a
    var compareOp = ""              // "==" in (a == b ? c : d)
    
    var thenVal: FloVal?
    var elseVal: FloVal?

    /// When activated, a radio segment needs to deactive all its neighbors
    /// via linked list of all the tern segments that occur before and after
    var radioPrev: FloValTern?
    var radioNext: FloValTern?
    
    override init(with from: FloVal) {

        if let from = from as? FloValTern {

            super.init(with: from)

            self.flo     = from.flo
            ternState    = from.ternState
            compareRight = from.compareRight?.copy() ?? nil
            compareOp    = from.compareOp
            thenVal      = from.thenVal?.copy() ?? nil
            elseVal      = from.elseVal?.copy() ?? nil
            radioPrev    = from.radioPrev
            radioNext    = from.radioNext
            parseLevel   = from.parseLevel
        }
        else {
            //TODO: placeholder?
            super.init(Flo(),"ternary")
        }
    }
    override func copy() -> FloValTern {
        return FloValTern(with: self)
    }

    init(_ flo: Flo, _ parseLevel: Int) {
        super.init(flo, "ternary")
        self.flo = flo
        self.parseLevel = parseLevel
    }

    static func getTernLevel(_ level: Int) -> FloValTern?  {
        while ternStack.last?.parseLevel ?? 0 > level {
            let _ = ternStack.popLast()
        }
        if let ternLast = ternStack.last {
            return ternLast
        }
        else {
            print("🚫 FloValTern.getTernLevel(\(level)) not found")
        }
        return nil
    }
    
    static func setTernState(_ ternState_: FloTernState, _ level: Int) {
        if let tern = getTernLevel(level) {
            tern.ternState = ternState_
        }
    }

    static func setCompare(_ compareOp: String?) {
        if let compareOp = compareOp {
            if let tern = ternStack.last {
                tern.compareOp = compareOp
            }
        }
    }

    public func addPath(_ path_: String) {

        switch ternState {

            case .ifVal:

                if path == "" { path = path_ }
                else { compareRight = FloValPath(flo, with: path_) }

            case .thenVal: thenVal = FloValPath(flo, with: path_)
            case .elseVal: elseVal = FloValPath(flo, with: path_)
            default:    break
        }
    }

    /// While parsing, get most recently added FloVal to decorate with additional attributes.
    func getVal() -> FloVal? {
        switch ternState {
            case .ifVal:    return nil
            case .thenVal:  return thenVal
            case .elseVal:  return elseVal
            case .radioVal: return radioNext
            default: break
        }
        return nil
    }

    func addVal(_ val: FloVal) {
        
        if let ternVal = val as? FloValTern {

            switch ternState {
                case .ifVal, .thenVal: thenVal = ternVal
                case .elseVal:         elseVal = ternVal
                case .radioVal:

                    if let lastTern = FloValTern.ternStack.last {
                        if lastTern.id != ternVal.id {
                            lastTern.radioNext = ternVal
                            ternVal.radioPrev = lastTern
                        }
                    }
                default: break
            }
            FloValTern.ternStack.append(ternVal)
        }
        else {
            switch ternState {
                case .ifVal, .thenVal: thenVal = val
                case .elseVal:         elseVal = val
                default: break
            }
        }
    }
    func deepAddVal(_ val: FloVal) {

        if let ternVal = FloValTern.ternStack.last {
            ternVal.addVal(val)
        }
    }

    public override func printVal() -> String {
        return "??"
    }

    public override func scriptVal(_ scriptOpts: FloScriptOps) -> String {

        var script = scriptOpts.parens ? "(" : ""
        if scriptOpts.expand {
            script += Flo.scriptFlos(pathFlos)
            script.spacePlus(compareOp)
            script.spacePlus(Flo.scriptFlos(compareRight?.pathFlos ?? []))
        } else {
            script += path
            script.spacePlus(compareOp)
            script.spacePlus(compareRight?.path) 
        }
        if let thenVal = thenVal {
            script.spacePlus("?")
            script.spacePlus(thenVal.scriptVal([.def, .now]))
        }
        if let elseVal = elseVal {
            script.spacePlus(":")
            script.spacePlus(elseVal.scriptVal([.def, .now]))
        }
        if let radioNext = radioNext {
            script.spacePlus("|")
            script.spacePlus(radioNext.scriptVal([.def, .now]))
        }
        script += scriptOpts.parens ? ")" : ""
        return script
    }
}
