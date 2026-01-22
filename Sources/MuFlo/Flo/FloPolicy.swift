//  Policy.swift
//  created by musesum on 1/21/26.

import Foundation

public struct Policy: OptionSet, Sendable, Codable {

    public static let menu      = Self(rawValue: 1 << 0)
    public static let share     = Self(rawValue: 1 << 1)
    public static let `private` = Self(rawValue: 1 << 2)
    //WARNING: always extend mask for new flags
    private let mask: Int = 0b111

    private static let all: [Policy] = [.menu, .share, .private]

    public var rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    var key: String? {
        switch self {
        case .menu    : return "menu"
        case .share   : return "share"
        case .private : return "private"
        default       : return nil
        }
    }

    public init() {
        self.rawValue = (Self.menu.rawValue |
                         Self.share.rawValue)
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
    ///     tape (...)          // set on
    ///     tape (share, ...)   // set on
    ///     tape (share 1, ...) // set on
    ///
    /// TODO:
    ///     add tests to MuFloTest.swift
    ///     live changes so that `menu 0` will hide sub menus
    ///         based on the state of a particular node
    ///
    mutating func update(_ flo: Flo) {
        let parentPolicy = flo.parent?.policy ?? Policy()
        let oldRawValue = rawValue
        for wherePolicy in Policy.all {
            let newFlag = getFlag(wherePolicy)
            let whereFlag = wherePolicy.rawValue

            setFlag(whereFlag,newFlag)
        }
        if rawValue != oldRawValue {
            print("Policy changed: \(oldRawValue) -> \(rawValue) for \(flo.name)")
        }

        func getFlag(_ wherePolicy: Policy) -> Int {
            let whereFlag = wherePolicy.rawValue
            guard let exprs = flo.exprs, /// if no expression
                  let key = wherePolicy.key, /// unknown key
                  let any = exprs.nameAny[key] else {
                /// not found, so use parentPolicy's flag
                return whereFlag & parentPolicy.rawValue
            }

            guard let val = (any as? Scalar)?.value else {
                /// has name key but no scalar, so set Flag on
                return whereFlag
            }
            /// flag has explicit value, so use that
            return val > 0 ? whereFlag : 0
        }
        func setFlag(_ whereFlag: Int, // position of flag
                     _ newFlag: Int)   // new value of flag
        {
            let whereMask = mask ^ whereFlag
            let oldValue = self.rawValue
            self.rawValue = (oldValue & whereMask) | newFlag
            //print("\(oldValue)~\(whereFlag)|\(newFlag)=\(self.rawValue)", terminator: " ")
        }
    }
}

