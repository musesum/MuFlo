//  ParMatching.swift
//
//  Created by warren on 8/5/17.
//  Copyright © 2017 DeepMuse
//  License: Apache 2.0 - see License file

import Foundation

/// An array of `[ParItem]`, which can reduce a single suffix
public class ParMatching {

    public var parItems = [ParItem]()
    var count = 0
    var ok = false

    var value: String? {
        get {
            if ok, let last = parItems.last {
                return last.value
            }
            return nil
        }
    }
    public var parLast: ParItem? {
        get {
            if ok, let last = parItems.last {
                return last
            }
            return nil
        }
    }

    init(_ parItem: ParItem? = nil, ok: Bool = false ) {
        if let parItem = parItem {

            if parItem.nextPars.isEmpty,
               parItem.node?.reps.repMin == 0 {
            }
            self.ok = ok
            parItems.append(parItem)
        }
    }

    init(_ parItems: [ParItem], ok: Bool = false ) {
        self.parItems = parItems
        self.ok = ok
    }

    /// add a sub ParMatching to this ParMatching
    func add (_ matching: ParMatching?) -> Bool {

        if  let matching = matching,
            let parLast = matching.parLast {

                add(parLast)
                return true
        }
        return false
    }

    /// add a parItem to this ParMatching
    func add (_ parItem: ParItem) {

        if !(parItem.node?.ignore ?? false) {
            parItems.append(parItem)
        }
    }

    /// return parItem with fewest hops
    func bestCandidate() -> ParMatching {
        guard var bestParItem = parItems.first else {
            return ParMatching(nil, ok: false)
        }
        for parItem in parItems {
            if parItem.hops < bestParItem.hops {
                bestParItem = parItem
            }
        }
        return ParMatching(bestParItem, ok: true)
    }

    /// Reduce anys
    func reduceFound(_ node: ParNode, _ isName: Bool = false) -> ParMatching {
        
        if !ok { return ParMatching(nil, ok: false) }
        
        switch parItems.count {

        case 0:
            let item = ParItem(node, nil)
            let matching = ParMatching(item, ok: true)
            return matching

        case 1:
            if  let parFirst = parItems.first,
                let parNode = parFirst.node {

                switch parNode.parOp  {

                case .def, .and, .or:

                    if isName, parNode.id != node.id {
                        return ParMatching(ParItem(node, [parFirst]), ok: true)
                    } else {
                        return ParMatching(parFirst, ok: true)
                    }
                case .match:

                    return ParMatching(parFirst, ok: true)

                case .quo, .rgx:

                    let item = ParItem(node, parFirst.value, parFirst.hops)
                    let matching = ParMatching(item, ok: true)
                    return matching
                }
            }
        default: break
        }

        // 
        var hasPromotePars = false
        var promotedNextPars = [ParItem]()
        for parItem in parItems {
            if let promotePars = promoteNextPars(parItem) {
                
                hasPromotePars = true
                promotedNextPars.append(contentsOf: promotePars)

            } else {

                promotedNextPars.append(parItem)
            }
        }
        if hasPromotePars {
            parItems = promotedNextPars
        }

        // sum up hops for chidren
        var hops = 0
        for parItem in parItems {
            hops += parItem.hops
        }
        let parItem = ParItem(node, parItems, hops)
        return ParMatching(parItem, ok: true)
    }

    /// Accommodate a graph like this, example:
    ///
    /// ParNode("or", [ParNode("and"), …
    ///            ParNode("+", [ParNode("\"|\""), …
    ///                      ParNode("and")])]), …
    ///
    /// which splits ParNode("+", []) into (.and, .many,"")
    /// So, the node.pattern is ""
    ///
    /// During a parse, the "" ParNode can contain a subarray,
    /// so promote it to the same level as its siblings
    ///
    /// for example, convert:
    ///     or:(path: show, (path: hide, path: setting, path: clear))
    /// to  or:(path: show, path: hide, path: setting, path: clear)

    func promoteNextPars(_ parItem: ParItem) -> [ParItem]? {
        if  parItem.node?.pattern == "",
            parItem.value == nil {

            return parItem.nextPars
        }
        return nil
    }
}
