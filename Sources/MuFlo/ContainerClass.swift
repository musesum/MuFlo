//
//  ContainerClass.swift
//  DeepMuse
//
//  Created by warren on 6/19/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import Foundation
import Collections




class ArrayClass<T>: Sequence {
    var array: [T]

    init(array: [T] = []) { self.array = array }
    func append(_ item: T) { array.append(item)  }
    var first: T? { array.first }
    var last: T? { array.last }
    var isEmpty: Bool { array.isEmpty }
    var count: Int { array.count }

    func makeIterator() -> ArrayIterator<T> {
        return ArrayIterator(array: array)
    }
}

// Custom iterator conforming to IteratorProtocol
class ArrayIterator<T>: IteratorProtocol {
    private let array: [T]
    private var currentIndex = 0

    init(array: [T]) {
        self.array = array
    }

    // Required method to conform to IteratorProtocol
    func next() -> T? {
        guard currentIndex < array.count else {
            return nil
        }

        let element = array[currentIndex]
        currentIndex += 1
        return element
    }
}

public class OrderedDictionaryClass<Key: Hashable, Value>: Sequence where Key: Hashable  {
    var dictionary: OrderedDictionary<Key, Value>

    public init(_ dictionary: OrderedDictionary<Key, Value> = [:]) { self.dictionary = dictionary }
    public var values: OrderedDictionary<Key, Value>.Values { dictionary.values }
    public var keys: OrderedSet<Key> { dictionary.keys }
    public var count: Int { dictionary.count }
    public var isEmpty: Bool { dictionary.isEmpty }

    public func makeIterator() -> OrderedDictionary<Key, Value>.Iterator { return dictionary.makeIterator() }

    public subscript(key: Key) -> Value? {
        get { return dictionary[key] }
        set { dictionary[key] = newValue }
    }
}
public class DictionaryClass<Key, Value>: Sequence where Key: Hashable {
    var dictionary: [Key: Value]

    public init(_ dictionary: [Key: Value]) { self.dictionary = dictionary }
    public var values: Dictionary<Key, Value>.Values { dictionary.values }
    public var keys: Dictionary<Key, Value>.Keys { dictionary.keys }
    public var count: Int { dictionary.count }
    public var isEmpty: Bool { dictionary.isEmpty }
    
    public func makeIterator() -> DictionaryIterator<Key, Value> { return dictionary.makeIterator() }
    public subscript(key: Key) -> Value? {
        get { return dictionary[key] }
        set { dictionary[key] = newValue }
    }
}

