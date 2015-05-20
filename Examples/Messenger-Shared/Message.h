//
//  Message.h
//  Messenger
//
//  Created by Ignacio Romero Z. on 1/16/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Message : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIImage *attachment;

@end
