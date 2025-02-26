//  ParRepeats.swift
//  created by musesum on 7/3/17.

import Foundation

let MaxReps = 200

enum ParCount: String {
    case one    // {1,1} exactly one
    case opt    // {0,1} zero or one
    case any    // {0,MaxReps} one or more
    case many   // {1,MaxReps} one or more
    case range  // {m,n} from m to n // reserved for later
}

public class ParRepeats {

    var count = ParCount.one // repetitions of after edges
    var repMin = 1  // minimum repetitions
    var repMax = 1  // maximum repetitions
    var isExplicit = false // was explicitly declared, otherwise default value
    var description: String { "{\(repMin),\(repMax)}" }

    init(_ count: ParCount = .one) {
        updateCount(count)
    }

    public static func == (lhs: ParRepeats, rhs: ParRepeats) -> Bool {
        return ((lhs.repMin == rhs.repMin) &&
                (lhs.repMax == rhs.repMax))
    }

    func updateCount(_ count_: ParCount) {
        count = count_
        switch count {
        case .one:    repMin = 1; repMax = 1        //        {1,1}
        case .opt:    repMin = 0; repMax = 1        // ?      {0,1}
        case .any:    repMin = 0; repMax = MaxReps  // *      {0,}
        case .many:   repMin = 1; repMax = MaxReps  // +      {1,}
        case .range:  repMin = 1; repMax = 1        // {m,n}  {m,n}
        }
    }
    /// set min and max count based on `{a,b}`
    ///
    ///     {1,2} repMin: 1 repMax: 2
    ///     {1,}  repMin: 1 repMax: MaxReps (200)
    ///     {,2}  repMin: 0 repMax: 2
    ///     {2}   repMin: 2 repMax: 2
    func parseRange(_ input: String) {
        count = .range
        var comma = 0
        for i in 1..<input.count {
            let c = input[i]
            if c == "," {
                comma = i
                if i > 1 {
                    repMin = Int(input[1 ..< i])!   // 1 in `{1,2}`
                    repMax = MaxReps                // 1 in `{1,}`
                } else {
                    repMin = 0                      // 2 in `{,2}`
                }
            } else if c == "}" {

                if comma == 0, i > 1 {              // 2 in `{2}`
                    repMax = Int(input[1 ..< i])!
                    repMin = repMax
                }
                else if i > comma + 1 {             // 2 in `{1,2}`
                    repMax = Int(input[comma+1 ..< i])!
                }
            }
        }
    }


    func parse(_ input: String) {
        isExplicit = true
        switch input.first {
        case ".": updateCount(.one)
        case "?": updateCount(.opt)
        case "*": updateCount(.any)
        case "+": updateCount(.many)
        case "{": parseRange(input)
        default: updateCount(.range) ; isExplicit = false
        }
    }

    func makeScript() -> String  {

        var script = ""

        switch count {
        case .range:

            script += "{\(repMin),"
            script += repMax == MaxReps ? "" : String(repMax)
            script += "}"

        case .one:   break

        default:

            script =  count.rawValue
        }
        return script
    }

}

