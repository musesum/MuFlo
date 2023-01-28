//  Created by warren on 1/27/23.

import Foundation

public struct FloFindOps: OptionSet {

    public static let parents  = FloFindOps(rawValue: 1 << 0) // General type FloValScalar
    public static let children = FloFindOps(rawValue: 1 << 1) // General type FloValScalar
    public static let makePath = FloFindOps(rawValue: 1 << 2) // General type FloValScalar

    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    var parents  : Bool { contains(.parents ) }
    var children : Bool { contains(.children) }
    var makePath : Bool { contains(.makePath) }
}
