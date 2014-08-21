//
//  UIView+SCKHelpers.m
//  Slack
//
//  Created by Ignacio on 8/20/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "UIView+SCKHelpers.h"

@implementation UIView (SCKHelpers)

- (void)animateLayoutIfNeeded:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations
{
    NSTimeInterval duration = bounce ? 0.5 : 0.2;
    [self animateLayoutIfNeededWithDuration:duration bounce:bounce curve:curve animations:animations];
}

- (void)animateLayoutIfNeededWithDuration:(NSTimeInterval)duration bounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations
{
    CGFloat damping = bounce ? 0.7 : 1.0;
    CGFloat velocity = bounce ? 0.7 : 0.0;
    
    [UIView animateWithDuration:duration
                          delay:0.0
         usingSpringWithDamping:damping
          initialSpringVelocity:velocity
                        options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         [self layoutIfNeeded];
                         
                         if (animations) {
                             animations();
                         }
                     }
                     completion:NULL];
}

@end
