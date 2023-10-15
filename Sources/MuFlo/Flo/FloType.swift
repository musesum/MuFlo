//  FloType.swift
//  created by musesum on 6/15/19.

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
