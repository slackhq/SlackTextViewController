//
//  STTwitterOSRequest.h
//  STTwitterDemoOSX
//
//  Created by Nicolas Seriot on 20/02/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACAccount;

@interface STTwitterOSRequest : NSObject <NSURLConnectionDelegate>

- (id)initWithAPIResource:(NSString *)resource
            baseURLString:(NSString *)baseURLString
               httpMethod:(NSInteger)httpMethod
               parameters:(NSDictionary *)params
                  account:(ACAccount *)account
      uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
          completionBlock:(void(^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id response))completionBlock
               errorBlock:(void(^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock;

- (NSURLConnection *)startRequest;

@end
