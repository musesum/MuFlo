//  Parser+connect.swift
//  created by musesum on 7/7/17.

import Collections

public extension Parser {
    /**
     Search self, then before's afters, before's before's afters, etc.

     - Parameters:
     - name: name of node to find
     - visit: track nodes already visited to break loops
     */
    func findLeft(_ name: String, _ visit: Visitor) -> Parser? {

        // haven't been here before, so check it out
        guard visit.newVisit(id) else { return nil }

        // name refers to a left-node, residing here
        if [.def,.and,.or].contains(type),
           pattern.count > 0,
           pattern == name,
           subParsers.count > 0 {

            return self
        }
        // check for siblings which haven't been visited
        for subParser in subParsers.values {
            if let node = subParser.findLeft(name, visit) {
                return node
            }
        }
        // check for aunts/uncles which haven't been visited
        if let node = uberParser?.findLeft(name, visit) {
            return node
        }
        return nil
    }

    /// find references to elsewhere in namespace and connect edges
    internal func connectReferences(_ visit: Visitor) {

        /// deja vu? if already been here, then skip
        if !visit.newVisit(id) { return }

        if nameRefersToDefinitionElsewhere() {
            findAndSubstituteEdges()
        }
        for subParser in subParsers.values {
            subParser.connectReferences(visit)
        }

        // name has no suffixes, so real definition must reside somewhere else
        func nameRefersToDefinitionElsewhere() -> Bool {
            if ![.regx,.quote].contains(type),
               pattern.count > 0, // is an explicitly declared node
               subParsers.count == 0 // has no suffixes, so elsewhere
            {
                return true
            }
            return false
        }
        
        // search for named node and subsitute its edges
        func findAndSubstituteEdges() {
            guard let uberParser else { return }
            guard let parser = uberParser.findLeft(pattern, Visitor(id)) else {
                return print("⁉️ could not find reference: \"\(pattern)\".\(id)") }

            if parser.isName, !(parser.repeats == self.repeats) {
                graft(parser)
            } else {
                uberParser.subParsers.replace(self, with: parser)
            }
        }
    }

    /// Reduce nested Suffixs of same type
    ///
    ///        a (b | (c | d) )   ⟹  a (b | c | d)
    ///        a (b | (c | d)?)?  ⟹  a (b | c | d)?
    ///        a (b | (c | d)*)*  ⟹  a (b | c | d)*
    ///        a (b | (c | d)*)   ⟹  no change
    ///        a (b | (c | d)*)?  ⟹  no change
    ///
    /// - Parameter visit: track nodes already visited to break loops
    ///
    func distillSuffixs(_ visit: Visitor) {

        if !visit.newVisit(id) { return }

        if type == .or,
           subParsers.count > 0 {

            for subParser in subParsers.values {
                if isSelfRecursive(subParser) {
                    distill()
                    break
                }
            }
        }
        for subParser in subParsers.values {
            subParser.distillSuffixs(visit)
        }

        /**
         nested suffix is extension of self

         (a | ( b | c))   ⟹  true
         (a | ( b | c)?)  ⟹  false
         */
        func isSelfRecursive(_ subParser: Parser) -> Bool {

            if subParser.type == type,
               subParser.repeats.repMax == repeats.repMax,
               subParser.repeats.repMin == repeats.repMin,
               subParser.uberParser != nil {
                return true
            } else {
                return false
            }
        }

        /// promote nested suffix
        ///
        ///     (a | ( b | c))  ⟹  (a | b | c)
        ///
        func distill() {

            var newChildren = OrderedDictionary<Int,Parser>()

            for subParser in subParsers.values {

                if isSelfRecursive(subParser) {

                    subParser.distillSuffixs(visit)
                    // adopt grandchilren as children
                    for grandNode in subParser.subParsers.values {
                        grandNode.uberParser = self
                        newChildren.append(grandNode)
                    }
                } else {
                    newChildren.append(subParser)
                }
            }
            subParsers = newChildren
        }

    }

}
