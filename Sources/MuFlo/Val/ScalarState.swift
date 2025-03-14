// created by musesum on 3/13/25

import Foundation
public struct ScalarState: OptionSet {

    public static let onOrigin  = ScalarState(rawValue: 1 <<  1)
    public static let offOrigin = ScalarState(rawValue: 1 <<  2)
    public static let hasPrior  = ScalarState(rawValue: 1 <<  3)

    /// Some values like midi.note.on midi.note.off should not persist transient values.
    /// So, when saving FloScriptOps.delta, ignore a transient node.
    /// Otherwise, restoring from a .delta could activate stale values,
    /// such as a stale midi.note.on
    var isTransient: Bool {
        let defset: ScalarOps = [.tween, .value, .liter]
        return (self.rawValue & defset.rawValue) == 0
    }

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public init(_ scalar: Scalar) {
        self = []
        if  scalar.scalarOps.origin {
            if scalar.value == scalar.origin {
                self.insert(.onOrigin)
            } else {
                self.insert(.offOrigin)
            }
        }
        if scalar.value != scalar.prior {
            self.insert(.hasPrior)
        }
    }
    public var onOrigin  : Bool { contains(.onOrigin ) }
    public var offOrigin : Bool { contains(.offOrigin ) }
    public var hasPrior  : Bool { contains(.hasPrior ) }
}
