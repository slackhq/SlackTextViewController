//
//  NSError+STTwitter.h
//  STTwitterDemoOSX
//
//  Created by Nicolas Seriot on 19/03/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kSTTwitterTwitterErrorDomain = @"STTwitterTwitterErrorDomain";
static NSString *kSTTwitterRateLimitLimit = @"STTwitterRateLimitLimit";
static NSString *kSTTwitterRateLimitRemaining = @"STTwitterRateLimitRemaining";
static NSString *kSTTwitterRateLimitResetDate = @"STTwitterRateLimitResetDate";

// https://dev.twitter.com/docs/error-codes-responses
typedef NS_ENUM( NSInteger, STTwitterTwitterErrorCode ) {
    STTwitterTwitterErrorCouldNotAuthenticate = 32, // Your call could not be completed as dialed.
    STTwitterTwitterErrorPageDoesNotExist = 34, // Corresponds with an HTTP 404 - the specified resource was not found.
    STTwitterTwitterErrorAccountSuspended = 64, // Corresponds with an HTTP 403 — the access token being used belongs to a suspended user and they can't complete the action you're trying to take
    STTwitterTwitterErrorAPIv1Inactive = 68, // Corresponds to a HTTP request to a retired v1-era URL.
    STTwitterTwitterErrorRateLimitExceeded = 88, // The request limit for this resource has been reached for the current rate limit window.
    STTwitterTwitterErrorInvalidOrExpiredToken = 89, // The access token used in the request is incorrect or has expired. Used in API v1.1
    STTwitterTwitterErrorSSLRequired = 92, // Only SSL connections are allowed in the API, you should update your request to a secure connection. See how to connect using SSL
    STTwitterTwitterErrorOverCapacity = 130, // Corresponds with an HTTP 503 - Twitter is temporarily over capacity.
    STTwitterTwitterErrorInternalError = 131, // Corresponds with an HTTP 500 - An unknown internal error occurred.
    STTwitterTwitterErrorCouldNotAuthenticateYou = 135, // Corresponds with a HTTP 401 - it means that your oauth_timestamp is either ahead or behind our acceptable range
    STTwitterTwitterErrorUnableToFollow = 161, // Corresponds with HTTP 403 — thrown when a user cannot follow another user due to some kind of limit
    STTwitterTwitterErrorNotAuthorizedToSeeStatus = 179, // Corresponds with HTTP 403 — thrown when a Tweet cannot be viewed by the authenticating user, usually due to the tweet's author having protected their tweets.
    STTwitterTwitterErrorDailyStatuUpdateLimitExceeded = 185, // Corresponds with HTTP 403 — thrown when a tweet cannot be posted due to the user having no allowance remaining to post. Despite the text in the error message indicating that this error is only thrown when a daily limit is reached, this error will be thrown whenever a posting limitation has been reached. Posting allowances have roaming windows of time of unspecified duration.
    STTwitterTwitterErrorDuplicatedStatus = 187, // The status text has been Tweeted already by the authenticated account.
    STTwitterTwitterErrorBadAuthenticationData = 215, // Typically sent with 1.1 responses with HTTP code 400. The method requires authentication but it was not presented or was wholly invalid.
    STTwitterTwitterErrorUserMustVerifyLogin = 231, // Returned as a challenge in xAuth when the user has login verification enabled on their account and needs to be directed to twitter.com to generate a temporary password.
    STTwitterTwitterErrorRetiredEndpoint = 251, // Corresponds to a HTTP request to a retired URL.
    STTwitterTwitterErrorApplicationCannotWrite = 261 // Corresponds with HTTP 403 — thrown when the application is restricted from POST, PUT, or DELETE actions. See How to appeal application suspension and other disciplinary actions.
};

@interface NSError (STTwitter)

+ (NSError *)st_twitterErrorFromResponseData:(NSData *)responseData
                             responseHeaders:(NSDictionary *)responseHeaders
                             underlyingError:(NSError *)underlyingError;

@end
