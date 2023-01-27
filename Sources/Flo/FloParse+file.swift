//  FloParse+file.swift
//
//  Created by warren on 9/11/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation
import Par

class BundleResource {

    private let resourcePath = "../Resources"
    private let name: String
    private let type: String

    init(name: String, type: String) {
        self.name = name
        self.type = type
    }

    var path: String {
        let bundle = Bundle(for: Swift.type(of: self))
        guard let path = bundle.path(forResource: name, ofType: type) else {
            let filename: String = type.isEmpty ? name : "\(name).\(type)"
            let fullPath = resourcePath + "/" + filename
            return fullPath
        }
        return path
    }
}

public extension FloParse {

    func read(_ filename: String, _ ext: String) -> String {

        let path = BundleResource(name: filename, type: ext).path
        do {
            return try String(contentsOfFile: path) }
        catch {
            print("🚫 ParStr::\(#function) error:\(error) loading contents of:\(path)")
        }
        return ""
    }

    func parseFlo(_ root: Flo, _ filename: String, _ ext: String = "flo.h") -> Bool {
        let script = read(filename, ext)
        print(filename, terminator: " ")
        let success = parseScript(root, script)
        print(success ? "✓" : "🚫 parse failed")
        return success
    }

}
