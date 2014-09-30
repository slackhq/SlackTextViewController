//
//  SwifterHelp.swift
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

public extension Swifter {

    /*
    GET    help/configuration

    Returns the current configuration used by Twitter including twitter.com slugs which are not usernames, maximum photo resolutions, and t.co URL lengths.

    It is recommended applications request this endpoint when they are loaded, but no more than once a day.
    */
    public func getHelpConfigurationWithSuccess(success: ((config: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "help/configuration.json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(config: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    help/languages

    Returns the list of languages supported by Twitter along with their ISO 639-1 code. The ISO 639-1 code is the two letter value to use if you include lang with any of your requests.
    */
    public func getHelpLanguagesWithSuccess(success: ((languages: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "help/languages.json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(languages: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    help/privacy

    Returns Twitter's Privacy Policy.
    */
    public func getHelpPrivacyWithSuccess(success: ((privacy: String?) -> Void)?, failure: FailureHandler?) {
        let path = "help/privacy.json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(privacy: json["privacy"].string)
            return

            }, failure: failure)
    }

    /*
    GET    help/tos

    Returns the Twitter Terms of Service in the requested format. These are not the same as the Developer Rules of the Road.
    */
    public func getHelpTermsOfServiceWithSuccess(success: ((tos: String?) -> Void)?, failure: FailureHandler?) {
        let path = "help/tos.json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(tos: json["tos"].string)
            return

            }, failure: failure)
    }

    /*
    GET    application/rate_limit_status

    Returns the current rate limits for methods belonging to the specified resource families.

    Each 1.1 API resource belongs to a "resource family" which is indicated in its method documentation. You can typically determine a method's resource family from the first component of the path after the resource version.

    This method responds with a map of methods belonging to the families specified by the resources parameter, the current remaining uses for each of those resources within the current rate limiting window, and its expiration time in epoch time. It also includes a rate_limit_context field that indicates the current access token or application-only authentication context.

    You may also issue requests to this method without any parameters to receive a map of all rate limited GET methods. If your application only uses a few of methods, please explicitly provide a resources parameter with the specified resource families you work with.

    When using app-only auth, this method's response indicates the app-only auth rate limiting context.

    Read more about REST API Rate Limiting in v1.1 and review the limits.
    */
    public func getRateLimitsForResources(resources: [String], success: ((rateLimitStatus: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "application/rate_limit_status.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["resources"] = join(",", resources)

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(rateLimitStatus: json.object)
            return

            }, failure: failure)
    }
    
}
