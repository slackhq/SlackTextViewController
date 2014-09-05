//
//  UIView+ChatKitAdditions.m
//  SlackChatKit
//  https://github.com/tinyspeck/slack-chat-kit
//
//  Created by Ignacio Romero Zurbuchen on 8/20/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//  Licence: MIT-Licence
//

#import "UIView+ChatKitAdditions.h"

@implementation UIView (ChatKitAdditions)

CGRect adjustEndFrame(CGRect endFrame, UIInterfaceOrientation orientation) {
    
    // Inverts the end rect for landscape orientation
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        endFrame = CGRectMake(0.0, endFrame.origin.x, endFrame.size.height, endFrame.size.width);
    }
    
    return endFrame;
}

BOOL isValidKeyboardFrame(CGRect frame) {
    if ((frame.origin.y > CGRectGetHeight([UIScreen mainScreen].bounds)) ||
        (frame.size.height < 1) || (frame.size.width < 1) || (frame.origin.y < 0)) {
        return NO;
    }
    return YES;
}

- (void)animateLayoutIfNeededWithBounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations
{
    NSTimeInterval duration = bounce ? 0.5 : 0.2;
    [self animateLayoutIfNeededWithDuration:duration bounce:bounce curve:curve animations:animations];
}

- (void)animateLayoutIfNeededWithDuration:(NSTimeInterval)duration bounce:(BOOL)bounce curve:(NSInteger)curve animations:(void (^)(void))animations
{
    if (bounce) {
        [UIView animateWithDuration:duration
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.7
                            options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:NULL];
    }
    else {
        [UIView animateWithDuration:duration
                              delay:0.0
                            options:(curve << 16)|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionLayoutSubviews
                         animations:^{
                             [self layoutIfNeeded];
                             
                             if (animations) {
                                 animations();
                             }
                         }
                         completion:NULL];
    }
}

- (NSArray *)constraintsForAttribute:(NSLayoutAttribute)attribute
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", attribute];
    return [self.constraints filteredArrayUsingPredicate:predicate];
}

@end
