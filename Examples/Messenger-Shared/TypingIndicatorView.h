//
//  TypingIndicatorView.h
//  Messenger
//
//  Created by Ignacio Romero Z. on 6/27/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTypingIndicatorProtocol.h"

static CGFloat kTypingIndicatorViewMinimumHeight = 80.0;
static CGFloat kTypingIndicatorViewAvatarHeight = 30.0;

@interface TypingIndicatorView : UIView <SLKTypingIndicatorProtocol>

- (void)presentIndicatorWithName:(NSString *)name image:(UIImage *)image;
- (void)dismissIndicator;

@end
