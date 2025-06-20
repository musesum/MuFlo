import UIKit

public extension UITouch.Phase {
    
    var done: Bool { return self == .ended || self == .cancelled }

    var symbol: String {
        switch self {
        case .began : "ᴮ"
        case .moved : "ᴹ"
        case .ended : "ᴱ"
        default     : "⁰"
        }
    }
}

public extension Int {
    
    func uiPhase() -> UITouch.Phase {
        
        switch self {
        case 0: return .began
        case 1: return .moved
        case 2: return .moved // stationary override for now
        default: return .ended
        }
    }
}
