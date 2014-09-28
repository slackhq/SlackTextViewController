//
//  STTwitterAppOnly.m
//  STTwitter
//
//  Created by Nicolas Seriot on 3/13/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "STTwitterAppOnly.h"
#import "STHTTPRequest.h"
#import "NSString+STTwitter.h"
#import "STHTTPRequest+STTwitter.h"

@interface NSData (Base64)
- (NSString *)base64Encoding; // private API
@end

@implementation STTwitterAppOnly

- (id)init {
    self = [super init];
    
    // TODO: remove cookies from Twitter if needed
    
    return self;
}

+ (instancetype)twitterAppOnlyWithConsumerName:(NSString *)consumerName consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    STTwitterAppOnly *twitterAppOnly = [[[self class] alloc] init];
    twitterAppOnly.consumerName = consumerName;
    twitterAppOnly.consumerKey = consumerKey;
    twitterAppOnly.consumerSecret = consumerSecret;
    return twitterAppOnly;
}

#pragma mark STTwitterOAuthProtocol

- (BOOL)canVerifyCredentials {
    return YES;
}

- (NSString *)oauthAccessToken {
    return nil;
}

- (NSString *)oauthAccessTokenSecret {
    return nil;
}

- (void)invalidateBearerTokenWithSuccessBlock:(void(^)())successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    if(_bearerToken == nil) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:STTwitterAppOnlyCannotFindBearerTokenToBeInvalidated userInfo:@{NSLocalizedDescriptionKey : @"Cannot invalidate missing bearer token"}];
        errorBlock(error);
        return;
    }
    
    [self postResource:@"oauth2/invalidate_token"
         baseURLString:@"https://api.twitter.com"
            parameters:@{ @"access_token" : _bearerToken }
          useBasicAuth:YES
   uploadProgressBlock:nil
 downloadProgressBlock:nil
          successBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
              
              if([json isKindOfClass:[NSDictionary class]] == NO) {
                  successBlock(json);
                  return;
              }
              
              self.bearerToken = [json valueForKey:@"access_token"];
              
              NSString *oldToken = self.bearerToken;
              
              self.bearerToken = nil;
              
              successBlock(oldToken);
              
          } errorBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
              errorBlock(error);
          }];
    
    // POST /oauth2/invalidate_token HTTP/1.1
    // Authorization: Basic eHZ6MWV2RlM0d0VFUFRHRUZQSEJvZzpMOHFxOVBaeVJn
    // NmllS0dFS2hab2xHQzB2SldMdzhpRUo4OERSZHlPZw==
    // User-Agent: My Twitter App v1.0.23
    // Host: api.twitter.com
    // Accept: */*
    //
    // Content-Length: 119
    // Content-Type: application/x-www-form-urlencoded
    //
    // access_token=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    
    // HTTP/1.1 200 OK
    // Content-Type: application/json; charset=utf-8
    // Content-Length: 127
    // ...
    //
    // {"access_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}
}

+ (NSString *)base64EncodedBearerTokenCredentialsWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    NSString *encodedConsumerToken = [consumerKey st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedConsumerSecret = [consumerSecret st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *bearerTokenCredentials = [NSString stringWithFormat:@"%@:%@", encodedConsumerToken, encodedConsumerSecret];
    NSData *data = [bearerTokenCredentials dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64Encoding];
}

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postResource:@"oauth2/token"
         baseURLString:@"https://api.twitter.com"
            parameters:@{ @"grant_type" : @"client_credentials" }
          useBasicAuth:YES
   uploadProgressBlock:nil
 downloadProgressBlock:nil
          successBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
              
              if([json isKindOfClass:[NSDictionary class]] == NO) {
                  NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:STTwitterAppOnlyCannotFindJSONInResponse userInfo:@{NSLocalizedDescriptionKey : @"Cannot find JSON dictionary in response"}];
                  errorBlock(error);
                  return;
              }
              
              NSString *tokenType = [json valueForKey:@"token_type"];
              if([tokenType isEqualToString:@"bearer"] == NO) {
                  NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:STTwitterAppOnlyCannotFindBearerTokenInResponse userInfo:@{NSLocalizedDescriptionKey : @"Cannot find bearer token in server response"}];
                  errorBlock(error);
                  return;
              }
              
              self.bearerToken = [json valueForKey:@"access_token"];
              
              successBlock(_bearerToken);
              
          } errorBlock:^(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
              errorBlock(error);
          }];
}

- (STHTTPRequest *)getResource:(NSString *)resource
                 baseURLString:(NSString *)baseURLString // no trailing slash
                    parameters:(NSDictionary *)params
                 progressBlock:(void(^)(STHTTPRequest *r, id json))progressBlock
                  successBlock:(void (^)(STHTTPRequest *r, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
                    errorBlock:(void (^)(STHTTPRequest *r, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    /*
     GET /1.1/statuses/user_timeline.json?count=100&screen_name=twitterapi HTTP/1.1
     Host: api.twitter.com
     User-Agent: My Twitter App v1.0.23
     Authorization: Bearer AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAA
     AAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
     Accept-Encoding: gzip
     */
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@", baseURLString, resource];
    
    NSMutableArray *parameters = [NSMutableArray array];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *s = [NSString stringWithFormat:@"%@=%@", key, obj];
        [parameters addObject:s];
    }];
    
    if([parameters count]) {
        NSString *parameterString = [parameters componentsJoinedByString:@"&"];
        
        [urlString appendFormat:@"?%@", parameterString];
    }
    
    //    NSString *requestID = [[NSUUID UUID] UUIDString];
    
    __block STHTTPRequest *r = [STHTTPRequest twitterRequestWithURLString:urlString
                                             stTwitterUploadProgressBlock:nil
                                           stTwitterDownloadProgressBlock:^(id json) {
                                               if(progressBlock) progressBlock(r, json);
                                           } stTwitterSuccessBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
                                               successBlock(r, requestHeaders, responseHeaders, json);
                                           } stTwitterErrorBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
                                               errorBlock(r, requestHeaders, responseHeaders, error);
                                           }];
    if(_bearerToken) {
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _bearerToken]];
    }
    
    [r startAsynchronous];
    
    return r;
}

- (id)fetchResource:(NSString *)resource
         HTTPMethod:(NSString *)HTTPMethod
      baseURLString:(NSString *)baseURLString
         parameters:(NSDictionary *)params
uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void(^)(id r, id json))downloadProgressBlock
       successBlock:(void(^)(id r, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
         errorBlock:(void(^)(id r, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    if([baseURLString hasSuffix:@"/"]) {
        baseURLString = [baseURLString substringToIndex:[baseURLString length]-1];
    }
    
    if([HTTPMethod isEqualToString:@"GET"]) {
        
        return [self getResource:resource
                   baseURLString:baseURLString
                      parameters:params
                   progressBlock:downloadProgressBlock
                    successBlock:successBlock
                      errorBlock:errorBlock];
        
    } else if ([HTTPMethod isEqualToString:@"POST"]) {
        
        return [self postResource:resource
                    baseURLString:baseURLString
                       parameters:params
              uploadProgressBlock:uploadProgressBlock
            downloadProgressBlock:downloadProgressBlock
                     successBlock:successBlock
                       errorBlock:errorBlock];
        
    } else {
        NSAssert(NO, @"unsupported HTTP method");
        return nil;
    }
}

- (id)postResource:(NSString *)resource
     baseURLString:(NSString *)baseURLString // no trailing slash
        parameters:(NSDictionary *)params
      useBasicAuth:(BOOL)useBasicAuth
uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void(^)(id request, id json))downloadProgressBlock
      successBlock:(void(^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
        errorBlock:(void(^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", baseURLString, resource];
    
    __block STHTTPRequest *r = [STHTTPRequest twitterRequestWithURLString:urlString
                                             stTwitterUploadProgressBlock:uploadProgressBlock
                                           stTwitterDownloadProgressBlock:^(id json) {
                                               if(downloadProgressBlock) downloadProgressBlock(r, json);
                                           } stTwitterSuccessBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
                                               successBlock(r, requestHeaders, responseHeaders, json);
                                           } stTwitterErrorBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
                                               errorBlock(r, requestHeaders, responseHeaders, error);
                                           }];
    
    r.POSTDictionary = params;
    
    NSMutableDictionary *mutableParams = [params mutableCopy];
    
    r.encodePOSTDictionary = NO;
    
    r.POSTDictionary = mutableParams ? mutableParams : @{};
    
    if(useBasicAuth) {
        NSString *base64EncodedTokens = [[self class] base64EncodedBearerTokenCredentialsWithConsumerKey:_consumerKey consumerSecret:_consumerSecret];
        
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", base64EncodedTokens]];
    } else if(_bearerToken) {
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _bearerToken]];
        r.encodePOSTDictionary = YES;
    }
    
    [r startAsynchronous];
    
    return r;
}

- (STHTTPRequest *)postResource:(NSString *)resource
                  baseURLString:(NSString *)baseURLString
                     parameters:(NSDictionary *)params
            uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
          downloadProgressBlock:(void(^)(id r, id json))downloadProgressBlock
                   successBlock:(void(^)(id r, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
                     errorBlock:(void(^)(id r, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    return [self postResource:resource
                baseURLString:baseURLString
                   parameters:params
                 useBasicAuth:NO
          uploadProgressBlock:uploadProgressBlock
        downloadProgressBlock:downloadProgressBlock
                 successBlock:successBlock
                   errorBlock:errorBlock];
}

- (NSString *)loginTypeDescription {
    return @"App Only";
}

@end
