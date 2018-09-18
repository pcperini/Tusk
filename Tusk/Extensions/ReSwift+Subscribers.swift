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
    private var isStarted: Bool = false
    
    init(state: @escaping (AppState) -> StoreSubscriberStateType, newState: ((StoreSubscriberStateType) -> Void)? = nil) {
        self.stateFilter = state
        self.newStateHandler = newState
        self.start()
    }
    
    deinit {
        self.stop()
    }
    
    func start() {
        guard !self.isStarted else { return }
        GlobalStore.subscribe(self) { (subscription) in subscription.select(self.stateFilter) }
        self.isStarted = true
    }
    
    func stop() {
        self.isStarted = false
        GlobalStore.unsubscribe(self)
    }
    
    func newState(state: StoreSubscriberStateType) {
        self.newStateHandler?(state)
    }
}

protocol SubscriptionResponder {
    var subscriber: Subscriber { get }
}

struct Subscriber {
    private var subscribers: NSMutableArray = NSMutableArray()
    
    init() {}
    
    init<SubscriptionStateType: StateType>(state: @escaping (AppState) -> SubscriptionStateType, newState: ((SubscriptionStateType) -> Void)? = nil) {
        self.add(state: state, newState: newState)
    }
    
    mutating func add<SubscriptionStateType: StateType>(state: @escaping (AppState) -> SubscriptionStateType, newState: ((SubscriptionStateType) -> Void)? = nil, queue: DispatchQueue = .main) {
        var syncNewState: ((SubscriptionStateType) -> Void)? = nil
        if let newState = newState {
            syncNewState = { (state) in
                queue.async { newState(state) }
            }
        }
        
        let subscriber = SingleStateSubscriber(state: state, newState: syncNewState)
        self.subscribers.add(subscriber)
    }
    
    func start() {
        self.subscribers.forEach { ($0 as? SingleStateSubscriber<Any>)?.start() }
    }
    
    func stop() {
        self.subscribers.forEach { ($0 as? SingleStateSubscriber<Any>)?.stop() }
    }
}
