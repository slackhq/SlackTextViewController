//
//  UIView+SCKHelpers.h
//  Slack
//
//  Created by Ignacio on 8/20/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (SCKHelpers)

/**
 
 */
- (void)animateLayoutIfNeeded:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations;

/**
 
 */
- (void)animateLayoutIfNeededWithDuration:(NSTimeInterval)duration bounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations;

@end
