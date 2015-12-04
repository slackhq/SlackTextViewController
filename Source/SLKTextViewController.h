//
//   Copyright 2014 Slack Technologies, Inc.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SLKTextInputbar.h"
#import "SLKTextView.h"
#import "SLKTypingIndicatorView.h"
#import "SLKTypingIndicatorProtocol.h"

#import "SLKTextView+SLKAdditions.h"
#import "UIScrollView+SLKAdditions.h"
#import "UIView+SLKAdditions.h"

#import "SLKUIConstants.h"

/**
 UIKeyboard notification replacement, posting reliably only when showing/hiding the keyboard (not when resizing keyboard, or with inputAccessoryView reloads, etc).
 Only triggered when using SLKTextViewController's text view.
 */
UIKIT_EXTERN NSString *const SLKKeyboardWillShowNotification;
UIKIT_EXTERN NSString *const SLKKeyboardDidShowNotification;
UIKIT_EXTERN NSString *const SLKKeyboardWillHideNotification;
UIKIT_EXTERN NSString *const SLKKeyboardDidHideNotification;

UIKIT_EXTERN NSString *const SLKTextInputbarDidMoveNotification;

typedef NS_ENUM(NSUInteger, SLKKeyboardStatus) {
    SLKKeyboardStatusDidHide,
    SLKKeyboardStatusWillShow,
    SLKKeyboardStatusDidShow,
    SLKKeyboardStatusWillHide
};

/** @name A drop-in UIViewController subclass with a growing text input view and other useful messaging features. */
NS_CLASS_AVAILABLE_IOS(7_0) @interface SLKTextViewController : UIViewController <SLKTextViewDelegate, UITableViewDelegate, UITableViewDataSource,
                                                                                UICollectionViewDelegate, UICollectionViewDataSource,
                                                                                UIGestureRecognizerDelegate, UIAlertViewDelegate>

/** The main table view managed by the controller object. Created by default initializing with -init or initWithNibName:bundle: */
@property (nonatomic, readonly) UITableView *tableView;

/** The main collection view managed by the controller object. Not nil if the controller is initialised with -initWithCollectionViewLayout: */
@property (nonatomic, readonly) UICollectionView *collectionView;

/** The main scroll view managed by the controller object. Not nil if the controller is initialised with -initWithScrollView: */
@property (nonatomic, readonly) UIScrollView *scrollView;

/** The bottom toolbar containing a text view and buttons. */
@property (nonatomic, readonly) SLKTextInputbar *textInputbar;

/** The default typing indicator used to display user names horizontally. */
@property (nonatomic, readonly) SLKTypingIndicatorView *typingIndicatorView;

/**
 The custom typing indicator view. Default is kind of SLKTypingIndicatorView.
 To customize the typing indicator view, you will need to call -registerClassForTypingIndicatorView: nside of any initialization method.
 To interact with it directly, you will need to cast the return value of -typingIndicatorProxyView to the appropriate type.
 */
@property (nonatomic, readonly) UIView <SLKTypingIndicatorProtocol> *typingIndicatorProxyView;

/** A single tap gesture used to dismiss the keyboard. SLKTextViewController is its delegate. */
@property (nonatomic, readonly) UIGestureRecognizer *singleTapGesture;

/** A vertical pan gesture used for bringing the keyboard from the bottom. SLKTextViewController is its delegate. */
@property (nonatomic, readonly) UIPanGestureRecognizer *verticalPanGesture;

/** YES if control's animation should have bouncy effects. Default is YES. */
@property (nonatomic, assign) BOOL bounces;

/** YES if text view's content can be cleaned with a shake gesture. Default is NO. */
@property (nonatomic, assign) BOOL shakeToClearEnabled;

/** YES if keyboard can be dismissed gradually with a vertical panning gesture. Default is YES. */
@property (nonatomic, assign, getter = isKeyboardPanningEnabled) BOOL keyboardPanningEnabled;

/** YES if an external keyboard has been detected (this value updates only when the text view becomes first responder). */
@property (nonatomic, readonly, getter=isExternalKeyboardDetected) BOOL externalKeyboardDetected;

/** YES if the keyboard has been detected as undocked or split (iPad Only). */
@property (nonatomic, readonly, getter=isKeyboardUndocked) BOOL keyboardUndocked;

/** YES if after right button press, the text view is cleared out. Default is YES. */
@property (nonatomic, assign) BOOL shouldClearTextAtRightButtonPress;

/** YES if the scrollView should scroll to bottom when the keyboard is shown. Default is NO.*/
@property (nonatomic, assign) BOOL shouldScrollToBottomAfterKeyboardShows;

/**
 YES if the main table view is inverted. Default is YES.
 This allows the table view to start from the bottom like any typical messaging interface.
 If inverted, you must assign the same transform property to your cells to match the orientation (ie: cell.transform = tableView.transform;)
 Inverting the table view will enable some great features such as content offset corrections automatically when resizing the text input and/or showing autocompletion.
 */
@property (nonatomic, assign, getter = isInverted) BOOL inverted;

/** YES if the view controller is presented inside of a popover controller. If YES, the keyboard won't move the text input bar and tapping on the tableView/collectionView will not cause the keyboard to be dismissed. This property is compatible only with iPad. */
@property (nonatomic, assign, getter = isPresentedInPopover) BOOL presentedInPopover;

/** Convenience accessors (accessed through the text input bar) */
@property (nonatomic, readonly) SLKTextView *textView;
@property (nonatomic, readonly) UIButton *leftButton;
@property (nonatomic, readonly) UIButton *rightButton;


#pragma mark - Initialization
///------------------------------------------------
/// @name Initialization
///------------------------------------------------

/**
 Initializes a text view controller to manage a table view of a given style.
 If you use the standard -init method, a table view with plain style will be created.
 
 @param style A constant that specifies the style of main table view that the controller object is to manage (UITableViewStylePlain or UITableViewStyleGrouped).
 @return An initialized SLKTextViewController object or nil if the object could not be created.
 */
- (instancetype)initWithTableViewStyle:(UITableViewStyle)style SLK_DESIGNATED_INITIALIZER;

/**
 Initializes a collection view controller and configures the collection view with the provided layout.
 If you use the standard -init method, a table view with plain style will be created.
 
 @param layout The layout object to associate with the collection view. The layout controls how the collection view presents its cells and supplementary views.
 @return An initialized SLKTextViewController object or nil if the object could not be created.
 */
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout SLK_DESIGNATED_INITIALIZER;

/**
 Initializes a text view controller to manage an arbitraty scroll view. The caller is responsible for configuration of the scroll view, including wiring the delegate.
 
 @param a UISCrollView to be used as the main content area.
 @return An initialized SLKTextViewController object or nil if the object could not be created.
 */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView SLK_DESIGNATED_INITIALIZER;

/**
 Initializes either a table or collection view controller.
 You must override either +tableViewStyleForCoder: or +collectionViewLayoutForCoder: to define witch view to be layed out.
 
 @param decoder An unarchiver object.
 @return An initialized SLKTextViewController object or nil if the object could not be created.
 */
- (instancetype)initWithCoder:(NSCoder *)decoder SLK_DESIGNATED_INITIALIZER;

/**
 Returns the tableView style to be configured when using Interface Builder. Default is UITableViewStylePlain.
 You must override this method if you want to configure a tableView.
 
 @param decoder An unarchiver object.
 @return The tableView style to be used in the new instantiated tableView.
 */
+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder;

/**
 Returns the tableView style to be configured when using Interface Builder. Default is nil.
 You must override this method if you want to configure a collectionView.
 
 @param decoder An unarchiver object.
 @return The collectionView style to be used in the new instantiated collectionView.
 */
+ (UICollectionViewLayout *)collectionViewLayoutForCoder:(NSCoder *)decoder;


#pragma mark - Keyboard Handling
///------------------------------------------------
/// @name Keyboard Handling
///------------------------------------------------

/**
 Presents the keyboard, if not already, animated.
 You can override this method to perform additional tasks associated with presenting the keyboard.
 You SHOULD call super to inherit some conditionals.

 @param animated YES if the keyboard should show using an animation.
 */
- (void)presentKeyboard:(BOOL)animated;

/**
 Dimisses the keyboard, if not already, animated.
 You can override this method to perform additional tasks associated with dismissing the keyboard.
 You SHOULD call super to inherit some conditionals.
 
 @param animated YES if the keyboard should be dismissed using an animation.
 */
- (void)dismissKeyboard:(BOOL)animated;

/**
 Verifies if the text input bar should still move up/down even if it is not first responder. Default is NO.
 You can override this method to perform additional tasks associated with presenting the view.
 You don't need call super since this method doesn't do anything.
 
 @param responder The current first responder object.
 @return YES so the text input bar still move up/down.
 */
- (BOOL)forceTextInputbarAdjustmentForResponder:(UIResponder *)responder;

/**
 Verifies if the text input bar should still move up/down when it is first responder. Default is NO.
 This is very useful when presenting the view controller in a custom modal presentation, when there keyboard events are being handled externally to reframe the presented view.
 You SHOULD call super to inherit some conditionals.
 */
- (BOOL)ignoreTextInputbarAdjustment NS_REQUIRES_SUPER;

/**
 Notifies the view controller that the keyboard changed status.
 You can override this method to perform additional tasks associated with presenting the view.
 You don't need call super since this method doesn't do anything.
 
 @param status The new keyboard status.
 */
- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status;


#pragma mark - Interaction Notifications
///------------------------------------------------
/// @name Interaction Notifications
///------------------------------------------------

/**
 Notifies the view controller that the text will update.
 You can override this method to perform additional tasks associated with text changes.
 You MUST call super at some point in your implementation.
 */
- (void)textWillUpdate NS_REQUIRES_SUPER;

/**
 Notifies the view controller that the text did update.
 You can override this method to perform additional tasks associated with text changes.
 You MUST call super at some point in your implementation.
 
 @param If YES, the text input bar will be resized using an animation.
 */
- (void)textDidUpdate:(BOOL)animated NS_REQUIRES_SUPER;

/**
 Notifies the view controller that the text selection did change.
 Use this method a replacement of UITextViewDelegate's -textViewDidChangeSelection: which is not reliable enough when using third-party keyboards (they don't forward events properly sometimes).
 
 You can override this method to perform additional tasks associated with text changes.
 You MUST call super at some point in your implementation.
 */
- (void)textSelectionDidChange NS_REQUIRES_SUPER;

/**
 Notifies the view controller when the left button's action has been triggered, manually.
 You can override this method to perform additional tasks associated with the left button.
 You don't need call super since this method doesn't do anything.
 
 @param sender The object calling this method.
 */
- (void)didPressLeftButton:(id)sender;

/**
 Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
 You can override this method to perform additional tasks associated with the right button.
 You MUST call super at some point in your implementation.
 
 @param sender The object calling this method.
 */
- (void)didPressRightButton:(id)sender NS_REQUIRES_SUPER;

/**
 Verifies if the right button can be pressed. If NO, the button is disabled.
 You can override this method to perform additional tasks. You SHOULD call super to inherit some conditionals.
 
 @return YES if the right button can be pressed.
 */
- (BOOL)canPressRightButton;

/**
 Notifies the view controller when the user has pasted a supported media content (images and/or videos).
 You can override this method to perform additional tasks associated with image/video pasting. You don't need to call super since this method doesn't do anything.
 Only supported pastable medias configured in SLKTextView will be forwarded (take a look at SLKPastableMediaType).
 
 @para userInfo The payload containing the media data, content and media types.
 */
- (void)didPasteMediaContent:(NSDictionary *)userInfo;

/**
 Verifies that the typing indicator view should be shown. Default is YES, if meeting some requierements.
 You can override this method to perform additional tasks.
 You SHOULD call super to inherit some conditionals.
 
 @return YES if the typing indicator view should be presented.
 */
- (BOOL)canShowTypingIndicator;

/**
 Notifies the view controller when the user has shaked the device for undoing text typing.
 You can override this method to perform additional tasks associated with the shake gesture.
 Calling super will prompt a system alert view with undo option. This will not be called if 'undoShakingEnabled' is set to NO and/or if the text view's content is empty.
 */
- (void)willRequestUndo;

/**
 Notifies the view controller when the user has pressed the Return key (↵) with an external keyboard.
 You can override this method to perform additional tasks.
 You MUST call super at some point in your implementation.
 */
- (void)didPressReturnKey:(id)sender NS_REQUIRES_SUPER;

/**
 Notifies the view controller when the user has pressed the Escape key (Esc) with an external keyboard.
 You can override this method to perform additional tasks.
 You MUST call super at some point in your implementation.
 */
- (void)didPressEscapeKey:(id)sender NS_REQUIRES_SUPER;

/**
 Notifies the view controller when the user has pressed the arrow key with an external keyboard.
 You can override this method to perform additional tasks.
 You MUST call super at some point in your implementation.
 */
- (void)didPressArrowKey:(id)sender NS_REQUIRES_SUPER;


#pragma mark - Text Input Bar Adjustment
///------------------------------------------------
/// @name Text Input Bar Adjustment
///------------------------------------------------

/** YES if the text inputbar is hidden. Default is NO. */
@property (nonatomic, getter=isTextInputbarHidden) BOOL textInputbarHidden;

/**
 Changes the visibility of the text input bar.
 Calling this method with the animated parameter set to NO is equivalent to setting the value of the toolbarHidden property directly.
 
 @param hidden Specify YES to hide the toolbar or NO to show it.
 @param animated Specify YES if you want the toolbar to be animated on or off the screen.
 */
- (void)setTextInputbarHidden:(BOOL)hidden animated:(BOOL)animated;


#pragma mark - Text Edition
///------------------------------------------------
/// @name Text Edition
///------------------------------------------------

/** YES if the text editing mode is active. */
@property (nonatomic, readonly, getter = isEditing) BOOL editing;

/**
 Re-uses the text layout for edition, displaying an accessory view on top of the text input bar with options (cancel & save).
 You can override this method to perform additional tasks
 You MUST call super at some point in your implementation.
 
 @param text The string text to edit.
 */
- (void)editText:(NSString *)text NS_REQUIRES_SUPER;

/**
 Notifies the view controller when the editing bar's right button's action has been triggered, manually or by using the external keyboard's Return key.
 You can override this method to perform additional tasks associated with accepting changes.
 You MUST call super at some point in your implementation.
 
 @param sender The object calling this method.
 */
- (void)didCommitTextEditing:(id)sender NS_REQUIRES_SUPER;

/**
 Notifies the view controller when the editing bar's right button's action has been triggered, manually or by using the external keyboard's Esc key.
 You can override this method to perform additional tasks associated with accepting changes.
 You MUST call super at some point in your implementation.
 
 @param sender The object calling this method.
 */
- (void)didCancelTextEditing:(id)sender NS_REQUIRES_SUPER;


#pragma mark - Text Auto-Completion
///------------------------------------------------
/// @name Text Auto-Completion
///------------------------------------------------

/** The table view used to display autocompletion results. */
@property (nonatomic, readonly) UITableView *autoCompletionView;

/** YES if the autocompletion mode is active. */
@property (nonatomic, readonly, getter = isAutoCompleting) BOOL autoCompleting;

/** The recently found prefix symbol used as prefix for autocompletion mode. */
@property (nonatomic, readonly, copy) NSString *foundPrefix;

/** The range of the found prefix in the text view content. */
@property (nonatomic, readonly) NSRange foundPrefixRange;

/** The recently found word at the text view's caret position. */
@property (nonatomic, readonly, copy) NSString *foundWord;

/** An array containing all the registered prefix strings for autocompletion. */
@property (nonatomic, readonly, copy) NSArray *registeredPrefixes;

/**
 Registers any string prefix for autocompletion detection, useful for user mentions and/or hashtags autocompletion.
 The prefix must be valid string (i.e: '@', '#', '\', and so on). This also checks if no repeated prefix are inserted.
 Prefixes can be of any length.
 
 @param prefixes An array of prefix strings.
 */
- (void)registerPrefixesForAutoCompletion:(NSArray *)prefixes;

/**
 Notifies the view controller either the autocompletion prefix or word have changed.
 Use this method to modify your data source or fetch data asynchronously from an HTTP resource.
 Once your data source is ready, make sure to call -showAutoCompletionView: to display the view accordingly.
 You don't need call super since this method doesn't do anything.

 @param prefix The detected prefix.
 @param word The derected word.
 */
- (void)didChangeAutoCompletionPrefix:(NSString *)prefix andWord:(NSString *)word;

/**
 Use this method to programatically show/hide the autocompletion view.
 Right before the view is shown, -reloadData is called. So avoid calling it manually.
 
 @param show YES if the autocompletion view should be shown.
 */
- (void)showAutoCompletionView:(BOOL)show;

/**
 Verifies that the autocompletion view should be shown. Default is NO.
 To enabled autocompletion, you MUST override this method to perform additional tasks, before the autocompletion view is shown (i.e. populating the data source).
 
 @return YES if the autocompletion view should be shown.
 */
- (BOOL)canShowAutoCompletion DEPRECATED_MSG_ATTRIBUTE("Override -didChangeAutoCompletionPrefix:andWord: instead");

/**
 Returns a custom height for the autocompletion view. Default is 0.0.
 You can override this method to return a custom height.
 
 @return The autocompletion view's height.
 */
- (CGFloat)heightForAutoCompletionView;

/**
 Returns the maximum height for the autocompletion view. Default is 140 pts.
 You can override this method to return a custom max height.
 
 @return The autocompletion view's max height.
 */
- (CGFloat)maximumHeightForAutoCompletionView;

/**
 Cancels and hides the autocompletion view, animated.
 */
- (void)cancelAutoCompletion;

/**
 Accepts the autocompletion, replacing the detected word with a new string, keeping the prefix.
 This method is a convinience of -acceptAutoCompletionWithString:keepPrefix:
 
 @param string The string to be used for replacing autocompletion placeholders.
 */
- (void)acceptAutoCompletionWithString:(NSString *)string;

/**
 Accepts the autocompletion, replacing the detected word with a new string, and optionally replacing the prefix too.
 
 @param string The string to be used for replacing autocompletion placeholders.
 @param keepPrefix YES if the prefix shouldn't be overidden.
 */
- (void)acceptAutoCompletionWithString:(NSString *)string keepPrefix:(BOOL)keepPrefix;


#pragma mark - Text Caching
///------------------------------------------------
/// @name Text Caching
///------------------------------------------------

/**
 Returns the key to be associated with a given text to be cached. Default is nil.
 To enable text caching, you must override this method to return valid key.
 The text view will be populated automatically when the view controller is configured.
 You don't need to call super since this method doesn't do anything.
 
 @return The string key for which to enable text caching.
 */
- (NSString *)keyForTextCaching;

/**
 Removes the current's vien controller cached text.
 To enable this, you must return a valid key string in -keyForTextCaching.
 */
- (void)clearCachedText;

/**
 Removes all the cached text from disk.
 */
+ (void)clearAllCachedText;


#pragma mark - Customization
///------------------------------------------------
/// @name Customization
///------------------------------------------------

/**
 Registers a class for customizing the behavior and appearance of the text view.
 You need to call this method inside of any initialization method.
 
 @param aClass A SLKTextView subclass.
 */
- (void)registerClassForTextView:(Class)aClass;

/**
 Registers a class for customizing the behavior and appearance of the typing indicator view.
 You need to call this method inside of any initialization method.
 Make sure to conform to SLKTypingIndicatorProtocol and implement the required methods.
 
 @param aClass A UIView subclass conforming to the SLKTypingIndicatorProtocol.
 */
- (void)registerClassForTypingIndicatorView:(Class)aClass;


#pragma mark - Delegate Methods Requiring Super
///------------------------------------------------
/// @name Delegate Methods Requiring Super
///------------------------------------------------

/** SLKTextViewDelegate */
- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text NS_REQUIRES_SUPER;
- (BOOL)textView:(SLKTextView *)textView shouldInsertSuffixForFormattingWithSymbol:(NSString *)symbol prefixRange:(NSRange)prefixRange NS_REQUIRES_SUPER;

/** UIScrollViewDelegate */
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView NS_REQUIRES_SUPER;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate NS_REQUIRES_SUPER;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView NS_REQUIRES_SUPER;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView NS_REQUIRES_SUPER;

/** UIGestureRecognizerDelegate */
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer NS_REQUIRES_SUPER;

/** UIAlertViewDelegate */
#ifndef __IPHONE_8_0
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex NS_REQUIRES_SUPER;
#endif

#pragma mark - Life Cycle Methods Requiring Super
///------------------------------------------------
/// @name Life Cycle Methods Requiring Super
///------------------------------------------------

/**
 Configures view hierarchy and layout constraints. If you override these methods, make sure to call super.
 */
- (void)loadView NS_REQUIRES_SUPER;
- (void)viewDidLoad NS_REQUIRES_SUPER;
- (void)viewWillAppear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewDidAppear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewWillDisappear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewDidDisappear:(BOOL)animated NS_REQUIRES_SUPER;
- (void)viewWillLayoutSubviews NS_REQUIRES_SUPER;
- (void)viewDidLayoutSubviews NS_REQUIRES_SUPER;

@end
