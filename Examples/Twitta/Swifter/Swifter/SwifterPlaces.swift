//
//  SwifterPlaces.swift
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
    GET    geo/id/:place_id

    Returns all the information about a known place.
    */
    public func getGeoIDWithPlaceID(placeID: String, success: ((place: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "geo/id/\(placeID).json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(place: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    geo/reverse_geocode

    Given a latitude and a longitude, searches for up to 20 places that can be used as a place_id when updating a status.

    This request is an informative call and will deliver generalized results about geography.
    */
    public func getGeoReverseGeocodeWithLat(lat: Double, long: Double, accuracy: String?, granularity: String?, maxResults: Int?, callback: String?, success: ((place: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "geo/reverse_geocode.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["lat"] = lat
        parameters["long"] = long

        if accuracy != nil {
            parameters["accuracy"] = accuracy!
        }
        if granularity != nil {
            parameters["granularity"] = granularity!
        }
        if maxResults != nil {
            parameters["max_results"] = maxResults!
        }
        if callback != nil {
            parameters["callback"] = callback!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(place: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    geo/search

    Search for places that can be attached to a statuses/update. Given a latitude and a longitude pair, an IP address, or a name, this request will return a list of all the valid places that can be used as the place_id when updating a status.

    Conceptually, a query can be made from the user's location, retrieve a list of places, have the user validate the location he or she is at, and then send the ID of this location with a call to POST statuses/update.

    This is the recommended method to use find places that can be attached to statuses/update. Unlike GET geo/reverse_geocode which provides raw data access, this endpoint can potentially re-order places with regards to the user who is authenticated. This approach is also preferred for interactive place matching with the user.
    */
    public func getGeoSearchWithLat(lat: Double?, long: Double?, query: String?, ipAddress: String?, accuracy: String?, granularity: String?, maxResults: Int?, containedWithin: String?, attributeStreetAddress: String?, callback: String?, success: ((places: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        assert(lat != nil || long != nil || query != nil || ipAddress != nil, "At least one of the following parameters must be provided to access this resource: lat, long, ipAddress, or query")

        let path = "geo/search.json"

        var parameters = Dictionary<String, AnyObject>()

        if lat != nil {
            parameters["lat"] = lat!
        }
        if long != nil {
            parameters["long"] = long!
        }
        if query != nil {
            parameters["query"] = query!
        }
        if ipAddress != nil {
            parameters["ipAddress"] = ipAddress!
        }
        if accuracy != nil {
            parameters["accuracy"] = accuracy!
        }
        if granularity != nil {
            parameters["granularity"] = granularity!
        }
        if maxResults != nil {
            parameters["max_results"] = maxResults!
        }
        if containedWithin != nil {
            parameters["contained_within"] = containedWithin!
        }
        if attributeStreetAddress != nil {
            parameters["attribute:street_address"] = attributeStreetAddress
        }
        if callback != nil {
            parameters["callback"] = callback!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(places: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    geo/similar_places

    Locates places near the given coordinates which are similar in name.

    Conceptually you would use this method to get a list of known places to choose from first. Then, if the desired place doesn't exist, make a request to POST geo/place to create a new one.

    The token contained in the response is the token needed to be able to create a new place.
    */
    public func getGeoSimilarPlacesWithLat(lat: Double, long: Double, name: String, containedWithin: String?, attributeStreetAddress: String?, callback: String?, success: ((places: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "geo/similar_places.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["lat"] = lat
        parameters["long"] = long
        parameters["name"] = name

        if containedWithin != nil {
            parameters["contained_within"] = containedWithin!
        }
        if attributeStreetAddress != nil {
            parameters["attribute:street_address"] = attributeStreetAddress
        }
        if callback != nil {
            parameters["callback"] = callback!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in
            
            success?(places: json.array)
            return
            
            }, failure: failure)
    }
    
}
