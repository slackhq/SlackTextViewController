//
//  ViewController.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 4/8/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (IBAction)showMessages:(id)sender
{
    [self performSegueWithIdentifier:@"show_messages" sender:sender];
}

@end
