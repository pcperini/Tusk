E//
//  ReSwift+Extensions.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import ReSwift

protocol SetAction<ValueType>: Action {
    let value: ValueType
}
