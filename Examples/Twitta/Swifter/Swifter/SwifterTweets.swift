//
//  SwifterTweets.swift
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
    GET    statuses/retweets/:id

    Returns up to 100 of the first retweets of a given tweet.
    */
    public func getStatusesRetweetsWithID(id: Int, count: Int?, trimUser: Bool?, success: ((statuses: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/retweets/\(id).json"

        var parameters = Dictionary<String, AnyObject>()
        if count != nil {
            parameters["count"] = count!
        }
        if trimUser != nil {
            parameters["trim_user"] = trimUser!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(statuses: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    statuses/show/:id

    Returns a single Tweet, specified by the id parameter. The Tweet's author will also be embedded within the tweet.

    See Embeddable Timelines, Embeddable Tweets, and GET statuses/oembed for tools to render Tweets according to Display Requirements.

    # About Geo

    If there is no geotag for a status, then there will be an empty <geo/> or "geo" : {}. This can only be populated if the user has used the Geotagging API to send a statuses/update.

    The JSON response mostly uses conventions laid out in GeoJSON. Unfortunately, the coordinates that Twitter renders are reversed from the GeoJSON specification (GeoJSON specifies a longitude then a latitude, whereas we are currently representing it as a latitude then a longitude). Our JSON renders as: "geo": { "type":"Point", "coordinates":[37.78029, -122.39697] }

    # Contributors

    If there are no contributors for a Tweet, then there will be an empty or "contributors" : {}. This field will only be populated if the user has contributors enabled on his or her account -- this is a beta feature that is not yet generally available to all.

    This object contains an array of user IDs for users who have contributed to this status (an example of a status that has been contributed to is this one). In practice, there is usually only one ID in this array. The JSON renders as such "contributors":[8285392].
    */
    public func getStatusesShowWithID(id: Int, count: Int?, trimUser: Bool?, includeMyRetweet: Bool?, includeEntities: Bool?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/show.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id
        if count != nil {
            parameters["count"] = count!
        }
        if trimUser != nil {
            parameters["trim_user"] = trimUser!
        }
        if includeMyRetweet != nil {
            parameters["include_my_retweet"] = includeMyRetweet!
        }
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	statuses/destroy/:id

    Destroys the status specified by the required ID parameter. The authenticating user must be the author of the specified status. Returns the destroyed status if successful.
    */
    public func postStatusesDestroyWithID(id: Int, trimUser: Bool?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/destroy/\(id).json"

        var parameters = Dictionary<String, AnyObject>()
        if trimUser != nil {
            parameters["trim_user"] = trimUser!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	statuses/update

    Updates the authenticating user's current status, also known as tweeting. To upload an image to accompany the tweet, use POST statuses/update_with_media.

    For each update attempt, the update text is compared with the authenticating user's recent tweets. Any attempt that would result in duplication will be blocked, resulting in a 403 error. Therefore, a user cannot submit the same status twice in a row.

    While not rate limited by the API a user is limited in the number of tweets they can create at a time. If the number of updates posted by the user reaches the current allowed limit this method will return an HTTP 403 error.

    - Any geo-tagging parameters in the update will be ignored if geo_enabled for the user is false (this is the default setting for all users unless the user has enabled geolocation in their settings)
    - The number of digits passed the decimal separator passed to lat, up to 8, will be tracked so that the lat is returned in a status object it will have the same number of digits after the decimal separator.
    - Please make sure to use to use a decimal point as the separator (and not the decimal comma) for the latitude and the longitude - usage of the decimal comma will cause the geo-tagged portion of the status update to be dropped.
    - For JSON, the response mostly uses conventions described in GeoJSON. Unfortunately, the geo object has coordinates that Twitter renderers are reversed from the GeoJSON specification (GeoJSON specifies a longitude then a latitude, whereas we are currently representing it as a latitude then a longitude. Our JSON renders as: "geo": { "type":"Point", "coordinates":[37.78217, -122.40062] }
    - The coordinates object is replacing the geo object (no deprecation date has been set for the geo object yet) -- the difference is that the coordinates object, in JSON, is now rendered correctly in GeoJSON.
    - If a place_id is passed into the status update, then that place will be attached to the status. If no place_id was explicitly provided, but latitude and longitude are, we attempt to implicitly provide a place by calling geo/reverse_geocode.
    - Users will have the ability, from their settings page, to remove all the geotags from all their tweets en masse. Currently we are not doing any automatic scrubbing nor providing a method to remove geotags from individual tweets.

    See:

    - https://dev.twitter.com/notifications/multiple-media-entities-in-tweets
    - https://dev.twitter.com/docs/api/multiple-media-extended-entities
    */
    public func postStatusUpdate(status: String, inReplyToStatusID: Int?, lat: Double?, long: Double?, placeID: Double?, displayCoordinates: Bool?, trimUser: Bool?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        var path: String = "statuses/update.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["status"] = status

        if inReplyToStatusID != nil {
            parameters["in_reply_to_status_id"] = inReplyToStatusID!
        }
        if placeID != nil {
            parameters["place_id"] = placeID!
            parameters["display_coordinates"] = true
        }
        else if lat != nil && long != nil {
            parameters["lat"] = lat!
            parameters["long"] = long!
            parameters["display_coordinates"] = true
        }
        if trimUser != nil {
            parameters["trim_user"] = trimUser!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    public func postStatusUpdate(status: String, media: NSData, inReplyToStatusID: Int?, lat: Double?, long: Double?, placeID: Double?, displayCoordinates: Bool?, trimUser: Bool?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        var path: String = "statuses/update_with_media.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["status"] = status
        parameters["media[]"] = media
        parameters[Swifter.DataParameters.dataKey] = "media[]"

        if inReplyToStatusID != nil {
            parameters["in_reply_to_status_id"] = inReplyToStatusID!
        }
        if placeID != nil {
            parameters["place_id"] = placeID!
            parameters["display_coordinates"] = true
        }
        else if lat != nil && long != nil {
            parameters["lat"] = lat!
            parameters["long"] = long!
            parameters["display_coordinates"] = true
        }
        if trimUser != nil {
            parameters["trim_user"] = trimUser!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	statuses/retweet/:id

    Retweets a tweet. Returns the original tweet with retweet details embedded.

    - This method is subject to update limits. A HTTP 403 will be returned if this limit as been hit.
    - Twitter will ignore attempts to perform duplicate retweets.
    - The retweet_count will be current as of when the payload is generated and may not reflect the exact count. It is intended as an approximation.

    Returns Tweets (1: the new tweet)
    */
    public func postStatusRetweetWithID(id: Int, trimUser: Bool?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/retweet/\(id).json"

        var parameters = Dictionary<String, AnyObject>()
        if trimUser != nil {
            parameters["trim_user"] = trimUser!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    statuses/oembed

    Returns information allowing the creation of an embedded representation of a Tweet on third party sites. See the oEmbed specification for information about the response format.

    While this endpoint allows a bit of customization for the final appearance of the embedded Tweet, be aware that the appearance of the rendered Tweet may change over time to be consistent with Twitter's Display Requirements. Do not rely on any class or id parameters to stay constant in the returned markup.
    */
    public func getStatusesOEmbedWithID(id: Int, maxWidth: Int?, hideMedia: Bool?, hideThread: Bool?, omitScript: Bool?, align: String?, related: String?, lang: String?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/oembed.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id

        if maxWidth != nil {
            parameters["max_width"] = maxWidth!
        }
        if hideMedia != nil {
            parameters["hide_media"] = hideMedia!
        }
        if hideThread != nil {
            parameters["hide_thread"] = hideThread!
        }
        if omitScript != nil {
            parameters["omit_scipt"] = omitScript!
        }
        if align != nil {
            parameters["align"] = align!
        }
        if related != nil {
            parameters["related"] = related!
        }
        if lang != nil {
            parameters["lang"] = lang!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    public func getStatusesOEmbedWithURL(url: NSURL, maxWidth: Int?, hideMedia: Bool?, hideThread: Bool?, omitScript: Bool?, align: String?, related: String?, lang: String?, success: ((status: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/oembed.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["url"] = url.absoluteString

        if maxWidth != nil {
            parameters["max_width"] = maxWidth!
        }
        if hideMedia != nil {
            parameters["hide_media"] = hideMedia!
        }
        if hideThread != nil {
            parameters["hide_thread"] = hideThread!
        }
        if omitScript != nil {
            parameters["omit_scipt"] = omitScript!
        }
        if align != nil {
            parameters["align"] = align!
        }
        if related != nil {
            parameters["related"] = related!
        }
        if lang != nil {
            parameters["lang"] = lang!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(status: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    statuses/retweeters/ids

    Returns a collection of up to 100 user IDs belonging to users who have retweeted the tweet specified by the id parameter.

    This method offers similar data to GET statuses/retweets/:id and replaces API v1's GET statuses/:id/retweeted_by/ids method.
    */
    public func getStatusesRetweetersWithID(id: Int, cursor: Int?, stringifyIDs: Bool?, success: ((ids: [JSONValue]?, previousCursor: Int?, nextCursor: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/retweeters/ids.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id

        if cursor != nil {
            parameters["cursor"] = cursor!
        }
        if stringifyIDs != nil {
            parameters["stringify_ids"] = cursor!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            switch (json["ids"].array, json["previous_cursor"].integer, json["next_cursor"].integer) {
            case (let ids, let previousCursor, let nextCursor):
                success?(ids: ids, previousCursor: previousCursor, nextCursor: nextCursor)
            default:
                success?(ids: nil, previousCursor: nil, nextCursor: nil)
            }

            }, failure: failure)
    }

    /*
    GET statuses/lookup

    Returns fully-hydrated tweet objects for up to 100 tweets per request, as specified by comma-separated values passed to the id parameter. This method is especially useful to get the details (hydrate) a collection of Tweet IDs. GET statuses/show/:id is used to retrieve a single tweet object.
    */
    public func getStatusesLookupTweetIDs(tweetIDs: [Int], includeEntities: Bool?, map: Bool?, success: ((statuses: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "statuses/lookup.json"

        var parameters = Dictionary<String, AnyObject>()
        let tweetIDStrings = tweetIDs.map { String($0) }
        parameters["id"] = join(",", tweetIDStrings)

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if map != nil {
            parameters["map"] = map!
        }
        
        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in
            
            success?(statuses: json.array)
            return
            
            }, failure: failure)
    }
    
}
