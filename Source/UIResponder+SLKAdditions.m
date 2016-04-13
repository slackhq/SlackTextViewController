//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "UIResponder+SLKAdditions.h"

static __weak id ___currentFirstResponder;

@implementation UIResponder (SLKAdditions)

/**
 Based on Jakob Egger's answer in http://stackoverflow.com/a/14135456/590010
 */
+ (instancetype)slk_currentFirstResponder
{
    ___currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(slk_findFirstResponder:) to:nil from:nil forEvent:nil];
    
    return ___currentFirstResponder;
}

- (void)slk_findFirstResponder:(id)sender
{
    ___currentFirstResponder = self;
}

@end
