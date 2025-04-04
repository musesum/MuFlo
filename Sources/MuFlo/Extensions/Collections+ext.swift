// created by musesum on 7/6/24

import Collections

public typealias Name = String
public typealias NameInt = OrderedDictionaryClass<String,Int>
public typealias NameAny = OrderedDictionaryClass<String,Any>
public typealias EvalAnys =  ContiguousArray<EvalAny>

@MainActor //_____
extension EvalAnys {
    /// set a faux Set key, even though this is a Dict
    public mutating func setKey(_ key: String, op: EvalOp) {
        // already has op? return
        for opAny in self {
            if opAny.op == op { return }
        }
        // not yet, so add a (name,op) pair
        let nameRefer = [EvalAny(name: key),
                         EvalAny(op: op)]
        append(contentsOf: nameRefer)
    }
}
extension OrderedDictionary {

    mutating func replace(key: Key, with newKey: Key, value: Value) {
        guard let index = self.index(forKey: key) else { return }
        self.remove(at: index) // Remove the old key-value pair
        self.updateValue(value, forKey: newKey, insertingAt: index) // Insert the new key-value pair at the same position
    }
}
extension OrderedDictionary<Int,Parser> {
    mutating func replace(_ oldNode: Parser, with newNode: Parser) {
        guard let index = self.index(forKey: oldNode.id)
        else { return print("⁉️ OrderedDictionary::replace oldNode: \(oldNode.scriptTitle()) not Found") }

        self.remove(at: index)
        self.updateValue(newNode, forKey: newNode.id, insertingAt: index)
    }
    mutating func append(_ parser: Parser) {
        self[parser.id] = parser
    }
}
