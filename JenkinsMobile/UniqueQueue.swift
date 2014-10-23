//
//  UniqueQueue.swift
//  JenkinsMobile
//
//  Worst class name ever?
//  Just alias it! swift is cool and does that
//
//  Q: How do you catch an UniqueQueue?
//  A: Unique up on 'em!
//
//  Created by Kyle on 10/8/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

import Foundation

public class UniqueQueue {
    
    var itemsDict = Dictionary<String,Bool>()
    var itemsArray: [String] = []
    
    init() {}
    
    func count() -> Int {
        assertCount()
        return itemsArray.count
    }
    
    func push(newItem: String) {
        if let existingItem = itemsDict[newItem] {
            return
        } else {
            itemsArray.append(newItem)
            itemsDict[newItem] = true
        }
        assertCount()
    }
    
    func pop() -> String? {
        if itemsArray.count == 0 {
            return nil
        } else {
            let itm = itemsArray[0]
            itemsArray.removeAtIndex(0)
            itemsDict.removeValueForKey(itm)
            assertCount()
            return itm
        }
    }
    
    func assertCount() {
        assert(itemsArray.count==itemsDict.count, "UniqueQueue array and dictionary not in Sync!!")
    }
    
    func removeAll() {
        itemsArray.removeAll(keepCapacity: false)
        itemsDict.removeAll(keepCapacity: false)
    }
    
}

extension UniqueQueue: SequenceType {
    public func generate() -> IndexingGenerator<[String]> {
        return itemsArray.generate()
    }
}