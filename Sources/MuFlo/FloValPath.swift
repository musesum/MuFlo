//  FloValPath.swift
//
//  Created by warren on 4/23/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import MuPar // Visitor

public class FloValPath: FloVal {

    @objc  var path = ""
    var pathFlos = [Flo]()

    override init(_ flo: Flo, _ name: String) {
        super.init(flo, name)
    }

    init(_ flo: Flo, with path: String) {
        super.init(flo, path)
        self.path = path
    }
    
    init(with: FloValPath) {
        super.init(with: with)
        path = with.path
        // copy only path definition; not edges, which are relative to Flo's position in hierarchy
        // pathFlos  = with.pathFlos
    }

    public static func == (lhs: FloValPath, rhs: FloValPath) -> Bool {
        return lhs.path == rhs.path
    }


    public override func printVal() -> String {

        if pathFlos.isEmpty {
            return path
        }
        else {
            var script = pathFlos.count > 1 ? "(" : ""

            for pathFlo in pathFlos {
                script.spacePlus(pathFlo.val?.printVal() ?? pathFlo.name)
            }
            if pathFlos.count > 1 { return script.with(trailing: ")") }
            else                  { return script }
        }
    }
    public override func scriptVal(_ scriptFlags: FloScriptFlags = [.parens]) -> String {
        
        if scriptFlags.expand {
            var script = Flo.scriptFlos(pathFlos)
            if script.first != "(" {
                script = "(\(script))"
            }
            return script
        } else {
            return path
        }
    }

    override func copy() -> FloValPath {
        let newFloValPath = FloValPath(with: self)
        return newFloValPath
    }

    public override func setVal(_ any: Any?,
                                _ visitor: Visitor) -> Bool {
        //TODO: is ever used during runtime?
        return true
    }

    public override func getVal() -> Any {
        return path
    }

}
