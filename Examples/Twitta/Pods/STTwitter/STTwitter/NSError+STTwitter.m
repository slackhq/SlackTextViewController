//
//  NSError+STTwitter.m
//  STTwitterDemoOSX
//
//  Created by Nicolas Seriot on 19/03/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import "NSError+STTwitter.h"

@implementation NSError (STTwitter)

+ (NSError *)st_twitterErrorFromResponseData:(NSData *)responseData
                             responseHeaders:(NSDictionary *)responseHeaders
                             underlyingError:(NSError *)underlyingError {
    
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
    
    NSString *message = nil;
    NSInteger code = 0;
    
    if([json isKindOfClass:[NSDictionary class]]) {
        id errors = [json valueForKey:@"errors"];
        if([errors isKindOfClass:[NSArray class]] && [(NSArray *)errors count] > 0) {
            // assume format: {"errors":[{"message":"Sorry, that page does not exist","code":34}]}
            NSDictionary *errorDictionary = [errors lastObject];
            if([errorDictionary isKindOfClass:[NSDictionary class]]) {
                message = errorDictionary[@"message"];
                code = [[errorDictionary valueForKey:@"code"] integerValue];
            }
        } else if ([json valueForKey:@"error"]) {
            /*
             eg. when requesting timeline from a protected account
             {
             error = "Not authorized.";
             request = "/1.1/statuses/user_timeline.json?count=20&screen_name=premfe";
             }
             */
            message = [json valueForKey:@"error"];
        } else if([errors isKindOfClass:[NSString class]]) {
            // assume format {errors = "Screen name can't be blank";}
            message = errors;
        }
    }
    
    if(message) {
        NSString *rateLimitLimit = [responseHeaders valueForKey:@"x-rate-limit-limit"];
        NSString *rateLimitRemaining = [responseHeaders valueForKey:@"x-rate-limit-remaining"];
        NSString *rateLimitReset = [responseHeaders valueForKey:@"x-rate-limit-reset"];
        
        NSDate *rateLimitResetDate = rateLimitReset ? [NSDate dateWithTimeIntervalSince1970:[rateLimitReset doubleValue]] : nil;
        
        NSMutableDictionary *md = [NSMutableDictionary dictionary];
        md[NSLocalizedDescriptionKey] = message;
        if(underlyingError) md[NSUnderlyingErrorKey] = underlyingError;
        if(rateLimitLimit) md[kSTTwitterRateLimitLimit] = rateLimitLimit;
        if(rateLimitRemaining) md[kSTTwitterRateLimitRemaining] = rateLimitRemaining;
        if(rateLimitResetDate) md[kSTTwitterRateLimitResetDate] = rateLimitResetDate;
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithDictionary:md];
        
        return [NSError errorWithDomain:kSTTwitterTwitterErrorDomain code:code userInfo:userInfo];
    }
    
    return nil;
}

@end
