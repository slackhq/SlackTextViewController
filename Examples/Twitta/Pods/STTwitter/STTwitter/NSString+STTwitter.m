//
//  NSString+STTwitter.m
//  STTwitter
//
//  Created by Nicolas Seriot on 11/2/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import "NSString+STTwitter.h"

NSUInteger kSTTwitterDefaultShortURLLength = 22;
NSUInteger kSTTwitterDefaultShortURLLengthHTTPS = 23;

NSString *kSTPOSTDataKey = @"kSTPOSTDataKey";
NSString *kSTPOSTMediaFileNameKey = @"kSTPOSTMediaFileNameKey";

@implementation NSString (STTwitter)

- (NSString *)st_firstMatchWithRegex:(NSString *)regex error:(NSError **)e {
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:&error];
    
    if(re == nil) {
        if(e) *e = error;
        return nil;
    }
    
    NSArray *matches = [re matchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    if([matches count] == 0) {
        NSString *errorDescription = [NSString stringWithFormat:@"Can't find a match for regex: %@", regex];
        if(e) *e = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
        return nil;
    }
    
    NSTextCheckingResult *match = [matches lastObject];
    NSRange matchRange = [match rangeAtIndex:1];
    return [self substringWithRange:matchRange];
}

// use values from GET help/configuration
- (NSInteger)st_numberOfCharactersInATweetWithShortURLLength:(NSUInteger)shortURLLength shortURLLengthHTTPS:(NSUInteger)shortURLLengthHTTPS {
    
    // NFC normalized string https://dev.twitter.com/docs/counting-characters
    NSString *s = [self precomposedStringWithCanonicalMapping];
    
    NSInteger count = [s length];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(https?://[A-Za-z0-9_\\.\\-/]+)"
                                                                           options:0
                                                                             error:&error];
    
    NSArray *matches = [regex matchesInString:s
                                      options:0
                                        range:NSMakeRange(0, [s length])];
    
    for (NSTextCheckingResult *match in matches) {
        NSRange urlRange = [match rangeAtIndex:1];
        NSString *urlString = [s substringWithRange:urlRange];
        
        count -= urlRange.length;
        count += [urlString hasPrefix:@"https"] ? shortURLLengthHTTPS : shortURLLength;
    }
    
    return count;
}

// use default values for URL shortening
- (NSInteger)st_numberOfCharactersInATweet {
    return [self st_numberOfCharactersInATweetWithShortURLLength:kSTTwitterDefaultShortURLLength
                                             shortURLLengthHTTPS:kSTTwitterDefaultShortURLLengthHTTPS];
}

@end
