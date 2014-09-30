//
//  SwifterSpam.swift
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
    POST   users/report_spam

    Report the specified user as a spam account to Twitter. Additionally performs the equivalent of POST blocks/create on behalf of the authenticated user.
    */
    public func postUsersReportSpamWithScreenName(screenName: String, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "users/report_spam.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    public func postUsersReportSpamWithScreenName(userID: Int, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "users/report_spam.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["user_id"] = userID

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }
    
}
