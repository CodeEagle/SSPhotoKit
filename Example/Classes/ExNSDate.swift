//
//  ExNSDate.swift
//  Pods
//
//  Created by LawLincoln on 15/7/23.
//
//

import UIKit

extension NSDate {
    
    class func componetsWithTimeInterval(timeInterval: NSTimeInterval) -> NSDateComponents {
        let calendar = NSCalendar.currentCalendar()
        let date1 = NSDate()
        let date2 = NSDate(timeInterval: timeInterval, sinceDate: date1)
        let flags = NSCalendarUnit.CalendarUnitSecond | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitYear
        return calendar.components(flags, fromDate: date1, toDate: date2, options: NSCalendarOptions.allZeros)
        
    }
    
    class func timeDescriptionOfTimeInterval(timeInterval: NSTimeInterval) -> String {
        let components = NSDate.componetsWithTimeInterval(timeInterval)

        let roundedSeconds = Int(lroundf(Float(timeInterval) - Float(components.hour * 60 * 60) - Float(components.minute * 60 )))
        if components.hour > 0 {
            return NSString(format: "%ld:%02ld:%02ld", components.hour, components.minute, roundedSeconds) as String
        } else {
            return NSString(format: "%ld:%02ld", components.minute, roundedSeconds) as String
        }
    }
}

