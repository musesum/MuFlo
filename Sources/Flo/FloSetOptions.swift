//  FloFlags.swift
//
//  Created by warren on 5/9/19.
//  Copyright © 2019 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public struct FloSetOptions: OptionSet {

    public static let activate = FloSetOptions(rawValue: 1 << 0) // trigger event
    public static let sneak    = FloSetOptions(rawValue: 1 << 1) // quietly set value, no trigger
    public static let changed  = FloSetOptions(rawValue: 1 << 3) // bang only when changed
    public static let animNow  = FloSetOptions(rawValue: 1 << 4) // only set `now`, not `next` for animation

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var activate : Bool { contains(.activate) }
    var sneak    : Bool { contains(.sneak   ) }
    var changed  : Bool { contains(.changed ) }
    var animNow  : Bool { contains(.animNow ) }

    static public func += (lhs: inout FloSetOptions, rhs: FloSetOptions) {
        lhs.rawValue &= rhs.rawValue
    }

}
