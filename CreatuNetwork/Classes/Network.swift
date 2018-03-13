//
//  Authorize.swift
//  WowApp
//
//  Created by Mohan on 3/6/18.
//  Copyright © 2018 Mohan. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import SystemConfiguration

public struct Network {
 
    fileprivate static let bag = DisposeBag()

    public static func request<T>(_ api: T) -> Observable<AuthorizeResponse> where T: ApiTargetType {
        return Observable.create { (observer) -> Disposable in
            self.authenticate(api).subscribe(onNext: { (shouldRefreshToken) in
                if shouldRefreshToken {
                    var responseObj = AuthorizeResponse()
                    responseObj.response = nil
                    responseObj.shouldTokenRefresh = true
                    responseObj.message = nil
                    responseObj.success = false
                    observer.onNext(responseObj)
                    observer.onCompleted()
                } else {
                    let provider = AuthorizeNetworking<T>.establish()
                    provider.request(with: api).filterSuccessfulStatusCodes().mapJSON().subscribe(onNext: {(response) in
                        debugPrint(response)
                        var responseObj = AuthorizeResponse()
                        responseObj.response = response
                        responseObj.shouldTokenRefresh = false
                        responseObj.success = true
                        responseObj.message = nil
                        observer.onNext(responseObj)
                        observer.onCompleted()
                    }, onError: { (error) in
                        observer.onError(error)
                    }).disposed(by: bag)
                }
            }, onError: { ( error ) in
                observer.onError(error)
            })
        }
    }

    static func available() -> Bool {
        return self.isInternetAvailable()
    }

}

extension Network {
    fileprivate static func authenticate(_ api: ApiTargetType) -> Observable<Bool> {
         return Observable.create { (observer) -> Disposable in
            if !api.checkTokenValidity {
                observer.onNext(false)
                observer.onCompleted()
            } else {
                if Authorize.shouldRefreshToken {
                    observer.onNext(true)
                    observer.onCompleted()
                } else {
                    observer.onNext(false)
                    observer.onCompleted()
                }
            }
           return Disposables.create()
        }
    }

   fileprivate static func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
}
