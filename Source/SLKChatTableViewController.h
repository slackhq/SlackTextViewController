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

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) SLKTextView *textView;

- (instancetype)initWithStyle:(UITableViewStyle)style;

@end
