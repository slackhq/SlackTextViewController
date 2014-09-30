//
//  SwifterTrends.swift
//  Swifter
//
//  Created by Matt Donnelly on 21/06/2014.
//  Copyright (c) 2014 Matt Donnelly. All rights reserved.
//

import Foundation

public extension Swifter {

    /*
    GET    trends/place

    Returns the top 10 trending topics for a specific WOEID, if trending information is available for it.

    The response is an array of "trend" objects that encode the name of the trending topic, the query parameter that can be used to search for the topic on Twitter Search, and the Twitter Search URL.

    This information is cached for 5 minutes. Requesting more frequently than that will not return any more data, and will count against your rate limit usage.
    */
    public func getTrendsPlaceWithWOEID(id: Int, excludeHashtags: Bool?, success: ((trends: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "trends/place.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id

        if excludeHashtags != nil {
            if excludeHashtags! {
                parameters["exclude"] = "hashtags"
            }
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(trends: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    trends/available

    Returns the locations that Twitter has trending topic information for.

    The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in.

    A WOEID is a Yahoo! Where On Earth ID.
    */
    public func getTrendsAvailableWithSuccess(success: ((trends: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "trends/available.json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(trends: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    trends/closest

    Returns the locations that Twitter has trending topic information for, closest to a specified location.

    The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in.

    A WOEID is a Yahoo! Where On Earth ID.
    */
    public func getTrendsClosestWithLat(lat: Double, long: Double, success: ((trends: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "trends/closest.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["lat"] = lat
        parameters["long"] = long

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(trends: json.array)
            return

            }, failure: failure)
    }

}