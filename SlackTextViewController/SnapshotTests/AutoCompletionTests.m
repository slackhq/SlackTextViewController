//
//  AutoCompletionTests.m
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

SpecBegin(AutoCompletionTests)

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


#pragma mark - Autocompletion Tests

describe(@"Autocompletion Tests", ^{
    
    beforeEach(^{
        [tvc presentKeyboard:NO];
        
        [tvc.textView slk_clearText:YES];
        [tvc.textView slk_insertTextAtCaretRange:@"hello @"];
    });
    
    itShould(@"display the autocompletion view", ^{
        
        expect(tvc.foundWord).to.beNil;
        expect(tvc.autoCompleting).to.beTruthy;
        
        return window;
    });
    
    itShould(@"filter results in autocompletion view", ^{
        
        [tvc.textView slk_insertTextAtCaretRange:@"an"];
        
        // Auto-completion mode should be enabled
        expect(tvc.foundPrefix).to.equal(@"@");
        expect(tvc.foundWord).to.equal(@"an");
        expect(tvc.autoCompleting).to.beTruthy;
        
        return window;
    });
    
    itShould(@"insert the first autocompletion item to the text input with prefix", ^{
        
        [tvc acceptAutoCompletionWithString:@"Anna" keepPrefix:YES];
        
        // Auto-completion mode should now be disabled
        expect(tvc.foundPrefix).to.beNil;
        expect(tvc.foundWord).to.beNil;
        expect(tvc.autoCompleting).to.beFalsy;
        
        expect(tvc.textView.text).to.equal(@"hello @Anna");
        
        return window;
    });
});


SpecEnd
