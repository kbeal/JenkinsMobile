//
//  JobBatch.swift
//  JenkinsMobile
//
//  Custom NSDictionary that provides a specialized hashing function
//  to improve performance for a Dictionary containing a Job
//
//  Uses the name property of the Dictionary Item to compute hash
//  and determine equality
//
//  Created by Kyle Beal on 11/16/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//

import Foundation

public class JobDictionary: NSObject {
    
    var dictionary: NSDictionary!
    
    public init?(dictionary: NSDictionary) {
        super.init()
        let name: String? = dictionary.objectForKey(JobNameKey) as? String
        if name == nil { return nil }
        self.dictionary = dictionary
    }
    
    public subscript(key: AnyObject) -> AnyObject? {
        return self.dictionary.objectForKey(key)
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        var isEqual: Bool = false
        
        if let obj: JobDictionary = object as? JobDictionary {
            isEqual = obj[JobNameKey]!.isEqual(self.dictionary[JobNameKey])
        }
        
        return isEqual
    }
    
    public override var hash: Int {
        return self.dictionary.objectForKey(JobNameKey)!.hash
    }
    
    public override func valueForKey(key: String) -> AnyObject? {
        return self.dictionary.valueForKey(key)
    }
}
