//  BundleResource.swift
//  
//  Created by warren on 9/10/19.
//  License: Apache 2.0 - see License file

import Foundation

class BundleResource {

    let resourcePath = "../Resources"
    let name: String
    let type: String

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
