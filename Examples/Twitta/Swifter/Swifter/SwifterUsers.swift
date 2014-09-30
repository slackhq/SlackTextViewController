//
//  SwifterUsers.swift
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
    GET    account/settings

    Returns settings (including current trend, geo and sleep time information) for the authenticating user.
    */
    public func getAccountSettingsWithSuccess(success: ((settings: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "account/settings.json"

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(settings: json.object)
            return

            }, failure: failure)
    }

    /*
    GET	account/verify_credentials

    Returns an HTTP 200 OK response code and a representation of the requesting user if authentication was successful; returns a 401 status code and an error message if not. Use this method to test if supplied user credentials are valid.
    */
    public func getAccountVerifyCredentials(includeEntities: Bool?, skipStatus: Bool?, success: ((myInfo: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "account/verify_credentials.json"

        var parameters = Dictionary<String, AnyObject>()
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(myInfo: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	account/settings

    Updates the authenticating user's settings.
    */
    public func postAccountSettings(trendLocationWOEID: Int?, sleepTimeEnabled: Bool?, startSleepTime: Int?, endSleepTime: Int?, timeZone: String?, lang: String?, success: ((settings: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        assert(trendLocationWOEID != nil || sleepTimeEnabled != nil || startSleepTime != nil || endSleepTime != nil || timeZone != nil || lang != nil, "At least one or more should be provided when executing this request")

        let path = "account/settings.json"

        var parameters = Dictionary<String, AnyObject>()
        if trendLocationWOEID != nil {
            parameters["trend_location_woeid"] = trendLocationWOEID!
        }
        if sleepTimeEnabled != nil {
            parameters["sleep_time_enabled"] = sleepTimeEnabled!
        }
        if startSleepTime != nil {
            parameters["start_sleep_time"] = startSleepTime!
        }
        if endSleepTime != nil {
            parameters["end_sleep_time"] = endSleepTime!
        }
        if timeZone != nil {
            parameters["time_zone"] = timeZone!
        }
        if lang != nil {
            parameters["lang"] = lang!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(settings: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	account/update_delivery_device

    Sets which device Twitter delivers updates to for the authenticating user. Sending none as the device parameter will disable SMS updates.
    */
    public func postAccountUpdateDeliveryDeviceSMS(device: Bool, includeEntities: Bool?, success: ((deliveryDeviceSettings: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "account/update_delivery_device.json"

        var parameters = Dictionary<String, AnyObject>()
        if device {
            parameters["device"] = "sms"
        }
        else {
            parameters["device"] = "none"
        }
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(deliveryDeviceSettings: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	account/update_profile

    Sets values that users are able to set under the "Account" tab of their settings page. Only the parameters specified will be updated.
    */
    public func postAccountUpdateProfileWithName(name: String?, url: String?, location: String?, description: String?, includeEntities: Bool?, skipStatus: Bool?, success: ((profile: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        assert(name != nil || url != nil || location != nil || description != nil || includeEntities != nil || skipStatus != nil)

        let path = "account/update_profile.json"

        var parameters = Dictionary<String, AnyObject>()
        if name != nil {
            parameters["name"] = name!
        }
        if url != nil {
            parameters["url"] = url!
        }
        if location != nil {
            parameters["location"] = location!
        }
        if description != nil {
            parameters["description"] = description!
        }
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(profile: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	account/update_profile_background_image

    Updates the authenticating user's profile background image. This method can also be used to enable or disable the profile background image. Although each parameter is marked as optional, at least one of image, tile or use must be provided when making this request.
    */
    public func postAccountUpdateProfileBackgroundImage(imageData: NSData?, title: String?, includeEntities: Bool?, use: Bool?, success: ((profile: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        assert(imageData != nil || title != nil || use != nil, "At least one of image, tile or use must be provided when making this request")

        let path = "account/update_profile_background_image.json"

        var parameters = Dictionary<String, AnyObject>()
        if imageData != nil {
            parameters["image"] = imageData!.base64EncodedStringWithOptions(nil)
        }
        if title != nil {
            parameters["title"] = title!
        }
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if use != nil {
            parameters["use"] = use!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(profile: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	account/update_profile_colors

    Sets one or more hex values that control the color scheme of the authenticating user's profile page on twitter.com. Each parameter's value must be a valid hexidecimal value, and may be either three or six characters (ex: #fff or #ffffff).
    */
    public func postUpdateAccountProfileColors(profileBackgroundColor: String?, profileLinkColor: String?, profileSidebarBorderColor: String?, profileSidebarFillColor: String?, profileTextColor: String?, includeEntities: Bool?, skipStatus: Bool?, success: ((profile: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler) {
        let path = "account/update_profile_colors.json"

        var parameters = Dictionary<String, AnyObject>()

        if profileBackgroundColor != nil {
            parameters["profile_background_color"] = profileBackgroundColor!
        }
        if profileLinkColor != nil {
            parameters["profile_link_color"] = profileLinkColor!
        }
        if profileSidebarBorderColor != nil {
            parameters["profile_sidebar_link_color"] = profileSidebarBorderColor!
        }
        if profileSidebarFillColor != nil {
            parameters["profile_sidebar_fill_color"] = profileSidebarFillColor!
        }
        if profileTextColor != nil {
            parameters["profile_text_color"] = profileTextColor!
        }
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(profile: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	account/update_profile_image

    Updates the authenticating user's profile image. Note that this method expects raw multipart data, not a URL to an image.

    This method asynchronously processes the uploaded file before updating the user's profile image URL. You can either update your local cache the next time you request the user's information, or, at least 5 seconds after uploading the image, ask for the updated URL using GET users/show.
    */
    public func postAccountUpdateProfileImage(imageData: NSData?, includeEntities: Bool?, skipStatus: Bool?, success: ((profile: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "account/update_profile_image.json"

        var parameters = Dictionary<String, AnyObject>()
        if imageData != nil {
            parameters["image"] = imageData!.base64EncodedStringWithOptions(nil)
        }
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(profile: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    blocks/list

    Returns a collection of user objects that the authenticating user is blocking.
    */
    public func getBlockListWithIncludeEntities(includeEntities: Bool?, skipStatus: Bool?, cursor: Int?, success: ((users: [JSONValue]?, previousCursor: Int?, nextCursor: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "blocks/list.json"

        var parameters = Dictionary<String, AnyObject>()
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }
        if cursor != nil {
            parameters["cursor"] = cursor!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            switch (json["users"].array, json["previous_cursor"].integer, json["next_cursor"].integer) {
            case (let users, let previousCursor, let nextCursor):
                success?(users: users, previousCursor: previousCursor, nextCursor: nextCursor)
            default:
                success?(users: nil, previousCursor: nil, nextCursor: nil)
            }

            }, failure: failure)
    }

    /*
    GET    blocks/ids

    Returns an array of numeric user ids the authenticating user is blocking.
    */
    public func getBlockIDsWithStingifyIDs(stringifyIDs: String?, cursor: Int?, success: ((ids: [JSONValue]?, previousCursor: Int?, nextCursor: Int?) -> Void)?, failure: FailureHandler) {
        let path = "blocks/ids.json"

        var parameters = Dictionary<String, AnyObject>()
        if stringifyIDs != nil {
            parameters["stringify_ids"] = stringifyIDs!
        }
        if cursor != nil {
            parameters["cursor"] = cursor!
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
    POST	blocks/create

    Blocks the specified user from following the authenticating user. In addition the blocked user will not show in the authenticating users mentions or timeline (unless retweeted by another user). If a follow or friend relationship exists it is destroyed.
    */
    public func postBlocksCreateWithScreenName(screenName: String, includeEntities: Bool?, skipStatus: Bool?, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler) {
        let path = "blocks/create.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    public func postBlocksCreateWithUserID(userID: Int, includeEntities: Bool?, skipStatus: Bool?, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler) {
        let path = "blocks/create.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["user_id"] = userID

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    /*
    POST	blocks/destroy

    Un-blocks the user specified in the ID parameter for the authenticating user. Returns the un-blocked user in the requested format when successful. If relationships existed before the block was instated, they will not be restored.
    */
    public func postDestroyBlocksWithUserID(userID: Int, includeEntities: Bool?, skipStatus: Bool?, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler) {
        let path = "blocks/destroy.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["user_id"] = userID

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    public func postDestroyBlocksWithScreenName(screenName: String, includeEntities: Bool?, skipStatus: Bool?, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler) {
        let path = "blocks/destroy.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    users/lookup

    Returns fully-hydrated user objects for up to 100 users per request, as specified by comma-separated values passed to the user_id and/or screen_name parameters.

    This method is especially useful when used in conjunction with collections of user IDs returned from GET friends/ids and GET followers/ids.

    GET users/show is used to retrieve a single user object.

    There are a few things to note when using this method.

    - You must be following a protected user to be able to see their most recent status update. If you don't follow a protected user their status will be removed.
    - The order of user IDs or screen names may not match the order of users in the returned array.
    - If a requested user is unknown, suspended, or deleted, then that user will not be returned in the results list.
    - If none of your lookup criteria can be satisfied by returning a user object, a HTTP 404 will be thrown.
    - You are strongly encouraged to use a POST for larger requests.
    */
    public func getUsersLookupWithScreenNames(screenNames: [String], includeEntities: Bool?, success: ((users: [JSONValue]?) -> Void)?, failure: FailureHandler) {
        let path = "users/lookup.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = join(",", screenNames)

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(users: json.array)
            return

            }, failure: failure)
    }

    public func getUsersLookupWithUserIDs(userIDs: [Int], includeEntities: Bool?, success: ((users: [JSONValue]?) -> Void)?, failure: FailureHandler) {
        let path = "users/lookup.json"

        var parameters = Dictionary<String, AnyObject>()

        let userIDStrings = userIDs.map { String($0) }
        parameters["user_id"] = join(",", userIDStrings)

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(users: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    users/show

    Returns a variety of information about the user specified by the required user_id or screen_name parameter. The author's most recent Tweet will be returned inline when possible. GET users/lookup is used to retrieve a bulk collection of user objects.

    You must be following a protected user to be able to see their most recent Tweet. If you don't follow a protected user, the users Tweet will be removed. A Tweet will not always be returned in the current_status field.
    */
    public func getUsersShowWithScreenName(screenName: String, includeEntities: Bool?, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler) {
        let path = "users/show.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    public func getUsersShowWithUserID(userID: Int, includeEntities: Bool?, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler) {
        let path = "users/show.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["user_id"] = userID

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    users/search

    Provides a simple, relevance-based search interface to public user accounts on Twitter. Try querying by topical interest, full name, company name, location, or other criteria. Exact match searches are not supported.

    Only the first 1,000 matching results are available.
    */
    public func getUsersSearchWithQuery(q: String, page: Int?, count: Int?, includeEntities: Bool?, success: ((users: [JSONValue]?) -> Void)?, failure: FailureHandler) {
        let path = "users/search/json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["q"] = q

        if page != nil {
            parameters["page"] = page!
        }
        if count != nil {
            parameters["count"] = count!
        }
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(users: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    users/contributees

    Returns a collection of users that the specified user can "contribute" to.
    */
    public func getUsersContributeesWithUserID(id: Int, includeEntities: Bool?, skipStatus: Bool?, success: ((users: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "users/contributees.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(users: json.array)
            return

            }, failure: failure)
    }

    public func getUsersContributeesWithScreenName(screenName: String, includeEntities: Bool?, skipStatus: Bool?, success: ((users: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "users/contributees.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(users: json.array)
            return

            }, failure: failure)
    }

    /*
    GET    users/contributors

    Returns a collection of users who can contribute to the specified account.
    */
    public func getUsersContributorsWithUserID(id: Int, includeEntities: Bool?, skipStatus: Bool?, success: ((users: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "users/contributors.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["id"] = id

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(users: json.array)
            return

            }, failure: failure)
    }

    public func getUsersContributorsWithScreenName(screenName: String, includeEntities: Bool?, skipStatus: Bool?, success: ((users: [JSONValue]?) -> Void)?, failure: FailureHandler?) {
        let path = "users/contributors.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }

        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(users: json.array)
            return

            }, failure: failure)
    }

    /*
    POST   account/remove_profile_banner

    Removes the uploaded profile banner for the authenticating user. Returns HTTP 200 upon success.
    */
    public func postAccountRemoveProfileBannerWithSuccess(success: ((response: JSON) -> Void)?, failure: FailureHandler?) {
        let path = "account/remove_profile_banner.json"

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(response: json)
            return

            }, failure: failure)
    }

    /*
    POST    account/update_profile_banner

    Uploads a profile banner on behalf of the authenticating user. For best results, upload an <5MB image that is exactly 1252px by 626px. Images will be resized for a number of display options. Users with an uploaded profile banner will have a profile_banner_url node in their Users objects. More information about sizing variations can be found in User Profile Images and Banners and GET users/profile_banner.

    Profile banner images are processed asynchronously. The profile_banner_url and its variant sizes will not necessary be available directly after upload.

    If providing any one of the height, width, offset_left, or offset_top parameters, you must provide all of the sizing parameters.

    HTTP Response Codes
    200, 201, 202	Profile banner image succesfully uploaded
    400	Either an image was not provided or the image data could not be processed
    422	The image could not be resized or is too large.
    */
    public func postAccountUpdateProfileBannerWithImageData(imageData: NSData?, width: Int?, height: Int?, offsetLeft: Int?, offsetTop: Int?, success: ((response: JSON) -> Void)?, failure: FailureHandler?) {
        let path = "account/update_profile_banner.json"

        var parameters = Dictionary<String, AnyObject>()
        if imageData != nil {
            parameters["banner"] = imageData!.base64EncodedStringWithOptions(nil)
        }
        if width != nil {
            parameters["width"] = width!
        }
        if height != nil {
            parameters["height"] = height!
        }
        if offsetLeft != nil {
            parameters["offset_left"] = offsetLeft!
        }
        if offsetTop != nil {
            parameters["offset_top"] = offsetTop!
        }

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(response: json)
            return

            }, failure: failure)
    }

    /*
    GET    users/profile_banner

    Returns a map of the available size variations of the specified user's profile banner. If the user has not uploaded a profile banner, a HTTP 404 will be served instead. This method can be used instead of string manipulation on the profile_banner_url returned in user objects as described in User Profile Images and Banners.
    */
    public func getUsersProfileBannerWithUserID(userID: Int, success: ((response: JSON) -> Void)?, failure: FailureHandler?) {
        let path = "users/profile_banner.json"

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: [:], uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(response: json)
            return

            }, failure: failure)
    }

    /*
    POST   mutes/users/create

    Mutes the user specified in the ID parameter for the authenticating user.

    Returns the muted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.

    Actions taken in this method are asynchronous and changes will be eventually consistent.
    */
    public func postMutesUsersCreateForScreenName(screenName: String, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "mutes/users/create.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    public func postMutesUsersCreateForUserID(userID: Int, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "mutes/users/create.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["user_id"] = userID

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    /*
    POST   mutes/users/destroy

    Un-mutes the user specified in the ID parameter for the authenticating user.

    Returns the unmuted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.

    Actions taken in this method are asynchronous and changes will be eventually consistent.
    */
    public func postMutesUsersDestroyForScreenName(screenName: String, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "mutes/users/destroy.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["screen_name"] = screenName

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    public func postMutesUsersDestroyForUserID(userID: Int, success: ((user: Dictionary<String, JSONValue>?) -> Void)?, failure: FailureHandler?) {
        let path = "mutes/users/destroy.json"

        var parameters = Dictionary<String, AnyObject>()
        parameters["user_id"] = userID

        self.postJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in

            success?(user: json.object)
            return

            }, failure: failure)
    }

    /*
    GET    mutes/users/ids

    Returns an array of numeric user ids the authenticating user has muted.
    */
    public func getMutesUsersIDsWithCursor(cursor: Int?, success: ((ids: [JSONValue]?, previousCursor: Int?, nextCursor: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "mutes/users/ids.json"

        var parameters = Dictionary<String, AnyObject>()
        if cursor != nil {
            parameters["cursor"] = cursor!
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
    GET    mutes/users/list
    
    Returns an array of user objects the authenticating user has muted.
    */
    public func getMutesUsersListWithCursor(cursor: Int?, includeEntities: Bool?, skipStatus: Bool?, success: ((users: [JSONValue]?, previousCursor: Int?, nextCursor: Int?) -> Void)?, failure: FailureHandler?) {
        let path = "mutes/users/list.json"
        
        var parameters = Dictionary<String, AnyObject>()
        if includeEntities != nil {
            parameters["include_entities"] = includeEntities!
        }
        if skipStatus != nil {
            parameters["skip_status"] = skipStatus!
        }
        if cursor != nil {
            parameters["cursor"] = cursor!
        }
        
        self.getJSONWithPath(path, baseURL: self.apiURL, parameters: parameters, uploadProgress: nil, downloadProgress: nil, success: {
            json, response in
            
            switch (json["users"].array, json["previous_cursor"].integer, json["next_cursor"].integer) {
            case (let users, let previousCursor, let nextCursor):
                success?(users: users, previousCursor: previousCursor, nextCursor: nextCursor)
            default:
                success?(users: nil, previousCursor: nil, nextCursor: nil)
            }
            
            }, failure: failure)
    }
    
}
