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
        self.text = date.toStringWithRelativeTime()
    }
    
    private func stopTimer() {
        if self.timer != nil { self.timer?.invalidate() }
    }
}
