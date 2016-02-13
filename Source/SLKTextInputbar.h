//
//   Copyright 2014-2016 Slack Technologies, Inc.
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

#import <UIKit/UIKit.h>

@class SLKTextView;
@class SLKInputAccessoryView;

typedef NS_ENUM(NSUInteger, SLKCounterStyle) {
    SLKCounterStyleNone,
    SLKCounterStyleSplit,
    SLKCounterStyleCountdown,
    SLKCounterStyleCountdownReversed
};

typedef NS_ENUM(NSUInteger, SLKCounterPosition) {
    SLKCounterPositionTop,
    SLKCounterPositionBottom
};

/** @name A custom tool bar encapsulating messaging controls. */
@interface SLKTextInputbar : UIToolbar

/** The centered text input view.
 The maximum number of lines is configured by default, to best fit each devices dimensions.
 For iPhone 4       (<=480pts): 4 lines
 For iPhone 5 & 6   (>=568pts): 6 lines
 For iPad           (>=768pts): 8 lines
 */
@property (nonatomic, strong) SLKTextView *textView;

/** The custom input accessory view, used as empty achor view to detect the keyboard frame. */
@property (nonatomic, strong) SLKInputAccessoryView *inputAccessoryView;

/** The left action button action. */
@property (nonatomic, strong) UIButton *leftButton;

/** The right action button action. */
@property (nonatomic, strong) UIButton *rightButton;

/** YES if the right button should be hidden animatedly in case the text view has no text in it. Default is YES. */
@property (nonatomic, readwrite) BOOL autoHideRightButton;

/** YES if animations should have bouncy effects. Default is YES. */
@property (nonatomic, assign) BOOL bounces;

/** The inner padding to use when laying out content in the view. Default is {5, 8, 5, 8}. */
@property (nonatomic, assign) UIEdgeInsets contentInset;

/** The minimum height based on the intrinsic content size's. */
@property (nonatomic, readonly) CGFloat minimumInputbarHeight;

/** The most appropriate height calculated based on the amount of lines of text and other factors. */
@property (nonatomic, readonly) CGFloat appropriateHeight;


#pragma mark - Initialization
///------------------------------------------------
/// @name Initialization
///------------------------------------------------

/**
 Initializes a text input bar with a class to be used for the text view
 
 @param textViewClass The class to be used when creating the text view. May be nil. If provided, the class must be a subclass of SLKTextView
 @return An initialized SLKTextInputbar object or nil if the object could not be created.
 */
- (instancetype)initWithTextViewClass:(Class)textViewClass;


#pragma mark - Text Editing
///------------------------------------------------
/// @name Text Editing
///------------------------------------------------

/** The view displayed on top if the text input bar, containing the button outlets, when editing is enabled. */
@property (nonatomic, strong) UIView *editorContentView;

/** The title label displayed in the middle of the accessoryView. */
@property (nonatomic, strong) UILabel *editorTitle;

/** The 'cancel' button displayed left in the accessoryView. */
@property (nonatomic, strong) UIButton *editorLeftButton;

/** The 'accept' button displayed right in the accessoryView. */
@property (nonatomic, strong) UIButton *editorRightButton;

/** The accessory view's maximum height. Default is 38 pts. */
@property (nonatomic, assign) CGFloat editorContentViewHeight;

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
 End editing the text, by updating the 'editing' flag and the view constraints.
 */
- (void)endTextEdition;


#pragma mark - Text Counting
///------------------------------------------------
/// @name Text Counting
///------------------------------------------------

/** The label used to display the character counts. */
@property (nonatomic, readonly) UILabel *charCountLabel;

/** The maximum character count allowed. If larger than 0, a character count label will be displayed on top of the right button. Default is 0, which means limitless.*/
@property (nonatomic, readwrite) NSUInteger maxCharCount;

/** The character counter formatting. Ignored if maxCharCount is 0. Default is None. */
@property (nonatomic, assign) SLKCounterStyle counterStyle;

/** The character counter layout style. Ignored if maxCharCount is 0. Default is SLKCounterPositionTop. */
@property (nonatomic, assign) SLKCounterPosition counterPosition;

/** YES if the maxmimum character count has been exceeded. */
@property (nonatomic, readonly) BOOL limitExceeded;

/** The normal color used for character counter label. Default is lightGrayColor. */
@property (nonatomic, strong, readwrite) UIColor *charCountLabelNormalColor;

/** The color used for character counter label when it has exceeded the limit. Default is redColor. */
@property (nonatomic, strong, readwrite) UIColor *charCountLabelWarningColor;

@end
