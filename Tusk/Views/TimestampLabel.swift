//
//  TimestampLabel.swift
//  Tusk
//
//  Created by Patrick Perini on 8/14/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import AFDateHelper

class TimestampLabel: UILabel {
    @IBInspectable var fullLength: Bool = true
    
    private var timer: Timer?
    var date: Date? {
        didSet {
            guard let date = self.date else {
                self.text = ""
                self.stopTimer()
                return
            }
            
            self.startTimer(date: date)
        }
    }
    
    private func startTimer(date: Date) {
        self.stopTimer()
        
        let elapsedTime = Date().timeIntervalSince(date)
        let interval: TimeInterval
        
        switch elapsedTime {
        case 0...60: interval = 1
        case 61...3600: interval = 60
        default: interval = 3600
        }
        
        self.updateText(timer: self.timer)
        self.timer = Timer(timeInterval: interval, repeats: true, block: self.updateText)
    }
    
    private func updateText(timer: Timer?) {
        guard let date = self.date else { return }
        
        if self.fullLength {
            self.text = date.toStringWithRelativeTime(strings: [
                .nowPast: "just now",
                .oneMinutePast: "1 minute ago",
                .oneHourPast: "1 hour ago",
                .oneDayPast: "1 day ago",
                .oneWeekPast: "1 week ago",
                .oneMonthPast: "1 month ago",
                .oneYearPast: "1 year ago"
            ])
        } else {
            self.text = date.toStringWithRelativeTime(strings: [
                .nowPast: "now",
                .secondsPast: "%.fs",
                .oneMinutePast: "1m",
                .minutesPast: "%.fm",
                .oneHourPast: "1h",
                .hoursPast: "%.fh",
                .oneDayPast: "1d",
                .daysPast: "%.fd",
                .oneWeekPast: "1w",
                .weeksPast: "%.fw",
                .oneMonthPast: "1m",
                .monthsPast: "%.fm",
                .oneYearPast: "1y",
                .yearsPast: "%.fy"
            ])
        }
    }
    
    private func stopTimer() {
        if self.timer != nil { self.timer?.invalidate() }
    }
}
