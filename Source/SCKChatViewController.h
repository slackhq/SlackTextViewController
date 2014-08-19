//
//  SCKChatViewController.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCKTextContainerView.h"
#import "SCKTypeIndicatorView.h"

/** */
@interface SCKChatViewController : UIViewController

/** The tableView. */
@property (nonatomic, readonly) UITableView *tableView;
/** The bottom text container view, wrapping the text view and buttons. */
@property (nonatomic, readonly) SCKTextContainerView *textContainerView;
/** The typing indicator. */
@property (nonatomic, readonly) SCKTypeIndicatorView *typeIndicatorView;
/** YES if control's animation should be elastic and bouncy. Default is YES. */
@property (nonatomic, assign) BOOL allowElasticity;

// Convenience accessors (access through the text container view)
@property (nonatomic, readonly) SCKTextView *textView;
@property (nonatomic, readonly) UIButton *leftButton;
@property (nonatomic, readonly) UIButton *rightButton; 

/** Shows the keyboard */
- (void)presentKeyboard;

/** Dismisses the keyboard */
- (void)dismissKeyboard;

@end


@protocol SCKAutoCompletionDataSource <UITableViewDataSource>

- (BOOL)tableView:(UITableView *)tableView shouldAutoCompleteForFoundString:(NSString *)string;

@end

@protocol SCKAutoCompletionDelegate <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectStringRepresentation:(NSString *)string;

@end


@interface SCKChatViewController (AutoCompletion)

@property (nonatomic, assign) id<SCKAutoCompletionDataSource>autoCompletionDataSource;
@property (nonatomic, assign) id<SCKAutoCompletionDelegate>autoCompletionDelegate;

- (void)registerAutoCompletionStringRepresentation:(NSString *)string;
- (void)registerAutoCompletionStringRepresentations:(NSArray *)strings;

- (void)removeAutoCompletionStringRepresentation:(NSString *)string;

@end