//
//  JobDictionary.swift
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

open class JobDictionary: NSObject, NSCoding {
    
    var dictionary: NSDictionary!
    
    required convenience public init?(coder decoder: NSCoder) {
        let dictionary = decoder.decodeObject(forKey: JobDictionaryDictionaryKey) as! NSDictionary
        self.init(dictionary: dictionary)
    }
    
    public init?(dictionary: NSDictionary) {
        super.init()
        let name: String? = dictionary.object(forKey: JobNameKey) as? String
        if name == nil { return nil }
        self.dictionary = dictionary
    }
    
    open subscript(key: AnyObject) -> AnyObject? {
        return self.dictionary.object(forKey: key) as AnyObject?
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        var isEqual: Bool = false
        
        if let obj: JobDictionary = object as? JobDictionary {
            isEqual = obj[JobNameKey as AnyObject]!.isEqual(self.dictionary[JobNameKey])
        }
        
        return isEqual
    }
    
    open override var hash: Int {
        return (self.dictionary.object(forKey: JobNameKey)! as AnyObject).hash
    }
    
    open override func value(forKey key: String) -> Any? {
        return self.dictionary.value(forKey: key)
    }

    open func encode(with coder: NSCoder) {
        coder.encode(self.dictionary, forKey: JobDictionaryDictionaryKey)
    }
}
