//
//  SwifterSavedSearches.swift
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
    GET    saved_searches/list

    Returns the authenticated user's saved search queries.
    */
    public func getSavedSearchesListWithSuccess(success: ((savedSearches: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "saved_searches/list.json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(savedSearches: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    saved_searches/show/:id

    Retrieve the information for the saved search represented by the given id. The authenticating user must be the owner of saved search ID being requested.
    */
    public func getSavedSearchesShowWithID(id: Int, success: ((savedSearch: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "saved_searches/show/\(id).json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(savedSearch: json.object)
            return

            }, failure: failure)
    }

    /*
    POST   saved_searches/create

    Create a new saved search for the authenticated user. A user may only have 25 saved searches.
    */
    public func postSavedSearchesCreateShowWithQuery(query: String, success: ((savedSearch: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "saved_searches/create.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["query"] = query

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(savedSearch: json.object)
            return

            }, failure: failure)
    }

    /*
    POST   saved_searches/destroy/:id

    Destroys a saved search for the authenticating user. The authenticating user must be the owner of saved search id being destroyed.
    */
    public func postSavedSearchesDestroyWithID(id: Int, success: ((savedSearch: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "saved_searches/destroy/\(id).json"

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(savedSearch: json.object)
            return
            
            }, failure: failure)
    }
    
}
