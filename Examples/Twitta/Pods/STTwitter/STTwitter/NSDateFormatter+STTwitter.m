//
//  NSDateFormatter+STTwitter.m
//  curtter
//
//  Created by Nicolas Seriot on 16/11/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "NSDateFormatter+STTwitter.h"

static NSDateFormatter *stTwitterDateFormatter = nil;

@implementation NSDateFormatter (STTwitter)

+ (NSDateFormatter *)st_TwitterDateFormatter {

    // parses the 'created_at' field, eg. "Sun Jun 28 20:33:01 +0000 2009"
    
    if(stTwitterDateFormatter == nil) {
        stTwitterDateFormatter = [[NSDateFormatter alloc] init];
        [stTwitterDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [stTwitterDateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    }
    
    return stTwitterDateFormatter;
}

@end
