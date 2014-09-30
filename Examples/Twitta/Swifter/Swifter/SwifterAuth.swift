//
//  SwifterAuth.swift
//  Swifter
//
//  Copyright (c) 2014 Matt Donnelly.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

public extension Swifter {

    public typealias TokenSuccessHandler = (accessToken: SwifterCredential.OAuthAccessToken?, response: NSURLResponse) -> Void

    public func authorizeWithCallbackURL(callbackURL: NSURL, success: TokenSuccessHandler, failure: ((error: NSError) -> Void)?) {
        self.postOAuthRequestTokenWithCallbackURL(callbackURL, success: {
            token, response in

            var requestToken = token!

            NSNotificationCenter.defaultCenter().addObserverForName(CallbackNotification.notificationName, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock:{
                notification in

                NSNotificationCenter.defaultCenter().removeObserver(self)

                let url = notification.userInfo![CallbackNotification.optionsURLKey] as NSURL

                let parameters = url.query!.parametersFromQueryString()
                requestToken.verifier = parameters["oauth_verifier"]

                self.postOAuthAccessTokenWithRequestToken(requestToken, success: {
                    accessToken, response in

                    self.client.credential = SwifterCredential(accessToken: accessToken!)
                    success(accessToken: accessToken!, response: response)

                    }, failure: failure)
                })

            let authorizeURL = NSURL(string: "/oauth/authorize", relativeToURL: self.apiURL)
            let queryURL = NSURL(string: authorizeURL.absoluteString! + "?oauth_token=\(token!.key)")

            #if os(iOS)
                UIApplication.sharedApplication().openURL(queryURL)
            #else
                NSWorkspace.sharedWorkspace().openURL(queryURL)
            #endif
            }, failure: failure)
    }

    public class func handleOpenURL(url: NSURL) {
        let notification = NSNotification(name: CallbackNotification.notificationName, object: nil,
            userInfo: [CallbackNotification.optionsURLKey: url])
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }

    public func authorizeAppOnlyWithSuccess(success: TokenSuccessHandler?, failure: FailureHandler?) {
        self.postOAuth2BearerTokenWithSuccess({
            json, response in

            if let tokenType = json["token_type"].string {
                if tokenType == "bearer" {
                    let accessToken = json["access_token"].string

                    let credentialToken = SwifterCredential.OAuthAccessToken(key: accessToken!, secret: "")

                    self.client.credential = SwifterCredential(accessToken: credentialToken)

                    success?(accessToken: credentialToken, response: response)
                }
                else {
                    let error = NSError(domain: "Swifter", code: SwifterError.appOnlyAuthenticationErrorCode, userInfo: [NSLocalizedDescriptionKey: "Cannot find bearer token in server response"]);
                    failure?(error: error)
                }
            }
            else if let errors = json["errors"].object {
                let error = NSError(domain: SwifterError.domain, code: errors["code"]!.integer!, userInfo: [NSLocalizedDescriptionKey: errors["message"]!.string!]);
                failure?(error: error)
            }
            else {
                let error = NSError(domain: SwifterError.domain, code: SwifterError.appOnlyAuthenticationErrorCode, userInfo: [NSLocalizedDescriptionKey: "Cannot find JSON dictionary in response"]);
                failure?(error: error)
            }

        }, failure: failure)
    }

    public func postOAuth2BearerTokenWithSuccess(success: JSONSuccessHandler?, failure: FailureHandler?) {
        let path = "/oauth2/token"

        var parameters = Dictionary<String, AnyObject>()
        parameters["grant_type"] = "client_credentials"

        self.jsonRequestWithPath(path, baseURL: self.apiURL, method: "POST", parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: success, failure: failure)
    }

    public func postOAuth2InvalidateBearerTokenWithSuccess(success: TokenSuccessHandler?, failure: FailureHandler?) {
        let path = "/oauth2/invalidate_token"

        self.jsonRequestWithPath(path, baseURL: self.apiURL, method: "POST", parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            if let accessToken = json["access_token"].string {
                self.client.credential = nil

                let credentialToken = SwifterCredential.OAuthAccessToken(key: accessToken, secret: "")

                success?(accessToken: credentialToken, response: response)
            }
            else {
                success?(accessToken: nil, response: response)
            }

            }, failure: failure)
    }

    public func postOAuthRequestTokenWithCallbackURL(callbackURL: NSURL, success: TokenSuccessHandler, failure: FailureHandler?) {
        let path = "/oauth/request_token"

        var parameters =  Dictionary<String, AnyObject>()

        if let callbackURLString = callbackURL.absoluteString {
            parameters["oauth_callback"] = callbackURLString
        }

        self.client.post(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            data, response in

            let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
            let accessToken = SwifterCredential.OAuthAccessToken(queryString: responseString)
            success(accessToken: accessToken, response: response)

            }, failure: failure)
    }

    public func postOAuthAccessTokenWithRequestToken(requestToken: SwifterCredential.OAuthAccessToken, success: TokenSuccessHandler, failure: FailureHandler?) {
        if let verifier = requestToken.verifier {
            let path =  "/oauth/access_token"

            var parameters = Dictionary<String, AnyObject>()
            parameters["oauth_token"] = requestToken.key
            parameters["oauth_verifier"] = verifier

            self.client.post(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
                data, response in

                let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
                let accessToken = SwifterCredential.OAuthAccessToken(queryString: responseString)
                success(accessToken: accessToken, response: response)

                }, failure: failure)
        }
        else {
            let userInfo = [NSLocalizedFailureReasonErrorKey: "Bad OAuth response received from server"]
            let error = NSError(domain: SwifterError.domain, code: NSURLErrorBadServerResponse, userInfo: userInfo)
            failure?(error: error)
        }
    }

}
