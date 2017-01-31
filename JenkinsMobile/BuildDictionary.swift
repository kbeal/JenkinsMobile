//
//  BuildDictionary.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/2/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation

open class BuildDictionary: NSObject, NSCoding {
    
    var dictionary: NSDictionary!
    
    required convenience public init?(coder decoder: NSCoder) {
        let dictionary = decoder.decodeObject(forKey: BuildDictionaryDictionaryKey) as! NSDictionary
        self.init(dictionary: dictionary)
    }
    
    public init?(dictionary: NSDictionary) {
        super.init()
        let number: Int? = dictionary.object(forKey: BuildNumberKey) as? Int
        if number == nil { return nil }
        self.dictionary = dictionary
    }
    
    open subscript(key: AnyObject) -> AnyObject? {
        return self.dictionary.object(forKey: key) as AnyObject?
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        var isEqual: Bool = false
        
        if let obj: BuildDictionary = object as? BuildDictionary {
            isEqual = obj[BuildNumberKey as AnyObject]!.isEqual(self.dictionary[BuildNumberKey])
        }
        
        return isEqual
    }
    
    open override var hash: Int {
        return (self.dictionary.object(forKey: BuildNumberKey)! as AnyObject).hash
    }
    
    open override func value(forKey key: String) -> Any? {
        return self.dictionary.value(forKey: key)
    }
    
    open func encode(with coder: NSCoder) {
        coder.encode(self.dictionary, forKey: BuildDictionaryDictionaryKey)
    }
}

