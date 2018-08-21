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
    associatedtype RequestType where RequestType: Paginatable
    
    var nextPage: RequestRange? { get set }
    var previousPage: RequestRange? { get set }
    var paginatingData: PaginatingData<DataType, RequestType> { get set }
    
    static func provider(range: RequestRange?) -> Request<[RequestType]>
}

struct PaginatingData<DataType, RequestType> where DataType: Paginatable, RequestType: Paginatable {
    typealias DataFilter = (DataType) -> Bool
    
    var minimumPageSize: Int
    var provider: (RequestRange?) -> Request<[RequestType]>
    var typeMapper: ([RequestType]) -> [DataType]
    
    init(minimumPageSize: Int = 0, typeMapper: @escaping ([RequestType]) -> [DataType] = { $0 as? [DataType] ?? [] }, provider: @escaping ((RequestRange?) -> Request<[RequestType]>)) {
        self.minimumPageSize = minimumPageSize
        self.typeMapper = typeMapper
        self.provider = provider
    }
    
    func pollData(client: Client, range: RequestRange? = nil, existingData: [DataType], filters: [DataFilter] = [], completion: @escaping ([DataType], Pagination?) -> Void) {
        let request: Request<[RequestType]> = self.provider(range)
        var allData = existingData

        client.run(request) { (result) in
            switch result {
            case .success(let data, let pagination): do {
                allData = self.mergeData(existingData: allData, newData: self.typeMapper(data), filters: filters)
                print("success", #file, #line, DataType.self)
                
                guard let nextPage = pagination?.next, allData.count < self.minimumPageSize else { completion(allData, pagination); return }
                self.pollData(client: client,
                              range: nextPage,
                              existingData: allData,
                              filters: filters,
                              completion: completion)
                }
            case .failure(let error): print(error, #file, #line)
            }
        }
    }
    
    private func mergeData(existingData: [DataType], newData: [DataType], filters: [DataFilter]) -> [DataType] {
        guard let newFirst = newData.first, let newLast = newData.last else { return existingData }
        var dataSet = Set<DataType>()
        dataSet = dataSet.union(existingData.filter { (item) in
            item > newLast || item < newFirst
        })
        
        dataSet = dataSet.union(newData)
        var results = Array(dataSet).sorted(by: { (lhs, rhs) -> Bool in
            lhs > rhs
        })
        
        results = filters.reduce(results) { (all, next) in all.filter(next) }
        return results
    }
    
    func updatedPages<PaginatableStateType: PaginatableState>(pagination: Pagination?, state: PaginatableStateType) -> (RequestRange?, RequestRange?) {
        guard let oldNext = state.nextPage, let oldPrev = state.previousPage else { return (pagination?.next, pagination?.previous) }
        guard let newNext = pagination?.next, let newPrev = pagination?.previous else { return (state.nextPage, state.previousPage) }
        
        let setNext: RequestRange? = newNext < oldNext ? newNext : oldNext
        let setPrev: RequestRange? = newPrev > oldPrev ? newPrev : oldPrev
        
        return (setNext, setPrev)
    }
}
