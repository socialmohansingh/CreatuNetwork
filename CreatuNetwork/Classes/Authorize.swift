//
//  Authorize.swift
//  WowApp
//
//  Created by Mohan on 3/9/18.
//  Copyright © 2018 Mohan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Moya

public enum AuthHeaderType {
    case bearer
    case basic
    case custom
    case none
}

public struct AuthorizeModel: Codable {
    public var accessToken: String?
    public var refreshToken: String?
    public var tokenType: String?
    public var updatedDate: Date?
    public var expireIn: Int = 3600

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case updatedDate = "updated_date"
        case expireIn = "expires_in"
    }

    public init(){}

}

public struct Authorize {
    //    public static var shared = Authorize()
    //    fileprivate init() {} 

    /// set or get your custom header 
    public static var customHeader: [String: String]? {
        get {
            if let header = UserDefaults.standard.dictionary(forKey: "auth_custom_header") as? [String: String] {
                return header
            }
            return nil
        }

        set {
            if let values = newValue {
                UserDefaults.standard.set(values, forKey: "auth_custom_header")
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_custom_header")
                UserDefaults.standard.synchronize()
            }
            UserDefaults.standard.synchronize()
        }
    }


    /// get your refresh token
    public static var refreshToken: String? {
        if let auth = self.auth {
            return auth.refreshToken
        }
        return nil
    }


    /// get your saved authorize model
    public static var authorizeModel: AuthorizeModel? {
        return self.auth
    }


    /// get your saved access token
    public static var accessToken: String? {
        if let auth = self.auth {
            return auth.accessToken
        }
        return nil
    }


    /// update authorize throough json data
    ///
    /// - Parameter authorize: your authorize json keys ["access_token":"<your-token>", "refresh_token":"<your-refresh-token>","token_type":"<your-token-type>","updated_date":"<your-update-date>","expires_in":"<your-expire-limit>"]
    /// - Returns: return true if successfully updated
    public static func updateAuthorize(_ authorize: [String: Any]) -> Bool {
        if let authorizeModelData = try? JSONSerialization.data(withJSONObject: authorize, options: .prettyPrinted), var authorizeModel = try? JSONDecoder().decode(AuthorizeModel.self, from: authorizeModelData) {
            if authorizeModel.updatedDate == nil {
                authorizeModel.updatedDate = Date()
            }
            self.auth = authorizeModel
            return true
        }
        return false
    }


    /// update authorize model
    ///
    /// - Parameter authorize: authorize model
    /// - Returns: return true if successfully updated
    public static func updateAuthorize(_ authorize: AuthorizeModel) -> Bool {

        if authorize.updatedDate == nil {
            var auth = authorize
            auth.updatedDate = Date()
            self.auth = authorize
        }
        else{
            self.auth = authorize
        }

        return true
    }


    /// clear all your auth data
    ///
    /// - Returns: return true if successfully cleared
    public static func clearSavedData() -> Bool {
        self.auth = nil
        self.customHeader = nil
        return true
    }


    /// update access token
    ///
    /// - Parameter expireAt: token expire limit default 3600 sec
    /// - Returns: eturn true if successfully saved your token
    public static func updateTokenExpireTime(_ expireAt: Int = 3600) -> Bool {
        if var auth = self.auth {
            auth.expireIn = expireAt
            auth.updatedDate = Date()
            self.auth = auth
        }
        return true
    }


    /// update access token
    ///
    /// - Parameters:
    ///   - token: your token data
    ///   - expireAt: token expire limit default 3600 sec
    /// - Returns: return true if successfully saved your token
    public static func setAccessToken(_ token: String, expireAt:Int = 3600) -> Bool {
        if var auth = self.auth {
            auth.accessToken = token
            auth.expireIn = expireAt
            auth.updatedDate = Date()
            self.auth = auth
        } else {
            var auth = AuthorizeModel()
            auth.accessToken = token
            auth.expireIn = expireAt
            auth.updatedDate = Date()
            self.auth = auth
        }
        return true
    }


    /// Update access token :>your token base 64 string of clientUd:clientSecret
    ///
    /// - Parameters:
    ///   - clientId: your token client id
    ///   - clientSecret: your token client secret
    ///   - expireAt: token expire limit default 3600 sec
    /// - Returns: return true if successfully saved your token
    public static func setAccessToken(_ clientId: String, clientSecret: String, expireAt: Int = 3600) -> Bool {
        let authString = "\(clientId):\(clientSecret)"
        if let dataFromString = authString.data(using: .utf8) {
            let encodedToken = dataFromString.base64EncodedString()
            if var auth = self.auth {
                auth.accessToken = encodedToken
                auth.expireIn = expireAt
                auth.updatedDate = Date()
                self.auth = auth
            } else {
                var auth = AuthorizeModel()
                auth.accessToken = encodedToken
                auth.expireIn = expireAt
                auth.updatedDate = Date()
                self.auth = auth
            }
            return true
        }
        return false
    }

    /// Check whether its time to refresh the token or not
    public static var shouldRefreshToken: Bool {
        if let authValue = auth, let updateDate = authValue.updatedDate {
            return (-1) * updateDate.timeIntervalSinceNow > Double(authValue.expireIn)
        }
        return true
    }

}

extension Authorize {

    /// The auth data for current session after authorization of app
    fileprivate static var auth: AuthorizeModel? {
        set {
            if var newValue = newValue {

                if newValue.updatedDate == nil {
                    newValue.updatedDate = Date()
                }

                guard let authValues = try? JSONEncoder().encode(newValue) else { return }
                UserDefaults.standard.setValue(authValues, forKey: "AuthSession")
                UserDefaults.standard.synchronize()
            } else {
                UserDefaults.standard.removeObject(forKey: "AuthSession")
                UserDefaults.standard.synchronize()
            }
        }
        get {
            if let authData = UserDefaults.standard.value(forKey: "AuthSession") as? Data {
                let authValue = try? JSONDecoder().decode(AuthorizeModel.self, from: authData)
                return authValue
            }
            return nil
        }
    }
}

