//
//  TimelineState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/11/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

struct TimelineState: StatusesState {
    // Timeline catches all status actions, generically
    struct ToggleFavourite: Action { let client: Client; let status: Status }
    struct ToggleReblog: Action { let client: Client; let status: Status }
    struct PostStatus: Action {
        let client: Client
        let content: String
    }
    
    var statuses: [Status] = []
    var filters: [(Status) -> Bool] = [{ $0.visibility != .direct }]
    
    var nextPage: RequestRange? = nil
    var previousPage: RequestRange? = nil
    var paginatingData: PaginatingData<Status, Status> = PaginatingData<Status, Status>(provider: TimelineState.provider)
    
    static var additionalReducer: ((Action, TimelineState?) -> TimelineState)? = { (action: Action, state: TimelineState?) in
        let state = state ?? TimelineState()
        
        switch action {
        case let action as ToggleFavourite: state.toggleFavourite(client: action.client, status: action.status)
        case let action as ToggleReblog: state.toggleReblog(client: action.client, status: action.status)
        case let action as PostStatus: state.postStatus(client: action.client, content: action.content)
        default: break
        }
        
        return state
    }
    
    static func provider(range: RequestRange? = nil) -> Request<[Status]> {
        guard let range = range else { return Timelines.home(range: .limit(40)) }
        return Timelines.home(range: range)
    }
    
    func toggleFavourite(client: Client, status: Status) {
        let request = (status.favourited ?? false) ? Statuses.unfavourite(id: status.id) : Statuses.favourite(id: status.id)
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                GlobalStore.dispatch(UpdateStatus(value: resp))
                log.verbose("success \(request)")
                }
            case .failure(let error): log.error("error \(request) 🚨 Error: \(error)\n")
            }
        }
    }
    
    func toggleReblog(client: Client, status: Status) {
        let request = (status.reblogged ?? false) ? Statuses.unreblog(id: status.id) : Statuses.reblog(id: status.id)
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                GlobalStore.dispatch(UpdateStatus(value: resp))
                log.verbose("success \(request)")
                }
            case .failure(let error): log.error("error \(request) 🚨 Error: \(error)\n")
            }
        }
    }
    
    func postStatus(client: Client, content: String) {
        let request = Statuses.create(status: content,
                                      replyToID: nil,
                                      mediaIDs: [],
                                      sensitive: false,
                                      spoilerText: nil,
                                      visibility: .public)
        
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                GlobalStore.dispatch(InsertStatus(value: resp))
                log.verbose("success \(request)")
                }
            case .failure(let error): log.error("error \(request) 🚨 Error: \(error)\n")
            }
        }
    }
}
