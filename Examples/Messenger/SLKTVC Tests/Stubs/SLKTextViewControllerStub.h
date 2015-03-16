//
//  SLKTextViewControllerStub.h
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/11/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "SLKTextViewController.h"

typedef NS_ENUM(NSUInteger, SLKStubType) {
    SLKStubTypeDefault
};

@interface SLKTextViewControllerStub : SLKTextViewController

+ (instancetype)stubWithType:(SLKStubType)type;

@end
