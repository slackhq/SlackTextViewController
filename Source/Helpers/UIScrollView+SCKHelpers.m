//
//  UIScrollView+SCKHelpers.m
//  Slack
//
//  Created by Ignacio on 8/19/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "UIScrollView+SCKHelpers.h"

@implementation UIScrollView (SCKHelpers)

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if ([self canScrollToBottom] && ![self isAtBottom]) {
        CGPoint bottomOffset = CGPointMake(0.0, self.contentSize.height - self.bounds.size.height);
        [self setContentOffset:bottomOffset animated:YES];
    }
}

- (BOOL)isAtTop
{
    return (self.contentOffset.y == 0.0) ? YES : NO;
}

- (BOOL)isAtBottom
{
    CGFloat bottomOffset = self.contentSize.height-self.bounds.size.height;
    return (self.contentOffset.y == bottomOffset) ? YES : NO;
}

- (BOOL)canScrollToBottom
{
    if (self.contentSize.height > self.bounds.size.height) {
        return YES;
    }
    return NO;
}

@end
