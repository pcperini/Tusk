//
//  PaginatableState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

// TODO: Restructure for composition over inheritance

import ReSwift
import MastodonKit

protocol PaginatableState: StateType {
    associatedtype DataType where DataType: Encodable, DataType: Decodable
    
    var nextPage: RequestRange? { get set }
    var previousPage: RequestRange? { get set }
    var paginatingData: PaginatingData<DataType> { get set }
}

struct PaginatingData<DataType> where DataType: Encodable, DataType: Decodable {
    typealias MergeFunction = ([DataType], [DataType]) -> [DataType]
    typealias ProviderFunction = (RequestRange?) -> Request<[DataType]>
    
    func pollData(client: Client, range: RequestRange? = nil, provider: ProviderFunction, completion: @escaping ([DataType], Pagination?, @escaping MergeFunction) -> Void) {
        let request: Request<[DataType]> = provider(range)
        let merge: MergeFunction
        
        switch range {
        case .some(.since(_, _)): merge = { (old, new) in new + old }
        case .some(.max(_, _)): merge = { (old, new) in old + new }
        default: merge = { (old, new) in new }
        }
        
        client.run(request) { (result) in
            switch result {
            case .success(let data, let pagination): completion(data, pagination, merge)
            default: break
            }
        }
    }
    
    func updatePages<PaginatableStateType: PaginatableState>(pagination: Pagination?, state: PaginatableStateType) -> (RequestRange?, RequestRange?) {
        guard let oldNext = state.nextPage, let oldPrev = state.previousPage else { return (pagination?.next, pagination?.previous) }
        guard let newNext = pagination?.next, let newPrev = pagination?.previous else { return (state.nextPage, state.previousPage) }
        
        let setNext: RequestRange? = newNext < oldNext ? newNext : oldNext
        let setPrev: RequestRange? = newPrev > oldPrev ? newPrev : oldPrev
        
        return (setNext, setPrev)
    }
}
