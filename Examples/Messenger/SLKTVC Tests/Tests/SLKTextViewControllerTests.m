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
    
    describe(@"displays the text input", ^{
        
        it(@"at the bottom", ^{
            
            expect(tvc.textView.isFirstResponder).will.beFalsy();
            expect(window).will.haveValidSnapshotNamed(@"slktvc.keyboard.down");
        });
        
        it(@"on top of the keyboard, empty", ^{
            
            [tvc presentKeyboard:NO];
            
            expect(tvc.textView.isFirstResponder).will.beTruthy();
            expect(window).will.haveValidSnapshotNamed(@"slktvc.keyboard.up");
        });
        
        it(@"with 2 lines of text", ^{
            
            tvc.textView.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit.";
            
            [tvc presentKeyboard:NO];
            
            expect(tvc.textView.isFirstResponder).will.beTruthy();
            expect(tvc.textView.numberOfLines).to.equal(@2);
            expect(window).will.haveValidSnapshotNamed(@"slktvc.keyboard.up.2.lines");
        });
    });
});

SpecEnd
