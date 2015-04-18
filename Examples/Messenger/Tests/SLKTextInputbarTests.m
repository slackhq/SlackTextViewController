//
//  SLKTextInputbarTests.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/28/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#define EXP_SHORTHAND

#import "EXPMatchers+FBSnapshotTestExtensions.h"

#import "SLKTextInputbarStub.h"
#import "SLKTextViewStub.h"

SpecBegin(SLKTextInputbarTests)

__block SLKTextInputbarStub *inputbar = nil;
__block CGRect frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 44.0);

describe(@"SLKTextInputbar Screenshots", ^{
    
    beforeEach(^{
        inputbar = [[SLKTextInputbarStub alloc] initWithTextViewClass:[SLKTextViewStub class]];
        inputbar.frame = frame;
        inputbar.translucent = NO;
        inputbar.barTintColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        expect(inputbar).toNot.beNil();
    });
    
    itShould(@"display an empty input bar", ^{
        
        inputbar.autoHideRightButton = NO;
        
        expect(inputbar.autoHideRightButton).to.beFalsy();
        
        return inputbar;
    });
    
    itShould(@"display a default input bar", ^{
        
        expect(inputbar.autoHideRightButton).to.beTruthy();
        
        inputbar.textView.placeholder = @"Placeholder";

        [inputbar.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
        [inputbar.leftButton setTintColor:[UIColor grayColor]];
        
        return inputbar;
    });
});

SpecEnd