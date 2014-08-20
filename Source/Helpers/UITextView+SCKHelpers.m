//
//  UITextView+SCKHelpers.m
//  Slack
//
//  Created by Ignacio on 8/19/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "UITextView+SCKHelpers.h"

@implementation UITextView (SCKHelpers)

- (void)scrollRangeToBottom
{
    NSUInteger lenght = self.text.length;
    
    if (lenght > 0) {
        NSRange bottom = NSMakeRange(lenght-1.0, 1.0);
        [self scrollRangeToVisible:bottom];
    }
}

@end
