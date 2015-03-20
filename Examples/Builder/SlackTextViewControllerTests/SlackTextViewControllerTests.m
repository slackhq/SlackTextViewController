//
//  SlackTextViewControllerTests.m
//  SlackTextViewControllerTests
//
//  Created by Ignacio Romero Z. on 3/20/15.
//  Copyright (c) 2015 Slack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <SlackTextViewController/SLKTextViewController.h>

@interface SLKTextViewControllerTest : SLKTextViewController ()
@end

@interface SlackTextViewControllerTests : XCTestCase
@end

@implementation SlackTextViewControllerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testImportLibrary {
    SLKTextViewControllerTest *controller = [SLKTextViewControllerTest new];
    XCTAssertNotNil(controller);
}

@end
