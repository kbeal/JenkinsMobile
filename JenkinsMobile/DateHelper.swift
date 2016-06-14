//
//  DateHelper.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 2/13/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation

public class DateHelper {
    public static func dateStringFromTimestamp(timestamp: Double) -> String {
        let date: NSDate = NSDate(timeIntervalSince1970: timestamp/1000)
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
    }
    
    public static func dateStringFromDate(date: NSDate) -> String {
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .ShortStyle, timeStyle: .ShortStyle)
    }
    
    public static func relativeDateStringFromTimestamp(timestamp: Double) -> String? {
        var relativeString: String?
        let date: NSDate = NSDate(timeIntervalSince1970: timestamp/1000)
        let units: NSCalendarUnit = [.Second,.Minute,.Hour,.Day,.Month,.Year]
        let components = NSCalendar.currentCalendar().components(units, fromDate: date, toDate: NSDate(), options: [])
        
        let yearStr = String(components.year) + " yr"
        let monthStr = String(components.month) + " mo"
        let dayStr = components.day > 1 ? (String(components.day) + " days") : (String(components.day) + " day")
        let hourStr = String(components.hour) + " hr"
        let minuteStr = String(components.minute) + " min"
        let secondStr = String(components.second) + " sec"
        

        if (components.second > 0) {
            relativeString = secondStr
        }
        
        if (components.minute > 0) {
            relativeString = minuteStr
            if (components.minute < 10) {
                relativeString = minuteStr + " " + secondStr
            }
        }
        
        if (components.hour > 0) {
            relativeString = hourStr
            if (components.hour < 10) {
                relativeString = hourStr + " " + minuteStr
            }
        }
        
        if (components.day > 0) {
            relativeString = dayStr
            if (components.day < 10) {
                relativeString = dayStr + " " + hourStr
            }
        }
        
        if (components.month > 0) {
            relativeString = monthStr
            if (components.month < 10) {
                relativeString = monthStr + " " + dayStr
            }
        }
        
        if (components.year > 0) {
            relativeString = yearStr + " " + monthStr
        }
        

        return relativeString
    }
}