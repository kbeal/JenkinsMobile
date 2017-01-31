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

open class UniqueQueue<T: Hashable> {
    
    var itemsDict = Dictionary<T,Bool>()
    var itemsArray: [T] = []
    let lockQueue = DispatchQueue(label: "com.kylebeal.JenkinsMobile.UniqueQueue.LockQueue", attributes: [])
    
    init() {}
    
    func count() -> Int {
        var cnt: Int?
        lockQueue.sync(execute: {
            self.assertCount("count")
            cnt = self.itemsArray.count
        })
        return cnt!
    }
    
    func push(_ newItem: T) {
        lockQueue.sync(execute: {
            if let _ = self.itemsDict[newItem] {
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
        lockQueue.sync(execute: {
            if self.itemsArray.count == 0 {
                itm = nil
            } else {
                itm = self.itemsArray[0]
                self.itemsArray.remove(at: 0)
                self.itemsDict.removeValue(forKey: itm!)
                self.assertCount("pop")
            }
        })
        return itm
    }
    
    func assertCount(_ caller: String) {
        assert(self.itemsArray.count==self.itemsDict.count, "\(caller) UniqueQueue array \(self.itemsArray.count) and dictionary \(self.itemsDict.count) not in Sync!!")
    }
    
    func removeAll() {
        lockQueue.sync(execute: {
            self.itemsArray.removeAll(keepingCapacity: false)
            self.itemsDict.removeAll(keepingCapacity: false)
        })
    }
    
}

extension UniqueQueue: Sequence {
    public func makeIterator() -> IndexingIterator<[T]> {
        return itemsArray.makeIterator()
    }
}
