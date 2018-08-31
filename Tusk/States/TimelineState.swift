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
        let inReplyTo: Status?
        let visibility: Visibility
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
        case let action as PostStatus: state.postStatus(client: action.client,
                                                        content: action.content,
                                                        inReplyTo: action.inReplyTo,
                                                        visibility: action.visibility)
        default: break
        }
        
        return state
    }
    
    static func provider(range: RequestRange? = nil) -> Request<[Status]> {
        guard let range = range else { return Timelines.home(range: .limit(40)) }
        return Timelines.home(range: range)
    }
    
    func toggleFavourite(client: Client, status: Status) {
        let on = !(status.favourited ?? false)
        let request = on ? Statuses.favourite(id: status.id) : Statuses.unfavourite(id: status.id)
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                let newStatus = try! resp.cloned(changes: [
                    "favourites_count": resp.favouritesCount + (on ? 0 : -1)
                ])
                
                GlobalStore.dispatch(UpdateStatus(value: newStatus))
                log.verbose("success \(request)")
                }
            case .failure(let error): log.error("error \(request) 🚨 Error: \(error)\n")
            }
        }
    }
    
    func toggleReblog(client: Client, status: Status) {
        let on = !(status.reblogged ?? false)
        let request = on ? Statuses.reblog(id: status.id) : Statuses.unreblog(id: status.id)
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                let newStatus = try! resp.cloned(changes: [
                    "reblogs_count": resp.reblogsCount + (on ? 0 : -1)
                ])
                
                GlobalStore.dispatch(UpdateStatus(value: newStatus))
                log.verbose("success \(request)")
                }
            case .failure(let error): log.error("error \(request) 🚨 Error: \(error)\n")
            }
        }
    }
    
    func postStatus(client: Client, content: String, inReplyTo: Status?, visibility: Visibility) {
        let request = Statuses.create(status: content,
                                      replyToID: inReplyTo?.id,
                                      mediaIDs: [],
                                      sensitive: false,
                                      spoilerText: nil,
                                      visibility: visibility)
        
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
