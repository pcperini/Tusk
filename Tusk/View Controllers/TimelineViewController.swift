//
//  TimelineViewController.swift
//  Tusk
//
//  Created by Patrick Perini on 8/19/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import UIKit
import ReSwift

class TimelineViewController: StatusesContainerViewController<TimelineState> {
    override func setUpSubscriptions() {
        GlobalStore.subscribe(self) { (subscription) in subscription.select { (state) in state.timeline } }
    }
}
