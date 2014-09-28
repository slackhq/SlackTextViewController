//
//  STTwitterRequest.h
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/5/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STTwitterProtocol.h"

/*
 Based on the following documentation
 http://oauth.net/core/1.0/
 https://dev.twitter.com/docs/auth/authorizing-request
 https://dev.twitter.com/docs/auth/implementing-sign-twitter
 https://dev.twitter.com/docs/auth/creating-signature
 https://dev.twitter.com/docs/api/1/post/oauth/request_token
 https://dev.twitter.com/docs/oauth/xauth
 ...
 */

NS_ENUM(NSUInteger, STTwitterOAuthErrorCode) {
    STTwitterOAuthCannotPostAccessTokenRequestWithoutPIN,
    STTwitterOAuthBadCredentialsOrConsumerTokensNotXAuthEnabled
};

@interface STTwitterOAuth : NSObject <STTwitterProtocol>

+ (instancetype)twitterOAuthWithConsumerName:(NSString *)consumerName
                                 consumerKey:(NSString *)consumerKey
                              consumerSecret:(NSString *)consumerSecret;

+ (instancetype)twitterOAuthWithConsumerName:(NSString *)consumerName
                                 consumerKey:(NSString *)consumerKey
                              consumerSecret:(NSString *)consumerSecret
                                  oauthToken:(NSString *)oauthToken
                            oauthTokenSecret:(NSString *)oauthTokenSecret;

+ (instancetype)twitterOAuthWithConsumerName:(NSString *)consumerName
                                 consumerKey:(NSString *)consumerKey
                              consumerSecret:(NSString *)consumerSecret
                                    username:(NSString *)username
                                    password:(NSString *)password;

- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock
authenticateInsteadOfAuthorize:(BOOL)authenticateInsteadOfAuthorize
              forceLogin:(NSNumber *)forceLogin // optional, default @(NO)
              screenName:(NSString *)screenName // optional, default nil
           oauthCallback:(NSString *)oauthCallback
              errorBlock:(void(^)(NSError *error))errorBlock;

// convenience
- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock
           oauthCallback:(NSString *)oauthCallback
              errorBlock:(void(^)(NSError *error))errorBlock;


- (void)postAccessTokenRequestWithPIN:(NSString *)pin
                         successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postXAuthAccessTokenRequestWithUsername:(NSString *)username
                                       password:(NSString *)password
                                   successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                                     errorBlock:(void(^)(NSError *error))errorBlock;

// reverse auth phase 1
- (void)postReverseOAuthTokenRequest:(void(^)(NSString *authenticationHeader))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock;

- (BOOL)canVerifyCredentials;

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock errorBlock:(void(^)(NSError *error))errorBlock;

@end

@interface NSString (STTwitterOAuth)
+ (NSString *)st_random32Characters;
- (NSString *)st_signHmacSHA1WithKey:(NSString *)key;
- (NSDictionary *)st_parametersDictionary;
- (NSString *)st_urlEncodedString;
@end

@interface NSURL (STTwitterOAuth)
- (NSString *)st_normalizedForOauthSignatureString;
- (NSArray *)st_rawGetParametersDictionaries;
@end
