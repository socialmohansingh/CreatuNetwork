//
//  AuthorizeNetworking.swift
//  WowApp
//
//  Created by Mohan on 3/6/18.
//  Copyright © 2018 Mohan. All rights reserved.
//

import Foundation
import Moya
import RxSwift

//Networking for user
struct AuthorizeNetworking<MSTApi>: AuthNetworkingProtocol where MSTApi: ApiTargetType {
    typealias T = MSTApi   //swiftlint:disable:this type_name
    let provider: MoyaProvider<MSTApi>
}

//request maker for userNetworking
extension AuthorizeNetworking {

    func request(with token: MSTApi) -> Observable<Moya.Response> {
        let requiredRequest = self.provider.rx.request(token)
        return Observable.just(true).flatMap { _ in return requiredRequest }
    }

    static func establish() -> AuthorizeNetworking<T> {
        return AuthorizeNetworking(provider: authProvider([NetworkLoggerPlugin(verbose: true)]))
    }
}

extension AuthorizeNetworking {

    fileprivate static func authProvider<T>(_ plugins: [PluginType]) -> MoyaProvider<T> where T: ApiTargetType {
        return MoyaProvider(endpointClosure: AuthorizeNetworking<T>.authEndClosers(), plugins: plugins)
    }
}

//protocol Authorizable
//this will be used to determine which of the API should use Authorization header
public protocol AuthApiToken {
    var authTokenType: AuthHeaderType { get }
    var checkTokenValidity: Bool {get}
}

protocol AuthNetworkingProtocol {
    associatedtype T: TargetType, AuthApiToken //swiftlint:disable:this type_name
    var provider: MoyaProvider<T> { get }
}

public protocol ApiTargetType: TargetType, AuthApiToken {

}

extension AuthNetworkingProtocol {

    fileprivate static func authEndClosers<T>() -> (T) -> Endpoint where T: ApiTargetType {
        return { target in
            let url = target.baseURL.appendingPathComponent(target.path)
            let endpoint: Endpoint = Endpoint(url: url.absoluteString, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, task: target.task, httpHeaderFields: nil)

            var headerParameters = [String: String]()
            if let header = target.headers {
                headerParameters = header
            }

            //set the token if required
            if let headers = getAuthToken(target.authTokenType) {
                for (key, value) in headers {
                    headerParameters[key] = value
                }
                return endpoint.adding(newHTTPHeaderFields: headerParameters)
            } else {
                return endpoint
            }
        }
    }

    fileprivate static func getAuthToken(_ authTokenType: AuthHeaderType) -> [String: String]? {
        switch authTokenType {
        case .basic:
            if let token = Authorize.accessToken {
                return ["Authorization": "Basic \(token)"]
            }
            return nil
        case .bearer:
            if let token = Authorize.accessToken {
                return ["Authorization": "Bearer \(token)"]
            }
            return nil
        case .custom:
            if let customHeader = Authorize.customHeader {
                return customHeader
            }
            return nil
        case .none:
            return nil
        }
    }
}
