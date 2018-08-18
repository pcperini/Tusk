//
//  PaginatableState.swift
//  Tusk
//
//  Created by Patrick Perini on 8/13/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

// TODO: Refactor for OrderedSet and AddStatuses instead of SetStatuses

import ReSwift
import MastodonKit

protocol Paginatable: Encodable, Decodable, Comparable, Hashable {}

protocol PaginatableState: StateType {
    associatedtype DataType where DataType: Paginatable
    
    var nextPage: RequestRange? { get set }
    var previousPage: RequestRange? { get set }
    var paginatingData: PaginatingData<DataType> { get set }
    
    static func provider(range: RequestRange?) -> Request<[DataType]>
}

struct PaginatingData<DataType> where DataType: Paginatable {
    typealias ProviderFunction = (RequestRange?) -> Request<[DataType]>
    
    func pollData(client: Client, range: RequestRange? = nil, existingData: [DataType], provider: ProviderFunction, completion: @escaping ([DataType], Pagination?) -> Void) {
        let request: Request<[DataType]> = provider(range)

        client.run(request) { (result) in
            switch result {
            case .success(let data, let pagination): do {
                completion(self.mergeData(existingData: existingData, newData: data), pagination)
                print("success", #file, #line, DataType.self)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
    
    private func mergeData(existingData: [DataType], newData: [DataType]) -> [DataType] {
        guard let newFirst = newData.first, let newLast = newData.last else { return existingData }
        var dataSet = Set<DataType>()
        dataSet = dataSet.union(existingData.filter { (item) in
            item > newLast || item < newFirst
        })
        
        dataSet = dataSet.union(newData)
        return Array(dataSet).sorted(by: { (lhs, rhs) -> Bool in
            lhs > rhs
        })
    }
    
    func updatePages<PaginatableStateType: PaginatableState>(pagination: Pagination?, state: PaginatableStateType) -> (RequestRange?, RequestRange?) {
        guard let oldNext = state.nextPage, let oldPrev = state.previousPage else { return (pagination?.next, pagination?.previous) }
        guard let newNext = pagination?.next, let newPrev = pagination?.previous else { return (state.nextPage, state.previousPage) }
        
        let setNext: RequestRange? = newNext < oldNext ? newNext : oldNext
        let setPrev: RequestRange? = newPrev > oldPrev ? newPrev : oldPrev
        
        return (setNext, setPrev)
    }
}
