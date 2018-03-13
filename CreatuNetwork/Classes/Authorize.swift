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
import KeychainSwift

public enum AuthHeaderType {
    case bearer
    case basic
    case custom
    case none
}

public struct AuthorizeModel: Codable {
    var accessToken: String?
    var refreshToken: String?
    var tokenType: String?
    var updatedDate: Date?
    var expireIn: Double?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case updatedDate = "updated_date"
        case expireIn = "expires_in"
    }

}

public struct AuthorizeResponse {
    var shouldTokenRefresh = false
    var response: Any?
    var message: String?
    var success = true
}

public struct Authorize {
//    public static var shared = Authorize()
//    fileprivate init() {}

  public static var customHeader: [String: String]? {
        get {
            if let header = UserDefaults().dictionary(forKey: "auth_custom_header") as? [String: String] {
                return header
            }
            return nil
        }

        set {
            if let values = newValue {
                UserDefaults().set(values, forKey: "auth_custom_header")
            } else {
                UserDefaults().removeObject(forKey: "auth_custom_header")
            }
            UserDefaults().synchronize()
        }
    }

  public static var accessToken: String? {
            if let auth = self.auth {
                return auth.accessToken
            }
            return nil
    }

    /// Check whether its time to refresh the token or not
    public static var shouldRefreshToken: Bool {
        if let authValue = auth, let updateDate = authValue.updatedDate, let expireTimeInSecond = authValue.expireIn {
            return (-1) * updateDate.timeIntervalSinceNow > expireTimeInSecond
        }
        return true
    }

   public static func updateAuthorize(_ authorize: [String: Any]) -> Bool {
        if let authorizeModelData = try? JSONEncoder().encode(authorize), let authorizeModel = try? JSONDecoder().decode(AuthorizeModel.self, from: authorizeModelData) {
            self.auth = authorizeModel
            return true
        }
        return false
    }

    public static func updateAuthorize(_ authorize: AuthorizeModel) -> Bool {
        self.auth = authorize
        return true
    }

    public static func setAccessToken(_ token: String) -> Bool {
        if var auth = self.auth {
            auth.accessToken = token
            self.auth = auth
        } else {
            var auth = AuthorizeModel()
            auth.accessToken = token
            self.auth = auth
        }
        return true
    }

    public static func setAccessToken(_ clientId: String, clientSecret: String) -> Bool {
        let authString = "\(clientId):\(clientSecret)"
        if let dataFromString = authString.data(using: .utf8) {
            let encodedToken = dataFromString.base64EncodedString()
            if var auth = self.auth {
                auth.accessToken = encodedToken
                self.auth = auth
            } else {
                var auth = AuthorizeModel()
                auth.accessToken = encodedToken
                self.auth = auth
            }
            return true
        }
        return false
    }

}

extension Authorize {
    /// The Keychain in which we are going to stroe our data
    fileprivate static let keychain = KeychainSwift()

    /// The auth data for current session after authorization of app
    fileprivate static var auth: AuthorizeModel? {
        set {
            if let newValue = newValue {
                guard let authValues = try? JSONEncoder().encode(newValue) else { return }
                let authData = NSKeyedArchiver.archivedData(withRootObject: authValues)
                Authorize.keychain.set(authData, forKey: "AuthSession", withAccess: .accessibleAfterFirstUnlock)
            } else {
                Authorize.keychain.delete("AuthSession")
            }
        }
        get {
            if let authData = Authorize.keychain.getData("AuthSession") {
                let authValue = try? JSONDecoder().decode(AuthorizeModel.self, from: authData)
                return authValue
            }
            return nil
        }
    }
}
