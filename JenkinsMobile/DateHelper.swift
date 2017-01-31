//
//  DateHelper.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 2/13/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation

open class DateHelper {
    open static func dateStringFromTimestamp(_ timestamp: Double) -> String {
        let date: Date = Date(timeIntervalSince1970: timestamp/1000)
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }
    
    open static func dateStringFromDate(_ date: Date) -> String {
        return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
    }
    
    open static func relativeDateStringFromTimestamp(_ timestamp: Double) -> String? {
        var relativeString: String?
        let date: Date = Date(timeIntervalSince1970: timestamp/1000)
        let units: NSCalendar.Unit = [.second,.minute,.hour,.day,.month,.year]
        let components = (Calendar.current as NSCalendar).components(units, from: date, to: Date(), options: [])
        
        let yearStr = String(describing: components.year) + " yr"
        let monthStr = String(describing: components.month) + " mo"
        let dayStr = components.day! > 1 ? (String(describing: components.day) + " days") : (String(describing: components.day) + " day")
        let hourStr = String(describing: components.hour) + " hr"
        let minuteStr = String(describing: components.minute) + " min"
        let secondStr = String(describing: components.second) + " sec"
        

        if (components.second! > 0) {
            relativeString = secondStr
        }
        
        if (components.minute! > 0) {
            relativeString = minuteStr
            if (components.minute! < 10) {
                relativeString = minuteStr + " " + secondStr
            }
        }
        
        if (components.hour! > 0) {
            relativeString = hourStr
            if (components.hour! < 10) {
                relativeString = hourStr + " " + minuteStr
            }
        }
        
        if (components.day! > 0) {
            relativeString = dayStr
            if (components.day! < 10) {
                relativeString = dayStr + " " + hourStr
            }
        }
        
        if (components.month! > 0) {
            relativeString = monthStr
            if (components.month! < 10) {
                relativeString = monthStr + " " + dayStr
            }
        }
        
        if (components.year! > 0) {
            relativeString = yearStr + " " + monthStr
        }
        

        return relativeString
    }
}
