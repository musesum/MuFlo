// created by musesum on 1/6/25

import Foundation

/// result range for regular expression
struct RangeRegx {
    var matching: Range<String.Index>?
    var advance: Range<String.Index>?
    init(_ matching_: NSRange, _ advance_: NSRange, _ str: String) {
        matching = Range(matching_, in: str)
        advance = Range(advance_, in: str)
    }
}
