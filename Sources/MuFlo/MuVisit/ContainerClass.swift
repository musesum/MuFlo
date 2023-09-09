//
//  ContainerClass.swift
//  DeepMuse
//
//  Created by warren on 6/19/23.
//  Copyright © 2023 DeepMuse. All rights reserved.
//

import Foundation
import Collections

public class ArrayClass<T>: Sequence {
    var array: [T]

    public init(array: [T] = []) { self.array = array }
    public func append(_ item: T) { array.append(item)  }
    public var first: T? { array.first }
    public var last: T? { array.last }
    public var isEmpty: Bool { array.isEmpty }
    public var count: Int { array.count }

    public func makeIterator() -> ArrayIterator<T> {
        return ArrayIterator(array: array)
    }
}

// Custom iterator conforming to IteratorProtocol
public class ArrayIterator<T>: IteratorProtocol {
    private let array: [T]
    private var currentIndex = 0

    public init(array: [T]) {
        self.array = array
    }

    // Required method to conform to IteratorProtocol
    public func next() -> T? {
        guard currentIndex < array.count else {
            return nil
        }

        let element = array[currentIndex]
        currentIndex += 1
        return element
    }
}
public class OrderedSetClass<Key: Hashable>: Sequence where Key: Hashable  {
    public var keys: OrderedSet<Key>

    public init(_ keys: OrderedSet<Key> = []) { self.keys = keys }
    public var count: Int { keys.count }
    public var isEmpty: Bool { keys.isEmpty }

    public func append(_ key: Key) { keys.append(key) }
    public func makeIterator() -> OrderedSet<Key>.Iterator { return keys.makeIterator() }
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

