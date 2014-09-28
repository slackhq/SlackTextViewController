//
//  STTwitterAppOnly.h
//  STTwitter
//
//  Created by Nicolas Seriot on 3/13/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STTwitterProtocol.h"

#if DEBUG
#   define STLog(...) NSLog(__VA_ARGS__)
#else
#   define STLog(...)
#endif

NS_ENUM(NSUInteger, STTwitterAppOnlyErrorCode) {
    STTwitterAppOnlyCannotFindBearerTokenToBeInvalidated,
    STTwitterAppOnlyCannotFindJSONInResponse,
    STTwitterAppOnlyCannotFindBearerTokenInResponse
};

@interface STTwitterAppOnly : NSObject <STTwitterProtocol> {
    
}

@property (nonatomic, retain) NSString *consumerName;
@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *consumerSecret;
@property (nonatomic, retain) NSString *bearerToken;

+ (instancetype)twitterAppOnlyWithConsumerName:(NSString *)conumerName consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

+ (NSString *)base64EncodedBearerTokenCredentialsWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

- (void)invalidateBearerTokenWithSuccessBlock:(void(^)())successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

@end
