// created by musesum on 1/6/25

import Foundation

extension Substring {
    func advance(_ count: Int) -> Substring? {
        if count > 0 {
            if count < self.count {
                let startIndex = self.index(startIndex,
                                            offsetBy: count)
                return self[startIndex ..< endIndex]
            } else {
                return Substring()
            }
        }
        return nil
    }
}
