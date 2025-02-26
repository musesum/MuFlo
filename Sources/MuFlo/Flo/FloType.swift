//  FloType.swift
//  created by musesum on 6/15/19.

import Foundation

public enum FloType: String { case
    unknown,
    name,    /// `a`, `b`, `c` in `a { b c }`
    path,    /// `p.q.r` generates `p { q { r } }`
    graft,   /// `w{a b}.{c d(->c) }` generates `w { a { c d(->c) } b { c d(->c) } }`
    base,   /// `z:w`  generates `z { a { c d(->c) } b { c d(->c) } }`
    remove   ///
}
