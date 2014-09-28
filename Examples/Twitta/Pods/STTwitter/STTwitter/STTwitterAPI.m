//
//  STTwitterAPI.m
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/18/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import "STTwitterAPI.h"
#import "STTwitterOS.h"
#import "STTwitterOAuth.h"
#import "NSString+STTwitter.h"
#import "STTwitterAppOnly.h"
#import <Accounts/Accounts.h>
#import "STHTTPRequest.h"

NSString *kBaseURLStringAPI_1_1 = @"https://api.twitter.com/1.1";
NSString *kBaseURLStringUpload_1_1 = @"https://upload.twitter.com/1.1";
NSString *kBaseURLStringStream_1_1 = @"https://stream.twitter.com/1.1";
NSString *kBaseURLStringUserStream_1_1 = @"https://userstream.twitter.com/1.1";
NSString *kBaseURLStringSiteStream_1_1 = @"https://sitestream.twitter.com/1.1";

static NSDateFormatter *dateFormatter = nil;

@interface STTwitterAPI ()
@property (nonatomic, retain) NSObject <STTwitterProtocol> *oauth;
@end

@implementation STTwitterAPI

- (id)init {
    self = [super init];
    
    STTwitterAPI * __weak weakSelf = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:ACAccountStoreDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        // account must be considered invalid
        
        if(weakSelf == nil) return;
        
        if([weakSelf.oauth isKindOfClass:[STTwitterOS class]]) {
            weakSelf.oauth = nil;
        }
    }];
    
    return self;
}

+ (instancetype)twitterAPIOSWithAccount:(ACAccount *)account {
    STTwitterAPI *twitter = [[STTwitterAPI alloc] init];
    twitter.oauth = [STTwitterOS twitterAPIOSWithAccount:account];
    return twitter;
}

+ (instancetype)twitterAPIOSWithFirstAccount {
    STTwitterAPI *twitter = [[STTwitterAPI alloc] init];
    twitter.oauth = [STTwitterOS twitterAPIOSWithAccount:nil];
    return twitter;
}

+ (instancetype)twitterAPIWithOAuthConsumerName:(NSString *)consumerName
                                    consumerKey:(NSString *)consumerKey
                                 consumerSecret:(NSString *)consumerSecret
                                       username:(NSString *)username
                                       password:(NSString *)password {
    
    STTwitterAPI *twitter = [[STTwitterAPI alloc] init];
    
    twitter.oauth = [STTwitterOAuth twitterOAuthWithConsumerName:consumerName
                                                     consumerKey:consumerKey
                                                  consumerSecret:consumerSecret
                                                        username:username
                                                        password:password];
    
    return twitter;
}

+ (instancetype)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                consumerSecret:(NSString *)consumerSecret
                                      username:(NSString *)username
                                      password:(NSString *)password {
    
    return [self twitterAPIWithOAuthConsumerName:nil
                                     consumerKey:consumerKey
                                  consumerSecret:consumerSecret
                                        username:username
                                        password:password];
}

+ (instancetype)twitterAPIWithOAuthConsumerName:(NSString *)consumerName
                                    consumerKey:(NSString *)consumerKey
                                 consumerSecret:(NSString *)consumerSecret
                                     oauthToken:(NSString *)oauthToken
                               oauthTokenSecret:(NSString *)oauthTokenSecret {
    
    STTwitterAPI *twitter = [[STTwitterAPI alloc] init];
    
    twitter.oauth = [STTwitterOAuth twitterOAuthWithConsumerName:consumerName
                                                     consumerKey:consumerKey
                                                  consumerSecret:consumerSecret
                                                      oauthToken:oauthToken
                                                oauthTokenSecret:oauthTokenSecret];
    
    return twitter;
}

+ (instancetype)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                consumerSecret:(NSString *)consumerSecret
                                    oauthToken:(NSString *)oauthToken
                              oauthTokenSecret:(NSString *)oauthTokenSecret {
    
    return [self twitterAPIWithOAuthConsumerName:nil
                                     consumerKey:consumerKey
                                  consumerSecret:consumerSecret
                                      oauthToken:oauthToken
                                oauthTokenSecret:oauthTokenSecret];
}

+ (instancetype)twitterAPIWithOAuthConsumerName:(NSString *)consumerName
                                    consumerKey:(NSString *)consumerKey
                                 consumerSecret:(NSString *)consumerSecret {
    
    return [self twitterAPIWithOAuthConsumerName:consumerName
                                     consumerKey:consumerKey
                                  consumerSecret:consumerSecret
                                        username:nil
                                        password:nil];
}

+ (instancetype)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                consumerSecret:(NSString *)consumerSecret {
    
    return [self twitterAPIWithOAuthConsumerName:nil
                                     consumerKey:consumerKey
                                  consumerSecret:consumerSecret];
}

+ (instancetype)twitterAPIAppOnlyWithConsumerName:(NSString *)consumerName
                                      consumerKey:(NSString *)consumerKey
                                   consumerSecret:(NSString *)consumerSecret {
    
    STTwitterAPI *twitter = [[STTwitterAPI alloc] init];
    
    STTwitterAppOnly *appOnly = [STTwitterAppOnly twitterAppOnlyWithConsumerName:consumerName consumerKey:consumerKey consumerSecret:consumerSecret];
    
    twitter.oauth = appOnly;
    
    return twitter;
}

+ (instancetype)twitterAPIAppOnlyWithConsumerKey:(NSString *)consumerKey
                                  consumerSecret:(NSString *)consumerSecret {
    return [self twitterAPIAppOnlyWithConsumerName:nil consumerKey:consumerKey consumerSecret:consumerSecret];
}

- (NSString *)prettyDescription {
    NSMutableString *ms = [[_oauth loginTypeDescription] mutableCopy];
    
    if([_oauth consumerName]) {
        [ms appendFormat:@" (%@)", [_oauth consumerName]];
    }
    
    if([self userName]) {
        [ms appendFormat:@" - %@", [self userName]];
    }
    
    return ms;
}

- (NSDateFormatter *)dateFormatter {
    if(dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:SS'Z'"];
    }
    return dateFormatter;
}

- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock
authenticateInsteadOfAuthorize:(BOOL)authenticateInsteadOfAuthorize
              forceLogin:(NSNumber *)forceLogin screenName:(NSString *)screenName
           oauthCallback:(NSString *)oauthCallback
              errorBlock:(void(^)(NSError *error))errorBlock {
    
    [_oauth postTokenRequest:successBlock
authenticateInsteadOfAuthorize:authenticateInsteadOfAuthorize
                  forceLogin:forceLogin
                  screenName:screenName
               oauthCallback:oauthCallback
                  errorBlock:errorBlock];
}

- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock
           oauthCallback:(NSString *)oauthCallback
              errorBlock:(void(^)(NSError *error))errorBlock {
    [_oauth postTokenRequest:successBlock authenticateInsteadOfAuthorize:NO forceLogin:nil screenName:nil oauthCallback:oauthCallback errorBlock:errorBlock];
}

- (void)postAccessTokenRequestWithPIN:(NSString *)pin
                         successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock {
    [_oauth postAccessTokenRequestWithPIN:pin
                             successBlock:successBlock
                               errorBlock:errorBlock];
}

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock errorBlock:(void(^)(NSError *error))errorBlock {
    
    STTwitterAPI * __weak weakSelf = self;
    
    if([_oauth canVerifyCredentials]) {
        [_oauth verifyCredentialsWithSuccessBlock:^(NSString *username) {
            [weakSelf setUserName:username];
            successBlock(username);
        } errorBlock:^(NSError *error) {
            errorBlock(error);
        }];
    } else {
        [self getAccountVerifyCredentialsWithSuccessBlock:^(NSDictionary *account) {
            NSString *username = [account valueForKey:@"screen_name"];
            [weakSelf setUserName:username];
            successBlock(username);
        } errorBlock:^(NSError *error) {
            errorBlock(error);
        }];
    }
}

- (void)invalidateBearerTokenWithSuccessBlock:(void(^)())successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    if([self.oauth respondsToSelector:@selector(invalidateBearerTokenWithSuccessBlock:errorBlock:)]) {
        [self.oauth invalidateBearerTokenWithSuccessBlock:successBlock errorBlock:errorBlock];
    } else {
        STLog(@"-- self.oauth does not support tokens invalidation");
    }
}

- (NSString *)oauthAccessTokenSecret {
    return [_oauth oauthAccessTokenSecret];
}

- (NSString *)oauthAccessToken {
    return [_oauth oauthAccessToken];
}

- (NSString *)bearerToken {
    if([_oauth respondsToSelector:@selector(bearerToken)]) {
        return [_oauth bearerToken];
    }
    
    return nil;
}

- (NSString *)userName {
    
#if TARGET_OS_IPHONE
#else
    if([_oauth isKindOfClass:[STTwitterOS class]]) {
        STTwitterOS *twitterOS = (STTwitterOS *)_oauth;
        return twitterOS.username;
    }
#endif
    
    return _userName;
}

/**/

#pragma mark Generic methods to GET and POST

- (id)fetchResource:(NSString *)resource
         HTTPMethod:(NSString *)HTTPMethod
      baseURLString:(NSString *)baseURLString
         parameters:(NSDictionary *)params
uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void(^)(id request, id response))downloadProgressBlock
       successBlock:(void(^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id response))successBlock
         errorBlock:(void(^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    return [_oauth fetchResource:resource
                      HTTPMethod:HTTPMethod
                   baseURLString:baseURLString
                      parameters:params
             uploadProgressBlock:uploadProgressBlock
           downloadProgressBlock:downloadProgressBlock
                    successBlock:successBlock
                      errorBlock:errorBlock];
}

- (id)getResource:(NSString *)resource
    baseURLString:(NSString *)baseURLString
       parameters:(NSDictionary *)parameters
//uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void(^)(id json))downloadProgressBlock
     successBlock:(void(^)(NSDictionary *rateLimits, id json))successBlock
       errorBlock:(void(^)(NSError *error))errorBlock {
    
    return [_oauth fetchResource:resource
                      HTTPMethod:@"GET"
                   baseURLString:baseURLString
                      parameters:parameters
             uploadProgressBlock:nil
           downloadProgressBlock:^(id request, id response) {
               if(downloadProgressBlock) downloadProgressBlock(response);
           } successBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id response) {
               if(successBlock) successBlock(responseHeaders, response);
           } errorBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
               if(errorBlock) errorBlock(error);
           }];
}

- (id)postResource:(NSString *)resource
     baseURLString:(NSString *)baseURLString
        parameters:(NSDictionary *)parameters
uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void(^)(id json))downloadProgressBlock
      successBlock:(void(^)(NSDictionary *rateLimits, id response))successBlock
        errorBlock:(void(^)(NSError *error))errorBlock {
    
    return [_oauth fetchResource:resource
                      HTTPMethod:@"POST"
                   baseURLString:baseURLString
                      parameters:parameters
             uploadProgressBlock:uploadProgressBlock
           downloadProgressBlock:^(id request, id response) {
               if(downloadProgressBlock) downloadProgressBlock(response);
           } successBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id response) {
               if(successBlock) successBlock(responseHeaders, response);
           } errorBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
               if(errorBlock) errorBlock(error);
           }];
}

- (void)postResource:(NSString *)resource
       baseURLString:(NSString *)baseURLString
          parameters:(NSDictionary *)parameters
 uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void(^)(id json))downloadProgressBlock
          errorBlock:(void(^)(NSError *error))errorBlock {
    
    [_oauth fetchResource:resource
               HTTPMethod:@"POST"
            baseURLString:baseURLString
               parameters:parameters
      uploadProgressBlock:uploadProgressBlock
    downloadProgressBlock:^(id request, id response) {
        if(downloadProgressBlock) downloadProgressBlock(response);
    } successBlock:nil
               errorBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
                   errorBlock(error);
               }];
}

- (void)getResource:(NSString *)resource
      baseURLString:(NSString *)baseURLString
         parameters:(NSDictionary *)parameters
downloadProgressBlock:(void(^)(id json))downloadProgressBlock
         errorBlock:(void(^)(NSError *error))errorBlock {
    
    [_oauth fetchResource:resource
               HTTPMethod:@"GET"
            baseURLString:baseURLString
               parameters:parameters
      uploadProgressBlock:nil
    downloadProgressBlock:^(id request, id response) {
        if(downloadProgressBlock) downloadProgressBlock(response);
    } successBlock:nil
               errorBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
                   errorBlock(error);
               }];
}

- (void)getAPIResource:(NSString *)resource
            parameters:(NSDictionary *)parameters
         progressBlock:(void(^)(id json))progressBlock
          successBlock:(void(^)(NSDictionary *rateLimits, id json))successBlock
            errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getResource:resource
        baseURLString:kBaseURLStringAPI_1_1
           parameters:parameters
downloadProgressBlock:progressBlock
         successBlock:successBlock
           errorBlock:errorBlock];
}

// convenience
- (void)getAPIResource:(NSString *)resource
            parameters:(NSDictionary *)parameters
          successBlock:(void(^)(NSDictionary *rateLimits, id json))successBlock
            errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getResource:resource
        baseURLString:kBaseURLStringAPI_1_1
           parameters:parameters
downloadProgressBlock:nil
         successBlock:successBlock
           errorBlock:errorBlock];
}

- (void)postAPIResource:(NSString *)resource
             parameters:(NSDictionary *)parameters
    uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
          progressBlock:(void(^)(id json))progressBlock
           successBlock:(void(^)(NSDictionary *rateLimits, id json))successBlock
             errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postResource:resource
         baseURLString:kBaseURLStringAPI_1_1
            parameters:parameters
   uploadProgressBlock:uploadProgressBlock
 downloadProgressBlock:progressBlock
          successBlock:successBlock
            errorBlock:errorBlock];
}

// convenience
- (void)postAPIResource:(NSString *)resource
             parameters:(NSDictionary *)parameters
           successBlock:(void(^)(NSDictionary *rateLimits, id json))successBlock
             errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postResource:resource
         baseURLString:kBaseURLStringAPI_1_1
            parameters:parameters
   uploadProgressBlock:nil
 downloadProgressBlock:nil
          successBlock:successBlock
            errorBlock:errorBlock];
}

/**/

// reverse auth step 1

- (void)postReverseOAuthTokenRequest:(void(^)(NSString *authenticationHeader))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    [_oauth postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
        successBlock(authenticationHeader);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// reverse auth step 2

- (void)postReverseAuthAccessTokenWithAuthenticationHeader:(NSString *)authenticationHeader
                                              successBlock:(void(^)(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName))successBlock
                                                errorBlock:(void(^)(NSError *error))errorBlock {
    
    [_oauth postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader successBlock:^(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName) {
        successBlock(oAuthToken, oAuthTokenSecret, userID, screenName);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

/**/

- (void)profileImageFor:(NSString *)screenName

           successBlock:(void(^)(id image))successBlock

             errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getUserInformationFor:screenName
                   successBlock:^(NSDictionary *response) {
                       NSString *imageURLString = [response objectForKey:@"profile_image_url"];
                       
                       __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:imageURLString];
                       __weak STHTTPRequest *wr = r;
                       
                       r.completionBlock = ^(NSDictionary *headers, NSString *body) {
                           
                           NSData *imageData = wr.responseData;
                           
#if TARGET_OS_IPHONE
                           Class STImageClass = NSClassFromString(@"UIImage");
#else
                           Class STImageClass = NSClassFromString(@"NSImage");
#endif
                           successBlock([[STImageClass alloc] initWithData:imageData]);
                       };
                       
                       r.errorBlock = ^(NSError *error) {
                           errorBlock(error);
                       };

                       [r startAsynchronous];
                   } errorBlock:^(NSError *error) {
                       errorBlock(error);
                   }];
}

#pragma mark Timelines

- (void)getStatusesMentionTimelineWithCount:(NSString *)count
                                    sinceID:(NSString *)sinceID
                                      maxID:(NSString *)maxID
                                   trimUser:(NSNumber *)trimUser
                         contributorDetails:(NSNumber *)contributorDetails
                            includeEntities:(NSNumber *)includeEntities
                               successBlock:(void(^)(NSArray *statuses))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"include_rts"] = @"1"; // "It is recommended you always send include_rts=1 when using this API method" https://dev.twitter.com/docs/api/1.1/get/statuses/mentions_timeline
    if(count) md[@"count"] = count;
    if(sinceID) md[@"since_id"] = sinceID;
    if(maxID) md[@"max_id"] = maxID;
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    if(contributorDetails) md[@"contributor_details"] = [contributorDetails boolValue] ? @"1" : @"0";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"statuses/mentions_timeline.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getMentionsTimelineSinceID:(NSString *)sinceID
                             count:(NSUInteger)count
                      successBlock:(void(^)(NSArray *statuses))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getStatusesMentionTimelineWithCount:[@(count) description]
                                      sinceID:nil
                                        maxID:nil
                                     trimUser:nil
                           contributorDetails:nil
                              includeEntities:nil
                                 successBlock:^(NSArray *statuses) {
                                     successBlock(statuses);
                                 } errorBlock:^(NSError *error) {
                                     errorBlock(error);
                                 }];
}

/**/

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
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(sinceID) md[@"since_id"] = sinceID;
    if(count) md[@"count"] = count;
    if(maxID) md[@"max_id"] = maxID;
    
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    if(excludeReplies) md[@"exclude_replies"] = [excludeReplies boolValue] ? @"1" : @"0";
    if(contributorDetails) md[@"contributor_details"] = [contributorDetails boolValue] ? @"1" : @"0";
    if(includeRetweets) md[@"include_rts"] = [includeRetweets boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"statuses/user_timeline.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getStatusesHomeTimelineWithCount:(NSString *)count
                                 sinceID:(NSString *)sinceID
                                   maxID:(NSString *)maxID
                                trimUser:(NSNumber *)trimUser
                          excludeReplies:(NSNumber *)excludeReplies
                      contributorDetails:(NSNumber *)contributorDetails
                         includeEntities:(NSNumber *)includeEntities
                            successBlock:(void(^)(NSArray *statuses))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(count) md[@"count"] = count;
    if(sinceID) md[@"since_id"] = sinceID;
    if(maxID) md[@"max_id"] = maxID;
    
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    if(excludeReplies) md[@"exclude_replies"] = [excludeReplies boolValue] ? @"1" : @"0";
    if(contributorDetails) md[@"contributor_details"] = [contributorDetails boolValue] ? @"1" : @"0";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"statuses/home_timeline.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

/*
 - (void)getTimeline:(NSString *)timeline
 withParameters:(NSDictionary *)params
 sinceID:(NSString *)optionalSinceID
 maxID:(NSString *)optionalMaxID
 count:(NSUInteger)optionalCount
 successBlock:(void(^)(NSArray *statuses))successBlock
 errorBlock:(void(^)(NSError *error))errorBlock {
 
 NSMutableDictionary *mparams = [params mutableCopy];
 if (!mparams)
 mparams = [NSMutableDictionary new];
 
 if (optionalSinceID) mparams[@"since_id"] = optionalSinceID;
 if (optionalCount != NSNotFound) mparams[@"count"] = [@(optionalCount) stringValue];
 if (optionalMaxID) {
 NSDecimalNumber* maxID = [NSDecimalNumber decimalNumberWithString:optionalMaxID];
 
 if ( [maxID longLongValue] > 0 ) {
 mparams[@"max_id"] = optionalMaxID;
 }
 }
 
 __block NSMutableArray *statuses = [NSMutableArray new];
 __block void (^requestHandler)(id response) = nil;
 __block int count = 0;
 requestHandler = [[^(id response) {
 if ([response isKindOfClass:[NSArray class]] && [response count] > 0)
 [statuses addObjectsFromArray:response];
 
 //Only send another request if we got close to the requested limit, up to a maximum of 4 api calls
 if (count++ == 0 || (count <= 4 && [response count] >= (optionalCount - 5))) {
 //Set the max_id so that we don't get statuses we've already received
 NSString *lastID = [[statuses lastObject] objectForKey:@"id_str"];
 if (lastID) {
 NSDecimalNumber* lastIDNumber = [NSDecimalNumber decimalNumberWithString:lastID];
 
 if ([lastIDNumber longLongValue] > 0) {
 mparams[@"max_id"] = [@([lastIDNumber longLongValue] - 1) stringValue];
 }
 }
 
 [self getAPIResource:timeline parameters:mparams
 successBlock:requestHandler
 errorBlock:errorBlock];
 } else {
 successBlock(removeNull(statuses));
 [mparams release];
 [statuses release];
 }
 } copy] autorelease];
 
 //Send the first request
 requestHandler(nil);
 }
 */

- (void)getUserTimelineWithScreenName:(NSString *)screenName
                              sinceID:(NSString *)sinceID
                                maxID:(NSString *)maxID
                                count:(NSUInteger)count
                         successBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getStatusesUserTimelineForUserID:nil
                                screenName:screenName
                                   sinceID:sinceID
                                     count:(count == NSNotFound ? nil : [@(count) description])
                                     maxID:maxID
                                  trimUser:nil
                            excludeReplies:nil
                        contributorDetails:nil
                           includeRetweets:nil
                              successBlock:^(NSArray *statuses) {
                                  successBlock(statuses);
                              } errorBlock:^(NSError *error) {
                                  errorBlock(error);
                              }];
}

- (void)getUserTimelineWithScreenName:(NSString *)screenName
                                count:(NSUInteger)count
                         successBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getUserTimelineWithScreenName:screenName
                                sinceID:nil
                                  maxID:nil
                                  count:count
                           successBlock:successBlock
                             errorBlock:errorBlock];
}

- (void)getUserTimelineWithScreenName:(NSString *)screenName
                         successBlock:(void(^)(NSArray *statuses))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getUserTimelineWithScreenName:screenName count:20 successBlock:successBlock errorBlock:errorBlock];
}

- (void)getHomeTimelineSinceID:(NSString *)sinceID
                         count:(NSUInteger)count
                  successBlock:(void(^)(NSArray *statuses))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *countString = count > 0 ? [@(count) description] : nil;
    
    [self getStatusesHomeTimelineWithCount:countString
                                   sinceID:sinceID
                                     maxID:nil
                                  trimUser:nil
                            excludeReplies:nil
                        contributorDetails:nil
                           includeEntities:nil
                              successBlock:^(NSArray *statuses) {
                                  successBlock(statuses);
                              } errorBlock:^(NSError *error) {
                                  errorBlock(error);
                              }];
}

- (void)getStatusesRetweetsOfMeWithCount:(NSString *)count
                                 sinceID:(NSString *)sinceID
                                   maxID:(NSString *)maxID
                                trimUser:(NSNumber *)trimUser
                         includeEntities:(NSNumber *)includeEntities
                     includeUserEntities:(NSNumber *)includeUserEntities
                            successBlock:(void(^)(NSArray *statuses))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(count) md[@"count"] = count;
    if(sinceID) md[@"since_id"] = sinceID;
    if(maxID) md[@"max_id"] = maxID;
    
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(includeUserEntities) md[@"include_user_entities"] = [includeUserEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"statuses/retweets_of_me.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// convenience method, shorter
- (void)getStatusesRetweetsOfMeWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                                     errorBlock:(void(^)(NSError *error))errorBlock {
    [self getStatusesRetweetsOfMeWithCount:nil
                                   sinceID:nil
                                     maxID:nil
                                  trimUser:nil
                           includeEntities:nil
                       includeUserEntities:nil
                              successBlock:^(NSArray *statuses) {
                                  successBlock(statuses);
                              } errorBlock:^(NSError *error) {
                                  errorBlock(error);
                              }];
}

#pragma mark Tweets

- (void)getStatusesRetweetsForID:(NSString *)statusID
                           count:(NSString *)count
                        trimUser:(NSNumber *)trimUser
                    successBlock:(void(^)(NSArray *statuses))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSString *resource = [NSString stringWithFormat:@"statuses/retweets/%@.json", statusID];
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(count) md[@"count"] = count;
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    
    [self getAPIResource:resource parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getStatusesShowID:(NSString *)statusID
                 trimUser:(NSNumber *)trimUser
         includeMyRetweet:(NSNumber *)includeMyRetweet
          includeEntities:(NSNumber *)includeEntities
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    md[@"id"] = statusID;
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    if(includeMyRetweet) md[@"include_my_retweet"] = [includeMyRetweet boolValue] ? @"1" : @"0";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"statuses/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postStatusesDestroy:(NSString *)statusID
                   trimUser:(NSNumber *)trimUser
               successBlock:(void(^)(NSDictionary *status))successBlock
                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSString *resource = [NSString stringWithFormat:@"statuses/destroy/%@.json", statusID];
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"id"] = statusID;
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    
    [self postAPIResource:resource parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)existingStatusID
                mediaIDs:(NSArray *)mediaIDs
                latitude:(NSString *)latitude
               longitude:(NSString *)longitude
                 placeID:(NSString *)placeID // wins over lat/lon
      displayCoordinates:(NSNumber *)displayCoordinates
                trimUser:(NSNumber *)trimUser
            successBlock:(void(^)(NSDictionary *status))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock {
    
    if([mediaIDs count] == 0 && status == nil) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:STTwitterAPICannotPostEmptyStatus userInfo:@{NSLocalizedDescriptionKey : @"cannot post empty status"}];
        errorBlock(error);
        return;
    }
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithObject:status forKey:@"status"];
    
    if([mediaIDs count] > 0) {
        NSString *mediaIDsString = [mediaIDs componentsJoinedByString:@","];
        md[@"media_ids"] = mediaIDsString;
    }
    
    if(existingStatusID) {
        md[@"in_reply_to_status_id"] = existingStatusID;
    }
    
    if(placeID) {
        md[@"place_id"] = placeID;
        md[@"display_coordinates"] = @"true";
    } else if(latitude && longitude) {
        md[@"lat"] = latitude;
        md[@"lon"] = longitude;
        md[@"display_coordinates"] = @"true";
    }
    
    [self postAPIResource:@"statuses/update.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)existingStatusID
                latitude:(NSString *)latitude
               longitude:(NSString *)longitude
                 placeID:(NSString *)placeID // wins over lat/lon
      displayCoordinates:(NSNumber *)displayCoordinates
                trimUser:(NSNumber *)trimUser
            successBlock:(void(^)(NSDictionary *status))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postStatusUpdate:status
         inReplyToStatusID:existingStatusID
                  mediaIDs:nil
                  latitude:latitude
                 longitude:longitude
                   placeID:placeID
        displayCoordinates:displayCoordinates
                  trimUser:trimUser
              successBlock:successBlock
                errorBlock:errorBlock];
}

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
              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(status);
    NSAssert([mediaDataArray count] > 0, @"media data array must not be empty");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"status"] = status;
    if(possiblySensitive) md[@"possibly_sensitive"] = [possiblySensitive boolValue] ? @"1" : @"0";
    if(displayCoordinates) md[@"display_coordinates"] = [displayCoordinates boolValue] ? @"1" : @"0";
    if(inReplyToStatusID) md[@"in_reply_to_status_id"] = inReplyToStatusID;
    if(latitude) md[@"lat"] = latitude;
    if(longitude) md[@"long"] = longitude;
    if(placeID) md[@"place_id"] = placeID;
    md[@"media[]"] = [mediaDataArray objectAtIndex:0];
    md[kSTPOSTDataKey] = @"media[]";
    
    [self postResource:@"statuses/update_with_media.json"
         baseURLString:kBaseURLStringAPI_1_1
            parameters:md
   uploadProgressBlock:uploadProgressBlock
 downloadProgressBlock:nil
          successBlock:^(NSDictionary *rateLimits, id response) {
              successBlock(response);
          } errorBlock:errorBlock];
}

- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)existingStatusID
                mediaURL:(NSURL *)mediaURL
                 placeID:(NSString *)placeID
                latitude:(NSString *)latitude
               longitude:(NSString *)longitude
     uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
            successBlock:(void(^)(NSDictionary *status))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSData *data = [NSData dataWithContentsOfURL:mediaURL];
    
    if(data == nil) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:STTwitterAPIMediaDataIsEmpty userInfo:@{NSLocalizedDescriptionKey : @"data is nil"}];
        errorBlock(error);
        return;
    }
    
    [self postStatusUpdate:status
            mediaDataArray:@[data]
         possiblySensitive:nil
         inReplyToStatusID:existingStatusID
                  latitude:latitude
                 longitude:longitude
                   placeID:placeID
        displayCoordinates:@(YES)
       uploadProgressBlock:uploadProgressBlock
              successBlock:^(NSDictionary *status) {
                  successBlock(status);
              } errorBlock:^(NSError *error) {
                  errorBlock(error);
              }];
}

// GET statuses/oembed

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
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    NSParameterAssert(urlString);
    
#if DEBUG
    if(align) {
        NSArray *validValues = @[@"left", @"right", @"center", @"none"];
        NSAssert([validValues containsObject: align], @"");
    }
#endif
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"id"] = statusID;
    md[@"url"] = urlString;
    
    if(maxWidth) md[@"maxwidth"] = maxWidth;
    
    if(hideMedia) md[@"hide_media"] = [hideMedia boolValue] ? @"1" : @"0";
    if(hideThread) md[@"hide_thread"] = [hideThread boolValue] ? @"1" : @"0";
    if(omitScript) md[@"omit_script"] = [omitScript boolValue] ? @"1" : @"0";
    
    if(align) md[@"align"] = align;
    if(related) md[@"related"] = related;
    if(lang) md[@"lang"] = lang;
    
    [self getAPIResource:@"statuses/oembed.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	statuses/retweet/:id
- (void)postStatusRetweetWithID:(NSString *)statusID
                       trimUser:(NSNumber *)trimUser
                   successBlock:(void(^)(NSDictionary *status))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    
    NSString *resource = [NSString stringWithFormat:@"statuses/retweet/%@.json", statusID];
    
    [self postAPIResource:resource parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postStatusRetweetWithID:(NSString *)statusID
                   successBlock:(void(^)(NSDictionary *status))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postStatusRetweetWithID:statusID
                         trimUser:nil
                     successBlock:^(NSDictionary *status) {
                         successBlock(status);
                     } errorBlock:^(NSError *error) {
                         errorBlock(error);
                     }];
}

- (void)getStatusesRetweetersIDsForStatusID:(NSString *)statusID
                                     cursor:(NSString *)cursor
                               successBlock:(void(^)(NSArray *ids, NSString *previousCursor, NSString *nextCursor))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    md[@"id"] = statusID;
    if(cursor) md[@"cursor"] = cursor;
    md[@"stringify_ids"] = @"1";
    
    [self getAPIResource:@"statuses/retweeters/ids.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        NSArray *ids = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            previousCursor = response[@"previous_cursor_str"];
            nextCursor = response[@"next_cursor_str"];
            ids = response[@"ids"];
        }
        
        successBlock(ids, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
    
}

- (void)getListsSubscriptionsForUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                                 count:(NSString *)count
                                cursor:(NSString *)cursor
                          successBlock:(void(^)(NSArray *lists, NSString *previousCursor, NSString *nextCursor))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"missing userID or screenName");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(userID) {
        md[@"user_id"] = userID;
    } else if (screenName) {
        md[@"screen_name"] = screenName;
    }
    
    if(count) md[@"count"] = count;
    if(cursor) md[@"cursor"] = cursor;
    
    [self getAPIResource:@"lists/subscriptions.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSArray *lists = [response valueForKey:@"lists"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        successBlock(lists, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

//  GET     lists/ownerships

- (void)getListsOwnershipsForUserID:(NSString *)userID
                       orScreenName:(NSString *)screenName
                              count:(NSString *)count
                             cursor:(NSString *)cursor
                       successBlock:(void(^)(NSArray *lists, NSString *previousCursor, NSString *nextCursor))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"missing userID or screenName");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(userID) {
        md[@"user_id"] = userID;
    } else if (screenName) {
        md[@"screen_name"] = screenName;
    }
    
    if(count) md[@"count"] = count;
    if(cursor) md[@"cursor"] = cursor;
    
    [self getAPIResource:@"lists/ownerships.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSArray *lists = [response valueForKey:@"lists"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        successBlock(lists, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Search

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
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    NSParameterAssert(q);
    
    if(geoCode) md[@"geocode"] = geoCode;
    if(lang) md[@"lang"] = lang;
    if(locale) md[@"locale"] = locale;
    if(resultType) md[@"result_type"] = resultType;
    if(count) md[@"count"] = count;
    if(until) md[@"until"] = until;
    if(sinceID) md[@"since_id"] = sinceID;
    if(maxID) md[@"max_id"] = maxID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(callback) md[@"callback"] = callback;
    
    md[@"q"] = [q st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self getAPIResource:@"search/tweets.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSDictionary *searchMetadata = [response valueForKey:@"search_metadata"];
        NSArray *statuses = [response valueForKey:@"statuses"];
        
        successBlock(searchMetadata, statuses);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getSearchTweetsWithQuery:(NSString *)q
                    successBlock:(void(^)(NSDictionary *searchMetadata, NSArray *statuses))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getSearchTweetsWithQuery:q
                           geocode:nil
                              lang:nil
                            locale:nil
                        resultType:nil
                             count:nil
                             until:nil
                           sinceID:nil
                             maxID:nil
                   includeEntities:@(YES)
                          callback:nil
                      successBlock:^(NSDictionary *searchMetadata, NSArray *statuses) {
                          successBlock(searchMetadata, statuses);
                      } errorBlock:^(NSError *error) {
                          errorBlock(error);
                      }];
}

#pragma mark Streaming

+ (NSDictionary *)stallWarningDictionaryFromJSON:(NSString *)json {
    if([json isKindOfClass:[NSDictionary class]]) return nil;
    return [json valueForKey:@"warning"];
}

// POST statuses/filter

- (id)postStatusesFilterUserIDs:(NSArray *)userIDs
                keywordsToTrack:(NSArray *)keywordsToTrack
          locationBoundingBoxes:(NSArray *)locationBoundingBoxes
                      delimited:(NSNumber *)delimited
                  stallWarnings:(NSNumber *)stallWarnings
                  progressBlock:(void(^)(NSDictionary *tweet))progressBlock
              stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *follow = [userIDs componentsJoinedByString:@","];
    NSString *keywords = [keywordsToTrack componentsJoinedByString:@","];
    NSString *locations = [locationBoundingBoxes componentsJoinedByString:@","];
    
    NSAssert(([follow length] || [keywords length] || [locations length]), @"At least one predicate parameter (follow, locations, or track) must be specified.");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(delimited) md[@"delimited"] = [delimited boolValue] ? @"1" : @"0";
    if(stallWarnings) md[@"stall_warnings"] = [stallWarnings boolValue] ? @"1" : @"0";
    
    if([follow length]) md[@"follow"] = follow;
    if([keywords length]) md[@"track"] = keywords;
    if([locations length]) md[@"locations"] = locations;
    
    return [self postResource:@"statuses/filter.json"
                baseURLString:kBaseURLStringStream_1_1
                   parameters:md
          uploadProgressBlock:nil
        downloadProgressBlock:^(id json) {
            
            NSDictionary *stallWarning = [[self class] stallWarningDictionaryFromJSON:json];
            if(stallWarning && stallWarningBlock) {
                stallWarningBlock([stallWarning valueForKey:@"code"],
                                  [stallWarning valueForKey:@"message"],
                                  [[stallWarning valueForKey:@"percent_full"] integerValue]);
            } else {
                progressBlock(json);
            }
            
        } successBlock:^(NSDictionary *rateLimits, id response) {
            progressBlock(response);
        } errorBlock:^(NSError *error) {
            errorBlock(error);
        }];
}

// convenience
- (id)postStatusesFilterKeyword:(NSString *)keyword
                  progressBlock:(void(^)(NSDictionary *tweet))progressBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(keyword);
    
    return [self postStatusesFilterUserIDs:nil
                           keywordsToTrack:@[keyword]
                     locationBoundingBoxes:nil
                                 delimited:nil
                             stallWarnings:nil
                             progressBlock:progressBlock
                         stallWarningBlock:nil
                                errorBlock:errorBlock];
}

// GET statuses/sample
- (id)getStatusesSampleDelimited:(NSNumber *)delimited
                   stallWarnings:(NSNumber *)stallWarnings
                   progressBlock:(void(^)(id response))progressBlock
               stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(delimited) md[@"delimited"] = [delimited boolValue] ? @"1" : @"0";
    if(stallWarnings) md[@"stall_warnings"] = [stallWarnings boolValue] ? @"1" : @"0";
    
    return [self getResource:@"statuses/sample.json"
               baseURLString:kBaseURLStringStream_1_1
                  parameters:md
       downloadProgressBlock:^(id json) {
           
           NSDictionary *stallWarning = [[self class] stallWarningDictionaryFromJSON:json];
           if(stallWarning && stallWarningBlock) {
               stallWarningBlock([stallWarning valueForKey:@"code"],
                                 [stallWarning valueForKey:@"message"],
                                 [[stallWarning valueForKey:@"percent_full"] integerValue]);
           } else {
               progressBlock(json);
           }
           
       } successBlock:^(NSDictionary *rateLimits, id json) {
           // reaching successBlock for a stream request is an error
           errorBlock(json);
       } errorBlock:^(NSError *error) {
           errorBlock(error);
       }];
}

// GET statuses/firehose
- (id)getStatusesFirehoseWithCount:(NSString *)count
                         delimited:(NSNumber *)delimited
                     stallWarnings:(NSNumber *)stallWarnings
                     progressBlock:(void(^)(id response))progressBlock
                 stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(count) md[@"count"] = count;
    if(delimited) md[@"delimited"] = [delimited boolValue] ? @"1" : @"0";
    if(stallWarnings) md[@"stall_warnings"] = [stallWarnings boolValue] ? @"1" : @"0";
    
    return [self getResource:@"statuses/firehose.json"
               baseURLString:kBaseURLStringStream_1_1
                  parameters:md
       downloadProgressBlock:^(id json) {
           
           NSDictionary *stallWarning = [[self class] stallWarningDictionaryFromJSON:json];
           if(stallWarning && stallWarningBlock) {
               stallWarningBlock([stallWarning valueForKey:@"code"],
                                 [stallWarning valueForKey:@"message"],
                                 [[stallWarning valueForKey:@"percent_full"] integerValue]);
           } else {
               progressBlock(json);
           }
           
       } successBlock:^(NSDictionary *rateLimits, id json) {
           progressBlock(json);
       } errorBlock:^(NSError *error) {
           errorBlock(error);
       }];
}

// GET user
- (id)getUserStreamDelimited:(NSNumber *)delimited
               stallWarnings:(NSNumber *)stallWarnings
includeMessagesFromFollowedAccounts:(NSNumber *)includeMessagesFromFollowedAccounts
              includeReplies:(NSNumber *)includeReplies
             keywordsToTrack:(NSArray *)keywordsToTrack
       locationBoundingBoxes:(NSArray *)locationBoundingBoxes
               progressBlock:(void(^)(id response))progressBlock
           stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                  errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"stringify_friend_ids"] = @"1";
    if(delimited) md[@"delimited"] = [delimited boolValue] ? @"1" : @"0";
    if(stallWarnings) md[@"stall_warnings"] = [stallWarnings boolValue] ? @"1" : @"0";
    if(includeMessagesFromFollowedAccounts) md[@"with"] = @"user"; // default is 'followings'
    if(includeReplies && [includeReplies boolValue]) md[@"replies"] = @"all";
    
    NSString *keywords = [keywordsToTrack componentsJoinedByString:@","];
    NSString *locations = [locationBoundingBoxes componentsJoinedByString:@","];
    
    if([keywords length]) md[@"keywords"] = keywords;
    if([locations length]) md[@"locations"] = locations;
    
    return [self getResource:@"user.json"
               baseURLString:kBaseURLStringUserStream_1_1
                  parameters:md
       downloadProgressBlock:^(id json) {
           
           NSDictionary *stallWarning = [[self class] stallWarningDictionaryFromJSON:json];
           if(stallWarning && stallWarningBlock) {
               stallWarningBlock([stallWarning valueForKey:@"code"],
                                 [stallWarning valueForKey:@"message"],
                                 [[stallWarning valueForKey:@"percent_full"] integerValue]);
           } else {
               progressBlock(json);
           }
           
       } successBlock:^(NSDictionary *rateLimits, id json) {
           progressBlock(json);
       } errorBlock:^(NSError *error) {
           errorBlock(error);
       }];
}

// GET site
- (id)getSiteStreamForUserIDs:(NSArray *)userIDs
                    delimited:(NSNumber *)delimited
                stallWarnings:(NSNumber *)stallWarnings
       restrictToUserMessages:(NSNumber *)restrictToUserMessages
               includeReplies:(NSNumber *)includeReplies
                progressBlock:(void(^)(id response))progressBlock
            stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"stringify_friend_ids"] = @"1";
    if(delimited) md[@"delimited"] = [delimited boolValue] ? @"1" : @"0";
    if(stallWarnings) md[@"stall_warnings"] = [stallWarnings boolValue] ? @"1" : @"0";
    if(restrictToUserMessages) md[@"with"] = @"user"; // default is 'followings'
    if(includeReplies && [includeReplies boolValue]) md[@"replies"] = @"all";
    
    NSString *follow = [userIDs componentsJoinedByString:@","];
    if([follow length]) md[@"follow"] = follow;
    
    return [self getResource:@"site.json"
               baseURLString:kBaseURLStringSiteStream_1_1
                  parameters:md
       downloadProgressBlock:^(id json) {
           
           NSDictionary *stallWarning = [[self class] stallWarningDictionaryFromJSON:json];
           if(stallWarning && stallWarningBlock) {
               stallWarningBlock([stallWarning valueForKey:@"code"],
                                 [stallWarning valueForKey:@"message"],
                                 [[stallWarning valueForKey:@"percent_full"] integerValue]);
           } else {
               progressBlock(json);
           }
           
       } successBlock:^(NSDictionary *rateLimits, id json) {
           progressBlock(json);
       } errorBlock:^(NSError *error) {
           errorBlock(error);
       }];
}

#pragma mark Direct Messages

- (void)getDirectMessagesSinceID:(NSString *)sinceID
                           maxID:(NSString *)maxID
                           count:(NSString *)count
                 includeEntities:(NSNumber *)includeEntities
                      skipStatus:(NSNumber *)skipStatus
                    successBlock:(void(^)(NSArray *messages))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(sinceID) [md setObject:sinceID forKey:@"since_id"];
    if(maxID) [md setObject:maxID forKey:@"max_id"];
    if(count) [md setObject:count forKey:@"count"];
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"direct_messages.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// convenience
- (void)getDirectMessagesSinceID:(NSString *)sinceID
                           count:(NSUInteger)count
                    successBlock:(void(^)(NSArray *messages))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *countString = count > 0 ? [@(count) description] : nil;
    
    [self getDirectMessagesSinceID:sinceID
                             maxID:nil
                             count:countString
                   includeEntities:nil
                        skipStatus:nil
                      successBlock:^(NSArray *statuses) {
                          successBlock(statuses);
                      } errorBlock:^(NSError *error) {
                          errorBlock(error);
                      }];
}

- (void)getDirectMessagesSinceID:(NSString *)sinceID
                           maxID:(NSString *)maxID
                           count:(NSString *)count
                            page:(NSString *)page
                 includeEntities:(NSNumber *)includeEntities
                    successBlock:(void(^)(NSArray *messages))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(sinceID) [md setObject:sinceID forKey:@"since_id"];
    if(maxID) [md setObject:maxID forKey:@"max_id"];
    if(count) [md setObject:count forKey:@"count"];
    if(page) [md setObject:page forKey:@"page"];
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"direct_messages/sent.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getDirectMessagesShowWithID:(NSString *)messageID
                       successBlock:(void(^)(NSArray *messages))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSDictionary *d = @{@"id" : messageID};
    
    [self getAPIResource:@"direct_messages/show.json" parameters:d successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
    
}

- (void)postDestroyDirectMessageWithID:(NSString *)messageID
                       includeEntities:(NSNumber *)includeEntities
                          successBlock:(void(^)(NSDictionary *message))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"id"] = messageID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"direct_messages/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postDirectMessage:(NSString *)status
            forScreenName:(NSString *)screenName
                 orUserID:(NSString *)userID
             successBlock:(void(^)(NSDictionary *message))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock {
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithObject:status forKey:@"text"];
    
    NSAssert(screenName != nil || userID != nil, @"screenName OR userID is required");
    
    if(screenName) {
        md[@"screen_name"] = screenName;
    } else {
        md[@"user_id"] = userID;
    }
    
    [self postAPIResource:@"direct_messages/new.json"
               parameters:md
             successBlock:^(NSDictionary *rateLimits, id response) {
                 successBlock(response);
             } errorBlock:^(NSError *error) {
                 errorBlock(error);
             }];
}

- (void)_postDirectMessage:(NSString *)status
             forScreenName:(NSString *)screenName
                  orUserID:(NSString *)userID
                   mediaID:(NSString *)mediaID
              successBlock:(void(^)(NSDictionary *message))successBlock
                errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithObject:status forKey:@"text"];
    
    NSAssert(screenName != nil || userID != nil, @"screenName OR userID is required");
    
    if(screenName) {
        md[@"screen_name"] = screenName;
    } else {
        md[@"user_id"] = userID;
    }
    
    if(mediaID) md[@"media_id"] = mediaID;
    
    [self postAPIResource:@"direct_messages/new.json"
               parameters:md
             successBlock:^(NSDictionary *rateLimits, id response) {
                 successBlock(response);
             } errorBlock:^(NSError *error) {
                 errorBlock(error);
             }];
}

#pragma mark Friends & Followers

- (void)getFriendshipNoRetweetsIDsWithSuccessBlock:(void(^)(NSArray *ids))successBlock
                                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"stringify_ids"] = @"1";
    
    [self getAPIResource:@"friendships/no_retweets/ids.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFriendsIDsForUserID:(NSString *)userID
                  orScreenName:(NSString *)screenName
                        cursor:(NSString *)cursor
                         count:(NSString *)count
                  successBlock:(void(^)(NSArray *ids, NSString *previousCursor, NSString *nextCursor))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"userID or screenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(cursor) md[@"cursor"] = cursor;
    md[@"stringify_ids"] = @"1";
    
    if(count) md[@"count"] = count;
    
    [self getAPIResource:@"friends/ids.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *ids = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            ids = [response valueForKey:@"ids"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(ids, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFriendsIDsForScreenName:(NSString *)screenName
                      successBlock:(void(^)(NSArray *friends))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getFriendsIDsForUserID:nil
                    orScreenName:screenName
                          cursor:nil
                           count:nil
                    successBlock:^(NSArray *ids, NSString *previousCursor, NSString *nextCursor) {
                        successBlock(ids);
                    } errorBlock:^(NSError *error) {
                        errorBlock(error);
                    }];
}

- (void)getFollowersIDsForUserID:(NSString *)userID
                    orScreenName:(NSString *)screenName
                          cursor:(NSString *)cursor
                           count:(NSString *)count
                    successBlock:(void(^)(NSArray *followersIDs, NSString *previousCursor, NSString *nextCursor))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"userID or screenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(cursor) md[@"cursor"] = cursor;
    md[@"stringify_ids"] = @"1";
    if(count) md[@"count"] = count;
    
    [self getAPIResource:@"followers/ids.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *followersIDs = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            followersIDs = [response valueForKey:@"ids"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(followersIDs, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFollowersIDsForScreenName:(NSString *)screenName
                        successBlock:(void(^)(NSArray *followers))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getFollowersIDsForUserID:nil
                      orScreenName:screenName
                            cursor:nil
                             count:nil
                      successBlock:^(NSArray *ids, NSString *previousCursor, NSString *nextCursor) {
                          successBlock(ids);
                      } errorBlock:^(NSError *error) {
                          errorBlock(error);
                      }];
}

- (void)getFriendshipsLookupForScreenNames:(NSArray *)screenNames
                                 orUserIDs:(NSArray *)userIDs
                              successBlock:(void(^)(NSArray *users))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenNames || userIDs), @"missing screen names or user IDs");
    
    NSString *commaSeparatedScreenNames = [screenNames componentsJoinedByString:@","];
    NSString *commaSeparatedUserIDs = [userIDs componentsJoinedByString:@","];
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(commaSeparatedScreenNames) md[@"screen_name"] = commaSeparatedScreenNames;
    if(commaSeparatedUserIDs) md[@"user_id"] = commaSeparatedUserIDs;
    
    [self getAPIResource:@"friendships/lookup.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFriendshipIncomingWithCursor:(NSString *)cursor
                           successBlock:(void(^)(NSArray *IDs, NSString *previousCursor, NSString *nextCursor))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock {
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(cursor) md[@"cursor"] = cursor;
    md[@"stringify_ids"] = @"1";
    
    [self getAPIResource:@"friendships/incoming.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *ids = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            ids = [response valueForKey:@"ids"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(ids, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFriendshipOutgoingWithCursor:(NSString *)cursor
                           successBlock:(void(^)(NSArray *IDs, NSString *previousCursor, NSString *nextCursor))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock {
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(cursor) md[@"cursor"] = cursor;
    md[@"stringify_ids"] = @"1";
    
    [self getAPIResource:@"friendships/outgoing.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *ids = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            ids = [response valueForKey:@"ids"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(ids, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postFriendshipsCreateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                              successBlock:(void(^)(NSDictionary *befriendedUser))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    NSAssert((screenName || userID), @"screenName or userID is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    
    [self postAPIResource:@"friendships/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postFollow:(NSString *)screenName
      successBlock:(void(^)(NSDictionary *user))successBlock
        errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postFriendshipsCreateForScreenName:screenName orUserID:nil successBlock:^(NSDictionary *user) {
        successBlock(user);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postFriendshipsDestroyScreenName:(NSString *)screenName
                                orUserID:(NSString *)userID
                            successBlock:(void(^)(NSDictionary *unfollowedUser))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"screenName or userID is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    
    [self postAPIResource:@"friendships/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postUnfollow:(NSString *)screenName
        successBlock:(void(^)(NSDictionary *user))successBlock
          errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postFriendshipsDestroyScreenName:screenName orUserID:nil successBlock:^(NSDictionary *user) {
        successBlock(user);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postFriendshipsUpdateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                 enableDeviceNotifications:(NSNumber *)enableDeviceNotifications
                            enableRetweets:(NSNumber *)enableRetweets
                              successBlock:(void (^)(NSDictionary *))successBlock errorBlock:(void (^)(NSError *))errorBlock {
    NSAssert((screenName || userID), @"screenName or userID is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    if(enableDeviceNotifications) md[@"device"] = [enableDeviceNotifications boolValue] ? @"1" : @"0";
    if(enableRetweets) md[@"retweets"] = [enableRetweets boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"friendships/update.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postFriendshipsUpdateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                 enableDeviceNotifications:(BOOL)enableDeviceNotifications
                              successBlock:(void (^)(NSDictionary *))successBlock errorBlock:(void (^)(NSError *))errorBlock {
    NSAssert((screenName || userID), @"screenName or userID is missing");
    
    [self postFriendshipsUpdateForScreenName:screenName
                                    orUserID:userID
                   enableDeviceNotifications:@(enableDeviceNotifications)
                              enableRetweets:nil
                                successBlock:^(NSDictionary *user) {
                                    successBlock(user);
                                } errorBlock:^(NSError *error) {
                                    errorBlock(error);
                                }];
}

- (void)postFriendshipsUpdateForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                            enableRetweets:(BOOL)enableRetweets
                              successBlock:(void (^)(NSDictionary *))successBlock errorBlock:(void (^)(NSError *))errorBlock {
    NSAssert((screenName || userID), @"screenName or userID is missing");
    
    [self postFriendshipsUpdateForScreenName:screenName
                                    orUserID:userID
                   enableDeviceNotifications:nil
                              enableRetweets:@(enableRetweets)
                                successBlock:^(NSDictionary *user) {
                                    successBlock(user);
                                } errorBlock:^(NSError *error) {
                                    errorBlock(error);
                                }];
}

- (void)getFriendshipShowForSourceID:(NSString *)sourceID
                  orSourceScreenName:(NSString *)sourceScreenName
                            targetID:(NSString *)targetID
                  orTargetScreenName:(NSString *)targetScreenName
                        successBlock:(void(^)(id relationship))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock {
    NSAssert((sourceID || sourceScreenName), @"sourceID or sourceScreenName is missing");
    NSAssert((targetID || targetScreenName), @"targetID or targetScreenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(sourceID) md[@"source_id"] = sourceID;
    if(sourceScreenName) md[@"source_screen_name"] = sourceScreenName;
    if(targetID) md[@"target_id"] = targetID;
    if(targetScreenName) md[@"target_screen_name"] = targetScreenName;
    
    [self getAPIResource:@"friendships/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFriendsListForUserID:(NSString *)userID
                   orScreenName:(NSString *)screenName
                         cursor:(NSString *)cursor
                          count:(NSString *)count
                     skipStatus:(NSNumber *)skipStatus
            includeUserEntities:(NSNumber *)includeUserEntities
                   successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"userID or screenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(cursor) md[@"cursor"] = cursor;
    if(count) md[@"count"] = count;
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    if(includeUserEntities) md[@"include_user_entities"] = [includeUserEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"friends/list.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *users = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            users = [response valueForKey:@"users"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFriendsForScreenName:(NSString *)screenName
                   successBlock:(void(^)(NSArray *friends))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getFriendsListForUserID:nil
                     orScreenName:screenName
                           cursor:nil
                            count:nil
                       skipStatus:@(NO)
              includeUserEntities:@(YES)
                     successBlock:^(NSArray *users, NSString *previousCursor, NSString *nextCursor) {
                         successBlock(users);
                     } errorBlock:^(NSError *error) {
                         errorBlock(error);
                     }];
}

- (void)getFollowersListForUserID:(NSString *)userID
                     orScreenName:(NSString *)screenName
                           cursor:(NSString *)cursor
                       skipStatus:(NSNumber *)skipStatus
              includeUserEntities:(NSNumber *)includeUserEntities
                     successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"userID or screenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(cursor) md[@"cursor"] = cursor;
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    if(includeUserEntities) md[@"include_user_entities"] = [includeUserEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"followers/list.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *users = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            users = [response valueForKey:@"users"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// convenience
- (void)getFollowersForScreenName:(NSString *)screenName
                     successBlock:(void(^)(NSArray *followers))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getFollowersListForUserID:nil
                       orScreenName:screenName
                             cursor:nil
                         skipStatus:nil
                includeUserEntities:nil
                       successBlock:^(NSArray *users, NSString *previousCursor, NSString *nextCursor) {
                           successBlock(users);
                       } errorBlock:^(NSError *error) {
                           errorBlock(error);
                       }];
}

#pragma mark Users

// GET account/settings
- (void)getAccountSettingsWithSuccessBlock:(void(^)(NSDictionary *settings))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    [self getAPIResource:@"account/settings.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET account/verify_credentials
- (void)getAccountVerifyCredentialsWithIncludeEntites:(NSNumber *)includeEntities
                                           skipStatus:(NSNumber *)skipStatus
                                         successBlock:(void(^)(NSDictionary *myInfo))successBlock
                                           errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"account/verify_credentials.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getAccountVerifyCredentialsWithSuccessBlock:(void(^)(NSDictionary *account))successBlock
                                         errorBlock:(void(^)(NSError *error))errorBlock {
    [self getAccountVerifyCredentialsWithIncludeEntites:nil skipStatus:nil successBlock:^(NSDictionary *account) {
        successBlock(account);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST account/settings
- (void)postAccountSettingsWithTrendLocationWOEID:(NSString *)trendLocationWOEID // eg. "1"
                                 sleepTimeEnabled:(NSNumber *)sleepTimeEnabled // eg. @(YES)
                                   startSleepTime:(NSString *)startSleepTime // eg. "13"
                                     endSleepTime:(NSString *)endSleepTime // eg. "13"
                                         timezone:(NSString *)timezone // eg. "Europe/Copenhagen", "Pacific/Tongatapu"
                                         language:(NSString *)language // eg. "it", "en", "es"
                                     successBlock:(void(^)(NSDictionary *settings))successBlock
                                       errorBlock:(void(^)(NSError *error))errorBlock {
    NSAssert((trendLocationWOEID || sleepTimeEnabled || startSleepTime || endSleepTime || timezone || language), @"at least one parameter is needed");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(trendLocationWOEID) md[@"trend_location_woeid"] = trendLocationWOEID;
    if(sleepTimeEnabled) md[@"sleep_time_enabled"] = [sleepTimeEnabled boolValue] ? @"1" : @"0";
    if(startSleepTime) md[@"start_sleep_time"] = startSleepTime;
    if(endSleepTime) md[@"end_sleep_time"] = endSleepTime;
    if(timezone) md[@"time_zone"] = timezone;
    if(language) md[@"lang"] = language;
    
    [self postAPIResource:@"account/settings.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	account/update_delivery_device
- (void)postAccountUpdateDeliveryDeviceSMS:(BOOL)deliveryDeviceSMS
                           includeEntities:(NSNumber *)includeEntities
                              successBlock:(void(^)(NSDictionary *response))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"device"] = deliveryDeviceSMS ? @"sms" : @"none";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"account/update_delivery_device.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST account/update_profile
- (void)postAccountUpdateProfileWithName:(NSString *)name
                               URLString:(NSString *)URLString
                                location:(NSString *)location
                             description:(NSString *)description
                         includeEntities:(NSNumber *)includeEntities
                              skipStatus:(NSNumber *)skipStatus
                            successBlock:(void(^)(NSDictionary *profile))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((name || URLString || location || description || includeEntities || skipStatus), @"at least one parameter is needed");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(name) md[@"name"] = name;
    if(URLString) md[@"url"] = URLString;
    if(location) md[@"location"] = location;
    if(description) md[@"description"] = description;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";;
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"account/update_profile.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postUpdateProfile:(NSDictionary *)profileData
             successBlock:(void(^)(NSDictionary *myInfo))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock {
    [self postAPIResource:@"account/update_profile.json" parameters:profileData successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST account/update_profile_background_image
- (void)postAccountUpdateProfileBackgroundImageWithImage:(NSString *)base64EncodedImage
                                                   title:(NSString *)title
                                         includeEntities:(NSNumber *)includeEntities
                                              skipStatus:(NSNumber *)skipStatus
                                                     use:(NSNumber *)use
                                            successBlock:(void(^)(NSDictionary *profile))successBlock
                                              errorBlock:(void(^)(NSError *error))errorBlock {
    NSAssert((base64EncodedImage || title || includeEntities || skipStatus || use), @"at least one parameter is needed");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(base64EncodedImage) md[@"image"] = base64EncodedImage;
    if(title) md[@"title"] = title;
    
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";;
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    if(use) md[@"use"] = [use boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"account/update_profile_background_image.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST account/update_profile_colors
- (void)postAccountUpdateProfileColorsWithBackgroundColor:(NSString *)backgroundColor
                                                linkColor:(NSString *)linkColor
                                       sidebarBorderColor:(NSString *)sidebarBorderColor
                                         sidebarFillColor:(NSString *)sidebarFillColor
                                         profileTextColor:(NSString *)profileTextColor
                                          includeEntities:(NSNumber *)includeEntities
                                               skipStatus:(NSNumber *)skipStatus
                                             successBlock:(void(^)(NSDictionary *profile))successBlock
                                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(backgroundColor) md[@"profile_background_color"] = backgroundColor;
    if(linkColor) md[@"profile_link_color"] = linkColor;
    if(sidebarBorderColor) md[@"profile_sidebar_border_color"] = sidebarBorderColor;
    if(sidebarFillColor) md[@"profile_sidebar_fill_color"] = sidebarFillColor;
    if(profileTextColor) md[@"profile_text_color"] = profileTextColor;
    
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"account/update_profile_colors.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST account/update_profile_image
- (void)postAccountUpdateProfileImage:(NSString *)base64EncodedImage
                      includeEntities:(NSNumber *)includeEntities
                           skipStatus:(NSNumber *)skipStatus
                         successBlock:(void(^)(NSDictionary *profile))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(base64EncodedImage);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"image"] = base64EncodedImage;
    
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"account/update_profile_image.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET blocks/list
- (void)getBlocksListWithincludeEntities:(NSNumber *)includeEntities
                              skipStatus:(NSNumber *)skipStatus
                                  cursor:(NSString *)cursor
                            successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    if(cursor) md[@"cursor"] = cursor;
    
    [self getAPIResource:@"blocks/list.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSArray *users = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            users = [response valueForKey:@"users"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET blocks/ids
- (void)getBlocksIDsWithCursor:(NSString *)cursor
                  successBlock:(void(^)(NSArray *ids, NSString *previousCursor, NSString *nextCursor))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock {
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"stringify_ids"] = @"1";
    if(cursor) md[@"cursor"] = cursor;
    
    [self getAPIResource:@"blocks/ids.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSArray *ids = nil;
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            ids = [response valueForKey:@"ids"];
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
        }
        
        successBlock(ids, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST blocks/create
- (void)postBlocksCreateWithScreenName:(NSString *)screenName
                              orUserID:(NSString *)userID
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(NSDictionary *user))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"missing screenName or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"blocks/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST blocks/destroy
- (void)postBlocksDestroyWithScreenName:(NSString *)screenName
                               orUserID:(NSString *)userID
                        includeEntities:(NSNumber *)includeEntities
                             skipStatus:(NSNumber *)skipStatus
                           successBlock:(void(^)(NSDictionary *user))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"missing screenName or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"blocks/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/lookup
- (void)getUsersLookupForScreenName:(NSString *)screenName
                           orUserID:(NSString *)userID
                    includeEntities:(NSNumber *)includeEntities
                       successBlock:(void(^)(NSArray *users))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"missing screenName or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"users/lookup.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/show
- (void)getUsersShowForUserID:(NSString *)userID
                 orScreenName:(NSString *)screenName
              includeEntities:(NSNumber *)includeEntities
                 successBlock:(void(^)(NSDictionary *user))successBlock
                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"missing screenName or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"users/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getUserInformationFor:(NSString *)screenName
                 successBlock:(void(^)(NSDictionary *user))successBlock
                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getUsersShowForUserID:nil orScreenName:screenName includeEntities:nil successBlock:^(NSDictionary *user) {
        successBlock(user);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/search
- (void)getUsersSearchQuery:(NSString *)query
                       page:(NSString *)page
                      count:(NSString *)count
            includeEntities:(NSNumber *)includeEntities
               successBlock:(void(^)(NSArray *users))successBlock
                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(query);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    md[@"q"] = [query st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(page) md[@"page"] = page;
    if(count) md[@"count"] = count;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"users/search.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response); // NSArray of users dictionaries
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/contributees
- (void)getUsersContributeesWithUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(NSArray *contributees))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"missing screenName or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"users/contributees.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/contributors
- (void)getUsersContributorsWithUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(NSArray *contributors))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"missing screenName or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"users/contributors.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST account/remove_profile_banner
- (void)postAccountRemoveProfileBannerWithSuccessBlock:(void(^)(id response))successBlock
                                            errorBlock:(void(^)(NSError *error))errorBlock {
    [self postAPIResource:@"account/remove_profile_banner.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST account/update_profile_banner
- (void)postAccountUpdateProfileBannerWithImage:(NSString *)base64encodedImage
                                          width:(NSString *)width
                                         height:(NSString *)height
                                     offsetLeft:(NSString *)offsetLeft
                                      offsetTop:(NSString *)offsetTop
                                   successBlock:(void(^)(id response))successBlock
                                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    if(width || height || offsetLeft || offsetTop) {
        NSParameterAssert(width);
        NSParameterAssert(height);
        NSParameterAssert(offsetLeft);
        NSParameterAssert(offsetTop);
    }
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"banner"] = base64encodedImage;
    if(width) md[@"width"] = width;
    if(height) md[@"height"] = height;
    if(offsetLeft) md[@"offset_left"] = offsetLeft;
    if(offsetTop) md[@"offset_top"] = offsetTop;
    
    [self postAPIResource:@"account/update_profile_banner.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/profile_banner
- (void)getUsersProfileBannerForUserID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                          successBlock:(void(^)(NSDictionary *banner))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((screenName || userID), @"missing screenName or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    
    [self getAPIResource:@"users/profile_banner.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/suggestions
- (void)getUsersSuggestionsWithISO6391LanguageCode:(NSString *)ISO6391LanguageCode
                                      successBlock:(void(^)(NSArray *suggestions))successBlock
                                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(ISO6391LanguageCode) md[@"lang"] = ISO6391LanguageCode;
    
    [self getAPIResource:@"users/suggestions.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/suggestions/:slug/members
- (void)getUsersSuggestionsForSlugMembers:(NSString *)slug // short name of list or a category, eg. "twitter"
                             successBlock:(void(^)(NSArray *members))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert(slug, @"missing slug");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    md[@"slug"] = slug;
    
    NSString *resource = [NSString stringWithFormat:@"users/suggestions/%@/members.json", slug];
    
    [self getAPIResource:resource parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST mutes/users/create
- (void)postMutesUsersCreateForScreenName:(NSString *)screenName
                                 orUserID:(NSString *)userID
                             successBlock:(void(^)(NSDictionary *user))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"userID or screenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    
    [self postAPIResource:@"mutes/users/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST mutes/users/destroy
- (void)postMutesUsersDestroyForScreenName:(NSString *)screenName
                                  orUserID:(NSString *)userID
                              successBlock:(void(^)(NSDictionary *user))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"userID or screenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    
    [self postAPIResource:@"mutes/users/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET mutes/users/ids
- (void)getMutesUsersIDsWithCursor:(NSString *)cursor
                      successBlock:(void(^)(NSArray *userIDs, NSString *previousCursor, NSString *nextCursor))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(cursor) md[@"cursor"] = cursor;
    
    [self getAPIResource:@"mutes/users/ids.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSArray *userIDs = [response valueForKey:@"ids"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        
        successBlock(userIDs, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET mutes/users/list
- (void)getMutesUsersListWithCursor:(NSString *)cursor
                    includeEntities:(NSNumber *)includeEntities
                         skipStatus:(NSNumber *)skipStatus
                       successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    if(cursor) md[@"cursor"] = cursor;
    if(includeEntities) md[@"include_entities"] = includeEntities;
    if(skipStatus) md[@"skip_status"] = skipStatus;
    
    [self getAPIResource:@"mutes/users/list.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSArray *users = [response valueForKey:@"users"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Suggested Users

// GET users/suggestions/:slug
- (void)getUsersSuggestionsForSlug:(NSString *)slug // short name of list or a category, eg. "twitter"
                              lang:(NSString *)lang
                      successBlock:(void(^)(NSString *name, NSString *slug, NSArray *users))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert(slug, @"slug is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(lang) md[@"lang"] = lang;
    
    [self getAPIResource:@"users/suggestions/twitter.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSString *name = nil;
        NSString *slug = nil;
        NSArray *users = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            name = [response valueForKey:@"name"];
            slug = [response valueForKey:@"slug"];
            users = [response valueForKey:@"users"];
        }
        
        successBlock(name,  slug, users);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Favorites

// GET favorites/list
- (void)getFavoritesListWithUserID:(NSString *)userID
                        screenName:(NSString *)screenName
                             count:(NSString *)count
                           sinceID:(NSString *)sinceID
                             maxID:(NSString *)maxID
                   includeEntities:(NSNumber *)includeEntities
                      successBlock:(void(^)(NSArray *statuses))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(count) md[@"count"] = count;
    if(sinceID) md[@"since_id"] = sinceID;
    if(maxID) md[@"max_id"] = maxID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"favorites/list.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFavoritesListWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getFavoritesListWithUserID:nil
                          screenName:nil
                               count:nil
                             sinceID:nil
                               maxID:nil
                     includeEntities:nil
                        successBlock:^(NSArray *statuses) {
                            successBlock(statuses);
                        } errorBlock:^(NSError *error) {
                            errorBlock(error);
                        }];
}

// POST favorites/destroy
- (void)postFavoriteDestroyWithStatusID:(NSString *)statusID
                        includeEntities:(NSNumber *)includeEntities
                           successBlock:(void(^)(NSDictionary *status))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(statusID) md[@"id"] = statusID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"favorites/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	favorites/create
- (void)postFavoriteCreateWithStatusID:(NSString *)statusID
                       includeEntities:(NSNumber *)includeEntities
                          successBlock:(void(^)(NSDictionary *status))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(statusID) md[@"id"] = statusID;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    
    [self postAPIResource:@"favorites/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postFavoriteState:(BOOL)favoriteState
              forStatusID:(NSString *)statusID
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *action = favoriteState ? @"create" : @"destroy";
    
    NSString *resource = [NSString stringWithFormat:@"favorites/%@.json", action];
    
    NSDictionary *d = @{@"id" : statusID};
    
    [self postAPIResource:resource parameters:d successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Lists

// GET	lists/list

- (void)getListsSubscribedByUsername:(NSString *)username
                            orUserID:(NSString *)userID
                             reverse:(NSNumber *)reverse
                        successBlock:(void(^)(NSArray *lists))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((username || userID), @"missing username or userID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(username) {
        md[@"screen_name"] = username;
    } else if (userID) {
        md[@"user_id"] = userID;
    }
    
    if(reverse) md[@"reverse"] = [reverse boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/list.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSAssert([response isKindOfClass:[NSArray class]], @"bad response type");
        
        NSArray *lists = (NSArray *)response;
        
        successBlock(lists);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET    lists/statuses

- (void)getListsStatusesForListID:(NSString *)listID
                          sinceID:(NSString *)sinceID
                            maxID:(NSString *)maxID
                            count:(NSString *)count
                  includeEntities:(NSNumber *)includeEntities
                  includeRetweets:(NSNumber *)includeRetweets
                     successBlock:(void(^)(NSArray *statuses))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    
    if(sinceID) md[@"since_id"] = sinceID;
    if(maxID) md[@"max_id"] = maxID;
    if(count) md[@"count"] = count;
    
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(includeRetweets) md[@"include_rts"] = includeRetweets ? @"1" : @"0";
    
    [self getAPIResource:@"lists/statuses.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSAssert([response isKindOfClass:[NSArray class]], @"bad response type");
        
        NSArray *statuses = (NSArray *)response;
        
        successBlock(statuses);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getListsStatusesForSlug:(NSString *)slug
                     screenName:(NSString *)ownerScreenName
                        ownerID:(NSString *)ownerID
                        sinceID:(NSString *)sinceID
                          maxID:(NSString *)maxID
                          count:(NSString *)count
                includeEntities:(NSNumber *)includeEntities
                includeRetweets:(NSNumber *)includeRetweets
                   successBlock:(void(^)(NSArray *statuses))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    if(sinceID) md[@"since_id"] = sinceID;
    if(maxID) md[@"max_id"] = maxID;
    if(count) md[@"count"] = count;
    
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(includeRetweets) md[@"include_rts"] = [includeRetweets boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/statuses.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSAssert([response isKindOfClass:[NSArray class]], @"bad response type");
        
        NSArray *statuses = (NSArray *)response;
        
        successBlock(statuses);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST lists/members/destroy

- (void)postListsMembersDestroyForListID:(NSString *)listID
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSDictionary *d = @{ @"list_id" : listID };
    
    [self postAPIResource:@"lists/members/destroy" parameters:d successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListsMembersDestroyForSlug:(NSString *)slug
                                userID:(NSString *)userID
                            screenName:(NSString *)screenName
                       ownerScreenName:(NSString *)ownerScreenName
                               ownerID:(NSString *)ownerID
                          successBlock:(void(^)())successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    md[@"slug"] = slug;
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerScreenName) md[@"owner_id"] = ownerID;
    
    [self postAPIResource:@"lists/members/destroy" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock();
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET lists/memberships

- (void)getListsMembershipsForUserID:(NSString *)userID
                        orScreenName:(NSString *)screenName
                              cursor:(NSString *)cursor
                  filterToOwnedLists:(NSNumber *)filterToOwnedLists
                        successBlock:(void(^)(NSArray *lists, NSString *previousCursor, NSString *nextCursor))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert((userID || screenName), @"userID or screenName is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(cursor) md[@"cursor"] = cursor;
    if(filterToOwnedLists) md[@"filter_to_owned_lists"] = [filterToOwnedLists boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/memberships.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSString *previousCursor = nil;
        NSString *nextCursor = nil;
        NSArray *lists = nil;
        
        if([response isKindOfClass:[NSDictionary class]]) {
            previousCursor = [response valueForKey:@"previous_cursor_str"];
            nextCursor = [response valueForKey:@"next_cursor_str"];
            lists = [response valueForKey:@"lists"];
        }
        
        successBlock(lists, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET	lists/subscribers

- (void)getListsSubscribersForSlug:(NSString *)slug
                   ownerScreenName:(NSString *)ownerScreenName
                         orOwnerID:(NSString *)ownerID
                            cursor:(NSString *)cursor
                   includeEntities:(NSNumber *)includeEntities
                        skipStatus:(NSNumber *)skipStatus
                      successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or onwerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) {
        md[@"owner_screen_name"] = ownerScreenName;
    } else if (ownerID) {
        md[@"owner_id"] = ownerID;
    }
    if(cursor) md[@"cursor"] = cursor;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/subscribers.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *users = [response valueForKey:@"users"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getListsSubscribersForListID:(NSString *)listID
                              cursor:(NSString *)cursor
                     includeEntities:(NSNumber *)includeEntities
                          skipStatus:(NSNumber *)skipStatus
                        successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    if(cursor) md[@"cursor"] = cursor;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/subscribers.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *users = [response valueForKey:@"users"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/subscribers/create

- (void)postListSubscribersCreateForListID:(NSString *)listID
                              successBlock:(void(^)(id response))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    
    [self postAPIResource:@"lists/subscribers/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListSubscribersCreateForSlug:(NSString *)slug
                         ownerScreenName:(NSString *)ownerScreenName
                               orOwnerID:(NSString *)ownerID
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    
    [self postAPIResource:@"lists/subscribers/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET	lists/subscribers/show

- (void)getListsSubscribersShowForListID:(NSString *)listID
                                  userID:(NSString *)userID
                            orScreenName:(NSString *)screenName
                         includeEntities:(NSNumber *)includeEntities
                              skipStatus:(NSNumber *)skipStatus
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    NSParameterAssert(listID);
    NSAssert((userID || screenName), @"missing userID or screenName");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/subscribers/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getListsSubscribersShowForSlug:(NSString *)slug
                       ownerScreenName:(NSString *)ownerScreenName
                             orOwnerID:(NSString *)ownerID
                                userID:(NSString *)userID
                          orScreenName:(NSString *)screenName
                       includeEntities:(NSNumber *)includeEntities
                            skipStatus:(NSNumber *)skipStatus
                          successBlock:(void(^)(id response))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    NSAssert((userID || screenName), @"missing userID or screenName");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/subscribers/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/subscribers/destroy

- (void)postListSubscribersDestroyForListID:(NSString *)listID
                               successBlock:(void(^)(id response))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    
    [self postAPIResource:@"lists/subscribers/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListSubscribersDestroyForSlug:(NSString *)slug
                          ownerScreenName:(NSString *)ownerScreenName
                                orOwnerID:(NSString *)ownerID
                             successBlock:(void(^)(id response))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    
    [self postAPIResource:@"lists/subscribers/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/members/create_all

- (void)postListsMembersCreateAllForListID:(NSString *)listID
                                   userIDs:(NSArray *)userIDs // array of strings
                             orScreenNames:(NSArray *)screenNames // array of strings
                              successBlock:(void(^)(id response))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    NSParameterAssert(listID);
    NSAssert((userIDs || screenNames), @"missing usersIDs or screenNames");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    
    if(userIDs) {
        md[@"user_id"] = [userIDs componentsJoinedByString:@","];
    } else if (screenNames) {
        md[@"screen_name"] = [screenNames componentsJoinedByString:@","];
    }
    
    [self postAPIResource:@"lists/members/create_all.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListsMembersCreateAllForSlug:(NSString *)slug
                         ownerScreenName:(NSString *)ownerScreenName
                               orOwnerID:(NSString *)ownerID
                                 userIDs:(NSArray *)userIDs // array of strings
                           orScreenNames:(NSArray *)screenNames // array of strings
                            successBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    NSAssert((userIDs || screenNames), @"missing usersIDs or screenNames");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    
    if(ownerScreenName) {
        md[@"owner_screen_name"] = ownerScreenName;
    } else if (ownerID) {
        md[@"owner_id"] = ownerID;
    }
    
    if(userIDs) {
        md[@"user_id"] = [userIDs componentsJoinedByString:@","];
    } else if (screenNames) {
        md[@"screen_name"] = [screenNames componentsJoinedByString:@","];
    }
    
    [self postAPIResource:@"lists/members/create_all.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET	lists/members/show

- (void)getListsMembersShowForListID:(NSString *)listID
                              userID:(NSString *)userID
                          screenName:(NSString *)screenName
                     includeEntities:(NSNumber *)includeEntities
                          skipStatus:(NSNumber *)skipStatus
                        successBlock:(void(^)(NSDictionary *user))successBlock
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert(listID, @"listID is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/members/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getListsMembersShowForSlug:(NSString *)slug
                   ownerScreenName:(NSString *)ownerScreenName
                         orOwnerID:(NSString *)ownerID
                            userID:(NSString *)userID
                        screenName:(NSString *)screenName
                   includeEntities:(NSNumber *)includeEntities
                        skipStatus:(NSNumber *)skipStatus
                      successBlock:(void(^)(NSDictionary *user))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/members/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET	lists/members

- (void)getListsMembersForListID:(NSString *)listID
                          cursor:(NSString *)cursor
                 includeEntities:(NSNumber *)includeEntities
                      skipStatus:(NSNumber *)skipStatus
                    successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSAssert(listID, @"listID is missing");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    if(cursor) md[@"cursor"] = cursor;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/members.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *users = [response valueForKey:@"users"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getListsMembersForSlug:(NSString *)slug
               ownerScreenName:(NSString *)ownerScreenName
                     orOwnerID:(NSString *)ownerID
                        cursor:(NSString *)cursor
               includeEntities:(NSNumber *)includeEntities
                    skipStatus:(NSNumber *)skipStatus
                  successBlock:(void(^)(NSArray *users, NSString *previousCursor, NSString *nextCursor))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    if(cursor) md[@"cursor"] = cursor;
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"1" : @"0";
    if(skipStatus) md[@"skip_status"] = [skipStatus boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"lists/members.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        NSArray *users = [response valueForKey:@"users"];
        NSString *previousCursor = [response valueForKey:@"previous_cursor_str"];
        NSString *nextCursor = [response valueForKey:@"next_cursor_str"];
        successBlock(users, previousCursor, nextCursor);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/members/create

- (void)postListMemberCreateForListID:(NSString *)listID
                               userID:(NSString *)userID
                           screenName:(NSString *)screenName
                         successBlock:(void(^)(id response))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    NSAssert((userID || screenName), @"missing userID or screenName");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    if(userID) md[@"user_id"] = userID;
    if(screenName) md[@"screen_name"] = screenName;
    
    [self postAPIResource:@"lists/members/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListMemberCreateForSlug:(NSString *)slug
                    ownerScreenName:(NSString *)ownerScreenName
                          orOwnerID:(NSString *)ownerID
                             userID:(NSString *)userID
                         screenName:(NSString *)screenName
                       successBlock:(void(^)(id response))successBlock
                         errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    md[@"user_id"] = userID;
    md[@"screen_name"] = screenName;
    
    [self postAPIResource:@"lists/members/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/destroy

- (void)postListsDestroyForListID:(NSString *)listID
                     successBlock:(void(^)(id response))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    
    [self postAPIResource:@"lists/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListsDestroyForSlug:(NSString *)slug
                ownerScreenName:(NSString *)ownerScreenName
                      orOwnerID:(NSString *)ownerID
                   successBlock:(void(^)(id response))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    
    [self postAPIResource:@"lists/destroy.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/update

- (void)postListsUpdateForListID:(NSString *)listID
                            name:(NSString *)name
                       isPrivate:(BOOL)isPrivate
                     description:(NSString *)description
                    successBlock:(void(^)(id response))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    if(name) md[@"name"] = [name st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    md[@"mode"] = isPrivate ? @"private" : @"public";
    if(description) md[@"description"] = [description st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self postAPIResource:@"lists/update.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListsUpdateForSlug:(NSString *)slug
               ownerScreenName:(NSString *)ownerScreenName
                     orOwnerID:(NSString *)ownerID
                          name:(NSString *)name
                     isPrivate:(BOOL)isPrivate
                   description:(NSString *)description
                  successBlock:(void(^)(id response))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    if(name) md[@"name"] = [name st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    md[@"mode"] = isPrivate ? @"private" : @"public";
    if(description) md[@"description"] = [description st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self postAPIResource:@"lists/update.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/create

- (void)postListsCreateWithName:(NSString *)name
                      isPrivate:(BOOL)isPrivate
                    description:(NSString *)description
                   successBlock:(void(^)(NSDictionary *list))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(name);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"name"] = [name st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    md[@"mode"] = isPrivate ? @"private" : @"public";
    if(description) md[@"description"] = [description st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self postAPIResource:@"lists/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET	lists/show

- (void)getListsShowListID:(NSString *)listID
              successBlock:(void(^)(NSDictionary *list))successBlock
                errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    
    [self getAPIResource:@"lists/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getListsShowListSlug:(NSString *)slug
             ownerScreenName:(NSString *)ownerScreenName
                   orOwnerID:(NSString *)ownerID
                successBlock:(void(^)(NSDictionary *list))successBlock
                  errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    if(ownerScreenName) md[@"owner_screen_name"] = ownerScreenName;
    if(ownerID) md[@"owner_id"] = ownerID;
    
    [self getAPIResource:@"lists/show.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST	lists/members/destroy_all

- (void)postListsMembersDestroyAllForListID:(NSString *)listID
                                    userIDs:(NSArray *)userIDs // array of strings
                              orScreenNames:(NSArray *)screenNames // array of strings
                               successBlock:(void(^)(id response))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(listID);
    NSAssert((userIDs || screenNames), @"missing usersIDs or screenNames");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"list_id"] = listID;
    
    if(userIDs) {
        md[@"user_id"] = [userIDs componentsJoinedByString:@","];
    } else if (screenNames) {
        md[@"screen_name"] = [screenNames componentsJoinedByString:@","];
    }
    
    [self postAPIResource:@"lists/members/destroy_all.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postListsMembersDestroyAllForSlug:(NSString *)slug
                          ownerScreenName:(NSString *)ownerScreenName
                                orOwnerID:(NSString *)ownerID
                                  userIDs:(NSArray *)userIDs // array of strings
                            orScreenNames:(NSArray *)screenNames // array of strings
                             successBlock:(void(^)(id response))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(slug);
    NSAssert((ownerScreenName || ownerID), @"missing ownerScreenName or ownerID");
    NSAssert((userIDs || screenNames), @"missing usersIDs or screenNames");
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"slug"] = slug;
    
    if(ownerScreenName) {
        md[@"owner_screen_name"] = ownerScreenName;
    } else if (ownerID) {
        md[@"owner_id"] = ownerID;
    }
    
    if(userIDs) {
        md[@"user_id"] = [userIDs componentsJoinedByString:@","];
    } else if (screenNames) {
        md[@"screen_name"] = [screenNames componentsJoinedByString:@","];
    }
    
    [self postAPIResource:@"lists/members/destroy_all.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Saved Searches

// GET saved_searches/list
- (void)getSavedSearchesListWithSuccessBlock:(void(^)(NSArray *savedSearches))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getAPIResource:@"saved_searches/list.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET saved_searches/show/:id
- (void)getSavedSearchesShow:(NSString *)savedSearchID
                successBlock:(void(^)(NSDictionary *savedSearch))successBlock
                  errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(savedSearchID);
    
    NSString *resource = [NSString stringWithFormat:@"saved_searches/show/%@.json", savedSearchID];
    
    [self getAPIResource:resource parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST saved_searches/create
- (void)postSavedSearchesCreateWithQuery:(NSString *)query
                            successBlock:(void(^)(NSDictionary *createdSearch))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(query);
    
    NSDictionary *d = @{ @"query" : query };
    
    [self postAPIResource:@"saved_searches/create.json" parameters:d successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST saved_searches/destroy/:id
- (void)postSavedSearchesDestroy:(NSString *)savedSearchID
                    successBlock:(void(^)(NSDictionary *destroyedSearch))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(savedSearchID);
    
    NSString *resource = [NSString stringWithFormat:@"saved_searches/destroy/%@.json", savedSearchID];
    
    [self postAPIResource:resource parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Places & Geo

// GET geo/id/:place_id
- (void)getGeoIDForPlaceID:(NSString *)placeID // A place in the world. These IDs can be retrieved from geo/reverse_geocode.
              successBlock:(void(^)(NSDictionary *place))successBlock
                errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *resource = [NSString stringWithFormat:@"geo/id/%@.json", placeID];
    
    [self getAPIResource:resource parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET geo/reverse_geocode
- (void)getGeoReverseGeocodeWithLatitude:(NSString *)latitude // eg. "37.7821120598956"
                               longitude:(NSString *)longitude // eg. "-122.400612831116"
                                accuracy:(NSString *)accuracy // eg. "5ft"
                             granularity:(NSString *)granularity // eg. "city"
                              maxResults:(NSString *)maxResults // eg. "3"
                                callback:(NSString *)callback // If supplied, the response will use the JSONP format with a callback of the given name.
                            successBlock:(void(^)(NSDictionary *query, NSDictionary *result))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(latitude);
    NSParameterAssert(longitude);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"lat"] = latitude;
    md[@"long"] = longitude;
    if(accuracy) md[@"accuracy"] = accuracy;
    if(granularity) md[@"granularity"] = granularity;
    if(maxResults) md[@"max_results"] = maxResults;
    if(callback) md[@"callback"] = callback;
    
    [self getAPIResource:@"geo/reverse_geocode.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSDictionary *query = [response valueForKeyPath:@"query"];
        NSDictionary *result = [response valueForKeyPath:@"result"];
        
        successBlock(query, result);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getGeoReverseGeocodeWithLatitude:(NSString *)latitude
                               longitude:(NSString *)longitude
                            successBlock:(void(^)(NSArray *places))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getGeoReverseGeocodeWithLatitude:latitude
                                 longitude:longitude
                                  accuracy:nil
                               granularity:nil
                                maxResults:nil
                                  callback:nil
                              successBlock:^(NSDictionary *query, NSDictionary *result) {
                                  successBlock([result valueForKey:@"places"]);
                              } errorBlock:^(NSError *error) {
                                  errorBlock(error);
                              }];
}

// GET geo/search

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
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(latitude) md[@"lat"] = latitude;
    if(longitude) md[@"long"] = longitude;
    if(query) md[@"query"] = query;
    if(ipAddress) md[@"ip"] = ipAddress;
    if(granularity) md[@"granularity"] = granularity;
    if(accuracy) md[@"accuracy"] = accuracy;
    if(maxResults) md[@"max_results"] = maxResults;
    if(placeIDContaintedWithin) md[@"contained_within"] = placeIDContaintedWithin;
    if(attributeStreetAddress) md[@"attribute:street_address"] = attributeStreetAddress;
    if(callback) md[@"callback"] = callback;
    
    [self getAPIResource:@"geo/reverse_geocode.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSDictionary *query = [response valueForKeyPath:@"query"];
        NSDictionary *result = [response valueForKeyPath:@"result"];
        
        successBlock(query, result);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getGeoSearchWithLatitude:(NSString *)latitude
                       longitude:(NSString *)longitude
                    successBlock:(void(^)(NSArray *places))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(latitude);
    NSParameterAssert(longitude);
    
    [self getGeoSearchWithLatitude:latitude
                         longitude:longitude
                             query:nil
                         ipAddress:nil
                       granularity:nil
                          accuracy:nil
                        maxResults:nil
           placeIDContaintedWithin:nil
            attributeStreetAddress:nil
                          callback:nil
                      successBlock:^(NSDictionary *query, NSDictionary *result) {
                          successBlock([result valueForKey:@"places"]);
                      } errorBlock:^(NSError *error) {
                          errorBlock(error);
                      }];
}

- (void)getGeoSearchWithIPAddress:(NSString *)ipAddress
                     successBlock:(void(^)(NSArray *places))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(ipAddress);
    
    [self getGeoSearchWithLatitude:nil
                         longitude:nil
                             query:nil
                         ipAddress:ipAddress
                       granularity:nil
                          accuracy:nil
                        maxResults:nil
           placeIDContaintedWithin:nil
            attributeStreetAddress:nil
                          callback:nil
                      successBlock:^(NSDictionary *query, NSDictionary *result) {
                          successBlock([result valueForKey:@"places"]);
                      } errorBlock:^(NSError *error) {
                          errorBlock(error);
                      }];
}

- (void)getGeoSearchWithQuery:(NSString *)query
                 successBlock:(void(^)(NSArray *places))successBlock
                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(query);
    
    [self getGeoSearchWithLatitude:nil
                         longitude:nil
                             query:query
                         ipAddress:nil
                       granularity:nil
                          accuracy:nil
                        maxResults:nil
           placeIDContaintedWithin:nil
            attributeStreetAddress:nil
                          callback:nil
                      successBlock:^(NSDictionary *query, NSDictionary *result) {
                          successBlock([result valueForKey:@"places"]);
                      } errorBlock:^(NSError *error) {
                          errorBlock(error);
                      }];
}

// GET geo/similar_places

- (void)getGeoSimilarPlacesToLatitude:(NSString *)latitude // eg. "37.7821120598956"
                            longitude:(NSString *)longitude // eg. "-122.400612831116"
                                 name:(NSString *)name // eg. "Twitter HQ"
              placeIDContaintedWithin:(NSString *)placeIDContaintedWithin // eg. "247f43d441defc03"
               attributeStreetAddress:(NSString *)attributeStreetAddress // eg. "795 Folsom St"
                             callback:(NSString *)callback // If supplied, the response will use the JSONP format with a callback of the given name.
                         successBlock:(void(^)(NSDictionary *query, NSArray *resultPlaces, NSString *resultToken))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(latitude);
    NSParameterAssert(longitude);
    NSParameterAssert(name);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"lat"] = latitude;
    md[@"long"] = longitude;
    md[@"name"] = name;
    if(placeIDContaintedWithin) md[@"contained_within"] = placeIDContaintedWithin;
    if(attributeStreetAddress) md[@"attribute:street_address"] = attributeStreetAddress;
    if(callback) md[@"callback"] = callback;
    
    [self getAPIResource:@"geo/reverse_geocode.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSDictionary *query = [response valueForKey:@"query"];
        NSDictionary *result = [response valueForKey:@"result"];
        NSArray *places = [result valueForKey:@"places"];
        NSString *token = [result valueForKey:@"token"];
        
        successBlock(query, places, token);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST get/place

// WARNING: deprecated since December 2nd, 2013 https://dev.twitter.com/discussions/22452

- (void)postGeoPlaceWithName:(NSString *)name // eg. "Twitter HQ"
     placeIDContaintedWithin:(NSString *)placeIDContaintedWithin // eg. "247f43d441defc03"
           similarPlaceToken:(NSString *)similarPlaceToken // eg. "36179c9bf78835898ebf521c1defd4be"
                    latitude:(NSString *)latitude // eg. "37.7821120598956"
                   longitude:(NSString *)longitude // eg. "-122.400612831116"
      attributeStreetAddress:(NSString *)attributeStreetAddress // eg. "795 Folsom St"
                    callback:(NSString *)callback // If supplied, the response will use the JSONP format with a callback of the given name.
                successBlock:(void(^)(NSDictionary *place))successBlock
                  errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"name"] = name;
    md[@"contained_within"] = placeIDContaintedWithin;
    md[@"token"] = similarPlaceToken;
    md[@"lat"] = latitude;
    md[@"long"] = longitude;
    if(attributeStreetAddress) md[@"attribute:street_address"] = attributeStreetAddress;
    if(callback) md[@"callback"] = callback;
    
    [self postAPIResource:@"get/create.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Trends

// GET trends/place
- (void)getTrendsForWOEID:(NSString *)WOEID // 'Yahoo! Where On Earth ID', Paris is "615702"
          excludeHashtags:(NSNumber *)excludeHashtags
             successBlock:(void(^)(NSDate *asOf, NSDate *createdAt, NSArray *locations, NSArray *trends))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(WOEID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"id"] = WOEID;
    if(excludeHashtags) md[@"exclude"] = [excludeHashtags boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"trends/place.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSDictionary *d = [response lastObject];
        
        NSDate *asOf = nil;
        NSDate *createdAt = nil;
        NSArray *locations = nil;
        NSArray *trends = nil;
        
        if([d isKindOfClass:[NSDictionary class]]) {
            NSString *asOfString = [d valueForKey:@"as_of"];
            NSString *createdAtString = [d valueForKey:@"created_at"];
            
            asOf = [[self dateFormatter] dateFromString:asOfString];
            createdAt = [[self dateFormatter] dateFromString:createdAtString];
            
            locations = [d valueForKey:@"locations"];
            trends = [d valueForKey:@"trends"];
        }
        
        successBlock(asOf, createdAt, locations, trends);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET trends/available
- (void)getTrendsAvailableWithSuccessBlock:(void(^)(NSArray *locations))successBlock
                                errorBlock:(void(^)(NSError *error))errorBlock {
    [self getAPIResource:@"trends/available.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET trends/closest
- (void)getTrendsClosestToLatitude:(NSString *)latitude
                         longitude:(NSString *)longitude
                      successBlock:(void(^)(NSArray *locations))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(latitude);
    NSParameterAssert(longitude);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"lat"] = latitude;
    md[@"long"] = longitude;
    
    [self getAPIResource:@"trends/closest.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Spam Reporting

// POST users/report_spam
- (void)postUsersReportSpamForScreenName:(NSString *)screenName
                                orUserID:(NSString *)userID
                            successBlock:(void(^)(id userProfile))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(screenName || userID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(screenName) md[@"screen_name"] = screenName;
    if(userID) md[@"user_id"] = userID;
    
    [self postAPIResource:@"users/report_spam.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark OAuth

// GET oauth/authenticate
// GET oauth/authorize
// POST oauth/access_token
// POST oauth/request_token
// POST oauth2/token
// POST oauth2/invalidate_token

#pragma mark Help

// GET help/configuration
- (void)getHelpConfigurationWithSuccessBlock:(void(^)(NSDictionary *currentConfiguration))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock {
    [self getAPIResource:@"help/configuration.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET help/languages
- (void)getHelpLanguagesWithSuccessBlock:(void (^)(NSArray *languages))successBlock
                              errorBlock:(void (^)(NSError *))errorBlock {
    [self getAPIResource:@"help/languages.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET help/privacy
- (void)getHelpPrivacyWithSuccessBlock:(void(^)(NSString *tos))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    [self getAPIResource:@"help/privacy.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock([response valueForKey:@"privacy"]);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET help/tos
- (void)getHelpTermsOfServiceWithSuccessBlock:(void(^)(NSString *tos))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    [self getAPIResource:@"help/tos.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock([response valueForKey:@"tos"]);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET application/rate_limit_status
- (void)getRateLimitsForResources:(NSArray *)resources // eg. statuses,friends,trends,help
                     successBlock:(void(^)(NSDictionary *rateLimits))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock {
    NSDictionary *d = nil;
    if (resources)
        d = @{ @"resources" : [resources componentsJoinedByString:@","] };
    [self getAPIResource:@"application/rate_limit_status.json" parameters:d successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

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
                       errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    
    NSParameterAssert(tweetIDs);
    NSAssert(([tweetIDs isKindOfClass:[NSArray class]]), @"tweetIDs must be an array");
    
    md[@"id"] = [tweetIDs componentsJoinedByString:@","];
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"true" : @"false";
    if(trimUser) md[@"trim_user"] = [trimUser boolValue] ? @"1" : @"0";
    if(map) md[@"map"] = [map boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"statuses/lookup.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

#pragma mark Media

- (void)postMediaUpload:(NSURL *)mediaURL
    uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
           successBlock:(void(^)(NSDictionary *imageDictionary, NSString *mediaID, NSString *size))successBlock
             errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSData *data = [NSData dataWithContentsOfURL:mediaURL];
    
    NSString *fileName = [mediaURL isFileURL] ? [[mediaURL path] lastPathComponent] : @"media.jpg";
    
    [self postMediaUploadData:data
                     fileName:fileName
          uploadProgressBlock:uploadProgressBlock
                 successBlock:successBlock
                   errorBlock:errorBlock];
}

- (void)postMediaUploadData:(NSData *)data
                   fileName:(NSString *)fileName
        uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
               successBlock:(void(^)(NSDictionary *imageDictionary, NSString *mediaID, NSString *size))successBlock
                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    // https://dev.twitter.com/docs/api/multiple-media-extended-entities
    
    if(data == nil) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:STTwitterAPIMediaDataIsEmpty userInfo:@{NSLocalizedDescriptionKey : @"data is nil"}];
        errorBlock(error);
        return;
    }
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"media"] = data;
    md[kSTPOSTDataKey] = @"media";
    md[kSTPOSTMediaFileNameKey] = fileName;
    
    [self postResource:@"media/upload.json"
         baseURLString:kBaseURLStringUpload_1_1
            parameters:md
   uploadProgressBlock:uploadProgressBlock
 downloadProgressBlock:nil
          successBlock:^(NSDictionary *rateLimits, id response) {
              
              NSDictionary *imageDictionary = [response valueForKey:@"image"];
              NSString *mediaID = [response valueForKey:@"media_id_string"];
              NSString *size = [response valueForKey:@"size"];
              
              successBlock(imageDictionary, mediaID, size);
          }
            errorBlock:errorBlock];
}

#pragma mark -
#pragma mark UNDOCUMENTED APIs

// GET activity/about_me.json
- (void)_getActivityAboutMeSinceID:(NSString *)sinceID
                             count:(NSString *)count //
                      includeCards:(NSNumber *)includeCards
                      modelVersion:(NSNumber *)modelVersion
                    sendErrorCodes:(NSNumber *)sendErrorCodes
                contributorDetails:(NSNumber *)contributorDetails
                   includeEntities:(NSNumber *)includeEntities
                  includeMyRetweet:(NSNumber *)includeMyRetweet
                      successBlock:(void(^)(NSArray *activities))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(sinceID) md[@"since_id"] = sinceID;
    if(count) md[@"count"] = count;
    if(contributorDetails) md[@"contributor_details"] = [contributorDetails boolValue] ? @"1" : @"0";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"true" : @"false";
    if(includeMyRetweet) md[@"include_my_retweet"] = [includeMyRetweet boolValue] ? @"1" : @"0";
    if(includeCards) md[@"include_cards"] = [includeCards boolValue] ? @"1" : @"0";
    if(modelVersion) md[@"model_version"] = [modelVersion boolValue] ? @"true" : @"false";
    if(sendErrorCodes) md[@"send_error_codes"] = [sendErrorCodes boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"activity/about_me.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

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
                          errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(sinceID) md[@"since_id"] = sinceID;
    if(count) md[@"count"] = count;
    if(includeCards) md[@"include_cards"] = [includeCards boolValue] ? @"1" : @"0";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"true" : @"false";
    if(includeMyRetweets) md[@"include_my_retweet"] = [includeMyRetweets boolValue] ? @"true" : @"false";
    if(includeUserEntites) md[@"include_user_entities"] = [includeUserEntites boolValue] ? @"1" : @"0";
    if(latestResults) md[@"latest_results"] = [latestResults boolValue] ? @"true" : @"false";
    if(sendErrorCodes) md[@"send_error_codes"] = [sendErrorCodes boolValue] ? @"1" : @"0";
    
    [self getAPIResource:@"activity/by_friends.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET statuses/:id/activity/summary.json
- (void)_getStatusesActivitySummaryForStatusID:(NSString *)statusID
                                  successBlock:(void(^)(NSArray *favoriters, NSArray *repliers, NSArray *retweeters, NSString *favoritersCount, NSString *repliersCount, NSString *retweetersCount))successBlock
                                    errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *resource = [NSString stringWithFormat:@"statuses/%@/activity/summary.json", statusID];
    
    [self getAPIResource:resource parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSArray *favoriters = [response valueForKey:@"favoriters"];
        NSArray *repliers = [response valueForKey:@"repliers"];
        NSArray *retweeters = [response valueForKey:@"retweeters"];
        NSString *favoritersCount = [response valueForKey:@"favoriters_count"];
        NSString *repliersCount = [response valueForKey:@"repliers_count"];
        NSString *retweetersCount = [response valueForKey:@"retweeters_count"];
        
        successBlock(favoriters, repliers, retweeters, favoritersCount, repliersCount, retweetersCount);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET conversation/show.json
- (void)_getConversationShowForStatusID:(NSString *)statusID
                           successBlock:(void(^)(NSArray *statuses))successBlock
                             errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(statusID);
    
    NSDictionary *d = @{@"id":statusID};
    
    [self getAPIResource:@"conversation/show.json" parameters:d successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET discover/highlight.json
- (void)_getDiscoverHighlightWithSuccessBlock:(void(^)(NSDictionary *metadata, NSArray *modules))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getAPIResource:@"discover/highlight.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSDictionary *metadata = [response valueForKey:@"metadata"];
        NSArray *modules = [response valueForKey:@"modules"];
        
        successBlock(metadata, modules);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET discover/universal.json
- (void)_getDiscoverUniversalWithSuccessBlock:(void(^)(NSDictionary *metadata, NSArray *modules))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getAPIResource:@"discover/universal.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        
        NSDictionary *metadata = [response valueForKey:@"metadata"];
        NSArray *modules = [response valueForKey:@"modules"];
        
        successBlock(metadata, modules);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET statuses/media_timeline.json
- (void)_getMediaTimelineWithSuccessBlock:(void(^)(NSArray *statuses))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getAPIResource:@"statuses/media_timeline.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET users/recommendations.json
- (void)_getUsersRecommendationsWithSuccessBlock:(void(^)(NSArray *recommendations))successBlock
                                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getAPIResource:@"users/recommendations.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET timeline/home.json
- (void)_getTimelineHomeWithSuccessBlock:(void(^)(id response))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getAPIResource:@"timeline/home.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET statuses/mentions_timeline.json
- (void)_getStatusesMentionsTimelineWithCount:(NSString *)count
                          contributorsDetails:(NSNumber *)contributorsDetails
                              includeEntities:(NSNumber *)includeEntities
                             includeMyRetweet:(NSNumber *)includeMyRetweet
                                 successBlock:(void(^)(NSArray *statuses))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(count) md[@"count"] = count;
    if(contributorsDetails) md[@"contributor_details"] = [contributorsDetails boolValue] ? @"1" : @"0";
    if(includeEntities) md[@"include_entities"] = [includeEntities boolValue] ? @"true" : @"false";
    if(includeMyRetweet) md[@"include_my_retweet"] = [includeMyRetweet boolValue] ? @"true" : @"false";
    
    [self getAPIResource:@"statuses/mentions_timeline.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET trends/available.json
- (void)_getTrendsAvailableWithSuccessBlock:(void(^)(NSArray *places))successBlock
                                 errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self getAPIResource:@"trends/available.json" parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// POST users/report_spam
- (void)_postUsersReportSpamForTweetID:(NSString *)tweetID
                              reportAs:(NSString *)reportAs // spam, abused, compromised
                             blockUser:(NSNumber *)blockUser
                          successBlock:(void(^)(id userProfile))successBlock
                            errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(tweetID);
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"tweet_id"] = tweetID;
    if(reportAs) md[@"report_as"] = reportAs;
    if(blockUser) md[@"block_user"] = [blockUser boolValue] ? @"true" : @"false";
    
    [self postAPIResource:@"users/report_spam.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

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
                         errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"adc"] = adc;
    md[@"discoverable_by_email"] = discoverableByEmail ? @"1" : @"0";
    md[@"email"] = email;
    md[@"geo_enabled"] = geoEnabled ? @"1" : @"0";
    md[@"lang"] = language;
    md[@"name"] = name;
    md[@"password"] = password;
    md[@"screen_name"] = screenName;
    md[@"send_error_codes"] = sendErrorCode ? @"1": @"0";
    md[@"time_zone"] = timeZone;
    
    [self postResource:@"account/generate.json"
         baseURLString:@"https://api.twitter.com/1"
            parameters:md
   uploadProgressBlock:nil
 downloadProgressBlock:^(id json) {
     //
 } successBlock:^(NSDictionary *rateLimits, id response) {
     successBlock(response);
 } errorBlock:^(NSError *error) {
     errorBlock(error);
 }];
}

// GET search/typeahead.json
- (void)_getSearchTypeaheadQuery:(NSString *)query
                      resultType:(NSString *)resultType // "all"
                  sendErrorCodes:(NSNumber *)sendErrorCodes
                    successBlock:(void(^)(id results))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"q"] = query;
    if(resultType) md[@"result_type"] = resultType;
    if(sendErrorCodes) md[@"send_error_codes"] = @([sendErrorCodes boolValue]);
    
    [self getAPIResource:@"search/typeahead.json" parameters:md successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

// GET conversation/show/:id.json
- (void)_getConversationShowWithTweetID:(NSString *)tweetID
                           successBlock:(void(^)(id results))successBlock
                      errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSParameterAssert(tweetID);
    
    NSString *ressource = [NSString stringWithFormat:@"conversation/show/%@.json", tweetID];
    
    [self getAPIResource:ressource parameters:nil successBlock:^(NSDictionary *rateLimits, id response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

@end

@implementation NSString (STTwitterAPI)

- (NSString *)htmlLinkName {
    NSString *ahref = [self st_firstMatchWithRegex:@"<a href=\".*\">(.*)</a>" error:nil];
    
    return ahref ? ahref : self;
}

@end
