//
//  BuildDictionary.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/2/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation

public class BuildDictionary: NSObject, NSCoding {
    
    var dictionary: NSDictionary!
    
    required convenience public init?(coder decoder: NSCoder) {
        let dictionary = decoder.decodeObjectForKey(BuildDictionaryDictionaryKey) as! NSDictionary
        self.init(dictionary: dictionary)
    }
    
    public init?(dictionary: NSDictionary) {
        super.init()
        let number: Int? = dictionary.objectForKey(BuildNumberKey) as? Int
        if number == nil { return nil }
        self.dictionary = dictionary
    }
    
    public subscript(key: AnyObject) -> AnyObject? {
        return self.dictionary.objectForKey(key)
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        var isEqual: Bool = false
        
        if let obj: BuildDictionary = object as? BuildDictionary {
            isEqual = obj[BuildNumberKey]!.isEqual(self.dictionary[BuildNumberKey])
        }
        
        return isEqual
    }
    
    public override var hash: Int {
        return self.dictionary.objectForKey(BuildNumberKey)!.hash
    }
    
    public override func valueForKey(key: String) -> AnyObject? {
        return self.dictionary.valueForKey(key)
    }
    
    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.dictionary, forKey: BuildDictionaryDictionaryKey)
    }
}

