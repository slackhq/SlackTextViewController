//
//  UIScrollView+ChatKitAdditions.m
//  Slack
//
//  Created by Ignacio Romero Zurbuchen on 8/19/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "UIScrollView+ChatKitAdditions.h"
#import <objc/runtime.h>

static NSString * const kKeyScrollViewVerticalIndicator = @"_verticalScrollIndicator";
static NSString * const kKeyScrollViewHorizontalIndicator = @"_horizontalScrollIndicator";

@implementation UIScrollView (ChatKitAdditions)

- (void)scrollToTopAnimated:(BOOL)animated
{
    if (![self isAtTop]) {
        CGPoint bottomOffset = CGPointZero;
        [self setContentOffset:bottomOffset animated:animated];
    }
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if ([self canScrollToBottom] && ![self isAtBottom]) {
        CGPoint bottomOffset = CGPointMake(0.0, self.contentSize.height - self.bounds.size.height);
        [self setContentOffset:bottomOffset animated:animated];
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

- (void)stopScrolling
{
    if (!self.isDragging) {
        return;
    }
    
    CGPoint offset = self.contentOffset;
    offset.y -= 1.0;
    [self setContentOffset:offset animated:NO];
    
    offset.y += 1.0;
    [self setContentOffset:offset animated:NO];
}

- (UIView *)verticalScroller
{
    if (objc_getAssociatedObject(self, _cmd) == nil) {
        objc_setAssociatedObject(self, _cmd, [self safeValueForKey:kKeyScrollViewVerticalIndicator], OBJC_ASSOCIATION_ASSIGN);
    }
    
    return objc_getAssociatedObject(self, _cmd);
}

- (UIView *)horizontalScroller
{
    if (objc_getAssociatedObject(self, _cmd) == nil) {
        objc_setAssociatedObject(self, _cmd, [self safeValueForKey:kKeyScrollViewHorizontalIndicator], OBJC_ASSOCIATION_ASSIGN);
    }
    
    return objc_getAssociatedObject(self, _cmd);
}

- (id)safeValueForKey:(NSString *)key
{
    Ivar instanceVariable = class_getInstanceVariable([self class], [key cStringUsingEncoding:NSUTF8StringEncoding]);
    return object_getIvar(self, instanceVariable);
}

@end
