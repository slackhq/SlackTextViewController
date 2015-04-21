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


beforeAll(^{
    
    tvc = [[SLKTextViewControllerStub alloc] init];
    tvc.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    tvc.textView.placeholder = @"Placeholder";
    tvc.textView.tintColor = tvc.textView.backgroundColor; // This helps preventing the caret to be displayed in the tests
    
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
        
        expect(tvc.textView.numberOfLines).will.beGreaterThan(@10);
        
        return window;
    });
    
    itShould(@"empty the text input after hitting right button", ^{
        
        // Simulates pressing the right button
        [tvc didPressRightButton:tvc.rightButton];
        
        expect(tvc.textView.numberOfLines).will.equal(@1);
        
        return window;
    });
});


#pragma mark - Autocompletion Tests

describe(@"Autocompletion Tests", ^{
    
    beforeEach(^{
        [tvc presentKeyboard:NO];
        
        [tvc.textView slk_clearText:YES];
        [tvc.textView slk_insertTextAtCaretRange:@"hello @"];
    });
    
    itShould(@"display the autocompletion view", ^{
        
        expect(tvc.foundPrefix).to.equal(@"@");
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
