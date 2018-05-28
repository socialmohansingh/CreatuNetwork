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
import SystemConfiguration
import Reachability

//Networking for user
struct AuthorizeNetworking<MSTApi>: AuthNetworkingProtocol where MSTApi: ApiTargetType {
    typealias T = MSTApi   //swiftlint:disable:this type_name
    let provider: MoyaProvider<MSTApi>
}

//request maker for userNetworking
extension AuthorizeNetworking {

    func requestWithProgress(with token: MSTApi) -> Observable<ProgressResponse> {
        let requiredRequest = self.provider.rx.requestWithProgress(token)
        return requiredRequest// { _ in return requiredRequest }
    }

    func request(with token: MSTApi) -> Observable<Moya.Response> {
        let requiredRequest = self.provider.rx.request(token)
        return Observable.just(true).flatMap { _ in return requiredRequest }
    }

    func requestWithProgress(with token: MSTApi, callbackQueue: DispatchQueue?) -> Observable<ProgressResponse> {
        let requiredRequest = self.provider.rx.requestWithProgress(token, callbackQueue: callbackQueue)
        return requiredRequest
    }

    func request(with token: MSTApi, callbackQueue: DispatchQueue?) -> Observable<Moya.Response> {
        let requiredRequest = self.provider.rx.request(token, callbackQueue: callbackQueue)
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

    /// set authorization header 
    var authTokenType: AuthHeaderType { get }

    /// if true check refresh token expire or not
    var checkTokenValidity: Bool {get}
}

protocol AuthNetworkingProtocol {
    associatedtype T: TargetType, AuthApiToken //swiftlint:disable:this type_name
    var provider: MoyaProvider<T> { get }
}

public protocol ApiTargetType: TargetType, AuthApiToken {

}

extension AuthNetworkingProtocol {


    /// update your endheader values
    ///
    /// - Returns: return api endpoint
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

    /// get your Authorization access token
    ///
    /// - Parameter authTokenType: token type like basic or bearer or custom
    /// - Returns: your access token header like [Authorization:"Bearer ytoken"]
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


class ConnectionManager {

    static let shared = ConnectionManager()
    private var reachability : Reachability!

    fileprivate init(){
        observeReachability()
    }

    func observeReachability(){
        self.reachability = Reachability()
        NotificationCenter.default.addObserver(self, selector:#selector(self.reachabilityChanged), name: NSNotification.Name.reachabilityChanged, object: nil)
        do {
            try self.reachability.startNotifier()
        }
        catch(let error) {
            print("Error occured while starting reachability notifications : \(error.localizedDescription)")
        }
    }

    @objc func reachabilityChanged(note: Notification) {
        let reachability = note.object as! Reachability
        switch reachability.connection {
        case .cellular:
            print("Network available via Cellular Data.")
            Network.connection.accept(true)
            break
        case .wifi:
            print("Network available via WiFi.")
            Network.connection.accept(true)
            break
        case .none:
            print("Network is not available.")
             Network.connection.accept(false)
            break
        }
        Network.internetSource.accept(reachability.connection)
    }

    public func isInternetAvailable() -> Bool {
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

