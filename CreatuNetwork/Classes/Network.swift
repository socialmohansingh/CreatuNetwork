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
import Reachability

public struct Network {

    fileprivate static let bag = DisposeBag()


    /// internet connection status true or false
    public static let connection = BehaviorRelay<Bool>(value:false)

    /// internet connection source like wifi, cellular, none
    public static let internetSource = BehaviorRelay<Reachability.Connection>(value:.none)

    init() {
        ConnectionManager.shared.observeReachability()
    }

    /// your api request with api progress status
    ///
    /// - Parameters:
    ///   - api: api information
    ///   - onCompleted: call if api successfully completed
    ///   - onError: call if api error
    ///   - onProgress: call if on progress api
    ///   - onRefresh: call if token expire
    ///   - onFinal: call after api completed
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

    /// your api request without api progress status
    ///
    /// - Parameters:
    ///   - api: api information
    ///   - onCompleted: call if api successfully completed
    ///   - onError: call if api error
    ///   - onRefresh: call if token expire
    ///   - onFinal: call after api completed
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


    /// your api request with api progress status
    ///
    /// - Parameters:
    ///   - callbackQueue: call back queue
    ///   - api: api information
    ///   - onCompleted: call if api successfully completed
    ///   - onError: call if api error
    ///   - onProgress: call if on progress api
    ///   - onRefresh: call if token expire
    ///   - onFinal: call after api completed
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

    /// your api request without api progress status
    ///
    /// - Parameters:
    ///   - callbackQueue: call back queue
    ///   - api: api information
    ///   - onCompleted: call if api successfully completed
    ///   - onError: call if api error
    ///   - onRefresh: call if token expire
    ///   - onFinal: call after api completed
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


    /// check internet available
    ///
    /// - Returns: return true if internet available or false
    public static func available() -> Bool {
        return ConnectionManager.shared.isInternetAvailable()
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
}


