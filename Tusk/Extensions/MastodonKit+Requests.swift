//
//  MastodonKit+Requests.swift
//  Tusk
//
//  Created by Patrick Perini on 9/10/18.
//  Copyright © 2018 Patrick Perini. All rights reserved.
//

import MastodonKit

extension Client {
    func run<ModelType>(request: Request<ModelType>,
                        always: ((Result<ModelType>) -> Void)? = nil,
                        success: @escaping (ModelType, Pagination?) -> Void,
                        failure: ((Error) -> Void)? = nil,
                        finally: ((Result<ModelType>) -> Void)? = nil) {
        self.run(request) { (result) in
            DispatchQueue.main.async { always?(result) }
            
            switch result {
            case .success(let resp, let page): do {
                DispatchQueue.main.async { success(resp, page) }
                log.verbose("success \(request)")
                }
            case .failure(let error): do {
                log.error("error \(request) 🚨 Error: \(error)\n")
                
                let errorObj = error as NSError
                let retry = (
                    errorObj.domain == NSPOSIXErrorDomain ||
                    (errorObj.domain == NSURLErrorDomain && (errorObj.code == NSURLErrorTimedOut))
                )
                
                if retry {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.run(request: request,
                                 always: always,
                                 success: success,
                                 failure: failure,
                                 finally: finally)
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    GlobalStore.dispatch(ErrorsState.AddError(value: error))
                    failure?(error)
                }
                }
            }
            
            DispatchQueue.main.async { finally?(result) }
        }
    }
}
