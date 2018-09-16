//
//  ReSwift+Subscribers.swift
//  Tusk
//
//  Created by Patrick Perini on 9/16/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import ReSwift

fileprivate class SingleStateSubscriber<StoreSubscriberStateType>: StoreSubscriber {
    let newStateHandler: ((StoreSubscriberStateType) -> Void)?
    private let stateFilter: (AppState) -> StoreSubscriberStateType
    
    init(state: @escaping (AppState) -> StoreSubscriberStateType, newState: ((StoreSubscriberStateType) -> Void)? = nil) {
        self.stateFilter = state
        self.newStateHandler = newState
        self.start()
    }
    
    deinit {
        self.stop()
    }
    
    func start() {
        GlobalStore.subscribe(self) { (subscription) in subscription.select(self.stateFilter) }
    }
    
    func stop() {
        GlobalStore.unsubscribe(self)
    }
    
    func newState(state: StoreSubscriberStateType) {
        self.newStateHandler?(state)
    }
}

struct Subscriber {
    private var subscribers: [SingleStateSubscriber<StateType>] = []
    
    init(state: @escaping (AppState) -> StateType, newState: ((StateType) -> Void)? = nil) {
        self.add(state: state, newState: newState)
    }
    
    mutating func add(state: @escaping (AppState) -> StateType, newState: ((StateType) -> Void)? = nil) {
        let subscriber = SingleStateSubscriber(state: state, newState: newState)
        self.subscribers.append(subscriber)
    }
    
    func start() {
        self.subscribers.forEach { $0.start() }
    }
    
    func stop() {
        self.subscribers.forEach { $0.stop() }
    }
}
