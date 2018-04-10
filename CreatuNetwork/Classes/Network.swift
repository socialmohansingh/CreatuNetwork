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

    public static func request<T>(_ api: T, onCompleted: @escaping (Moya.Response?) -> Void, onError: @escaping (Error) -> Void, onProgress: @escaping (ProgressResponse) -> Void, onRefresh: (() -> Void)? = nil, onFinal: (() -> Void)? = nil) where T: ApiTargetType {

        self.authenticate(api).subscribe(onNext: { (shouldRefreshToken) in
            if shouldRefreshToken {
                onRefresh?()
            } else {
                let provider = AuthorizeNetworking<T>.establish()
                provider.requestWithProgress(with: api).subscribe({ progressResponse in
                    debugPrint(progressResponse)
                    switch progressResponse {
                    case .completed:
                        onFinal?()
                    case .next(let responceData):
                        if responceData.completed {
                            onCompleted(responceData.response)
                        }
                        else {
                            onProgress(responceData)
                        }
                    case .error(let error):
                        onError(error)
                        onFinal?()
                    }

                }).disposed(by: bag)
            }
        }).disposed(by: bag)
    }

    public static func request<T>(_ api: T, onCompleted: @escaping (Moya.Response?) -> Void, onError: @escaping (Error) -> Void, onRefresh: (() -> Void)? = nil, onFinal: (() -> Void)? = nil) where T: ApiTargetType {

        self.authenticate(api).subscribe(onNext: { (shouldRefreshToken) in
            if shouldRefreshToken {
                onRefresh?()
            } else {
                let provider = AuthorizeNetworking<T>.establish()
                provider.request(with: api).subscribe({ response  in
                    debugPrint(response)
                    switch response {
                    case .completed:
                        onFinal?()
                    case .next(let responseData):
                        onCompleted(responseData)
                    case .error(let error):
                        onError(error)
                        onFinal?()
                    }
                }).disposed(by: bag)
            }
        }).disposed(by: bag)
    }

    public static func request<T>(_ api: T, callbackQueue: DispatchQueue?, onProgress: @escaping (ProgressResponse) -> Void, onCompleted: @escaping (Moya.Response?) -> Void, onError: @escaping (Error) -> Void, onRefresh: (() -> Void)? = nil, onFinal: (() -> Void)? = nil) where T: ApiTargetType {

        self.authenticate(api).subscribe(onNext: { (shouldRefreshToken) in
            if shouldRefreshToken {
                onRefresh?()
            } else {
                let provider = AuthorizeNetworking<T>.establish()
                provider.requestWithProgress(with: api, callbackQueue: callbackQueue).subscribe({ progressResponse in
                    debugPrint(progressResponse)
                    switch progressResponse {
                    case .completed:
                        onFinal?()
                    case .next(let responceData):
                        if responceData.completed {
                            onCompleted(responceData.response)
                        }
                        else {
                            onProgress(responceData)
                        }
                    case .error(let error):
                        onError(error)
                        onFinal?()
                    }

                }).disposed(by: bag)
            }
        }).disposed(by: bag)
    }

    public static func request<T>(_ api: T, callbackQueue: DispatchQueue?, onCompleted: @escaping (Moya.Response?) -> Void, onError: @escaping (Error) -> Void, onRefresh: (() -> Void)? = nil, onFinal: (() -> Void)? = nil) where T: ApiTargetType {

        self.authenticate(api).subscribe(onNext: { (shouldRefreshToken) in
            if shouldRefreshToken {
                onRefresh?()
            } else {
                let provider = AuthorizeNetworking<T>.establish()
                provider.request(with: api, callbackQueue: callbackQueue).subscribe({ response  in
                    debugPrint(response)
                    switch response {
                    case .completed:
                        onFinal?()
                    case .next(let responseData):
                        onCompleted(responseData)
                    case .error(let error):
                        onError(error)
                        onFinal?()
                    }
                }).disposed(by: bag)
            }
        }).disposed(by: bag)
    }

    public static func available() -> Bool {
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


