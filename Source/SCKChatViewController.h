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

/** A drop-in replacement of UITableViewController with chat features. */
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

/**
 Verifies if the right button can be pressed. If NO, the button is disabled.
 @discussion You can override this method to perform additional tasks.
 
 @return YES if the right button can be pressed.
 */
- (BOOL)canPressSendButton;

/**
 Presents the keyboard, if not already, animated.
 
 @animated YES if the keyboard should show using an animation.
 */
- (void)presentKeyboard:(BOOL)animated;

/**
 Dimisses the keyboard, if not already, animated.
 
 @animated YES if the keyboard should be dismissed using an animation.
 */
- (void)dismissKeyboard:(BOOL)animated;


///------------------------------------------------
/// Text typing Auto-Completion
///------------------------------------------------

@property (nonatomic, strong) NSString *detectedKey;
@property (nonatomic, strong) NSString *detectedWord;

/**
 Registers any string key for auto-completion detection. The keys must be valid NSString, no longer than 1 character.
 This also checks if no repeated key is inserted.
 
 @param keys An array of string keys.
 */
- (void)registerKeysForAutoCompletion:(NSArray *)keys;

/**
 Verifies that the auto-completion can be shown.
 @discussion You can override this method to perform additional tasks.
 
 @return YES if the auto-completion view can be shown.
 */
- (BOOL)canShowAutoCompletion;

/**
 Returns a custom height for the auto-completion view. Default and maximum is 0.0.
 */
- (CGFloat)heightForAutoCompletionView;

/**
 Returns the maximum height for the auto-completion view. Default and maximum is 140.0.
 */
- (CGFloat)maximumHeightForAutoCompletionView;

/**
 Cancels and hides the auto-completion view, animated
 */
- (void)cancelAutoCompletion;

/** 
 Accepts the auto-completion, replacing the detected key and word with a new string.
 
 @param string The string to be used for replacing auto-completion placeholders.
 */
- (void)acceptAutoCompletionWithString:(NSString *)string;

@end
