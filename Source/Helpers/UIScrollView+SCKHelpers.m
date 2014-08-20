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
    CGPoint bottomOffset = CGPointMake(0, self.contentSize.height - self.bounds.size.height);
    [self setContentOffset:bottomOffset animated:YES];
}

- (BOOL)isAtTop
{
    return (self.contentOffset.y <= 0) ? YES : NO;
}

- (BOOL)isAtBottom
{
//    CGPoint offset = self.contentOffset;
//    CGRect bounds = self.bounds;
//    CGSize size = self.contentSize;
//    UIEdgeInsets inset = self.contentInset;
//    float y = offset.y + bounds.size.height - inset.bottom;
//    float h = size.height;
//    
//    NSLog(@"y : %f", y);
//    NSLog(@"h : %f", h);
//
//    if (y >= h) {
//        NSLog(@"At the bottom...");
//    }
//    
//    return (y >= h) ? YES : NO;
    
    NSLog(@"self.bounds : %@", NSStringFromCGRect(self.bounds));
    return (self.contentOffset.y >= self.contentSize.height-self.bounds.size.height) ? YES : NO;
}


@end
