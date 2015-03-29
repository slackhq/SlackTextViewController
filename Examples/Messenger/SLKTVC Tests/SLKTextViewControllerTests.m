//
//  SLKTextViewControllerTests.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/11/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#define EXP_SHORTHAND

#import "EXPMatchers+FBSnapshotTestExtensions.h"
#import "NSString+LoremIpsum.h"

#import "SLKTextViewControllerStub.h"
#import "SLKTextViewStub.h"

SpecBegin(SLKTextViewControllerTests)

__block UIWindow *window = nil;
__block SLKTextViewControllerStub *tvc = nil;
__block UINavigationController *nvc = nil;

describe(@"SLKTextViewController Screenshots", ^{
    
    beforeAll(^{
        
        tvc = [[SLKTextViewControllerStub alloc] init];
        tvc.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        tvc.textView.placeholder = @"Placeholder";
        
        [tvc.leftButton setImage:[UIImage imageNamed:@"icn_upload"] forState:UIControlStateNormal];
        [tvc.leftButton setTintColor:[UIColor grayColor]];

        [tvc registerClassForTextView:[SLKTextViewStub class]];
        
        nvc = [[UINavigationController alloc] initWithRootViewController:tvc];
        nvc.view.backgroundColor = [UIColor whiteColor];
                
        window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.rootViewController = [[UINavigationController alloc] initWithRootViewController:tvc];
        window.backgroundColor = [UIColor redColor]; // Red color represents the keyboard area
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
    
    itTestsOrRecordsSnapshotsAsync(@"displays the text input with 2 lines of text", ^{
        
        tvc.textView.text = [NSString sentence];
        
        expect(tvc.textView.numberOfLines).will.equal(@2);
        
        return window;
    });
    
    itTestsOrRecordsSnapshotsAsync(@"displays the text input with multiple lines of text", ^{
        
        tvc.textView.text = [NSString sentencesWithNumber:5];
        
        expect(tvc.textView.numberOfLines).will.beGreaterThan(@10);
        
        return window;
    });
    
    itTestsOrRecordsSnapshotsAsync(@"displays the text input with multiple lines of text", ^{
        
        tvc.textView.text = [NSString sentencesWithNumber:5];
        
        expect(tvc.textView.numberOfLines).will.beGreaterThan(@10);
        
        return window;
    });
});

SpecEnd
