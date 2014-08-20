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

@protocol SCKAutoCompletionDelegate;

/** */
@interface SCKChatViewController : UIViewController

/** The main tableView. */
@property (nonatomic, readonly) UITableView *tableView;
/** The bottom text container view, wrapping the text view and buttons. */
@property (nonatomic, readonly) SCKTextContainerView *textContainerView;
/** The typing indicator. */
@property (nonatomic, readonly) SCKTypeIndicatorView *typeIndicatorView;
/** The tableView used to display auto-completion results. */
@property (nonatomic, readonly) UITableView *autoCompleteView;
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

- (void)hideAutoCompleteView;

- (void)replaceFoundStringWithString:(NSString *)string;


// Auto-completion
/** */
@property (nonatomic, weak) id<SCKAutoCompletionDelegate>autoCompletionDelegate;
/** */
@property (nonatomic, strong) NSMutableArray *signLookup;

@end


@protocol SCKAutoCompletionDelegate <NSObject>
@optional

/** */
- (BOOL)tableView:(UITableView *)tableView shouldShowAutoCompletionForSearchString:(NSString *)string withSign:(NSString *)sign;

/** */
- (CGFloat)tableView:(UITableView *)tableView heightForSearchString:(NSString *)string withSign:(NSString *)sign;

@end