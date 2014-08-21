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

#import "UIScrollView+SCKHelpers.h"
#import "UITextView+SCKHelpers.h"

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

/**
 Notifies the view controller that the text input will be updated.
 @discussion You can override this method to perform additional tasks associated with presenting the view. If you override this method, you must call super at some point in your implementation.
 */
- (void)textWillUpdate;

/**
 Notifies the view controller that the text input has been updated.
 @discussion You can override this method to perform additional tasks associated with presenting the view. If you override this method, you must call super at some point in your implementation.
 
 @param If YES, the text container view was resized using an animation.
 */
- (void)textDidUpdate:(BOOL)animated;


/** Shows the keyboard */
- (void)presentKeyboard;

/** Dismisses the keyboard */
- (void)dismissKeyboard;

/** Hides the auto-completion view, animated */
- (void)cancelAutoCompletion;

/**  */
- (void)didSelectAutoCompletionSuggestion:(NSString *)string;

// Auto-completion
@property (nonatomic, strong) NSMutableArray *keysLookup;
@property (nonatomic, strong) NSString *keyString;
@property (nonatomic) NSRange keyRange;
@property (nonatomic, strong) NSString *currentWord;

// Methods to override
- (BOOL)canPressSendButton;
- (BOOL)canShowAutoCompletion;
- (CGFloat)heightForAutoCompletionView;

@end