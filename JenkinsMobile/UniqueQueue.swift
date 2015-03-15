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

public class UniqueQueue<T: Hashable> {
    
    var itemsDict = Dictionary<T,Bool>()
    var itemsArray: [T] = []
    let lockQueue = dispatch_queue_create("com.kylebeal.JenkinsMobile.UniqueQueue.LockQueue", DISPATCH_QUEUE_SERIAL)
    
    init() {}
    
    func count() -> Int {
        var cnt: Int?
        dispatch_sync(lockQueue, {
            self.assertCount("count")
            cnt = self.itemsArray.count
        })
        return cnt!
    }
    
    func push(newItem: T) {
        dispatch_sync(lockQueue, {
            if let existingItem = self.itemsDict[newItem] {
                return
            } else {
                self.itemsArray.append(newItem)
                self.itemsDict[newItem] = true
            }
            self.assertCount("push")
        })
    }
    
    func pop() -> T? {
        var itm: T?
        dispatch_sync(lockQueue, {
            if self.itemsArray.count == 0 {
                itm = nil
            } else {
                itm = self.itemsArray[0]
                self.itemsArray.removeAtIndex(0)
                self.itemsDict.removeValueForKey(itm!)
                self.assertCount("pop")
            }
        })
        return itm
    }
    
    func assertCount(caller: String) {
        assert(self.itemsArray.count==self.itemsDict.count, "\(caller) UniqueQueue array \(self.itemsArray.count) and dictionary \(self.itemsDict.count) not in Sync!!")
    }
    
    func removeAll() {
        dispatch_sync(lockQueue, {
            self.itemsArray.removeAll(keepCapacity: false)
            self.itemsDict.removeAll(keepCapacity: false)
        })
    }
    
}

extension UniqueQueue: SequenceType {
    public func generate() -> IndexingGenerator<[T]> {
        return itemsArray.generate()
    }
}