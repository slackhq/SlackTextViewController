//
//  SLKChatTableViewController.h
//  SLKChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextContainerView.h"

@interface SLKChatTableViewController : UIViewController

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) SLKTextContainerView *textContainerView;
@property (nonatomic, readonly) SLKTextView *textView;
@property (nonatomic, readonly) UIButton *leftButton;
@property (nonatomic, readonly) UIButton *rightButton;

- (void)scrollToBottomAnimated:(BOOL)animated;

@end
