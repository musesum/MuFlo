//  FloType.swift
//
//  Created by warren on 6/15/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public enum FloType { case
    unknown,
    name,
    path,    /// `p.q.r` generates `p { q { r } }`
    many,    /// `w{a b}.{c d>>c}` generates `w {a { c d>>c } b { c d>>c } }`
    copyall, ///` z©w` generates `z {a { c d>>c } b { c d>>c } }`
    copyat,  /// `z@w`  generates `z {a { c d } b { c d } }`
    remove,
    duplicate
}
