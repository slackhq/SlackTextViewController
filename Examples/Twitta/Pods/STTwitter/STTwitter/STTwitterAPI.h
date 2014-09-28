/*
 Copyright (c) 2012, Nicolas Seriot
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of the Nicolas Seriot nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

//
//  STTwitterAPI.h
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/18/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ENUM(NSUInteger, STTwitterAPIErrorCode) {
    STTwitterAPICannotPostEmptyStatus,
    STTwitterAPIMediaDataIsEmpty
};

extern NSString *kBaseURLStringAPI_1_1;
extern NSString *kBaseURLStringStream_1_1;
extern NSString *kBaseURLStringUserStream_1_1;
extern NSString *kBaseURLStringSiteStream_1_1;

/*
 Tweet fields contents
 https://dev.twitter.com/docs/platform-objects/tweets
 https://dev.twitter.com/blog/new-withheld-content-fields-api-responses
 */

@class ACAccount;

@interface STTwitterAPI : NSObject

+ (instancetype)twitterAPIOSWithAccount:(ACAccount *) account;
+ (instancetype)twitterAPIOSWithFirstAccount;

+ (instancetype)twitterAPIWithOAuthConsumerName:(NSString *)consumerName // purely informational, can be anything
                                    consumerKey:(NSString *)consumerKey
                                 consumerSecret:(NSString *)consumerSecret;

// convenience
+ (instancetype)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                consumerSecret:(NSString *)consumerSecret;

+ (instancetype)twitterAPIWithOAuthConsumerName:(NSString *)consumerName // purely informational, can be anything
                                    consumerKey:(NSString *)consumerKey
                                 consumerSecret:(NSString *)consumerSecret
                                       username:(NSString *)username
                                       password:(NSString *)password;

// convenience
+ (instancetype)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                consumerSecret:(NSString *)consumerSecret
                                      username:(NSString *)username
                                      password:(NSString *)password;

+ (instancetype)twitterAPIWithOAuthConsumerName:(NSString *)consumerName // purely informational, can be anything
                                    consumerKey:(NSString *)consumerKey
                                 consumerSecret:(NSString *)consumerSecret
                                     oauthToken:(NSString *)oauthToken
                               oauthTokenSecret:(NSString *)oauthTokenSecret;

// convenience
+ (instancetype)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                consumerSecret:(NSString *)consumerSecret
                                    oauthToken:(NSString *)oauthToken
                              oauthTokenSecret:(NSString *)oauthTokenSecret;

// https://dev.twitter.com/docs/auth/application-only-auth
+ (instancetype)twitterAPIAppOnlyWithConsumerName:(NSString *)consumerName
                                      consumerKey:(NSString *)consumerKey
                                   consumerSecret:(NSString *)consumerSecret;

// convenience
+ (instancetype)twitterAPIAppOnlyWithConsumerKey:(NSString *)consumerKey
                                  consumerSecret:(NSString *)consumerSecret;

/*
 authenticateInsteadOfAuthorize == NO  will return an URL to oauth/authorize
 authenticateInsteadOfAuthorize == YES will return an URL to oauth/authenticate
 
 oauth/authorize differs from oauth/authorize in that if the user has already granted the application permission, the redirect will occur without the user having to re-approve the application. To realize this behavior, you must enable the Use Sign in with Twitter setting on your application record.
 */

- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock
authenticateInsteadOfAuthorize:(BOOL)authenticateInsteadOfAuthorize // use NO if you're not sure
              forceLogin:(NSNumber *)forceLogin
              screenName:(NSString *)screenName
           oauthCallback:(NSString *)oauthCallback
              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock
           oauthCallback:(NSString *)oauthCallback
              errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postAccessTokenRequestWithPIN:(NSString *)pin
                         successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

// https://dev.twitter.com/docs/ios/using-reverse-auth

// reverse auth step 1
- (void)postReverseOAuthTokenRequest:(void(^)(NSString *authenticationHeader))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

// reverse auth step 2
// WARNING: if the Twitter account was set in iOS settings, the tokens may be nil after a system update.
// In this case, you can call -[ACAccountStore renewCredentialsForAccount:completion:] to let the user enter her Twitter password again.
- (void)postReverseAuthAccessTokenWithAuthenticationHeader:(NSString *)authenticationHeader
                                              successBlock:(void(^)(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName))successBlock
                                                errorBlock:(void(^)(NSError *error))errorBlock;

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock errorBlock:(void(^)(NSError *error))errorBlock;

- (void)invalidateBearerTokenWithSuccessBlock:(void(^)())successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

- (NSString *)prettyDescription;

@property (nonatomic, retain) NSString *userName; // available for osx, set after successful connection for STTwitterOAuth

@property (nonatomic, readonly) NSString *oauthAccessToken;
@property (nonatomic, readonly) NSString *oauthAccessTokenSecret;
@property (nonatomic, readonly) NSString *bearerToken;

#pragma mark Generic methods to GET and POST

- (id)fetchResource:(NSString *)resource
         HTTPMethod:(NSString *)HTTPMethod
      baseURLString:(NSString *)baseURLString
         parameters:(NSDictionary *)params
uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void (^)(id request, id response))downloadProgressBlock
       successBlock:(void (^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id response))successBlock
         errorBlock:(void (^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock;

- (id)getResource:(NSString *)resource
    baseURLString:(NSString *)baseURLString
       parameters:(NSDictionary *)parameters
downloadProgressBlock:(void(^)(id json))progredownloadProgressBlockssBlock
     successBlock:(void(^)(NSDictionary *rateLimits, id json))successBlock
       errorBlock:(void(^)(NSError *error))errorBlock;

- (id)postResource:(NSString *)resource
     baseURLString:(NSString *)baseURLString
        parameters:(NSDictionary *)parameters
uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void(^)(id json))downloadProgressBlock
      successBlock:(void(^)(NSDictionary *rateLimits, id response))successBlock
        errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Timelines

/*
 GET	statuses/mentions_timeline
 Returns Tweets (*: mentions for the user)
 
 Returns the 20 most recent mentions (tweets containing a users's @screen_name) for the authenticating user.
 
 The timeline returned is the equivalent of the one seen when you view your mentions on twitter.com.
 
 This method can only return up to 800 tweets.
 */

- (void)getStatusesMentionTimelineWithCount:(NSString *)count
                                    sinceID:(NSString *)sinceID
                                      maxID:(NSString *)maxID
                                   trimUser:(NSNumber *)trimUser
                         contributorDetails:(NSNumber *)contributorDetails
                            includeEntities:(NSNumber *)includeEntities
                               successBlock:(void(^)(NSArray *statuses))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock;

// convenience method
- (void)getMentionsTimelineSinceID:(NSString *)sinceID
                             count:(NSUInteger)count
                      successBlock:(void(^)(NSArray *statuses))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	statuses/user_timeline
 Returns Tweets (*: tweets for the user)
 
 Returns a collection of the most recent Tweets posted by the user indicated by the screen_name or user_id parameters.
 
 User timelines belonging to protected users may only be requested when the authenticated user either "owns" the timeline or is an approved follower of the owner.
 
 The timeline returned is the equivalent of the one seen when you view a user's profile on twitter.com.
 
 This method can only return up to 3,200 of a user's most recent Tweets. Native retweets of other statuses by the user is included in this total, regardless of whether include_rts is set to false when requesting this resource.
 */

- (void)getStatusesUserTimelineForUserID:(NSString *)userID
                              screenName:(NSString *)screenName
                                 sinceID:(NSString *)sinceID
                                   count:(NSString *)count
                                   maxID:(NSString *)maxID
                                trimUser:(NSNumber *)trimUser
                          excludeReplies:(NSNumber *)excludeReplies
                      contributorDetails:(NSNumber *)contributorDetails
                         includeRetweets:(NSNumber *)includeRetweets
                            successBlock:(void(^)(NSArray *statuses))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience method
- (void)getUserTimelineWithScreenName:(NSString *)screenName
                              sinceID:(NSString *)sinceID
                                maxID:(NSString *)maxID
                                count:(NSUInteger)count
                         successBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

// convenience method
- (void)getUserTimelineWithScreenName:(NSString *)screenName
                                count:(NSUInteger)count
                         successBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

// convenience method
- (void)getUserTimelineWithScreenName:(NSString *)screenName
                         successBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	statuses/home_timeline
 
 Returns Tweets (*: tweets from people the user follows)
 
 Returns a collection of the most recent Tweets and retweets posted by the authenticating user and the users they follow. The home timeline is central to how most users interact with the Twitter service.
 
 Up to 800 Tweets are obtainable on the home timeline. It is more volatile for users that follow many users or follow users who tweet frequently.
 */

- (void)getStatusesHomeTimelineWithCount:(NSString *)count
                                 sinceID:(NSString *)sinceID
                                   maxID:(NSString *)maxID
                                trimUser:(NSNumber *)trimUser
                          excludeReplies:(NSNumber *)excludeReplies
                      contributorDetails:(NSNumber *)contributorDetails
                         includeEntities:(NSNumber *)includeEntities
                            successBlock:(void(^)(NSArray *statuses))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience method
- (void)getHomeTimelineSinceID:(NSString *)sinceID
                         count:(NSUInteger)count
                  successBlock:(void(^)(NSArray *statuses))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    statuses/retweets_of_me
 
 Returns the most recent tweets authored by the authenticating user that have been retweeted by others. This timeline is a subset of the user's GET statuses/user_timeline. See Working with Timelines for instructions on traversing timelines.
 */

- (void)getStatusesRetweetsOfMeWithCount:(NSString *)count
                                 sinceID:(NSString *)sinceID
                                   maxID:(NSString *)maxID
                                trimUser:(NSNumber *)trimUser
                         includeEntities:(NSNumber *)includeEntities
                     includeUserEntities:(NSNumber *)includeUserEntities
                            successBlock:(void(^)(NSArray *statuses))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience method
- (void)getStatusesRetweetsOfMeWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                                     errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Tweets

/*
 GET    statuses/retweets/:id
 
 Returns up to 100 of the first retweets of a given tweet.
 */
- (void)getStatusesRetweetsForID:(NSString *)statusID
                           count:(NSString *)count
                        trimUser:(NSNumber *)trimUser
                    successBlock:(void(^)(NSArray *statuses))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

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

- (void)getStatusesShowID:(NSString *)statusID
                 trimUser:(NSNumber *)trimUser
         includeMyRetweet:(NSNumber *)includeMyRetweet
          includeEntities:(NSNumber *)includeEntities
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	statuses/destroy/:id
 
 Destroys the status specified by the required ID parameter. The authenticating user must be the author of the specified status. Returns the destroyed status if successful.
 */

- (void)postStatusesDestroy:(NSString *)statusID
                   trimUser:(NSNumber *)trimUser
               successBlock:(void(^)(NSDictionary *status))successBlock
                 errorBlock:(void(^)(NSError *error))errorBlock;

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
 */

- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)existingStatusID
                latitude:(NSString *)latitude
               longitude:(NSString *)longitude
                 placeID:(NSString *)placeID
      displayCoordinates:(NSNumber *)displayCoordinates
                trimUser:(NSNumber *)trimUser
            successBlock:(void(^)(NSDictionary *status))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock;

// starting May 28th, 2014
// https://dev.twitter.com/notifications/multiple-media-entities-in-tweets
// https://dev.twitter.com/docs/api/multiple-media-extended-entities
- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)existingStatusID
                mediaIDs:(NSArray *)mediaIDs
                latitude:(NSString *)latitude
               longitude:(NSString *)longitude
                 placeID:(NSString *)placeID
      displayCoordinates:(NSNumber *)displayCoordinates
                trimUser:(NSNumber *)trimUser
            successBlock:(void(^)(NSDictionary *status))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	statuses/retweet/:id
 
 Retweets a tweet. Returns the original tweet with retweet details embedded.
 
 - This method is subject to update limits. A HTTP 403 will be returned if this limit as been hit.
 - Twitter will ignore attempts to perform duplicate retweets.
 - The retweet_count will be current as of when the payload is generated and may not reflect the exact count. It is intended as an approximation.
 
 Returns Tweets (1: the new tweet)
 */

- (void)postStatusRetweetWithID:(NSString *)statusID
                       trimUser:(NSNumber *)trimUser
                   successBlock:(void(^)(NSDictionary *status))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postStatusRetweetWithID:(NSString *)statusID
                   successBlock:(void(^)(NSDictionary *status))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	statuses/update_with_media
 
 Updates the authenticating user's current status and attaches media for upload. In other words, it creates a Tweet with a picture attached.
 
 Unlike POST statuses/update, this method expects raw multipart data. Your POST request's Content-Type should be set to multipart/form-data with the media[] parameter
 
 The Tweet text will be rewritten to include the media URL(s), which will reduce the number of characters allowed in the Tweet text. If the URL(s) cannot be appended without text truncation, the tweet will be rejected and this method will return an HTTP 403 error.
 */

- (void)postStatusUpdate:(NSString *)status
          mediaDataArray:(NSArray *)mediaDataArray // only one media is currently supported, help/configuration.json returns "max_media_per_upload" = 1
       possiblySensitive:(NSNumber *)possiblySensitive
       inReplyToStatusID:(NSString *)inReplyToStatusID
                latitude:(NSString *)latitude
               longitude:(NSString *)longitude
                 placeID:(NSString *)placeID
      displayCoordinates:(NSNumber *)displayCoordinates
     uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
            successBlock:(void(^)(NSDictionary *status))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)existingStatusID
                mediaURL:(NSURL *)mediaURL
                 placeID:(NSString *)placeID
                latitude:(NSString *)latitude
               longitude:(NSString *)longitude
     uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
            successBlock:(void(^)(NSDictionary *status))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    statuses/oembed
 
 Returns information allowing the creation of an embedded representation of a Tweet on third party sites. See the oEmbed specification for information about the response format.
 
 While this endpoint allows a bit of customization for the final appearance of the embedded Tweet, be aware that the appearance of the rendered Tweet may change over time to be consistent with Twitter's Display Requirements. Do not rely on any class or id parameters to stay constant in the returned markup.
 */

- (void)getStatusesOEmbedForStatusID:(NSString *)statusID
                           urlString:(NSString *)urlString
                            maxWidth:(NSString *)maxWidth
                           hideMedia:(NSNumber *)hideMedia
                          hideThread:(NSNumber *)hideThread
                          omitScript:(NSNumber *)omitScript
                               align:(NSString *)align // 'left', 'right', 'center' or 'none' (default)
                             related:(NSString *)related // eg. twitterapi,twittermedia,twitter
                                lang:(NSString *)lang
                        successBlock:(void(^)(NSDictionary *status))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    statuses/retweeters/ids
 
 Returns a collection of up to 100 user IDs belonging to users who have retweeted the tweet specified by the id parameter.
 
 This method offers similar data to GET statuses/retweets/:id and replaces API v1's GET statuses/:id/retweeted_by/ids method.
 */

- (void)getStatusesRetweetersIDsForStatusID:(NSString *)statusID
                                     cursor:(NSString *)cursor
                               successBlock:(void(^)(NSArray *ids, NSString *previousCursor, NSString *nextCursor))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Search

//	GET		search/tweets
- (void)getSearchTweetsWithQuery:(NSString *)q
                         geocode:(NSString *)geoCode // eg. "37.781157,-122.398720,1mi"
                            lang:(NSString *)lang // eg. "eu"
                          locale:(NSString *)locale // eg. "ja"
                      resultType:(NSString *)resultType // eg. "mixed, recent, popular"
                           count:(NSString *)count // eg. "100"
                           until:(NSString *)until // eg. "2012-09-01"
                         sinceID:(NSString *)sinceID // eg. "12345"
                           maxID:(NSString *)maxID // eg. "54321"
                 includeEntities:(NSNumber *)includeEntities
                        callback:(NSString *)callback // eg. "processTweets"
                    successBlock:(void(^)(NSDictionary *searchMetadata, NSArray *statuses))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

// convenience method
- (void)getSearchTweetsWithQuery:(NSString *)q
                    successBlock:(void(^)(NSDictionary *searchMetadata, NSArray *statuses))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Streaming

/*
 POST	statuses/filter
 
 Returns public statuses that match one or more filter predicates. Multiple parameters may be specified which allows most clients to use a single connection to the Streaming API. Both GET and POST requests are supported, but GET requests with too many parameters may cause the request to be rejected for excessive URL length. Use a POST request to avoid long URLs.
 
 The track, follow, and locations fields should be considered to be combined with an OR operator. track=foo&follow=1234 returns Tweets matching "foo" OR created by user 1234.
 
 The default access level allows up to 400 track keywords, 5,000 follow userids and 25 0.1-360 degree location boxes. If you need elevated access to the Streaming API, you should explore our partner providers of Twitter data here: https://dev.twitter.com/programs/twitter-certified-products/products#Certified-Data-Products
 
 At least one predicate parameter (follow, locations, or track) must be specified.
 */

- (id)postStatusesFilterUserIDs:(NSArray *)userIDs
                keywordsToTrack:(NSArray *)keywordsToTrack
          locationBoundingBoxes:(NSArray *)locationBoundingBoxes
                      delimited:(NSNumber *)delimited
                  stallWarnings:(NSNumber *)stallWarnings
                  progressBlock:(void(^)(NSDictionary *tweet))progressBlock
              stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (id)postStatusesFilterKeyword:(NSString *)keyword
                  progressBlock:(void(^)(NSDictionary *tweet))progressBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    statuses/sample
 
 Returns a small random sample of all public statuses. The Tweets returned by the default access level are the same, so if two different clients connect to this endpoint, they will see the same Tweets.
 */

- (id)getStatusesSampleDelimited:(NSNumber *)delimited
                   stallWarnings:(NSNumber *)stallWarnings
                   progressBlock:(void(^)(id response))progressBlock
               stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    statuses/firehose
 
 This endpoint requires special permission to access.
 
 Returns all public statuses. Few applications require this level of access. Creative use of a combination of other resources and various access levels can satisfy nearly every application use case.
 */

- (id)getStatusesFirehoseWithCount:(NSString *)count
                         delimited:(NSNumber *)delimited
                     stallWarnings:(NSNumber *)stallWarnings
                     progressBlock:(void(^)(id response))progressBlock
                 stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    user
 
 Streams messages for a single user, as described in User streams https://dev.twitter.com/docs/streaming-apis/streams/user
 */

- (id)getUserStreamDelimited:(NSNumber *)delimited
               stallWarnings:(NSNumber *)stallWarnings
includeMessagesFromFollowedAccounts:(NSNumber *)includeMessagesFromFollowedAccounts
              includeReplies:(NSNumber *)includeReplies
             keywordsToTrack:(NSArray *)keywordsToTrack
       locationBoundingBoxes:(NSArray *)locationBoundingBoxes
               progressBlock:(void(^)(id response))progressBlock
           stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                  errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    site
 
 Streams messages for a set of users, as described in Site streams https://dev.twitter.com/docs/streaming-apis/streams/site
 */

- (id)getSiteStreamForUserIDs:(NSArray *)userIDs
                    delimited:(NSNumber *)delimited
                stallWarnings:(NSNumber *)stallWarnings
       restrictToUserMessages:(NSNumber *)restrictToUserMessages
               includeReplies:(NSNumber *)includeReplies
                progressBlock:(void(^)(id response))progressBlock
            stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                   errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Direct Messages

/*
 GET	direct_messages
 
 Returns the 20 most recent direct messages sent to the authenticating user. Includes detailed information about the sender and recipient user. You can request up to 200 direct messages per call, up to a maximum of 800 incoming DMs.
 */

- (void)getDirectMessagesSinceID:(NSString *)sinceID
                           maxID:(NSString *)maxID
                           count:(NSString *)count
                 includeEntities:(NSNumber *)includeEntities
                      skipStatus:(NSNumber *)skipStatus
                    successBlock:(void(^)(NSArray *messages))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;
// convenience
- (void)getDirectMessagesSinceID:(NSString *)sinceID
                           count:(NSUInteger)count
                    successBlock:(void(^)(NSArray *messages))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    direct_messages/sent
 
 Returns the 20 most recent direct messages sent by the authenticating user. Includes detailed information about the sender and recipient user. You can request up to 200 direct messages per call, up to a maximum of 800 outgoing DMs.
 */

- (void)getDirectMessagesSinceID:(NSString *)sinceID
                           maxID:(NSString *)maxID
                           count:(NSString *)count
                            page:(NSString *)page
                 includeEntities:(NSNumber *)includeEntities
                    successBlock:(void(^)(NSArray *messages))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    direct_messages/show
 
 Returns a single direct message, specified by an id parameter. Like the /1.1/direct_messages.format request, this method will include the user objects of the sender and recipient.
 */

- (void)getDirectMessagesShowWithID:(NSString *)messageID
                       successBlock:(void(^)(NSArray *statuses))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	direct_messages/destroy
 
 Destroys the direct message specified in the required ID parameter. The authenticating user must be the recipient of the specified direct message.
 */

- (void)postDestroyDirectMessageWithID:(NSString *)messageID
                       includeEntities:(NSNumber *)includeEntities
                          successBlock:(void(^)(NSDictionary *message))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	direct_messages/new
 
 Sends a new direct message to the specified user from the authenticating user. Requires both the user and text parameters and must be a POST. Returns the sent message in the requested format if successful.
 */

- (void)postDirectMessage:(NSString *)status
            forScreenName:(NSString *)screenName
                 orUserID:(NSString *)userID
             successBlock:(void(^)(NSDictionary *message))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Friends & Followers

/*
 GET    friendships/no_retweets/ids
 
 Returns a collection of user_ids that the currently authenticated user does not want to receive retweets from. Use POST friendships/update to set the "no retweets" status for a given user account on behalf of the current user.
 */

- (void)getFriendshipNoRetweetsIDsWithSuccessBlock:(void(^)(NSArray *ids))successBlock
                                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    friends/ids
 Returns Users (*: user IDs for followees)
 
 Returns a cursored collection of user IDs for every user the specified user is following (otherwise known as their "friends").
 
 At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
 
 This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
 */

- (void)getFriendsIDsForUserID:(NSString *)userID
                  orScreenName:(NSString *)screenName
                        cursor:(NSString *)cursor
                         count:(NSString *)count
                  successBlock:(void(^)(NSArray *ids, NSString *previousCursor, NSString *nextCursor))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getFriendsIDsForScreenName:(NSString *)screenName
                      successBlock:(void(^)(NSArray *friends))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    followers/ids
 
 Returns a cursored collection of user IDs for every user following the specified user.
 
 At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 5,000 user IDs and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
 
 This method is especially powerful when used in conjunction with GET users/lookup, a method that allows you to convert user IDs into full user objects in bulk.
 */

- (void)getFollowersIDsForUserID:(NSString *)userID
                    orScreenName:(NSString *)screenName
                          cursor:(NSString *)cursor
                           count:(NSString *)count
                    successBlock:(void(^)(NSArray *followersIDs, NSString *previousCursor, NSString *nextCursor))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getFollowersIDsForScreenName:(NSString *)screenName
                        successBlock:(void(^)(NSArray *followers))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    friendships/lookup
 
 Returns the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none.
 */

- (void)getFriendshipsLookupForScreenNames:(NSArray *)screenNames
                                 orUserIDs:(NSArray *)userIDs
                              successBlock:(void(^)(NSArray *users))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    friendships/incoming
 
 Returns a collection of numeric IDs for every user who has a pending request to follow the authenticating user.
 */

- (void)getFriendshipIncomingWithCursor:(NSString *)cursor
                           successBlock:(void(^)(NSArray *IDs, NSString *previousCursor, NSString *nextCursor))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    friendships/outgoing
 
 Returns a collection of numeric IDs for every protected user for whom the authenticating user has a pending follow request.
 */

- (void)getFriendshipOutgoingWithCursor:(NSString *)cursor
                           successBlock:(void(^)(NSArray *IDs, NSString *previousCursor, NSString *nextCursor))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST   friendships/create
 
 Allows the authenticating users to follow the user specified in the ID parameter.
 
 Returns the befriended user in the requested format when successful. Returns a string describing the failure condition when unsuccessful. If you are already friends with the user a HTTP 403 may be returned, though for performance reasons you may get a 200 OK message even if the friendship already exists.
 
 Actions taken in this method are asynchronous and changes will be eventually consistent.
 */

- (void)postFriendshipsCreateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                              successBlock:(void(^)(NSDictionary *befriendedUser))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postFollow:(NSString *)screenName
      successBlock:(void(^)(NSDictionary *user))successBlock
        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	friendships/destroy
 
 Allows the authenticating user to unfollow the user specified in the ID parameter.
 
 Returns the unfollowed user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
 
 Actions taken in this method are asynchronous and changes will be eventually consistent.
 */

- (void)postFriendshipsDestroyScreenName:(NSString *)screenName
                                orUserID:(NSString *)userID
                            successBlock:(void(^)(NSDictionary *unfollowedUser))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postUnfollow:(NSString *)screenName
        successBlock:(void(^)(NSDictionary *user))successBlock
          errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	friendships/update
 
 Allows one to enable or disable retweets and device notifications from the specified user.
 */

- (void)postFriendshipsUpdateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                 enableDeviceNotifications:(NSNumber *)enableDeviceNotifications
                            enableRetweets:(NSNumber *)enableRetweets
                              successBlock:(void(^)(NSDictionary *user))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postFriendshipsUpdateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                 enableDeviceNotifications:(BOOL)enableDeviceNotifications
                              successBlock:(void(^)(NSDictionary *user))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postFriendshipsUpdateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                            enableRetweets:(BOOL)enableRetweets
                              successBlock:(void(^)(NSDictionary *user))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    friendships/show
 
 Returns detailed information about the relationship between two arbitrary users.
 */

- (void)getFriendshipShowForSourceID:(NSString *)sourceID
                  orSourceScreenName:(NSString *)sourceScreenName
                            targetID:(NSString *)targetID
                  orTargetScreenName:(NSString *)targetScreenName
                        successBlock:(void(^)(id relationship))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    friends/list
 
 Returns a cursored collection of user objects for every user the specified user is following (otherwise known as their "friends").
 
 At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 20 users and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
 */

- (void)getFriendsListForUserID:(NSString *)userID
                   orScreenName:(NSString *)screenName
                         cursor:(NSString *)cursor
                          count:(NSString *)count
                     skipStatus:(NSNumber *)skipStatus
            includeUserEntities:(NSNumber *)includeUserEntities
                   successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getFriendsForScreenName:(NSString *)screenName
                   successBlock:(void(^)(NSArray *friends))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    followers/list
 
 Returns a cursored collection of user objects for users following the specified user.
 
 At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 20 users and multiple "pages" of results can be navigated through using the next_cursor value in subsequent requests. See Using cursors to navigate collections for more information.
 */

- (void)getFollowersListForUserID:(NSString *)userID
                     orScreenName:(NSString *)screenName
                           cursor:(NSString *)cursor
                       skipStatus:(NSNumber *)skipStatus
              includeUserEntities:(NSNumber *)includeUserEntities
                     successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getFollowersForScreenName:(NSString *)screenName
                     successBlock:(void(^)(NSArray *followers))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Users

/*
 GET    account/settings
 
 Returns settings (including current trend, geo and sleep time information) for the authenticating user.
 */

- (void)getAccountSettingsWithSuccessBlock:(void(^)(NSDictionary *settings))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	account/verify_credentials
 
 Returns an HTTP 200 OK response code and a representation of the requesting user if authentication was successful; returns a 401 status code and an error message if not. Use this method to test if supplied user credentials are valid.
 */

- (void)getAccountVerifyCredentialsWithIncludeEntites:(NSNumber *)includeEntities
                                           skipStatus:(NSNumber *)skipStatus
                                         successBlock:(void(^)(NSDictionary *account))successBlock
                                           errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getAccountVerifyCredentialsWithSuccessBlock:(void(^)(NSDictionary *account))successBlock
                                         errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	account/settings
 
 Updates the authenticating user's settings.
 */

- (void)postAccountSettingsWithTrendLocationWOEID:(NSString *)trendLocationWOEID // eg. "1"
                                 sleepTimeEnabled:(NSNumber *)sleepTimeEnabled // eg. @(YES)
                                   startSleepTime:(NSString *)startSleepTime // eg. "13"
                                     endSleepTime:(NSString *)endSleepTime // eg. "13"
                                         timezone:(NSString *)timezone // eg. "Europe/Copenhagen", "Pacific/Tongatapu"
                                         language:(NSString *)language // eg. "it", "en", "es"
                                     successBlock:(void(^)(NSDictionary *settings))successBlock
                                       errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	account/update_delivery_device
 
 Sets which device Twitter delivers updates to for the authenticating user. Sending none as the device parameter will disable SMS updates.
 */

- (void)postAccountUpdateDeliveryDeviceSMS:(BOOL)deliveryDeviceSMS
                           includeEntities:(NSNumber *)includeEntities
                              successBlock:(void(^)(NSDictionary *response))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	account/update_profile
 
 Sets values that users are able to set under the "Account" tab of their settings page. Only the parameters specified will be updated.
 */

- (void)postAccountUpdateProfileWithName:(NSString *)name
                               URLString:(NSString *)URLString
                                location:(NSString *)location
                             description:(NSString *)description
                         includeEntities:(NSNumber *)includeEntities
                              skipStatus:(NSNumber *)skipStatus
                            successBlock:(void(^)(NSDictionary *profile))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postUpdateProfile:(NSDictionary *)profileData
             successBlock:(void(^)(NSDictionary *myInfo))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	account/update_profile_background_image
 
 Updates the authenticating user's profile background image. This method can also be used to enable or disable the profile background image. Although each parameter is marked as optional, at least one of image, tile or use must be provided when making this request.
 */

- (void)postAccountUpdateProfileBackgroundImageWithImage:(NSString *)base64EncodedImage
                                                   title:(NSString *)title
                                         includeEntities:(NSNumber *)includeEntities
                                              skipStatus:(NSNumber *)skipStatus
                                                     use:(NSNumber *)use
                                            successBlock:(void(^)(NSDictionary *profile))successBlock
                                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	account/update_profile_colors
 
 Sets one or more hex values that control the color scheme of the authenticating user's profile page on twitter.com. Each parameter's value must be a valid hexidecimal value, and may be either three or six characters (ex: #fff or #ffffff).
 */

- (void)postAccountUpdateProfileColorsWithBackgroundColor:(NSString *)backgroundColor
                                                linkColor:(NSString *)linkColor
                                       sidebarBorderColor:(NSString *)sidebarBorderColor
                                         sidebarFillColor:(NSString *)sidebarFillColor
                                         profileTextColor:(NSString *)profileTextColor
                                          includeEntities:(NSNumber *)includeEntities
                                               skipStatus:(NSNumber *)skipStatus
                                             successBlock:(void(^)(NSDictionary *profile))successBlock
                                               errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	account/update_profile_image
 
 Updates the authenticating user's profile image. Note that this method expects raw multipart data, not a URL to an image.
 
 This method asynchronously processes the uploaded file before updating the user's profile image URL. You can either update your local cache the next time you request the user's information, or, at least 5 seconds after uploading the image, ask for the updated URL using GET users/show.
 */

- (void)postAccountUpdateProfileImage:(NSString *)base64EncodedImage
                      includeEntities:(NSNumber *)includeEntities
                           skipStatus:(NSNumber *)skipStatus
                         successBlock:(void(^)(NSDictionary *profile))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    blocks/list
 
 Returns a collection of user objects that the authenticating user is blocking.
 */

- (void)getBlocksListWithincludeEntities:(NSNumber *)includeEntities
                              skipStatus:(NSNumber *)skipStatus
                                  cursor:(NSString *)cursor
                            successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    blocks/ids
 
 Returns an array of numeric user ids the authenticating user is blocking.
 */

- (void)getBlocksIDsWithCursor:(NSString *)cursor
                  successBlock:(void(^)(NSArray *ids, NSString *previousCursor, NSString *nextCursor))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	blocks/create
 
 Blocks the specified user from following the authenticating user. In addition the blocked user will not show in the authenticating users mentions or timeline (unless retweeted by another user). If a follow or friend relationship exists it is destroyed.
 */

- (void)postBlocksCreateWithScreenName:(NSString *)screenName
                              orUserID:(NSString *)userID
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(NSDictionary *user))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	blocks/destroy
 
 Un-blocks the user specified in the ID parameter for the authenticating user. Returns the un-blocked user in the requested format when successful. If relationships existed before the block was instated, they will not be restored.
 */

- (void)postBlocksDestroyWithScreenName:(NSString *)screenName
                               orUserID:(NSString *)userID
                        includeEntities:(NSNumber *)includeEntities
                             skipStatus:(NSNumber *)skipStatus
                           successBlock:(void(^)(NSDictionary *user))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock;

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

- (void)getUsersLookupForScreenName:(NSString *)screenName
                           orUserID:(NSString *)userID
                    includeEntities:(NSNumber *)includeEntities
                       successBlock:(void(^)(NSArray *users))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    users/show
 
 Returns a variety of information about the user specified by the required user_id or screen_name parameter. The author's most recent Tweet will be returned inline when possible. GET users/lookup is used to retrieve a bulk collection of user objects.
 
 You must be following a protected user to be able to see their most recent Tweet. If you don't follow a protected user, the users Tweet will be removed. A Tweet will not always be returned in the current_status field.
 */

- (void)getUsersShowForUserID:(NSString *)userID
                 orScreenName:(NSString *)screenName
              includeEntities:(NSNumber *)includeEntities
                 successBlock:(void(^)(NSDictionary *user))successBlock
                   errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getUserInformationFor:(NSString *)screenName
                 successBlock:(void(^)(NSDictionary *user))successBlock
                   errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)profileImageFor:(NSString *)screenName
           successBlock:(void(^)(id image))successBlock
             errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    users/search
 
 Provides a simple, relevance-based search interface to public user accounts on Twitter. Try querying by topical interest, full name, company name, location, or other criteria. Exact match searches are not supported.
 
 Only the first 1,000 matching results are available.
 */

- (void)getUsersSearchQuery:(NSString *)query
                       page:(NSString *)page
                      count:(NSString *)count
            includeEntities:(NSNumber *)includeEntities
               successBlock:(void(^)(NSArray *users))successBlock
                 errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    users/contributees
 
 Returns a collection of users that the specified user can "contribute" to.
 */

- (void)getUsersContributeesWithUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(NSArray *contributees))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    users/contributors
 
 Returns a collection of users who can contribute to the specified account.
 */

- (void)getUsersContributorsWithUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(NSArray *contributors))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST   account/remove_profile_banner
 
 Removes the uploaded profile banner for the authenticating user. Returns HTTP 200 upon success.
 */

- (void)postAccountRemoveProfileBannerWithSuccessBlock:(void(^)(id response))successBlock
                                            errorBlock:(void(^)(NSError *error))errorBlock;

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

- (void)postAccountUpdateProfileBannerWithImage:(NSString *)base64encodedImage
                                          width:(NSString *)width
                                         height:(NSString *)height
                                     offsetLeft:(NSString *)offsetLeft
                                      offsetTop:(NSString *)offsetTop
                                   successBlock:(void(^)(id response))successBlock
                                     errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    users/profile_banner
 
 Returns a map of the available size variations of the specified user's profile banner. If the user has not uploaded a profile banner, a HTTP 404 will be served instead. This method can be used instead of string manipulation on the profile_banner_url returned in user objects as described in User Profile Images and Banners.
 */

- (void)getUsersProfileBannerForUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                          successBlock:(void(^)(NSDictionary *banner))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST   mutes/users/create
 
 Mutes the user specified in the ID parameter for the authenticating user.
 
 Returns the muted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
 
 Actions taken in this method are asynchronous and changes will be eventually consistent.
 */
- (void)postMutesUsersCreateForScreenName:(NSString *)screenName
                                 orUserID:(NSString *)userID
                             successBlock:(void(^)(NSDictionary *user))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST   mutes/users/destroy
 
 Un-mutes the user specified in the ID parameter for the authenticating user.
 
 Returns the unmuted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
 
 Actions taken in this method are asynchronous and changes will be eventually consistent.
 */
- (void)postMutesUsersDestroyForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                              successBlock:(void(^)(NSDictionary *user))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    mutes/users/ids
 
 Returns an array of numeric user ids the authenticating user has muted.
 */
- (void)getMutesUsersIDsWithCursor:(NSString *)cursor
                      successBlock:(void(^)(NSArray *userIDs, NSString *previousCursor, NSString *nextCursor))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    mutes/users/list
 
 Returns an array of user objects the authenticating user has muted.
 */
- (void)getMutesUsersListWithCursor:(NSString *)cursor
                    includeEntities:(NSNumber *)includeEntities
                         skipStatus:(NSNumber *)skipStatus
                       successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Suggested Users

/*
 GET    users/suggestions/:slug
 
 Access the users in a given category of the Twitter suggested user list.
 
 It is recommended that applications cache this data for no more than one hour.
 */

- (void)getUsersSuggestionsForSlug:(NSString *)slug // short name of list or a category, eg. "twitter"
                              lang:(NSString *)lang
                      successBlock:(void(^)(NSString *name, NSString *slug, NSArray *users))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    users/suggestions
 
 Access to Twitter's suggested user list. This returns the list of suggested user categories. The category can be used in GET users/suggestions/:slug to get the users in that category.
 */

- (void)getUsersSuggestionsWithISO6391LanguageCode:(NSString *)ISO6391LanguageCode
                                      successBlock:(void(^)(NSArray *suggestions))successBlock
                                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    users/suggestions/:slug/members
 
 Access the users in a given category of the Twitter suggested user list and return their most recent status if they are not a protected user.
 */

- (void)getUsersSuggestionsForSlugMembers:(NSString *)slug // short name of list or a category, eg. "twitter"
                             successBlock:(void(^)(NSArray *members))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Favorites

/*
 GET    favorites/list
 
 Returns the 20 most recent Tweets favorited by the authenticating or specified user.
 
 If you do not provide either a user_id or screen_name to this method, it will assume you are requesting on behalf of the authenticating user. Specify one or the other for best results.
 */

- (void)getFavoritesListWithUserID:(NSString *)userID
                        screenName:(NSString *)screenName
                             count:(NSString *)count
                           sinceID:(NSString *)sinceID
                             maxID:(NSString *)maxID
                   includeEntities:(NSNumber *)includeEntities
                      successBlock:(void(^)(NSArray *statuses))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getFavoritesListWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	favorites/destroy
 
 Un-favorites the status specified in the ID parameter as the authenticating user. Returns the un-favorited status in the requested format when successful.
 
 This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
 */

- (void)postFavoriteDestroyWithStatusID:(NSString *)statusID
                        includeEntities:(NSNumber *)includeEntities
                           successBlock:(void(^)(NSDictionary *status))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	favorites/create
 
 Favorites the status specified in the ID parameter as the authenticating user. Returns the favorite status when successful.
 
 This process invoked by this method is asynchronous. The immediately returned status may not indicate the resultant favorited status of the tweet. A 200 OK response from this method will indicate whether the intended action was successful or not.
 */

- (void)postFavoriteCreateWithStatusID:(NSString *)statusID
                       includeEntities:(NSNumber *)includeEntities
                          successBlock:(void(^)(NSDictionary *status))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postFavoriteState:(BOOL)favoriteState
              forStatusID:(NSString *)statusID
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Lists

/*
 GET    lists/list
 
 Returns all lists the authenticating or specified user subscribes to, including their own. The user is specified using the user_id or screen_name parameters. If no user is given, the authenticating user is used.
 
 This method used to be GET lists in version 1.0 of the API and has been renamed for consistency with other call.
 
 A maximum of 100 results will be returned by this call. Subscribed lists are returned first, followed by owned lists. This means that if a user subscribes to 90 lists and owns 20 lists, this method returns 90 subscriptions and 10 owned lists. The reverse method returns owned lists first, so with reverse=true, 20 owned lists and 80 subscriptions would be returned. If your goal is to obtain every list a user owns or subscribes to, use GET lists/ownerships and/or GET lists/subscriptions instead.
 */

- (void)getListsSubscribedByUsername:(NSString *)username
                            orUserID:(NSString *)userID
                             reverse:(NSNumber *)reverse
                        successBlock:(void(^)(NSArray *lists))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	lists/statuses
 
 Returns a timeline of tweets authored by members of the specified list. Retweets are included by default. Use the include_rts=false parameter to omit retweets. Embedded Timelines is a great way to embed list timelines on your website.
 */

- (void)getListsStatusesForListID:(NSString *)listID
                          sinceID:(NSString *)sinceID
                            maxID:(NSString *)maxID
                            count:(NSString *)count
                  includeEntities:(NSNumber *)includeEntities
                  includeRetweets:(NSNumber *)includeRetweets
                     successBlock:(void(^)(NSArray *statuses))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock;

- (void)getListsStatusesForSlug:(NSString *)slug
                     screenName:(NSString *)ownerScreenName
                        ownerID:(NSString *)ownerID
                        sinceID:(NSString *)sinceID
                          maxID:(NSString *)maxID
                          count:(NSString *)count
                includeEntities:(NSNumber *)includeEntities
                includeRetweets:(NSNumber *)includeRetweets
                   successBlock:(void(^)(NSArray *statuses))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/members/destroy
 
 Removes the specified member from the list. The authenticated user must be the list's owner to remove members from the list.
 */

- (void)postListsMembersDestroyForListID:(NSString *)listID
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListsMembersDestroyForSlug:(NSString *)slug
                                userID:(NSString *)userID
                            screenName:(NSString *)screenName
                       ownerScreenName:(NSString *)ownerScreenName
                               ownerID:(NSString *)ownerID
                          successBlock:(void(^)())successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    lists/memberships
 
 Returns the lists the specified user has been added to. If user_id or screen_name are not provided the memberships for the authenticating user are returned.
 */

- (void)getListsMembershipsForUserID:(NSString *)userID
                        orScreenName:(NSString *)screenName
                              cursor:(NSString *)cursor
                  filterToOwnedLists:(NSNumber *)filterToOwnedLists // When set to true, t or 1, will return just lists the authenticating user owns, and the user represented by user_id or screen_name is a member of.
                        successBlock:(void(^)(NSArray *lists, NSString *previousCursor, NSString *nextCursor))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	lists/subscribers
 
 Returns the subscribers of the specified list. Private list subscribers will only be shown if the authenticated user owns the specified list.
 */

- (void)getListsSubscribersForSlug:(NSString *)slug
                   ownerScreenName:(NSString *)ownerScreenName
                         orOwnerID:(NSString *)ownerID
                            cursor:(NSString *)cursor
                   includeEntities:(NSNumber *)includeEntities
                        skipStatus:(NSNumber *)skipStatus
                      successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

- (void)getListsSubscribersForListID:(NSString *)listID
                              cursor:(NSString *)cursor
                     includeEntities:(NSNumber *)includeEntities
                          skipStatus:(NSNumber *)skipStatus
                        successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/subscribers/create
 
 Subscribes the authenticated user to the specified list.
 */

- (void)postListSubscribersCreateForListID:(NSString *)listID
                              successBlock:(void(^)(id response))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListSubscribersCreateForSlug:(NSString *)slug
                         ownerScreenName:(NSString *)ownerScreenName
                               orOwnerID:(NSString *)ownerID
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	lists/subscribers/show
 
 Check if the specified user is a subscriber of the specified list. Returns the user if they are subscriber.
 */

- (void)getListsSubscribersShowForListID:(NSString *)listID
                                  userID:(NSString *)userID
                            orScreenName:(NSString *)screenName
                         includeEntities:(NSNumber *)includeEntities
                              skipStatus:(NSNumber *)skipStatus
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

- (void)getListsSubscribersShowForSlug:(NSString *)slug
                       ownerScreenName:(NSString *)ownerScreenName
                             orOwnerID:(NSString *)ownerID
                                userID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(id response))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/subscribers/destroy
 
 Unsubscribes the authenticated user from the specified list.
 */

- (void)postListSubscribersDestroyForListID:(NSString *)listID
                               successBlock:(void(^)(id response))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListSubscribersDestroyForSlug:(NSString *)slug
                          ownerScreenName:(NSString *)ownerScreenName
                                orOwnerID:(NSString *)ownerID
                             successBlock:(void(^)(id response))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/members/create_all
 
 Adds multiple members to a list, by specifying a comma-separated list of member ids or screen names. The authenticated user must own the list to be able to add members to it. Note that lists can't have more than 5,000 members, and you are limited to adding up to 100 members to a list at a time with this method.
 
 Please note that there can be issues with lists that rapidly remove and add memberships. Take care when using these methods such that you are not too rapidly switching between removals and adds on the same list.
 */

- (void)postListsMembersCreateAllForListID:(NSString *)listID
                                   userIDs:(NSArray *)userIDs // array of strings
                             orScreenNames:(NSArray *)screenNames // array of strings
                              successBlock:(void(^)(id response))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListsMembersCreateAllForSlug:(NSString *)slug
                         ownerScreenName:(NSString *)ownerScreenName
                               orOwnerID:(NSString *)ownerID
                                 userIDs:(NSArray *)userIDs // array of strings
                           orScreenNames:(NSArray *)screenNames // array of strings
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	lists/members/show
 
 Check if the specified user is a member of the specified list.
 */

- (void)getListsMembersShowForListID:(NSString *)listID
                              userID:(NSString *)userID
                          screenName:(NSString *)screenName
                     includeEntities:(NSNumber *)includeEntities
                          skipStatus:(NSNumber *)skipStatus
                        successBlock:(void(^)(NSDictionary *user))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

- (void)getListsMembersShowForSlug:(NSString *)slug
                   ownerScreenName:(NSString *)ownerScreenName
                         orOwnerID:(NSString *)ownerID
                            userID:(NSString *)userID
                        screenName:(NSString *)screenName
                   includeEntities:(NSNumber *)includeEntities
                        skipStatus:(NSNumber *)skipStatus
                      successBlock:(void(^)(NSDictionary *user))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    lists/members
 
 Returns the members of the specified list. Private list members will only be shown if the authenticated user owns the specified list.
 */

- (void)getListsMembersForListID:(NSString *)listID
                          cursor:(NSString *)cursor
                 includeEntities:(NSNumber *)includeEntities
                      skipStatus:(NSNumber *)skipStatus
                    successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

- (void)getListsMembersForSlug:(NSString *)slug
               ownerScreenName:(NSString *)screenName
                     orOwnerID:(NSString *)ownerID
                        cursor:(NSString *)cursor
               includeEntities:(NSNumber *)includeEntities
                    skipStatus:(NSNumber *)skipStatus
                  successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/members/create
 
 Creates a new list for the authenticated user. Note that you can't create more than 20 lists per account.
 */

- (void)postListMemberCreateForListID:(NSString *)listID
                               userID:(NSString *)userID
                           screenName:(NSString *)screenName
                         successBlock:(void(^)(id response))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListMemberCreateForSlug:(NSString *)slug
                    ownerScreenName:(NSString *)ownerScreenName
                          orOwnerID:(NSString *)ownerID
                             userID:(NSString *)userID
                         screenName:(NSString *)screenName
                       successBlock:(void(^)(id response))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/destroy
 
 Deletes the specified list. The authenticated user must own the list to be able to destroy it.
 */

- (void)postListsDestroyForListID:(NSString *)listID
                     successBlock:(void(^)(id response))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListsDestroyForSlug:(NSString *)slug
                ownerScreenName:(NSString *)ownerScreenName
                      orOwnerID:(NSString *)ownerID
                   successBlock:(void(^)(id response))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/update
 
 Updates the specified list. The authenticated user must own the list to be able to update it.
 */

- (void)postListsUpdateForListID:(NSString *)listID
                            name:(NSString *)name
                       isPrivate:(BOOL)isPrivate
                     description:(NSString *)description
                    successBlock:(void(^)(id response))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListsUpdateForSlug:(NSString *)slug
               ownerScreenName:(NSString *)ownerScreenName
                     orOwnerID:(NSString *)ownerID
                          name:(NSString *)name
                     isPrivate:(BOOL)isPrivate
                   description:(NSString *)description
                  successBlock:(void(^)(id response))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/create
 
 Creates a new list for the authenticated user. Note that you can't create more than 20 lists per account.
 */

- (void)postListsCreateWithName:(NSString *)name
                      isPrivate:(BOOL)isPrivate
                    description:(NSString *)description
                   successBlock:(void(^)(NSDictionary *list))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	lists/show
 
 Returns the specified list. Private lists will only be shown if the authenticated user owns the specified list.
 */

- (void)getListsShowListID:(NSString *)listID
              successBlock:(void(^)(NSDictionary *list))successBlock
                errorBlock:(void(^)(NSError *error))errorBlock;

- (void)getListsShowListSlug:(NSString *)slug
             ownerScreenName:(NSString *)ownerScreenName
                   orOwnerID:(NSString *)ownerID
                successBlock:(void(^)(NSDictionary *list))successBlock
                  errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET	lists/subscriptions
 
 Obtain a collection of the lists the specified user is subscribed to, 20 lists per page by default. Does not include the user's own lists.
 */

- (void)getListsSubscriptionsForUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                                 count:(NSString *)count
                                cursor:(NSString *)cursor
                          successBlock:(void(^)(NSArray *lists, NSString *previousCursor, NSString *nextCursor))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	lists/members/destroy_all
 
 Removes multiple members from a list, by specifying a comma-separated list of member ids or screen names. The authenticated user must own the list to be able to remove members from it. Note that lists can't have more than 500 members, and you are limited to removing up to 100 members to a list at a time with this method.
 
 Please note that there can be issues with lists that rapidly remove and add memberships. Take care when using these methods such that you are not too rapidly switching between removals and adds on the same list.
 */

- (void)postListsMembersDestroyAllForListID:(NSString *)listID
                                    userIDs:(NSArray *)userIDs // array of strings
                              orScreenNames:(NSArray *)screenNames // array of strings
                               successBlock:(void(^)(id response))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postListsMembersDestroyAllForSlug:(NSString *)slug
                          ownerScreenName:(NSString *)ownerScreenName
                                orOwnerID:(NSString *)ownerID
                                  userIDs:(NSArray *)userIDs // array of strings
                            orScreenNames:(NSArray *)screenNames // array of strings
                             successBlock:(void(^)(id response))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    lists/ownerships
 
 Returns the lists owned by the specified Twitter user. Private lists will only be shown if the authenticated user is also the owner of the lists.
 */

- (void)getListsOwnershipsForUserID:(NSString *)userID
                       orScreenName:(NSString *)screenName
                              count:(NSString *)count
                             cursor:(NSString *)cursor
                       successBlock:(void(^)(NSArray *lists, NSString *previousCursor, NSString *nextCursor))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Saved Searches

/*
 GET    saved_searches/list
 
 Returns the authenticated user's saved search queries.
 */

- (void)getSavedSearchesListWithSuccessBlock:(void(^)(NSArray *savedSearches))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    saved_searches/show/:id
 
 Retrieve the information for the saved search represented by the given id. The authenticating user must be the owner of saved search ID being requested.
 */

- (void)getSavedSearchesShow:(NSString *)savedSearchID
                successBlock:(void(^)(NSDictionary *savedSearch))successBlock
                  errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST   saved_searches/create
 
 Create a new saved search for the authenticated user. A user may only have 25 saved searches.
 */

- (void)postSavedSearchesCreateWithQuery:(NSString *)query
                            successBlock:(void(^)(NSDictionary *createdSearch))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST   saved_searches/destroy/:id
 
 Destroys a saved search for the authenticating user. The authenticating user must be the owner of saved search id being destroyed.
 */

- (void)postSavedSearchesDestroy:(NSString *)savedSearchID
                    successBlock:(void(^)(NSDictionary *destroyedSearch))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Places & Geo

/*
 GET    geo/id/:place_id
 
 Returns all the information about a known place.
 */

- (void)getGeoIDForPlaceID:(NSString *)placeID // A place in the world. These IDs can be retrieved from geo/reverse_geocode.
              successBlock:(void(^)(NSDictionary *place))successBlock
                errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    geo/reverse_geocode
 
 Given a latitude and a longitude, searches for up to 20 places that can be used as a place_id when updating a status.
 
 This request is an informative call and will deliver generalized results about geography.
 */

- (void)getGeoReverseGeocodeWithLatitude:(NSString *)latitude // eg. "37.7821120598956"
                               longitude:(NSString *)longitude // eg. "-122.400612831116"
                                accuracy:(NSString *)accuracy // eg. "5ft"
                             granularity:(NSString *)granularity // eg. "city"
                              maxResults:(NSString *)maxResults // eg. "3"
                                callback:(NSString *)callback
                            successBlock:(void(^)(NSDictionary *query, NSDictionary *result))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getGeoReverseGeocodeWithLatitude:(NSString *)latitude
                               longitude:(NSString *)longitude
                            successBlock:(void(^)(NSArray *places))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    geo/search
 
 Search for places that can be attached to a statuses/update. Given a latitude and a longitude pair, an IP address, or a name, this request will return a list of all the valid places that can be used as the place_id when updating a status.
 
 Conceptually, a query can be made from the user's location, retrieve a list of places, have the user validate the location he or she is at, and then send the ID of this location with a call to POST statuses/update.
 
 This is the recommended method to use find places that can be attached to statuses/update. Unlike GET geo/reverse_geocode which provides raw data access, this endpoint can potentially re-order places with regards to the user who is authenticated. This approach is also preferred for interactive place matching with the user.
 */

- (void)getGeoSearchWithLatitude:(NSString *)latitude // eg. "37.7821120598956"
                       longitude:(NSString *)longitude // eg. "-122.400612831116"
                           query:(NSString *)query // eg. "Twitter HQ"
                       ipAddress:(NSString *)ipAddress // eg. 74.125.19.104
                     granularity:(NSString *)granularity // eg. "city"
                        accuracy:(NSString *)accuracy // eg. "5ft"
                      maxResults:(NSString *)maxResults // eg. "3"
         placeIDContaintedWithin:(NSString *)placeIDContaintedWithin // eg. "247f43d441defc03"
          attributeStreetAddress:(NSString *)attributeStreetAddress // eg. "795 Folsom St"
                        callback:(NSString *)callback // If supplied, the response will use the JSONP format with a callback of the given name.
                    successBlock:(void(^)(NSDictionary *query, NSDictionary *result))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getGeoSearchWithLatitude:(NSString *)latitude
                       longitude:(NSString *)longitude
                    successBlock:(void(^)(NSArray *places))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getGeoSearchWithIPAddress:(NSString *)ipAddress
                     successBlock:(void(^)(NSArray *places))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)getGeoSearchWithQuery:(NSString *)query
                 successBlock:(void(^)(NSArray *places))successBlock
                   errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    geo/similar_places
 
 Locates places near the given coordinates which are similar in name.
 
 Conceptually you would use this method to get a list of known places to choose from first. Then, if the desired place doesn't exist, make a request to POST geo/place to create a new one.
 
 The token contained in the response is the token needed to be able to create a new place.
 */

- (void)getGeoSimilarPlacesToLatitude:(NSString *)latitude // eg. "37.7821120598956"
                            longitude:(NSString *)longitude // eg. "-122.400612831116"
                                 name:(NSString *)name // eg. "Twitter HQ"
              placeIDContaintedWithin:(NSString *)placeIDContaintedWithin // eg. "247f43d441defc03"
               attributeStreetAddress:(NSString *)attributeStreetAddress // eg. "795 Folsom St"
                             callback:(NSString *)callback // If supplied, the response will use the JSONP format with a callback of the given name.
                         successBlock:(void(^)(NSDictionary *query, NSArray *resultPlaces, NSString *resultToken))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

/*
 POST	geo/place
 
 Creates a new place object at the given latitude and longitude.
 
 Before creating a place you need to query GET geo/similar_places with the latitude, longitude and name of the place you wish to create. The query will return an array of places which are similar to the one you wish to create, and a token. If the place you wish to create isn't in the returned array you can use the token with this method to create a new one.
 
 Learn more about Finding Tweets about Places.
 
 WARNING: deprecated since December 2nd, 2013 https://dev.twitter.com/discussions/22452
 */

- (void)postGeoPlaceWithName:(NSString *)name // eg. "Twitter HQ"
     placeIDContaintedWithin:(NSString *)placeIDContaintedWithin // eg. "247f43d441defc03"
           similarPlaceToken:(NSString *)similarPlaceToken // eg. "36179c9bf78835898ebf521c1defd4be"
                    latitude:(NSString *)latitude // eg. "37.7821120598956"
                   longitude:(NSString *)longitude // eg. "-122.400612831116"
      attributeStreetAddress:(NSString *)attributeStreetAddress // eg. "795 Folsom St"
                    callback:(NSString *)callback // If supplied, the response will use the JSONP format with a callback of the given name.
                successBlock:(void(^)(NSDictionary *place))successBlock
                  errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Trends

/*
 GET    trends/place
 
 Returns the top 10 trending topics for a specific WOEID, if trending information is available for it.
 
 The response is an array of "trend" objects that encode the name of the trending topic, the query parameter that can be used to search for the topic on Twitter Search, and the Twitter Search URL.
 
 This information is cached for 5 minutes. Requesting more frequently than that will not return any more data, and will count against your rate limit usage.
 */

- (void)getTrendsForWOEID:(NSString *)WOEID // 'Yahoo! Where On Earth ID', Paris is "615702"
          excludeHashtags:(NSNumber *)excludeHashtags
             successBlock:(void(^)(NSDate *asOf, NSDate *createdAt, NSArray *locations, NSArray *trends))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    trends/available
 
 Returns the locations that Twitter has trending topic information for.
 
 The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in.
 
 A WOEID is a Yahoo! Where On Earth ID.
 */

- (void)getTrendsAvailableWithSuccessBlock:(void(^)(NSArray *locations))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    trends/closest
 
 Returns the locations that Twitter has trending topic information for, closest to a specified location.
 
 The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in.
 
 A WOEID is a Yahoo! Where On Earth ID.
 */

- (void)getTrendsClosestToLatitude:(NSString *)latitude
                         longitude:(NSString *)longitude
                      successBlock:(void(^)(NSArray *locations))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Spam Reporting

/*
 POST   users/report_spam
 
 Report the specified user as a spam account to Twitter. Additionally performs the equivalent of POST blocks/create on behalf of the authenticated user.
 */

- (void)postUsersReportSpamForScreenName:(NSString *)screenName
                                orUserID:(NSString *)userID
                            successBlock:(void(^)(id userProfile))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark OAuth

#pragma mark Help

/*
 GET    help/configuration
 
 Returns the current configuration used by Twitter including twitter.com slugs which are not usernames, maximum photo resolutions, and t.co URL lengths.
 
 It is recommended applications request this endpoint when they are loaded, but no more than once a day.
 */

- (void)getHelpConfigurationWithSuccessBlock:(void(^)(NSDictionary *currentConfiguration))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    help/languages
 
 Returns the list of languages supported by Twitter along with their ISO 639-1 code. The ISO 639-1 code is the two letter value to use if you include lang with any of your requests.
 */

- (void)getHelpLanguagesWithSuccessBlock:(void(^)(NSArray *languages))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    help/privacy
 
 Returns Twitter's Privacy Policy.
 */

- (void)getHelpPrivacyWithSuccessBlock:(void(^)(NSString *privacy))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    help/tos
 
 Returns the Twitter Terms of Service in the requested format. These are not the same as the Developer Rules of the Road.
 */

- (void)getHelpTermsOfServiceWithSuccessBlock:(void(^)(NSString *tos))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

/*
 GET    application/rate_limit_status
 
 Returns the current rate limits for methods belonging to the specified resource families.
 
 Each 1.1 API resource belongs to a "resource family" which is indicated in its method documentation. You can typically determine a method's resource family from the first component of the path after the resource version.
 
 This method responds with a map of methods belonging to the families specified by the resources parameter, the current remaining uses for each of those resources within the current rate limiting window, and its expiration time in epoch time. It also includes a rate_limit_context field that indicates the current access token or application-only authentication context.
 
 You may also issue requests to this method without any parameters to receive a map of all rate limited GET methods. If your application only uses a few of methods, please explicitly provide a resources parameter with the specified resource families you work with.
 
 When using app-only auth, this method's response indicates the app-only auth rate limiting context.
 
 Read more about REST API Rate Limiting in v1.1 and review the limits.
 */

- (void)getRateLimitsForResources:(NSArray *)resources // eg. statuses,friends,trends,help
                     successBlock:(void(^)(NSDictionary *rateLimits))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Tweets

/*
 GET statuses/lookup
 
 Returns fully-hydrated tweet objects for up to 100 tweets per request, as specified by comma-separated values passed to the id parameter. This method is especially useful to get the details (hydrate) a collection of Tweet IDs. GET statuses/show/:id is used to retrieve a single tweet object.
 */

- (void)getStatusesLookupTweetIDs:(NSArray *)tweetIDs
                  includeEntities:(NSNumber *)includeEntities
                         trimUser:(NSNumber *)trimUser
                              map:(NSNumber *)map
                     successBlock:(void(^)(NSArray *tweets))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Media

/*
 POST media/upload.json
 
 https://dev.twitter.com/docs/api/multiple-media-extended-entities
 */

- (void)postMediaUpload:(NSURL *)mediaURL
    uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
           successBlock:(void(^)(NSDictionary *imageDictionary, NSString *mediaID, NSString *size))successBlock
             errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postMediaUploadData:(NSData *)data
                   fileName:(NSString *)fileName
        uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
               successBlock:(void(^)(NSDictionary *imageDictionary, NSString *mediaID, NSString *size))successBlock
                 errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark -
#pragma mark UNDOCUMENTED APIs

// GET activity/about_me.json
- (void)_getActivityAboutMeSinceID:(NSString *)sinceID
                             count:(NSString *)count
                      includeCards:(NSNumber *)includeCards
                      modelVersion:(NSNumber *)modelVersion
                    sendErrorCodes:(NSNumber *)sendErrorCodes
                contributorDetails:(NSNumber *)contributorDetails
                   includeEntities:(NSNumber *)includeEntities
                  includeMyRetweet:(NSNumber *)includeMyRetweet
                      successBlock:(void(^)(NSArray *activities))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

// GET activity/by_friends.json
- (void)_getActivityByFriendsSinceID:(NSString *)sinceID
                               count:(NSString *)count
                  contributorDetails:(NSNumber *)contributorDetails
                        includeCards:(NSNumber *)includeCards
                     includeEntities:(NSNumber *)includeEntities
                   includeMyRetweets:(NSNumber *)includeMyRetweets
                  includeUserEntites:(NSNumber *)includeUserEntites
                       latestResults:(NSNumber *)latestResults
                      sendErrorCodes:(NSNumber *)sendErrorCodes
                        successBlock:(void(^)(NSArray *activities))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

// GET statuses/:id/activity/summary.json
- (void)_getStatusesActivitySummaryForStatusID:(NSString *)statusID
                                  successBlock:(void(^)(NSArray *favoriters, NSArray *repliers, NSArray *retweeters, NSString *favoritersCount, NSString *repliersCount, NSString *retweetersCount))successBlock
                                    errorBlock:(void(^)(NSError *error))errorBlock;

// GET conversation/show.json
- (void)_getConversationShowForStatusID:(NSString *)statusID
                           successBlock:(void(^)(NSArray *statuses))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock;

// GET discover/highlight.json
- (void)_getDiscoverHighlightWithSuccessBlock:(void(^)(NSDictionary *metadata, NSArray *modules))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

// GET discover/universal.json
- (void)_getDiscoverUniversalWithSuccessBlock:(void(^)(NSDictionary *metadata, NSArray *modules))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

// GET statuses/media_timeline.json
- (void)_getMediaTimelineWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock;

// GET users/recommendations.json
- (void)_getUsersRecommendationsWithSuccessBlock:(void(^)(NSArray *recommendations))successBlock
                                      errorBlock:(void(^)(NSError *error))errorBlock;

// GET timeline/home.json
- (void)_getTimelineHomeWithSuccessBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// GET statuses/mentions_timeline.json
- (void)_getStatusesMentionsTimelineWithCount:(NSString *)count
                          contributorsDetails:(NSNumber *)contributorsDetails
                              includeEntities:(NSNumber *)includeEntities
                             includeMyRetweet:(NSNumber *)includeMyRetweet
                                 successBlock:(void(^)(NSArray *statuses))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

// GET trends/available.json
- (void)_getTrendsAvailableWithSuccessBlock:(void(^)(NSArray *places))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock;

// POST users/report_spam
- (void)_postUsersReportSpamForTweetID:(NSString *)tweetID
                              reportAs:(NSString *)reportAs // spam, abused, compromised
                             blockUser:(NSNumber *)blockUser
                          successBlock:(void(^)(id userProfile))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock;

// POST account/generate.json
- (void)_postAccountGenerateWithADC:(NSString *)adc
                discoverableByEmail:(BOOL)discoverableByEmail
                              email:(NSString *)email
                         geoEnabled:(BOOL)geoEnabled
                           language:(NSString *)language
                               name:(NSString *)name
                           password:(NSString *)password
                         screenName:(NSString *)screenName
                      sendErrorCode:(BOOL)sendErrorCode
                           timeZone:(NSString *)timeZone
                       successBlock:(void(^)(id userProfile))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock;

// GET search/typeahead.json
- (void)_getSearchTypeaheadQuery:(NSString *)query
                      resultType:(NSString *)resultType // "all"
                  sendErrorCodes:(NSNumber *)sendErrorCodes
                    successBlock:(void(^)(id results))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock;

// POST direct_messages/new.json
// only the media_id is part of the private API
- (void)_postDirectMessage:(NSString *)status
             forScreenName:(NSString *)screenName
                  orUserID:(NSString *)userID
                   mediaID:(NSString *)mediaID // returned by POST media/upload.json
              successBlock:(void(^)(NSDictionary *message))successBlock
                errorBlock:(void(^)(NSError *error))errorBlock;

// GET conversation/show/:id.json
- (void)_getConversationShowWithTweetID:(NSString *)tweetID
                           successBlock:(void(^)(id results))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock;

@end
