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

#import "SLKTextInputbar.h"
#import "SLKTextViewController.h"
#import "SLKTextView.h"

#import "UITextView+SLKAdditions.h"
#import "UIView+SLKAdditions.h"

#import "SLKUIConstants.h"

NSString * const SCKInputAccessoryViewKeyboardFrameDidChangeNotification = @"com.slack.TextViewController.TextInputbar.FrameDidChange";

@interface SLKTextInputbar () <UITextViewDelegate>

@property (nonatomic, strong) NSLayoutConstraint *leftButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonHC;
@property (nonatomic, strong) NSLayoutConstraint *leftMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *bottomMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *rightMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *accessoryViewHC;

@end

@implementation SLKTextInputbar

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.translucent = NO;
    self.autoHideRightButton = YES;
    self.editing = NO;
    
    [self addSubview:self.accessoryView];
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    
    [self setupViewConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
    [self.leftButton.imageView addObserver:self forKeyPath:NSStringFromSelector(@selector(image)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}


#pragma mark - UIView Overrides

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    [self updateConstraintConstants];
    [self layoutIfNeeded];
}


#pragma mark - UIView Overrides

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, kTextInputbarMinimumHeight);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}


#pragma mark - Getters

- (SLKTextView *)textView
{
    if (!_textView)
    {
        _textView = [SLKTextView new];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:15.0];
        _textView.maxNumberOfLines = [self defaultNumberOfLines];
        
//#if DEBUG && TARGET_IPHONE_SIMULATOR
//        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
//        _textView.spellCheckingType = UITextSpellCheckingTypeNo;
//#else
        _textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        _textView.spellCheckingType = UITextSpellCheckingTypeDefault;
//#endif
        
        _textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, -1, 0, 1);
        _textView.delegate = self;
        
        _textView.layer.cornerRadius = 5.0;
        _textView.layer.borderWidth = 1.0;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0].CGColor;
        
        // Registers the loupe gesture to detect when it will become visible
        for (UIGestureRecognizer *gesture in _textView.gestureRecognizers) {
            if ([gesture isKindOfClass:NSClassFromString(@"UIVariableDelayLoupeGesture")]) {
                [gesture addTarget:self action:@selector(willShowLoupe:)];
            }
        }
    }
    return _textView;
}

- (UIButton *)leftButton
{
    if (!_leftButton)
    {
        _leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton;
}

- (UIButton *)rightButton
{
    if (!_rightButton)
    {
        _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _rightButton.enabled = NO;
        
        [_rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    }
    return _rightButton;
}

- (UIView *)accessoryView
{
    if (!_accessoryView)
    {
        _accessoryView = [UIView new];
        _accessoryView.translatesAutoresizingMaskIntoConstraints = NO;
        _accessoryView.backgroundColor = self.backgroundColor;
        _accessoryView.clipsToBounds = YES;
        _accessoryView.hidden = YES;
        
        _editorTitle = [UILabel new];
        _editorTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _editorTitle.text = NSLocalizedString(@"Editing Message", nil);
        _editorTitle.textAlignment = NSTextAlignmentCenter;
        _editorTitle.backgroundColor = [UIColor clearColor];
        _editorTitle.font = [UIFont boldSystemFontOfSize:15.0];
        [_accessoryView addSubview:self.editorTitle];
        
        _editortLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editortLeftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editortLeftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _editortLeftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_editortLeftButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [_accessoryView addSubview:self.editortLeftButton];
        
        _editortRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editortRightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editortRightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _editortRightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _editortRightButton.enabled = NO;
        [_editortRightButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateNormal];
        [_accessoryView addSubview:self.editortRightButton];
        
        NSDictionary *views = @{@"label": self.editorTitle,
                                @"leftButton": self.editortLeftButton,
                                @"rightButton": self.editortRightButton,
                                };
        
        NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding),
                                  @"ver" : @(kTextViewVerticalPadding),
                                  };
        
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[leftButton(60)]-(==hor)-[label(>=0)]-(==hor)-[rightButton(60)]-(<=hor)-|" options:0 metrics:metrics views:views]];
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|" options:0 metrics:metrics views:views]];
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|" options:0 metrics:metrics views:views]];
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
    }
    return _accessoryView;
}

- (NSUInteger)defaultNumberOfLines
{
    if (UI_IS_IPAD) {
        return 8;
    }
    if (UI_IS_IPHONE4) {
        return 4;
    }
    else {
        return 6;
    }
}

- (CGFloat)appropriateRightButtonWidth
{
    NSString *title = [self.rightButton titleForState:UIControlStateNormal];
    CGSize rigthButtonSize = [title sizeWithAttributes:@{NSFontAttributeName: self.rightButton.titleLabel.font}];
    
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    return rigthButtonSize.width+kTextViewHorizontalPadding;
}

- (CGFloat)appropriateRightButtonMargin
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    
    return kTextViewHorizontalPadding;
}


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
    self.textView.inputAccessoryView.backgroundColor = color;
    self.accessoryView.backgroundColor = color;
}

- (void)setAutoHideRightButton:(BOOL)hide
{
    if (self.autoHideRightButton != hide) {
        _autoHideRightButton = hide;
    }
    
    self.rightButtonWC.constant = [self appropriateRightButtonWidth];
    [self layoutIfNeeded];
}

- (void)setEditing:(BOOL)editing
{
    if (self.isEditing == editing) {
        return;
    }
    
    _editing = editing;
    _accessoryView.hidden = !editing;
}


#pragma mark - Text Editing

- (BOOL)canEditText:(NSString *)text
{
    if (self.isEditing && [self.textView.text isEqualToString:text]) {
        return NO;
    }

    return YES;
}

- (void)beginTextEditing
{
    if (self.isEditing) {
        return;
    }
    
    self.editing = YES;
    
    [self updateConstraintConstants];
}

- (void)endTextEdition
{
    if (!self.isEditing) {
        return;
    }
    
    self.editing = NO;
    
    [self updateConstraintConstants];
}


#pragma mark - Magnifying Glass handling

- (void)willShowLoupe:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.textView.loupeVisible = YES;
    }
    else {
        self.textView.loupeVisible = NO;
    }
    
    // We still need to notify a selection change in the textview after the magnifying class is dismissed
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self textViewDidChangeSelection:self.textView];
    }
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        //Detected break. Should insert new line break manually.
        [textView insertNewLineBreak];
        
        return NO;
    }
    else {
        NSDictionary *userInfo = @{@"text": text, @"range": [NSValue valueWithRange:range]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewTextWillChangeNotification object:self.textView userInfo:userInfo];
        
        return YES;
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (self.textView.isLoupeVisible) {
        return;
    }
    
    NSDictionary *userInfo = @{@"range": [NSValue valueWithRange:textView.selectedRange]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewSelectionDidChangeNotification object:self.textView userInfo:userInfo];
}

- (void)didChangeTextView:(NSNotification *)notification
{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    if (self.autoHideRightButton && !self.isEditing)
    {
        CGFloat rightButtonNewWidth = [self appropriateRightButtonWidth];
        
        if (self.rightButtonWC.constant == rightButtonNewWidth) {
            return;
        }
        
        self.rightButtonWC.constant = rightButtonNewWidth;
        self.rightMarginWC.constant = [self appropriateRightButtonMargin];
        
        if (rightButtonNewWidth > 0) {
            [self.rightButton sizeToFit];
        }
        
        BOOL bounces = self.controller.bounces && [self.textView isFirstResponder];
        
        [self animateLayoutIfNeededWithBounce:bounces
                                      options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                                   animations:NULL];
    }
}


#pragma mark - View Auto-Layout

- (void)setupViewConstraints
{
    UIImage *leftButtonImg = [self.leftButton imageForState:UIControlStateNormal];
    
    [self.rightButton sizeToFit];
    
    CGFloat leftVerMargin = (self.intrinsicContentSize.height - leftButtonImg.size.height) / 2.0;
    CGFloat rightVerMargin = (self.intrinsicContentSize.height - CGRectGetHeight(self.rightButton.frame)) / 2.0;

    NSDictionary *views = @{@"textView": self.textView,
                            @"leftButton": self.leftButton,
                            @"rightButton": self.rightButton,
                            @"accessoryView": self.accessoryView
                            };
    
    NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding),
                              @"ver" : @(kTextViewVerticalPadding),
                              @"leftVerMargin" : @(leftVerMargin),
                              @"rightVerMargin" : @(rightVerMargin),
                              @"minTextViewHeight" : @(self.textView.intrinsicContentSize.height),
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[leftButton(0)]-(<=hor)-[textView]-(==hor)-[rightButton(0)]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton(0)]-(0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightVerMargin)-[rightButton]-(<=rightVerMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[accessoryView(0)]-(<=ver)-[textView(==minTextViewHeight@250)]-(==ver)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[accessoryView]|" options:0 metrics:metrics views:views]];

    NSArray *heightConstraints = [self constraintsForAttribute:NSLayoutAttributeHeight];
    NSArray *widthConstraints = [self constraintsForAttribute:NSLayoutAttributeWidth];
    NSArray *bottomConstraints = [self constraintsForAttribute:NSLayoutAttributeBottom];

    self.accessoryViewHC = heightConstraints[1];

    self.leftButtonWC = widthConstraints[0];
    self.leftButtonHC = heightConstraints[0];
    self.leftMarginWC = [self constraintsForAttribute:NSLayoutAttributeLeading][0];
    self.bottomMarginWC = bottomConstraints[0];

    self.rightButtonWC = widthConstraints[1];
    self.rightMarginWC = [self constraintsForAttribute:NSLayoutAttributeTrailing][0];
}

- (void)updateConstraintConstants
{
    CGFloat zero = 0.0;

    if (self.isEditing)
    {
        self.accessoryViewHC.constant = kAccessoryViewHeight;
        self.leftButtonWC.constant = zero;
        self.leftButtonHC.constant = zero;
        self.leftMarginWC.constant = zero;
        self.bottomMarginWC.constant = zero;
        self.rightButtonWC.constant = zero;
        self.rightMarginWC.constant = zero;
    }
    else
    {
        self.accessoryViewHC.constant = zero;

        CGSize leftButtonSize = [self.leftButton imageForState:self.leftButton.state].size;
        
        self.leftButtonWC.constant = roundf(leftButtonSize.width);
        self.leftButtonHC.constant = roundf(leftButtonSize.height);
        self.leftMarginWC.constant = (leftButtonSize.width > 0) ? kTextViewHorizontalPadding : zero;
        self.bottomMarginWC.constant = roundf((self.intrinsicContentSize.height - leftButtonSize.height) / 2.0);
        
        self.rightButtonWC.constant = [self appropriateRightButtonWidth];
        self.rightMarginWC.constant = [self appropriateRightButtonMargin];
    }
}

#pragma mark - Observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.leftButton.imageView] && [keyPath isEqualToString:NSStringFromSelector(@selector(image))]) {
        UIImage *newImage = change[NSKeyValueChangeNewKey];
        UIImage *oldImage = change[NSKeyValueChangeOldKey];
        if ([newImage isEqual:oldImage]) {
            return;
        }
        [self updateConstraintConstants];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
     [self removeObserver:self.leftButton.imageView forKeyPath:NSStringFromSelector(@selector(image))];
    
    _leftButton = nil;
    _rightButton = nil;
    
    _textView.delegate = nil;
    _textView = nil;
    
    _accessoryView = nil;
    _editorTitle = nil;
    _editortLeftButton = nil;
    _editortRightButton = nil;
    
    _leftButtonWC = nil;
    _leftButtonHC = nil;
    _leftMarginWC = nil;
    _bottomMarginWC = nil;
    _rightButtonWC = nil;
    _rightMarginWC = nil;
    _accessoryViewHC = nil;
}

@end

@implementation SCKInputAccessoryView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(center))];
    }
    
    [newSuperview addObserver:self forKeyPath:NSStringFromSelector(@selector(center)) options:0 context:NULL];
    
    [super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.superview] && [keyPath isEqualToString:NSStringFromSelector(@selector(center))])
    {
        NSDictionary *userInfo = @{UIKeyboardFrameEndUserInfoKey:[NSValue valueWithCGRect:[object frame]]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil userInfo:userInfo];
    }
}

- (void)dealloc
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(center))];
    }
}

@end
