//  Policy.swift
//  created by musesum on 1/21/26.

import Foundation

public struct Policy: OptionSet, Sendable, Codable {

    public static let menu  = Self(rawValue: 1 << 0)
    public static let share = Self(rawValue: 1 << 1)
    public static let local = Self(rawValue: 1 << 2)

    private static let all: [Policy] = [.menu, .share, .local]

    public var rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var key: String? {
        switch self {
        case .menu  : return "menu"
        case .share : return "share"
        case .local : return "local"
        default     : return nil
        }
    }

    public init() {
        self.rawValue = (Self.menu.rawValue | Self.share.rawValue)
    }

    static public func += (lhs: inout Policy, rhs: Policy) {
        lhs.rawValue |= rhs.rawValue
    }
    static public func -= (lhs: inout Policy, rhs: Policy) {
        lhs.rawValue = lhs.rawValue - rhs.rawValue
    }
    static public func - (lhs: Policy, rhs: Policy) -> Policy {
        return lhs.subtracting(rhs)
    }

    /// Policy flows top-down from parent to children
    /// current there are two ops: .share and .menu
    /// where .show determines that the node will show in a menu
    /// where .reflect dtermins wither nodel will broadcast to peers
    /// for example:
    ///     ```
    ///     tape (share 0,...) // turns sharing off
    ///     beat (share 1,...) // turn sharing back on
    ///     loop (menu 0,...)  // hides node from menu
    ///     ```
    /// The default value is 1 so that the following are equivalent
    ///     ```
    ///     tape (...)
    ///     tape (share, ...)
    ///     tape (share 1, ...)
    ///
    /// TODO:
    ///     add tests to MuFloTest.swift
    ///     live changes so that `menu 0` will hide sub menus
    ///         based on the state of a particular node
    ///
    func update(_ flo: Flo) {
        let priorOps = flo.parent?.policy ?? Policy()
        for whereOp in Policy.all {
            setOp(getOp())
            func getOp() -> Int {
                guard let exprs = flo.exprs, /// if no expression
                      let key = whereOp.key, /// error with constructin key
                      let any = exprs.nameAny[key] /// expres does not have key
                else { /// not found, so continue priorOp
                    return priorOps.rawValue & whereOp.rawValue
                }

                guard let val = (any as? Scalar)?.value
                else { /// has name key no scalar, so set testOp Flag
                    return whereOp.rawValue
                }
                return val > 0 ? whereOp.rawValue : 0
            }
            func setOp(_ newOp: Int) {
                // clear the bit for testOp, then set from newOp
                let cleared = flo.policy.rawValue & ~whereOp.rawValue
                flo.policy.rawValue = cleared | newOp
            }
        }
    }
}

