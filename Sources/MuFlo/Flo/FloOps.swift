//  FloOps.swift
//  created by musesum on 1/21/26.

import Foundation

public struct FloOps: OptionSet, Sendable, Codable {
    public static let none  = Self(rawValue: 0)
    public static let menu  = Self(rawValue: 1 << 0)
    public static let share = Self(rawValue: 1 << 1)
    public static let local = Self(rawValue: 1 << 2)
    public static let allOps: [FloOps] = [.menu, .share, .local]

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

    public var menu: Bool {
        get { contains(.menu) }
        set {
            if newValue {
                rawValue |= FloOps.menu.rawValue
            } else {
                rawValue -= FloOps.menu.rawValue
            }
        }
    }
    public var share: Bool {
        get { contains(.share) }
        set {
            if newValue {
                rawValue |= FloOps.share.rawValue
            } else {
                rawValue -= FloOps.share.rawValue
            }
        }
    }

    static public func += (lhs: inout FloOps, rhs: FloOps) {
        lhs.rawValue |= rhs.rawValue
    }
    static public func -= (lhs: inout FloOps, rhs: FloOps) {
        lhs.rawValue = lhs.rawValue - rhs.rawValue
    }
    static public func - (lhs: FloOps, rhs: FloOps) -> FloOps {
        return lhs.subtracting(rhs)
    }

    /// floOps creates a policy that flows top-down from parent to children
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
        let priorOps = flo.parent?.floOps ?? FloOps()
        for testOp in FloOps.allOps {
            setOp(getOp())
            func getOp() -> Int {
                guard let exprs = flo.exprs, /// if no expression
                      let key = testOp.key, /// error with constructin key
                      let any = exprs.nameAny[key] /// expres does not have key
                else { /// not found, so continue priorOp
                    return priorOps.rawValue & testOp.rawValue
                }

                guard let val = (any as? Scalar)?.value
                else { /// has name key no scalar, so set testOp Flag
                    return testOp.rawValue
                }
                return val > 0 ? testOp.rawValue : 0
            }
            func setOp(_ newOp: Int) {
                // clear the bit for testOp, then set from newOp
                let cleared = flo.floOps.rawValue & ~testOp.rawValue
                flo.floOps.rawValue = cleared | newOp
            }
        }
    }
}

