//
//  SLKTextViewControllerTests.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/11/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#define EXP_SHORTHAND

#import "EXPMatchers+FBSnapshotTestExtensions.h"

#import "SLKTextViewControllerStub.h"

#import <LoremIpsum/LoremIpsum.h>

SpecBegin(SLKTextViewControllerTests)

__block UIWindow *window = nil;
__block SLKTextViewControllerStub *tvc = nil;
__block UINavigationController *nvc = nil;

describe(@"Screenshots", ^{
    
    beforeEach(^{
        
        tvc = [SLKTextViewControllerStub stubWithType:SLKStubTypeDefault];
        
        nvc = [[UINavigationController alloc] initWithRootViewController:tvc];
        nvc.view.backgroundColor = [UIColor whiteColor];
                
        window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.rootViewController = [[UINavigationController alloc] initWithRootViewController:tvc];
        window.backgroundColor = [UIColor redColor];
        [window makeKeyAndVisible];
        
        expect(tvc.view).toNot.beNil();
        expect(nvc.view).toNot.beNil();
    });
    
    itTestsOrRecordsSnapshotsAsync(@"displays the text input at the bottom", ^{
        
        expect(tvc.textView.isFirstResponder).will.beFalsy();
        
        return window;
    });
    
    itTestsOrRecordsSnapshotsAsync(@"displays the text input on top of the keyboard", ^{
        
        [tvc presentKeyboard:NO];
        
        expect(tvc.textView.isFirstResponder).will.beTruthy();
        
        return window;
    });
    
    itTestsOrRecordsSnapshotsAsync(@"displays the text input on top of the keyboard with 2 lines of text", ^{
        
        tvc.textView.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit.";
        
        [tvc presentKeyboard:NO];
        
        expect(tvc.textView.isFirstResponder).will.beTruthy();
        expect(tvc.textView.numberOfLines).to.equal(@2);
        
        return window;
    });
});

SpecEnd
