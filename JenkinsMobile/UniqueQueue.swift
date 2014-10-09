//
//  UniqueQueue.swift
//  JenkinsMobile
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
    var itemcount: Int = 0
    
    func count() -> Int { return itemcount }
    
    func push(newItem: String) {
        
    }
    
    func pop() -> String {
        return "nil"
    }
    
}