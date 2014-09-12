//
//  SCKTextContainerView.h
//  SlackChatKit
//  https://github.com/tinyspeck/slack-chat-kit
//
//  Created by Ignacio Romero Zurbuchen on 8/16/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//  Licence: MIT-Licence
//

#import <UIKit/UIKit.h>

@class SCKChatViewController;
@class SCKTextView;

#define kTextViewVerticalPadding 5
#define kTextViewHorizontalPadding 8
#define kTextContainerViewHeight 44.0
#define kTextViewHeight 32.0
#define kEditingViewHeight 38.0

extern NSString * const SCKInputAccessoryViewKeyboardFrameDidChangeNotification;

@interface SCKInputAccessoryView : UIView
@end

/** @name A custom text input container used to encapsulate controls. */
@interface SCKTextContainerView : UIToolbar

/** A weak reference to the core view controller. */
@property (nonatomic, weak) SCKChatViewController *controller;

/** The centered text input view.
 @discussion The maximum number of lines is configured by default, to best fit each devices dimensions. You can overri
 For iPhone 4       (<=480pts): 4 lines
 For iPhone 5 & 6   (>=568pts): 6 lines
 For iPad           (>=768pts): 8 lines: 8 lines
 */
@property (nonatomic, strong) SCKTextView *textView;

/** The left action button action. */
@property (nonatomic, strong) UIButton *leftButton;
/** The right action button action. */
@property (nonatomic, strong) UIButton *rightButton;
/** YES if the right button should be hidden animatedly in case the text view has no text in it. Default is YES. */
@property (nonatomic, readwrite) BOOL autoHideRightButton;
/** The minimum height of the view. Relies on the intrinsicContentSize values. */
@property (nonatomic, readonly) CGFloat minHeight;
/** The maximum height of the view. Relies on maximum amount of lines of the textView. */
@property (nonatomic, readonly) CGFloat maxHeight;

///------------------------------------------------
/// @name Text Editing
///------------------------------------------------

/** The view displayed on top of the text view container when editing a message. */
@property (nonatomic, strong) UIView *accessoryView;
/** The title label displayed in the middle of the accessoryView. */
@property (nonatomic, strong) UILabel *editorTitle;
/** The 'cancel' button displayed left in the accessoryView. */
@property (nonatomic, strong) UIButton *editortLeftButton;
/** The 'accept' button displayed right in the accessoryView. */
@property (nonatomic, strong) UIButton *editortRightButton;
/** A Boolean value indicating whether the control is in edit mode. */
@property (nonatomic, getter = isEditing) BOOL editing;

/** 
 Verifies if the text can be edited.
 
 @param text The text to be edited.
 @return YES if the text is editable.
 */
- (BOOL)canEditText:(NSString *)text;

/**
 Begins editing the text, by updating the 'editing' flag and the view constraints.
 */
- (void)beginTextEditing;

/**
 Begins editing the text, by updating the 'editing' flag and the view constraints.
 */
- (void)endTextEdition;

@end