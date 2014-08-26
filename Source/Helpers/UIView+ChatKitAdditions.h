//
//  UIView+ChatKitAdditions.h
//  Slack
//
//  Created by Ignacio Romero Z. on 8/20/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ChatKitAdditions)

/**
 Animates the view's constraints by calling layoutIfNeeded.
 
 @param bounce YES if the animation should use spring damping and velocity to give a bouncy effect to animations.
 @param curve The animation curve.
 @param animations An additional block for custom animations.
 */
- (void)animateLayoutIfNeededWithBounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations;

/**
 Animates the view's constraints by calling layoutIfNeeded.
 
 @param duration The total duration of the animations, measured in seconds.
 @param bounce YES if the animation should use spring damping and velocity to give a bouncy effect to animations.
 @param curve The animation curve.
 @param animations An additional block for custom animations.
 */
- (void)animateLayoutIfNeededWithDuration:(NSTimeInterval)duration bounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations;

/**
 Returns the view constraints matching a specific layout attribute (top, bottom, left, right, leading, trailing, etc.)
 
 @param attribute The layout attribute to use for searching.
 @return An array of matching constraints.
 */
- (NSArray *)constraintsForAttribute:(NSLayoutAttribute)attribute;

@end
