//
//  SCKChatTableViewController.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCKTextContainerView.h"

@interface SCKChatTableViewController : UIViewController

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) SCKTextContainerView *textContainerView;
@property (nonatomic, readonly) SCKTextView *textView;
@property (nonatomic, readonly) UIButton *leftButton;
@property (nonatomic, readonly) UIButton *rightButton;

- (void)scrollToBottomAnimated:(BOOL)animated;

- (void)presentKeyboard;
- (void)dismissKeyboard;

@end
