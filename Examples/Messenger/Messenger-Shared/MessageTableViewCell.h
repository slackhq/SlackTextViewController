//
//  MessageTableViewCell.h
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 9/1/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAvatarSize 30.0
#define kMinimumHeight 50.0

@interface MessageTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UIImageView *attachmentView;

@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic, readonly) BOOL needsPlaceholder;
@property (nonatomic) BOOL usedForMessage;

@end
