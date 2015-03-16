//
//  SLKTextViewControllerStub.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/11/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "SLKTextViewControllerStub.h"

@implementation SLKTextViewControllerStub

+ (instancetype)stubWithType:(SLKStubType)type
{
    SLKTextViewControllerStub *stub = [[SLKTextViewControllerStub alloc] init];
    [stub configureStubWithType:type];
    return stub;
}

- (void)configureStubWithType:(SLKStubType)type
{
    if (type == SLKStubTypeDefault) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        self.textView.placeholder = @"Placeholder";
        self.textView.backgroundColor = [UIColor whiteColor];
        
        self.textInputbar.autoHideRightButton = NO;
        
        [self.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
        [self.leftButton setTintColor:[UIColor grayColor]];
    }
}

@end
