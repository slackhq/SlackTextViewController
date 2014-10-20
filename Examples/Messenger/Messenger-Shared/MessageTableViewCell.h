//
//  MessageTableViewCell.h
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 9/1/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAvatarSize 30.0
#define kMinimumHeight 40.0

@interface MessageTableViewCell : UITableViewCell

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic) BOOL needsPlaceholder;
@property (nonatomic) BOOL usedForMessage;

- (void)setPlaceholder:(UIImage *)image scale:(CGFloat)scale;

@end
