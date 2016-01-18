//
//  DisplayTests.m
//
//  Created by Ignacio Romero Z. on 18/1/16.
//  Copyright (c) 2016 Slack Technologies, Inc. All rights reserved.
//

#define EXP_SHORTHAND

#import <UIKit/UIKit.h>
#import <Specta/Specta.h>

#import "EXPMatchers+FBSnapshotTestExtensions.h"
#import "NSString+LoremIpsum.h"

#import "SLKTextViewControllerStub.h"
#import "SLKTextViewStub.h"

SpecBegin(DisplayTests)

__block UIWindow *window = nil;
__block SLKTextViewControllerStub *tvc = nil;
__block UINavigationController *nvc = nil;

beforeAll(^{
    
    tvc = [[SLKTextViewControllerStub alloc] init];
    nvc = [[UINavigationController alloc] initWithRootViewController:tvc];
    nvc.view.backgroundColor = [UIColor whiteColor];
    
    window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:tvc];
    window.backgroundColor = [UIColor redColor]; // Red color represents the keyboard area
    [window makeKeyAndVisible];
    
    expect(tvc.view).toNot.beNil();
    expect(nvc.view).toNot.beNil();
});


#pragma mark - Initialization Tests

describe(@"Initialization Tests", ^{
    
    it(@"initializes with a tableView", ^{
        SLKTextViewControllerStub *controller = [[SLKTextViewControllerStub alloc] initWithTableViewStyle:UITableViewStylePlain];
        expect(controller.tableView).toNot.beNil();
    });
    
    it(@"initializes with a collectionView", ^{
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        SLKTextViewControllerStub *controller = [[SLKTextViewControllerStub alloc] initWithCollectionViewLayout:layout];
        expect(controller.collectionView).toNot.beNil();
    });
    
    it(@"initializes with a scrollView", ^{
        UIScrollView *scrollView = [UIScrollView new];
        SLKTextViewControllerStub *controller = [[SLKTextViewControllerStub alloc] initWithScrollView:scrollView];
        expect(controller.scrollView).toNot.beNil();
    });
});


#pragma mark - Growing Text View Tests

describe(@"Growing Text View Tests", ^{
    
    itShould(@"display the text input at the bottom", ^{
        
        expect(tvc.textView.isFirstResponder).will.beFalsy();
        
        return window;
    });
    
    itShould(@"display the text input on top of the keyboard", ^{
        
        [tvc presentKeyboard:NO];
        
        expect(tvc.textView.isFirstResponder).will.beTruthy();
        
        return window;
    });
    
    itShould(@"display the text input with 2 lines of text", ^{
        
        tvc.textView.text = [NSString sentence];
        
        expect(tvc.textView.numberOfLines).will.equal(@2);
        
        return window;
    });
    
    itShould(@"display the text input with multiple lines of text", ^{
        
        tvc.textView.text = [NSString sentencesWithNumber:5];
        
        expect(tvc.textView.numberOfLines).will.beGreaterThanOrEqualTo(@9);
        
        return window;
    });
    
    itShould(@"empty the text input after hitting right button", ^{
        
        // Simulates pressing the right button
        [tvc didPressRightButton:tvc.rightButton];
        
        expect(tvc.textView.numberOfLines).will.equal(@1);
        
        return window;
    });
});


SpecEnd
