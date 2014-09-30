//
//  SwifterStreaming.swift
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
    POST	statuses/filter

    Returns public statuses that match one or more filter predicates. Multiple parameters may be specified which allows most clients to use a single connection to the Streaming API. Both GET and POST requests are supported, but GET requests with too many parameters may cause the request to be rejected for excessive URL length. Use a POST request to avoid long URLs.

    The track, follow, and locations fields should be considered to be combined with an OR operator. track=foo&follow=1234 returns Tweets matching "foo" OR created by user 1234.

    The default access level allows up to 400 track keywords, 5,000 follow userids and 25 0.1-360 degree location boxes. If you need elevated access to the Streaming API, you should explore our partner providers of Twitter data here: https://dev.twitter.com/programs/twitter-certified-products/products#Certified-Data-Products

    At least one predicate parameter (follow, locations, or track) must be specified.
    */
    public func postStatusesFilterWithFollow(follow: [String]?, track: [String]?, locations: [String]?, delimited: Bool?, stallWarnings: Bool?, progress: ((status: Dictionary<String, JSONValue>?) -> Void)?, stallWarningHandler: ((code: String?, message: String?, percentFull: Int?) -> Void)?, failure: FailureHandler?) {
        assert(follow != nil || track != nil || locations != nil, "At least one predicate parameter (follow, locations, or track) must be specified")

        let path = "statuses/filter.json"

        var parameters = Dictionary<String, AnyObject>()
        if follow != nil {
            parameters["follow"] = join(",", follow!)
        }
        if track != nil {
            parameters["track"] = join(",", track!)
        }
        if locations != nil {
            parameters["locations"] = join(",", locations!)
        }
        if delimited != nil {
            parameters["delimited"] = delimited!
        }
        if stallWarnings != nil {
            parameters["stall_warnings"] = stallWarnings!
        }

        self.postJSONWithPath(path, baseURL: self.streamURL, parameters: parameters, uploadProgress: nil, downloadProgress: {
            json, response in

            if let stallWarning = json["warning"].object {
                switch (stallWarning["code"]?.string, stallWarning["message"]?.string, stallWarning["percent_full"]?.integer) {
                case (let code , let message, let percentFull):
                    stallWarningHandler?(code: code, message: message, percentFull: percentFull)
                default:
                    stallWarningHandler?(code: nil, message: nil, percentFull: nil)
                }
            }
            else {
                progress?(status: json.object)
            }

            }, success: {
                json, response in

                progress?(status: json.object)
                return

            }, failure: failure)
    }

    /*
    GET    statuses/sample

    Returns a small random sample of all public statuses. The Tweets returned by the default access level are the same, so if two different clients connect to this endpoint, they will see the same Tweets.
    */
    public func getStatusesSampleDelimited(delimited: Bool?, stallWarnings: Bool?, progress: ((status: Dictionary<String, JSONValue>?) -> Void)?, stallWarningHandler: ((code: String?, message: String?, percentFull: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/sample.json"

        var parameters = Dictionary<String, AnyObject>()
        if delimited != nil {
            parameters["delimited"] = delimited!
        }
        if stallWarnings != nil {
            parameters["stall_warnings"] = stallWarnings!
        }

        self.getJSONWithPath(path, baseURL: self.streamURL, parameters: parameters, uploadProgress: nil, downloadProgress: {
            json, response in

            if let stallWarning = json["warning"].object {
                switch (stallWarning["code"]?.string, stallWarning["message"]?.string, stallWarning["percent_full"]?.integer) {
                case (let code , let message, let percentFull):
                    stallWarningHandler?(code: code, message: message, percentFull: percentFull)
                default:
                    stallWarningHandler?(code: nil, message: nil, percentFull: nil)
                }
            }
            else {
                progress?(status: json.object)
            }

            }, success: {
                json, response in

                progress?(status: json.object)
                return

            }, failure: failure)
    }

    /*
    GET    statuses/firehose

    This endpoint requires special permission to access.

    Returns all public statuses. Few applications require this level of access. Creative use of a combination of other resources and various access levels can satisfy nearly every application use case.
    */
    public func getStatusesFirehose(count: Int?, delimited: Bool?, stallWarnings: Bool?, progress: ((status: Dictionary<String, JSONValue>?) -> Void)?, stallWarningHandler: ((code: String?, message: String?, percentFull: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/firehose.json"

        var parameters = Dictionary<String, AnyObject>()
        if count != nil {
            parameters["count"] = count!
        }
        if delimited != nil {
            parameters["delimited"] = delimited!
        }
        if stallWarnings != nil {
            parameters["stall_warnings"] = stallWarnings!
        }

        self.getJSONWithPath(path, baseURL: self.streamURL, parameters: parameters, uploadProgress: nil, downloadProgress: {
            json, response in

            if let stallWarning = json["warning"].object {
                switch (stallWarning["code"]?.string, stallWarning["message"]?.string, stallWarning["percent_full"]?.integer) {
                case (let code , let message, let percentFull):
                    stallWarningHandler?(code: code, message: message, percentFull: percentFull)
                default:
                    stallWarningHandler?(code: nil, message: nil, percentFull: nil)
                }
            }
            else {
                progress?(status: json.object)
            }

            }, success: {
                json, response in

                progress?(status: json.object)
                return

            }, failure: failure)
    }

    /*
    GET    user

    Streams messages for a single user, as described in User streams https://dev.twitter.com/docs/streaming-apis/streams/user
    */
    public func getUserStreamDelimited(delimited: Bool?, stallWarnings: Bool?, includeMessagesFromFollowedAccounts: Bool?, includeReplies: Bool?, track: [String]?, locations: [String]?, stringifyFriendIDs: Bool?, progress: ((status: Dictionary<String, JSONValue>?) -> Void)?, stallWarningHandler: ((code: String?, message: String?, percentFull: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "user.json"

        var parameters = Dictionary<String, AnyObject>()
        if delimited != nil {
            parameters["delimited"] = delimited!
        }
        if stallWarnings != nil {
            parameters["stall_warnings"] = stallWarnings!
        }
        if includeMessagesFromFollowedAccounts != nil {
            if includeMessagesFromFollowedAccounts! {
                parameters["with"] = "user"
            }
        }
        if includeReplies != nil {
            if includeReplies! {
                parameters["replies"] = "all"
            }
        }
        if track != nil {
            parameters["track"] = join(",", track!)
        }
        if locations != nil {
            parameters["locations"] = join(",", locations!)
        }
        if stringifyFriendIDs != nil {
            parameters["stringify_friend_ids"] = stringifyFriendIDs!
        }

        self.getJSONWithPath(path, baseURL: self.streamURL, parameters: parameters, uploadProgress: nil, downloadProgress: {
            json, response in

            if let stallWarning = json["warning"].object {
                switch (stallWarning["code"]?.string, stallWarning["message"]?.string, stallWarning["percent_full"]?.integer) {
                case (let code , let message, let percentFull):
                    stallWarningHandler?(code: code, message: message, percentFull: percentFull)
                default:
                    stallWarningHandler?(code: nil, message: nil, percentFull: nil)
                }
            }
            else {
                progress?(status: json.object)
            }

            }, success: {
                json, response in

                progress?(status: json.object)
                return

            }, failure: failure)
    }

    /*
    GET    site

    Streams messages for a set of users, as described in Site streams https://dev.twitter.com/docs/streaming-apis/streams/site
    */
    public func getSiteStreamDelimited(delimited: Bool?, stallWarnings: Bool?, restrictToUserMessages: Bool?, includeReplies: Bool?, stringifyFriendIDs: Bool?, progress: ((status: Dictionary<String, JSONValue>?) -> Void)?, stallWarningHandler: ((code: String?, message: String?, percentFull: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "site.json"

        var parameters = Dictionary<String, AnyObject>()
        if delimited != nil {
            parameters["delimited"] = delimited!
        }
        if stallWarnings != nil {
            parameters["stall_warnings"] = stallWarnings!
        }
        if restrictToUserMessages != nil {
            if restrictToUserMessages! {
                parameters["with"] = "user"
            }
        }
        if includeReplies != nil {
            if includeReplies! {
                parameters["replies"] = "all"
            }
        }
        if stringifyFriendIDs != nil {
            parameters["stringify_friend_ids"] = stringifyFriendIDs!
        }

        self.getJSONWithPath(path, baseURL: self.streamURL, parameters: parameters, uploadProgress: nil, downloadProgress: {
            json, response in

            switch (json["warning"]["code"].string, json["warning"]["message"].string, json["warning"]["percent_full"].integer) {
            case (let code , let message, let percentFull):
                stallWarningHandler?(code: code, message: message, percentFull: percentFull)
            default:
                stallWarningHandler?(code: nil, message: nil, percentFull: nil)
            }

            }, success: {
                json, response in
                
                progress?(status: json.object)
                return
                
            }, failure: failure)
    }
    
}
