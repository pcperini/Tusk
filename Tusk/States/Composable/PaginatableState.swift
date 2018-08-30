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

protocol Paginatable: Encodable, Decodable, Comparable, Hashable { static var sortedByPageIndex: Bool { get } }
protocol PollAction: Action { var client: Client { get } }

protocol PaginatableState: StateType {
    associatedtype DataType where DataType: Paginatable
    associatedtype RequestType where RequestType: Paginatable
    
    var nextPage: RequestRange? { get set }
    var previousPage: RequestRange? { get set }
    var paginatingData: PaginatingData<DataType, RequestType> { get set }
    
    static func provider(range: RequestRange?) -> Request<[RequestType]>
}

import MastodonKit
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
            case .success(let resp, let pagination): do {
                allData = self.mergeData(existingData: allData, newData: self.typeMapper(resp), filters: filters, range: range)
                log.verbose("success \(request)", context: ["resp": resp, "type": DataType.self])
                
                guard let nextPage = pagination?.next, allData.count < self.minimumPageSize else { completion(allData, pagination); return }
                self.pollData(client: client,
                              range: nextPage,
                              existingData: allData,
                              filters: filters,
                              completion: completion)
                }
            case .failure(let error): log.error("error \(request) 🚨 Error: \(error)\n")
            }
        }
    }
    
    private func mergeData(existingData: [DataType], newData: [DataType], filters: [DataFilter], range: RequestRange? = nil) -> [DataType] {
        let dataSet = Set<DataType>(existingData).union(newData)
        return Array(dataSet).sorted(by: { (lhs, rhs) -> Bool in
            if DataType.sortedByPageIndex {
                let topPage: [DataType], bottomPage: [DataType]
                switch range {
                case .some(.max): (topPage, bottomPage) = (existingData, newData)
                default: (topPage, bottomPage) = (newData, existingData)
                }
                
                if (topPage.contains(lhs) && topPage.contains(rhs)) {
                    return topPage.index(of: lhs)! < topPage.index(of: rhs)!
                } else if (bottomPage.contains(lhs) && bottomPage.contains(rhs)) {
                    return bottomPage.index(of: lhs)! < bottomPage.index(of: rhs)!
                }
                
                return topPage.contains(lhs)
            } else {
                return lhs > rhs
            }
        })
    }
    
    func updatedPages(pagination: Pagination?, nextPage: RequestRange?, previousPage: RequestRange?) -> (RequestRange?, RequestRange?) {
        guard let oldNext = nextPage, let oldPrev = previousPage else { return (pagination?.next, pagination?.previous) }
        guard let newNext = pagination?.next, let newPrev = pagination?.previous else { return (nextPage, previousPage) }
        
        let setNext: RequestRange? = newNext < oldNext ? newNext : oldNext
        let setPrev: RequestRange? = newPrev > oldPrev ? newPrev : oldPrev
        
        return (setNext, setPrev)
    }
}
