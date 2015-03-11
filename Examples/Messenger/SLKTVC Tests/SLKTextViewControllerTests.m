//
//  SLKTextViewControllerTests.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/11/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#define EXP_SHORTHAND
#include <Specta/Specta.h>
#include <Expecta/Expecta.h>
#include <Expecta+Snapshots/EXPMatchers+FBSnapshotTest.h>

#import "SLKTextViewControllerStub.h"
#import "SLKNavigationControllerStub.h"

SpecBegin(SLKTextViewControllerTests)

__block SLKTextViewControllerStub *testVC;
__block SLKNavigationControllerStub *testNC;

dispatch_block_t sharedBefore = ^{
    testVC = [[SLKTextViewControllerStub alloc] init];
    [testVC presentKeyboard:NO];
    
    testNC = [[SLKNavigationControllerStub alloc] initWithRootViewController:testVC];
    testNC.view.backgroundColor = [UIColor whiteColor];
    testNC.navigationBar.barTintColor = [UIColor whiteColor];
    testNC.navigationBar.translucent = NO;
    
    expect(testVC.view).toNot.beNil();
    expect(testNC.view).toNot.beNil();
};

describe(@"A simple SLKTVC subclass instance", ^{
    
    describe(@"Basic displays", ^{
        before(^{
            sharedBefore();
        });
        
        it(@"Displays the text input on top of the keyboard", ^{
//            expect(testNC.view).will.recordSnapshotNamed(@"slktvc.keyboard.up");
            expect(testNC.view).will.haveValidSnapshotNamed(@"slktvc.keyboard.up");
        });
    });
});

SpecEnd
