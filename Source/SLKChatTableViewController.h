//
//  SLKChatTableViewController.h
//  SLKChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextView.h"

@interface SLKChatTableViewController : UIViewController

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) SLKTextView *textView;
@property (nonatomic, readonly) UIToolbar *textContainerView;

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

- (instancetype)initWithStyle:(UITableViewStyle)style;

- (void)scrollToBottomAnimated:(BOOL)animated;

@end
