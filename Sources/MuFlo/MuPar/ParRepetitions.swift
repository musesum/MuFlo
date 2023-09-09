//  ParRepetitions.swift
//
//  Created by warren on 7/3/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

public class ParRepetitions {
    
    enum Count: String { case
        one = ".",   // {1,1} exactly one
        opt = "?",   // {0,1} zero or one
        any = "*",   // {0,MaxReps} one or more
        many = "+",  // {1,MaxReps} one or more
        range = "{}" // {m,n} from m to n // reserved for later
    }
    var surf  = false // floating position,
    var count = Count.one // repetitions of after edges
    var repMin = 1  // minimum repetitions
    public var repMax = 1  // maximum repetitions
    var isExplicit = false // was explicitly declared, otherwise default value
    
    init(_ count_: Count = .one) {
        updateCount(count_)
    }

    public static func == (lhs: ParRepetitions, rhs: ParRepetitions) -> Bool {
        return ((lhs.repMin == rhs.repMin) &&
                (lhs.repMax == rhs.repMax))
    }

    func updateCount(_ count_: Count) {
        count = count_
        switch count {
        case .one:    repMin = 1; repMax = 1               //         {1,1}
        case .opt:    repMin = 0; repMax = 1               // ?       {0,1}
        case .any:    repMin = 0; repMax = ParEdge.MaxReps // *       {0,}
        case .many:   repMin = 1; repMax = ParEdge.MaxReps // +       {1,}
        case .range:  repMin = 1; repMax = 1               // {m,n}   {m,n}
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
                    repMax = ParEdge.MaxReps        // 1 in `{1,}`
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
        case "~": surf = true
        case "{": parseRange(input)
        default: updateCount(.range) ; isExplicit = false
        }
    }
    
    func makeScript() -> String  {

        var ret = ""

        switch count {
        case .range:

            ret += "{\(repMin),"
            ret += repMax == ParEdge.MaxReps ? "" : String(repMax)
            ret += "}"

        case .one:   break

        default:

            ret =  count.rawValue
        }
        if surf {
            ret += "~"
        }
        return ret
    }
    
}

