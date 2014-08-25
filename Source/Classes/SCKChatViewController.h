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

///------------------------------------------------------------------------
/// @name A drop-in replacement of UITableViewController with chat features.
///------------------------------------------------------------------------
@interface SCKChatViewController : UIViewController

/** The main table view managed by the controller object. */
@property (nonatomic, readonly) UITableView *tableView;
/** The bottom text container view, wrapping the text view and buttons. */
@property (nonatomic, readonly) SCKTextContainerView *textContainerView;
/** The typing indicator. */
@property (nonatomic, readonly) SCKTypeIndicatorView *typeIndicatorView;
/** YES if control's animation should have bouncy effects. Default is NO. */
@property (nonatomic, assign) BOOL bounces;
/** YES if text view's content can be cleaned with a shake gesture. Default is NO. */
@property (nonatomic, assign) BOOL allowUndo;

// Convenience accessors (access through the text container view)
@property (nonatomic, readonly) SCKTextView *textView;
@property (nonatomic, readonly) UIButton *leftButton;
@property (nonatomic, readonly) UIButton *rightButton;

/**
 Verifies if the right button can be pressed. If NO, the button is disabled.
 @discussion You can override this method to perform additional tasks.
 
 @return YES if the right button can be pressed.
 */
- (BOOL)canPressRightButton;

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
/// @name Text Typing Notifications
///------------------------------------------------

/**
 Notifies the view controller that the text input will be updated.
 @discussion You can override this method to perform additional tasks associated with presenting the view. You MUST call super at some point in your implementation.
 */
- (void)textWillUpdate;

/**
 Notifies the view controller that the text input has been updated.
 @discussion You can override this method to perform additional tasks associated with presenting the view. You MUST call super at some point in your implementation.
 
 @param If YES, the text container view was resized using an animation.
 */
- (void)textDidUpdate:(BOOL)animated;

/**
 Notifies the view controller when the left button's action has been triggered, manually.
 @discussion You can override this method to perform additional tasks associated with the left button. You MUST call super at some point in your implementation.
 
 @param sender The object calling this method.
 */
- (void)didPressLeftButton:(id)sender;

/**
 Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
 @discussion You can override this method to perform additional tasks associated with the right button. You MUST call super at some point in your implementation.
 
 @param sender The object calling this method.
 */
- (void)didPressRightButton:(id)sender;

/**
 Notifies the view controller when the user has pasted an image inside of the text view.
 @discussion You can override this method to perform additional tasks associated with image pasting.
 
 @param image The image that has been pasted. Only JPG or PNG are supported.
 */
- (void)didPasteImage:(UIImage *)image;

/**
 Notifies the view controller when the user has shaked the device for undoing text typing.
 @discussion You can override this method to perform additional tasks associated with the shake gesture. Calling super will prompt a system alert view with undo option. This will not be called if 'allowUndo' is set to NO and/or if the text view's content is empty.
 */
- (void)willRequestUndo;


///------------------------------------------------
/// @name Text Edition
///------------------------------------------------

/** YES if the text editing mode is active. */
@property (nonatomic, readonly, getter = isEditing) BOOL editing;

/**
 Re-uses the text layout for edition, displaying a header view on top of the text container vier with options (cancel & save).
 
 @param text The string text to edit.
 */
- (void)editText:(NSString *)text;

/**
 Notifies the view controller when the editing bar's right button's action has been triggered, manually or by using the external keyboard's Return key.
 @discussion You can override this method to perform additional tasks associated with accepting changes. You MUST call super at some point in your implementation.
 
 @param sender The object calling this method.
 */
- (void)didCommitTextEditing:(id)sender;

/**
 Notifies the view controller when the editing bar's right button's action has been triggered, manually or by using the external keyboard's Esc key.
 @discussion You can override this method to perform additional tasks associated with accepting changes. You MUST call super at some point in your implementation.
 
 @param sender The object calling this method.
 */
- (void)didCancelTextEditing:(id)sender;


///------------------------------------------------
/// @name Text Typing Auto-Completion
///------------------------------------------------

/** The table view used to display auto-completion results. */
@property (nonatomic, readonly) UITableView *autoCompletionView;
/** The recently detected key symbol used as prefix for auto-completion mode. */
@property (nonatomic, strong) NSString *detectedKey;
/** The recently detected word at the textView caret position. */
@property (nonatomic, strong) NSString *detectedWord;
/** YES if the auto-completion mode is active. */
@property (nonatomic, readonly, getter = isAutoCompleting) BOOL autoCompleting;

/**
 Registers any string key for auto-completion detection, useful for user mentions and/or hashtags auto-completion.
 @discussion The keys must be valid NSString, no longer than 1 character (i.e: '@', '#', '\', and so on)
 This also checks if no repeated key is inserted.
 
 @param keys An array of string keys.
 */
- (void)registerKeysForAutoCompletion:(NSArray *)keys;

/**
 Verifies that the auto-completion can be shown. Default is NO.
 @discussion You can override this method to perform additional tasks.
 
 @return YES if the auto-completion view can be shown.
 */
- (BOOL)canShowAutoCompletion;

/**
 Returns a custom height for the auto-completion view. Default and maximum is 0.0.
 @discussion You can override this method to return a custom height.

 @return The auto-completion view's height.
 */
- (CGFloat)heightForAutoCompletionView;

/**
 Returns the maximum height for the auto-completion view. Default is 140.0.
 @discussion You can override this method to return a custom max height.

 @return The auto-completion view's max height.
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
