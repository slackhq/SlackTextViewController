//
//  STHTTPRequest+STTwitter.m
//  STTwitter
//
//  Created by Nicolas Seriot on 8/6/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "STHTTPRequest+STTwitter.h"
#import "NSString+STTwitter.h"
#import "NSError+STTwitter.h"

#if DEBUG
#   define STLog(...) NSLog(__VA_ARGS__)
#else
#   define STLog(...)
#endif

@implementation STHTTPRequest (STTwitter)

+ (STHTTPRequest *)twitterRequestWithURLString:(NSString *)urlString
                  stTwitterUploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
                stTwitterDownloadProgressBlock:(void(^)(id json))downloadProgressBlock
                         stTwitterSuccessBlock:(void(^)(NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
                           stTwitterErrorBlock:(void(^)(NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    __block STHTTPRequest *r = [self requestWithURLString:urlString];
    __weak STHTTPRequest *wr = r;
    
    r.ignoreSharedCookiesStorage = YES;
    
    r.timeoutSeconds = DBL_MAX;
    
    r.uploadProgressBlock = uploadProgressBlock;
    
    r.downloadProgressBlock = ^(NSData *data, NSUInteger totalBytesReceived, long long totalBytesExpectedToReceive) {
        
        if(downloadProgressBlock == nil) return;
        
        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        
        if(json) {
            downloadProgressBlock(json);
            return;
        }
        
        // we can receive several dictionaries in the same data chunk
        // such as '{..}\r\n{..}\r\n{..}' which is not valid JSON
        // so we split them up into a 'jsonChunks' array such as [{..},{..},{..}]
        
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSArray *jsonChunks = [jsonString componentsSeparatedByString:@"\r\n"];
        
        for(NSString *jsonChunk in jsonChunks) {
            if([jsonChunk length] == 0) continue;
            NSData *data = [jsonChunk dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonError = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if(json == nil) {
                //                errorBlock(wr.responseHeaders, jsonError);
                return; // not enough information to say it's an error
            }
            downloadProgressBlock(json);
        }
    };
    
    r.completionDataBlock = ^(NSDictionary *responseHeaders, NSData *responseData) {
        
        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
        
        if(json == nil) {
            successBlock(wr.requestHeaders, wr.responseHeaders, wr.responseString); // response is not necessarily json
            return;
        }
        
        successBlock(wr.requestHeaders, wr.responseHeaders, json);
    };
    
    r.errorBlock = ^(NSError *error) {
        
        NSError *e = [NSError st_twitterErrorFromResponseData:wr.responseData responseHeaders:wr.responseHeaders underlyingError:error];
        if(e) {
            errorBlock(wr.requestHeaders, wr.responseHeaders, e);
            return;
        }

        if(error) {
            errorBlock(wr.requestHeaders, wr.responseHeaders, error);
            return;
        }
        
        e = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:@{NSLocalizedDescriptionKey : wr.responseString}];
        
        if (wr.responseString) STLog(@"-- body: %@", wr.responseString);
        
        //        BOOL isCancellationError = [[error domain] isEqualToString:@"STHTTPRequest"] && ([error code] == kSTHTTPRequestCancellationError);
        //        if(isCancellationError) return;
        
        errorBlock(wr.requestHeaders, wr.responseHeaders, error);
    };
    
    return r;
}

+ (void)expandedURLStringForShortenedURLString:(NSString *)urlString
                                  successBlock:(void(^)(NSString *expandedURLString))successBlock
                                    errorBlock:(void(^)(NSError *error))errorBlock {
    
    STHTTPRequest *r = [STHTTPRequest requestWithURLString:urlString];
    
    r.ignoreSharedCookiesStorage = YES;
    r.preventRedirections = YES;
    
    r.completionBlock = ^(NSDictionary *responseHeaders, NSString *body) {
        
        NSString *location = [responseHeaders valueForKey:@"location"];
        if(location == nil) [responseHeaders valueForKey:@"Location"];
        
        successBlock(location);
    };
    
    r.errorBlock = ^(NSError *error) {
        errorBlock(error);
    };
    
    [r startAsynchronous];
}

@end
