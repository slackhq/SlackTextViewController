//
//  SLKTextViewControllerStub.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/11/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "SLKTextViewControllerStub.h"

@implementation SLKTextViewControllerStub

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.textView.placeholder = @"Placeholder";
    [self.textView becomeFirstResponder];
    
    self.textInputbar.autoHideRightButton = NO;

    [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
    [self.leftButton setTintColor:[UIColor blueColor]];
}

@end
