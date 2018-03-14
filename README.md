# CreatuNetwork

[![CI Status](http://img.shields.io/travis/mohansinghthagunna/CreatuNetwork.svg?style=flat)](https://travis-ci.org/mohansinghthagunna/CreatuNetwork)
[![Version](https://img.shields.io/cocoapods/v/CreatuNetwork.svg?style=flat)](http://cocoapods.org/pods/CreatuNetwork)
[![License](https://img.shields.io/cocoapods/l/CreatuNetwork.svg?style=flat)](http://cocoapods.org/pods/CreatuNetwork)
[![Platform](https://img.shields.io/cocoapods/p/CreatuNetwork.svg?style=flat)](http://cocoapods.org/pods/CreatuNetwork)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
- Swift 4 or higher
- target IOS 10 or higher

## Linked Library

- Alamofire (4.7.0)
- KeychainSwift (10.0.0)
- Moya (11.0.1)
- ReachabilitySwift (4.1.0)
- Result (3.2.4)
- RxCocoa (4.1.2)
- RxSwift (4.1.2)

## Installation

CreatuNetwork is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CreatuNetwork'
```

## Api Model
In you api add extention [ApiTargetType]()
```Swift

import Foundation
import Moya
import CreatuNetwork

enum UserApi {
    case login([String: Any])
    case logout([String: Any])
    case register([String: Any])
}

extension UserApi: ApiTargetType {
    var checkTokenValidity: Bool {
        return false
    }

    var baseURL: URL {
        return URL(string: "{{ YOUR-BASE-URL-HERE }}")!
    }

    var path: String {
        switch self {
        case .register:
            return "{{ REGISTER }}"
        case .login:
            return "{{ LOGIN}}"
        case .logout:
            return "{{ LOGOUT }}"
        }
    }

    var method: Moya.Method {
        switch self {
        case .register,
             .login,
             .logout:
            return .post
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        case .register(let parameters),
             .login(let parameters),
             .logout(let parameters):
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        return ["Accept": "application/json"]
    }

    var authTokenType: AuthHeaderType {
        switch self {
        case .login:
            return .basic
        case .register,
             .logout:
            return .bearer
        }
    }
}

```

## Request

- request
```Swift
Network.request(UserApi.login(["username": "{{ USERNAME }}", "password": "{{ PASSWORD }}"])).subscribe(onNext: {(response) in
                    debugPrint(response)
                }, onError: { (error) in
                    debugPrint(error)
                }).disposed(by: bag)
```
- network check
```Swift
Network.available() -> Bool // true if netowk available
```
## Response
- response model
```swift
    var shouldTokenRefresh = false // true if your token out of date and you need to refresh token 
    var response: Any? // your response data
    var message: String? // error message
    var success = true // true if your request successfully completed
```

## For token based life cycle

- if custom authorization header
```Swift
Authorize.customHeader {get set}
```

- get access token
```Swift
Authorize.accessToken {get}
```
- get refresh token
```Swift
Authorize.refreshToken {get}
```

- get authorize model
```Swift
Authorize.authorizeModel { get }
```

- set access token with client id and client secret
```Swift
Authorize.setAccessToken(_ clientId: String, clientSecret: String) -> Bool
```

- set accesstoken with token string
```Swift
Authorize.setAccessToken(_ token: String) -> Bool
```

- clear all authorize saved data
```Swift
Authorize.clearSavedData() -> Bool
```

- update authorize model 
```Swift
Authorize.updateAuthorize(_ authorize: AuthorizeModel) -> Bool
```

- update authorize model with json
```Swift
Authorize.updateAuthorize(_ authorize: [String: Any]) -> Bool 
```
## Author

mohansinghthagunna, mohansingh_thagunna@outlook.com

## License

CreatuNetwork is available under the MIT license. See the LICENSE file for more info.
