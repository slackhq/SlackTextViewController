//
//  ChatViewCell.h
//  ChatRoom
//
//  Created by Ignacio Romero Zurbuchen on 9/1/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kAvatarSize 30.0
#define kMinimumHeight 40.0

@interface ChatViewCell : UITableViewCell

@property (nonatomic) BOOL hasPlaceholder;
@property (nonatomic, strong) NSIndexPath *indexPath;

@end
