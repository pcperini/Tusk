//
//  StatusUpdateState.swift
//  Tusk
//
//  Created by Patrick Perini on 9/1/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import Foundation
import MastodonKit
import ReSwift

protocol StatusUpdateAction: Action {
    var client: Client { get }
    var id: String { get }
}

struct StatusUpdateState: StateType {
    struct ToggleFavourite: StatusUpdateAction { let client: Client; let id: String; let status: Status }
    struct ToggleReblog: StatusUpdateAction { let client: Client; let id: String; let status: Status }
    struct PostStatus: StatusUpdateAction {
        let client: Client
        let id: String
        let content: String
        let inReplyTo: Status?
        let visibility: Visibility
        let attachments: [MediaAttachment]
    }
    struct ReportStatus: StatusUpdateAction { let client: Client; let id: String; let status: Status }
    
    struct AddResult: Action { let id: String; let result: Result<Status> }
    
    var updates: [String: Result<Status>] = [:]
    
    static func updateID() -> String {
        return UUID().uuidString
    }
    
    static func reducer(action: Action, state: StatusUpdateState?) -> StatusUpdateState {
        var state = state ?? StatusUpdateState()
        
        switch action {
        case let action as ToggleFavourite: state.toggleFavourite(client: action.client, id: action.id, status: action.status)
        case let action as ToggleReblog: state.toggleReblog(client: action.client, id: action.id, status: action.status)
        case let action as PostStatus: state.postStatus(client: action.client,
                                                        id: action.id,
                                                        content: action.content,
                                                        inReplyTo: action.inReplyTo,
                                                        visibility: action.visibility,
                                                        attachments: action.attachments)
        case let action as ReportStatus: state.reportStatus(client: action.client, id: action.id, status: action.status)
        case let action as AddResult: state.updates[action.id] = action.result
        default: break
        }
        
        return state
    }
    
    func toggleFavourite(client: Client, id: String, status: Status) {
        let on = !(status.favourited ?? false)
        let request = on ? Statuses.favourite(id: status.id) : Statuses.unfavourite(id: status.id)
        client.run(request) { (result) in
            GlobalStore.dispatch(AddResult(id: id, result: result))
            
            switch result {
            case .success(let resp, _): do {
                let newStatus = try! resp.cloned(changes: [
                    "favourites_count": resp.favouritesCount + (on ? 0 : -1)
                    ])
                
                
                GlobalStore.dispatch(StatusesState.UpdateStatus(value: newStatus))
                log.verbose("success \(request)")
                }
            case .failure(let error): do {
                    log.error("error \(request) 🚨 Error: \(error)\n")
                    GlobalStore.dispatch(ErrorsState.AddError(value: error))
                    }
            }
        }
    }
    
    func toggleReblog(client: Client, id: String, status: Status) {
        let on = !(status.reblogged ?? false)
        let request = on ? Statuses.reblog(id: status.id) : Statuses.unreblog(id: status.id)
        client.run(request) { (result) in
            GlobalStore.dispatch(AddResult(id: id, result: result))
            
            switch result {
            case .success(let resp, _): do {
                let newStatus = try! resp.cloned(changes: [
                    "reblogs_count": resp.reblogsCount + (on ? 0 : -1)
                    ])
                
                GlobalStore.dispatch(StatusesState.UpdateStatus(value: newStatus))
                log.verbose("success \(request)")
                }
            case .failure(let error): do {
                    log.error("error \(request) 🚨 Error: \(error)\n")
                    GlobalStore.dispatch(ErrorsState.AddError(value: error))
                    }
            }
        }
    }
    
    func postStatus(client: Client, id: String, content: String, inReplyTo: Status?, visibility: Visibility, attachments: [MediaAttachment]) {
        var uploads: [Attachment] = []
        let statusPost = {
            let request = Statuses.create(status: content,
                                          replyToID: inReplyTo?.id,
                                          mediaIDs: uploads.map { $0.id },
                                          sensitive: false,
                                          spoilerText: nil,
                                          visibility: visibility)
            
            client.run(request) { (result) in
                GlobalStore.dispatch(AddResult(id: id, result: result))
                
                switch result {
                case .success(let resp, _): do {
                    GlobalStore.dispatch(TimelineState.InsertStatus(value: resp))
                    log.verbose("success \(request)")
                    }
                case .failure(let error): do {
                    log.error("error \(request) 🚨 Error: \(error)\n")
                    GlobalStore.dispatch(ErrorsState.AddError(value: error))
                    }
                }
            }
        }
        
        if attachments.isEmpty {
            statusPost()
        }
        else {
            attachments.forEach { (attachment) in
                let request = Media.upload(media: attachment)
                client.run(request) { (result) in
                    switch result {
                    case .success(let resp, _): do {
                        uploads.append(resp)
                        log.verbose("success \(request)")
                        
                        if (uploads.count == attachments.count) { statusPost() }
                        }
                    case .failure(let error): do {
                        log.error("error \(request) 🚨 Error: \(error)\n")
                        GlobalStore.dispatch(AddResult(id: id, result: Result<Status>.failure(error)))
                        }
                    }
                }
            }
        }
    }
    
    func reportStatus(client: Client, id: String, status: Status) {
        let request = Reports.report(accountID: status.account.id, statusIDs: [status.id], reason: "This post was offensive.")
        client.run(request) { (result) in
            switch result {
            case .success(let resp, _): do {
                GlobalStore.dispatch(StatusesState.RemoveStatus(value: status))
                GlobalStore.dispatch(AddResult(id: id, result: Result<Status>.success(status, nil)))
                log.verbose("success \(request), \(resp)")
                }
            case .failure(let error): do {
                log.error("error \(request) 🚨 Error: \(error)\n")
                GlobalStore.dispatch(AddResult(id: id, result: Result<Status>.failure(error)))
                GlobalStore.dispatch(ErrorsState.AddError(value: error))
                }
            }
        }
    }
}
