//
//  SwifterFavorites.swift
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
    GET    favorites/list

    Returns the 20 most recent Tweets favorited by the authenticating or specified user.

    If you do not provide either a user_id or screen_name to this method, it will assume you are requesting on behalf of the authenticating user. Specify one or the other for best results.
    */
    public func getFavoritesListWithCount(count: Int?, sinceID: Int?, maxID: Int?, success: ((statuses: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "favorites/list.json"

        var parameters = Dictionary<String, AnyObject>()
        if count != nil {
            parameters["count"] = count!
        }
        if sinceID != nil {
            parameters["since_id"] = sinceID!
        }
        if maxID != nil {
            parameters["max_id"] = maxID!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(statuses: json.array)
            return

            }, failure: failure)
    }

    public func getFavoritesListWithUserID(userID: Int, count: Int?, sinceID: Int?, maxID: Int?, success: ((statuses: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "favorites/list.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["user_id"] = userID

        if count != nil {
            parameters["count"] = count!
        }
        if sinceID != nil {
            parameters["since_id"] = sinceID!
        }
        if maxID != nil {
            parameters["max_id"] = maxID!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(statuses: json.array)
            return

            }, failure: failure)
    }

    public func getFavoritesListWithScreenName(screenName: String, count: Int?, sinceID: Int?, maxID: Int?, success: ((statuses: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "favorites/list.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        if count != nil {
            parameters["count"] = count!
        }
        if sinceID != nil {
            parameters["since_id"] = sinceID!
        }
        if maxID != nil {
            parameters["max_id"] = maxID!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(statuses: json.array)
            return

            }, failure: failure)
    }

    /*
    POST	favorites/destroy

    Un-favorites the status specified in the ID parameter as the authenticating user. Returns the un-favorited status in the requested format when successful.

    This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
    */
    public func postDestroyFavoriteWithID(id: Int, includeEntities: Bool?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "favorites/destroy.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	favorites/create

    Favorites the status specified in the ID parameter as the authenticating user. Returns the favorite status when successful.

    This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
    */
    public func postCreateFavoriteWithID(id: Int, includeEntities: Bool?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: SwifterHTTPRequest.FailureHandler?) {
        let path = "favorites/create.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in
            
            success?(status: json.object)
            return
            
            }, failure: failure)
    }
    
}
