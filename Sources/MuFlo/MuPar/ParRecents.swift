//  ParRecents.swift
//
//  Created by warren on 9/11/19.
//  License: Apache 2.0 - see License file

import Foundation


public class ParRecents: ParMatching {

    public static var shortTermMemory = TimeInterval(0) // seconds

    func forget(_ timeNow: TimeInterval) {
        if parItems.count == 0 {
            return
        }
        if timeNow == 0 {
            return parItems.removeAll()
        }
        let cutoffTime = timeNow - ParRecents.shortTermMemory
        var removeCount = 0
        for parItem in parItems {
            if parItem.time < cutoffTime {
                removeCount += 1
            } else {
                break
            }
        }
        if removeCount > 0 {
            parItems.removeFirst(removeCount)
        }
    }

 }
