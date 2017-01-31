//
//  DateHelperTests.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 2/13/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile

class DateHelerTests: XCTestCase {
    func testCreateDateStringFromTimeStamp() {
        let currenttime: Double = 1454286019292
        let datestring = DateHelper.dateStringFromTimestamp(currenttime)
        XCTAssert(datestring == "1/31/16, 7:20 PM")
    }
    
    func testRelativeDateStringFromTimeStamp() {
        let rightnow = Date()
        let calendar = Calendar.current
        var components = DateComponents()
        
        // 1 yr 6 mo
        components.year = -1
        components.month = -6
        components.day = -4
        let oneYearSixMonthsAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let oneYearSixMonthsAgoStr = DateHelper.relativeDateStringFromTimestamp((oneYearSixMonthsAgo?.timeIntervalSince1970)! * 1000)
        
        // 10 mo
        components.year = 0
        components.month = -10
        let tenMonthsAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let tenMonthsAgoStr = DateHelper.relativeDateStringFromTimestamp((tenMonthsAgo?.timeIntervalSince1970)! * 1000)
        
        // 7 mo 20 days
        components.month = -7
        components.day = -19
        let sevenMonthsTwentyDaysAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let sevenMonthsTwentyDaysAgoStr = DateHelper.relativeDateStringFromTimestamp((sevenMonthsTwentyDaysAgo?.timeIntervalSince1970)! * 1000)
        
        // 11 days
        components.month = 0
        components.day = -11
        let elevenDaysAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let elevenDaysAgoStr = DateHelper.relativeDateStringFromTimestamp((elevenDaysAgo?.timeIntervalSince1970)! * 1000)
        
        // 8 days 4 hours
        components.day = -8
        components.hour = -4
        let eightDaysFourHoursAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let eightDaysFourHoursAgoStr = DateHelper.relativeDateStringFromTimestamp((eightDaysFourHoursAgo?.timeIntervalSince1970)! * 1000)
        
        // ten hours
        components.day = 0
        components.hour = -10
        components.minute = -15
        let tenHoursAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let tenHoursAgoStr = DateHelper.relativeDateStringFromTimestamp((tenHoursAgo?.timeIntervalSince1970)! * 1000)
        
        // six hours 15 minutes
        components.hour = -6
        let sixHoursFifteenMinutesAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let sixHoursFifteenMinutesAgoStr = DateHelper.relativeDateStringFromTimestamp((sixHoursFifteenMinutesAgo?.timeIntervalSince1970)! * 1000)
        
        // 37 minutes
        components.hour = 0
        components.minute = -37
        components.second = -56
        let thirtySevenMinutesAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let thirtySevenMinutesAgoStr = DateHelper.relativeDateStringFromTimestamp((thirtySevenMinutesAgo?.timeIntervalSince1970)! * 1000)
        
        // 4 min 56 sec
        components.minute = -4
        let fourMinutesFiftySixSecondsAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let fourMinutesFiftySixSecondsAgoStr = DateHelper.relativeDateStringFromTimestamp((fourMinutesFiftySixSecondsAgo?.timeIntervalSince1970)! * 1000)
        
        components.minute = 0
        let fiftySixSecondsAgo = (calendar as NSCalendar).date(byAdding: components, to: rightnow, options: [])
        let fiftySixSecondsAgoStr = DateHelper.relativeDateStringFromTimestamp((fiftySixSecondsAgo?.timeIntervalSince1970)! * 1000)
        
        let monthsAndDays = try! NSRegularExpression(pattern: "^\\d\\smo\\s\\d\\d\\sdays$", options: [])
        let range = NSMakeRange(0, (sevenMonthsTwentyDaysAgoStr?.characters.count)!)
        let nummatches = monthsAndDays.numberOfMatches(in: sevenMonthsTwentyDaysAgoStr!, options: [], range: range)
        
        XCTAssertEqual("1 yr 6 mo", oneYearSixMonthsAgoStr)
        XCTAssertEqual("10 mo", tenMonthsAgoStr)
        XCTAssertEqual(nummatches,1)
        XCTAssertEqual("11 days", elevenDaysAgoStr)
        XCTAssertEqual("8 days 4 hr", eightDaysFourHoursAgoStr)
        XCTAssertEqual("10 hr", tenHoursAgoStr)
        XCTAssertEqual("6 hr 15 min", sixHoursFifteenMinutesAgoStr)
        XCTAssertEqual("37 min", thirtySevenMinutesAgoStr)
        XCTAssertEqual("4 min 56 sec", fourMinutesFiftySixSecondsAgoStr)
        XCTAssertEqual("56 sec", fiftySixSecondsAgoStr)
    }
}
