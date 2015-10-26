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
#import "SLKInputAccessoryView.h"

#import "SLKTextView+SLKAdditions.h"
#import "UIView+SLKAdditions.h"

#import "SLKUIConstants.h"

NSString * const SLKTextInputbarDidMoveNotification =   @"SLKTextInputbarDidMoveNotification";

@interface SLKTextInputbar ()

@property (nonatomic, strong) NSLayoutConstraint *leftButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonHC;
@property (nonatomic, strong) NSLayoutConstraint *leftMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *bottomMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *rightMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonTopMarginC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonBottomMarginC;
@property (nonatomic, strong) NSLayoutConstraint *editorContentViewHC;
@property (nonatomic, strong) NSArray *charCountLabelVCs;

@property (nonatomic, strong) UILabel *charCountLabel;

@property (nonatomic) CGPoint previousOrigin;

@property (nonatomic, strong) Class textViewClass;

@end

@implementation SLKTextInputbar

#pragma mark - Initialization

- (instancetype)initWithTextViewClass:(Class)textViewClass
{
    if (self = [super init]) {
        self.textViewClass = textViewClass;
        [self slk_commonInit];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        [self slk_commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        [self slk_commonInit];
    }
    return self;
}

- (void)slk_commonInit
{
    self.charCountLabelNormalColor = [UIColor lightGrayColor];
    self.charCountLabelWarningColor = [UIColor redColor];
    
    self.autoHideRightButton = YES;
    self.editorContentViewHeight = 38.0;
    self.contentInset = UIEdgeInsetsMake(5.0, 8.0, 5.0, 8.0);
    
    [self addSubview:self.editorContentView];
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    [self addSubview:self.charCountLabel];
    
    [self slk_setupViewConstraints];
    [self slk_updateConstraintConstants];
    
    self.counterStyle = SLKCounterStyleNone;
    self.counterPosition = SLKCounterPositionTop;
    
    [self slk_registerNotifications];
    
    [self slk_registerTo:self.layer forSelector:@selector(position)];
    [self slk_registerTo:self.leftButton.imageView forSelector:@selector(image)];
    [self slk_registerTo:self.rightButton.titleLabel forSelector:@selector(font)];
}


#pragma mark - UIView Overrides

- (void)layoutIfNeeded
{
    if (self.constraints.count == 0 || !self.window) {
        return;
    }
    
    [self slk_updateConstraintConstants];
    [super layoutIfNeeded];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, [self minimumInputbarHeight]);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}


#pragma mark - Getters

- (SLKTextView *)textView
{
    if (!_textView) {
        Class class = self.textViewClass ? : [SLKTextView class];
        
        _textView = [[class alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:15.0];
        _textView.maxNumberOfLines = [self slk_defaultNumberOfLines];

        _textView.typingSuggestionEnabled = YES;
        _textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, -1.0, 0.0, 1.0);
        _textView.textContainerInset = UIEdgeInsetsMake(8.0, 4.0, 8.0, 0.0);
        _textView.layer.cornerRadius = 5.0;
        _textView.layer.borderWidth = 0.5;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:205.0/255.0 alpha:1.0].CGColor;
    }
    return _textView;
}

- (SLKInputAccessoryView *)inputAccessoryView
{
    if (!_inputAccessoryView)
    {
        _inputAccessoryView = [[SLKInputAccessoryView alloc] initWithFrame:CGRectZero];
        _inputAccessoryView.backgroundColor = [UIColor clearColor];
        _inputAccessoryView.userInteractionEnabled = NO;
    }
    
    return _inputAccessoryView;
}

- (UIButton *)leftButton
{
    if (!_leftButton) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton;
}

- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _rightButton.enabled = NO;
        
        NSString *title = NSLocalizedString(@"Send", nil);
        
        [_rightButton setTitle:title forState:UIControlStateNormal];
    }
    return _rightButton;
}

- (UIView *)editorContentView
{
    if (!_editorContentView) {
        _editorContentView = [UIView new];
        _editorContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _editorContentView.backgroundColor = self.backgroundColor;
        _editorContentView.clipsToBounds = YES;
        _editorContentView.hidden = YES;
        
        [_editorContentView addSubview:self.editorTitle];
        [_editorContentView addSubview:self.editorLeftButton];
        [_editorContentView addSubview:self.editorRightButton];
        
        NSDictionary *views = @{@"label": self.editorTitle,
                                @"leftButton": self.editorLeftButton,
                                @"rightButton": self.editorRightButton,
                                };
        
        NSDictionary *metrics = @{@"left" : @(self.contentInset.left),
                                  @"right" : @(self.contentInset.right)
                                  };
        
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[leftButton(60)]-(left)-[label(>=0)]-(right)-[rightButton(60)]-(<=right)-|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|" options:0 metrics:metrics views:views]];
        [_editorContentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
    }
    return _editorContentView;
}

- (UILabel *)editorTitle
{
    if (!_editorTitle) {
        _editorTitle = [UILabel new];
        _editorTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _editorTitle.textAlignment = NSTextAlignmentCenter;
        _editorTitle.backgroundColor = [UIColor clearColor];
        _editorTitle.font = [UIFont boldSystemFontOfSize:15.0];
        
        NSString *title = NSLocalizedString(@"Editing Message", nil);
        
        _editorTitle.text = title;
    }
    return _editorTitle;
}

- (UIButton *)editorLeftButton
{
    if (!_editorLeftButton) {
        _editorLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editorLeftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editorLeftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _editorLeftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        
        NSString *title = NSLocalizedString(@"Cancel", nil);
        
        [_editorLeftButton setTitle:title forState:UIControlStateNormal];
    }
    return _editorLeftButton;
}

- (UIButton *)editorRightButton
{
    if (!_editorRightButton) {
        _editorRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editorRightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editorRightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _editorRightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _editorRightButton.enabled = NO;
        
        NSString *title = NSLocalizedString(@"Save", nil);
        
        [_editorRightButton setTitle:title forState:UIControlStateNormal];
    }
    return _editorRightButton;
}

- (UILabel *)charCountLabel
{
    if (!_charCountLabel) {
        _charCountLabel = [UILabel new];
        _charCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _charCountLabel.backgroundColor = [UIColor clearColor];
        _charCountLabel.textAlignment = NSTextAlignmentRight;
        _charCountLabel.font = [UIFont systemFontOfSize:11.0];
        
        _charCountLabel.hidden = NO;
    }
    return _charCountLabel;
}

- (CGFloat)minimumInputbarHeight
{
    CGFloat minimumTextViewHeight = self.textView.intrinsicContentSize.height;
    minimumTextViewHeight += self.contentInset.top + self.contentInset.bottom;
    
    return minimumTextViewHeight;
}

- (CGFloat)appropriateHeight
{
    CGFloat height = 0.0;
    CGFloat minimumHeight = [self minimumInputbarHeight];
    
    if (self.textView.numberOfLines == 1) {
        height = minimumHeight;
    }
    else if (self.textView.numberOfLines < self.textView.maxNumberOfLines) {
        height = [self slk_inputBarHeightForLines:self.textView.numberOfLines];
    }
    else {
        height = [self slk_inputBarHeightForLines:self.textView.maxNumberOfLines];
    }
    
    if (height < minimumHeight) {
        height = minimumHeight;
    }
    
    if (self.isEditing) {
        height += self.editorContentViewHeight;
    }
    
    return roundf(height);
}

- (CGFloat)slk_inputBarHeightForLines:(NSUInteger)numberOfLines
{
    CGFloat height = self.textView.intrinsicContentSize.height;
    height -= self.textView.font.lineHeight;
    height += roundf(self.textView.font.lineHeight*numberOfLines);
    height += self.contentInset.top + self.contentInset.bottom;
    
    return height;
}

- (BOOL)limitExceeded
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (self.maxCharCount > 0 && text.length > self.maxCharCount) {
        return YES;
    }
    return NO;
}

- (CGFloat)slk_appropriateRightButtonWidth
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }

    NSString *title = [self.rightButton titleForState:UIControlStateNormal];

    CGSize rightButtonSize;
    
    if ([title length] == 0 && self.rightButton.imageView.image) {
        rightButtonSize = self.rightButton.imageView.image.size;
    }
    else {
        rightButtonSize = [title sizeWithAttributes:@{NSFontAttributeName: self.rightButton.titleLabel.font}];
    }

    return rightButtonSize.width + self.contentInset.right;
}

- (CGFloat)slk_appropriateRightButtonMargin
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    return self.contentInset.right;
}

- (NSUInteger)slk_defaultNumberOfLines
{
    if (SLK_IS_IPAD) {
        return 8;
    }
    if (SLK_IS_IPHONE4) {
        return 4;
    }
    else {
        return 6;
    }
}


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
    self.editorContentView.backgroundColor = color;
}

- (void)setAutoHideRightButton:(BOOL)hide
{
    if (self.autoHideRightButton == hide) {
        return;
    }
    
    _autoHideRightButton = hide;
    
    self.rightButtonWC.constant = [self slk_appropriateRightButtonWidth];
    self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];

    [self layoutIfNeeded];
}

- (void)setContentInset:(UIEdgeInsets)insets
{
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, insets)) {
        return;
    }
    
    if (UIEdgeInsetsEqualToEdgeInsets(self.contentInset, UIEdgeInsetsZero)) {
        _contentInset = insets;
        return;
    }
    
    _contentInset = insets;
    
    // Add new constraints
    [self removeConstraints:self.constraints];
    [self slk_setupViewConstraints];
    
    // Add constant values and refresh layout
    [self slk_updateConstraintConstants];
    [super layoutIfNeeded];
}

- (void)setEditing:(BOOL)editing
{
    if (self.isEditing == editing) {
        return;
    }
    
    _editing = editing;
    _editorContentView.hidden = !editing;
}

- (void)setCounterPosition:(SLKCounterPosition)counterPosition
{
    if (self.counterPosition == counterPosition && self.charCountLabelVCs) {
        return;
    }
    
    // Clears the previous constraints
    if (_charCountLabelVCs.count > 0) {
        [self removeConstraints:_charCountLabelVCs];
        _charCountLabelVCs = nil;
    }
    
    _counterPosition = counterPosition;
    
    NSDictionary *views = @{@"rightButton": self.rightButton,
                            @"charCountLabel": self.charCountLabel
                            };
    
    NSDictionary *metrics = @{@"top" : @(self.contentInset.top),
                              @"bottom" : @(-self.contentInset.bottom/2.0)
                              };
    
    // Constraints are different depending of the counter's position type
    if (counterPosition == SLKCounterPositionBottom) {
        _charCountLabelVCs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[charCountLabel]-(bottom)-[rightButton]" options:0 metrics:metrics views:views];
    }
    else {
        _charCountLabelVCs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(top@750)-[charCountLabel]-(>=0)-|" options:0 metrics:metrics views:views];
    }
    
    [self addConstraints:self.charCountLabelVCs];
}


#pragma mark - Text Editing

- (BOOL)canEditText:(NSString *)text
{
    if ((self.isEditing && [self.textView.text isEqualToString:text]) || self.controller.isTextInputbarHidden) {
        return NO;
    }
    
    return YES;
}

- (void)beginTextEditing
{
    if (self.isEditing || self.controller.isTextInputbarHidden) {
        return;
    }
    
    self.editing = YES;
    
    [self slk_updateConstraintConstants];
    
    if (!self.isFirstResponder) {
        [self layoutIfNeeded];
    }
}

- (void)endTextEdition
{
    if (!self.isEditing || self.controller.isTextInputbarHidden) {
        return;
    }
    
    self.editing = NO;
    
    [self slk_updateConstraintConstants];
}


#pragma mark - Character Counter

- (void)slk_updateCounter
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSString *counter = nil;
    
    if (self.counterStyle == SLKCounterStyleNone) {
        counter = [NSString stringWithFormat:@"%lu", (unsigned long)text.length];
    }
    if (self.counterStyle == SLKCounterStyleSplit) {
        counter = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)text.length, (unsigned long)self.maxCharCount];
    }
    if (self.counterStyle == SLKCounterStyleCountdown) {
        counter = [NSString stringWithFormat:@"%ld", (long)(text.length - self.maxCharCount)];
    }
    if (self.counterStyle == SLKCounterStyleCountdownReversed)
    {
        counter = [NSString stringWithFormat:@"%ld", (long)(self.maxCharCount - text.length)];
    }
    
    self.charCountLabel.text = counter;
    self.charCountLabel.textColor = [self limitExceeded] ? self.charCountLabelWarningColor : self.charCountLabelNormalColor;
}


#pragma mark - Notification Events

- (void)slk_didChangeTextViewText:(NSNotification *)notification
{
    SLKTextView *textView = (SLKTextView *)notification.object;
    
    // Skips this it's not the expected textView.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    // Updates the char counter label
    if (self.maxCharCount > 0) {
        [self slk_updateCounter];
    }
    
    if (self.autoHideRightButton && !self.isEditing)
    {
        CGFloat rightButtonNewWidth = [self slk_appropriateRightButtonWidth];
        
        if (self.rightButtonWC.constant == rightButtonNewWidth) {
            return;
        }
        
        self.rightButtonWC.constant = rightButtonNewWidth;
        self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];
        
        if (rightButtonNewWidth > 0) {
            [self.rightButton sizeToFit];
        }
        
        BOOL bounces = self.controller.bounces && [self.textView isFirstResponder];
        
        if (self.window) {
            [self slk_animateLayoutIfNeededWithBounce:bounces
                                              options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState
                                           animations:NULL];
        }
        else {
            [self layoutIfNeeded];
        }
    }
}

- (void)slk_didChangeTextViewContentSize:(NSNotification *)notification
{
    if (self.maxCharCount > 0) {
        BOOL shouldHide = (self.textView.numberOfLines == 1) || self.editing;
        self.charCountLabel.hidden = shouldHide;
    }
}

- (void)slk_didChangeContentSizeCategory:(NSNotification *)notification
{
    if (!self.textView.isDynamicTypeEnabled) {
        return;
    }
    
    [self layoutIfNeeded];
}


#pragma mark - View Auto-Layout

- (void)slk_setupViewConstraints
{
    [self.rightButton sizeToFit];
    
    CGFloat rightVerMargin = (self.intrinsicContentSize.height - CGRectGetHeight(self.rightButton.frame)) / 2.0;
    
    NSDictionary *views = @{@"textView": self.textView,
                            @"leftButton": self.leftButton,
                            @"rightButton": self.rightButton,
                            @"contentView": self.editorContentView,
                            @"charCountLabel": self.charCountLabel
                            };
    
    NSDictionary *metrics = @{@"top" : @(self.contentInset.top),
                              @"bottom" : @(self.contentInset.bottom),
                              @"left" : @(self.contentInset.left),
                              @"right" : @(self.contentInset.right),
                              @"rightVerMargin" : @(rightVerMargin),
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[leftButton(0)]-(<=left)-[textView]-(right)-[rightButton(0)]-(right)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton(0)]-(0@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightVerMargin)-[rightButton]-(<=rightVerMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left@250)-[charCountLabel(<=50@1000)]-(right@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[contentView(0)]-(<=top)-[textView(0@999)]-(bottom)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:metrics views:views]];
    
    self.editorContentViewHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.editorContentView secondItem:nil];
    
    self.leftButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.leftButton secondItem:nil];
    self.leftButtonHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.leftButton secondItem:nil];
    
    self.leftMarginWC = [self slk_constraintsForAttribute:NSLayoutAttributeLeading][0];
    self.bottomMarginWC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.leftButton];
    
    self.rightButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.rightButton secondItem:nil];
    self.rightMarginWC = [self slk_constraintsForAttribute:NSLayoutAttributeTrailing][0];
    
    self.rightButtonTopMarginC = [self slk_constraintForAttribute:NSLayoutAttributeTop firstItem:self.rightButton secondItem:self];
    self.rightButtonBottomMarginC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.rightButton];
}

- (void)slk_updateConstraintConstants
{
    CGFloat zero = 0.0;
    
    if (self.isEditing)
    {
        self.editorContentViewHC.constant = self.editorContentViewHeight;
        self.leftButtonWC.constant = zero;
        self.leftButtonHC.constant = zero;
        self.leftMarginWC.constant = zero;
        self.bottomMarginWC.constant = zero;
        self.rightButtonWC.constant = zero;
        self.rightMarginWC.constant = zero;
    }
    else {
        self.editorContentViewHC.constant = zero;
        
        CGSize leftButtonSize = [self.leftButton imageForState:self.leftButton.state].size;
        
        if (leftButtonSize.width > 0) {
            self.leftButtonHC.constant = roundf(leftButtonSize.height);
            self.bottomMarginWC.constant = roundf((self.intrinsicContentSize.height - leftButtonSize.height) / 2.0);
        }
        
        self.leftButtonWC.constant = roundf(leftButtonSize.width);
        self.leftMarginWC.constant = (leftButtonSize.width > 0) ? self.contentInset.left : zero;
        
        self.rightButtonWC.constant = [self slk_appropriateRightButtonWidth];
        self.rightMarginWC.constant = [self slk_appropriateRightButtonMargin];
        
        [self.rightButton sizeToFit];
        
        CGFloat rightVerMargin = (self.intrinsicContentSize.height - CGRectGetHeight(self.rightButton.frame)) / 2.0;
        
        self.rightButtonTopMarginC.constant = rightVerMargin;
        self.rightButtonBottomMarginC.constant = rightVerMargin;
    }
}


#pragma mark - Observers

- (void)slk_registerTo:(id)object forSelector:(SEL)selector
{
    if (object) {
        [object addObserver:self forKeyPath:NSStringFromSelector(selector) options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)slk_unregisterFrom:(id)object forSelector:(SEL)selector
{
    if (object) {
        [object removeObserver:self forKeyPath:NSStringFromSelector(selector)];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.layer] && [keyPath isEqualToString:NSStringFromSelector(@selector(position))]) {
        
        if (!CGPointEqualToPoint(self.previousOrigin, self.frame.origin)) {
            self.previousOrigin = self.frame.origin;
            [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextInputbarDidMoveNotification object:self userInfo:@{@"origin": [NSValue valueWithCGPoint:self.previousOrigin]}];
        }
    }
    else if ([object isEqual:self.leftButton.imageView] && [keyPath isEqualToString:NSStringFromSelector(@selector(image))]) {
        
        UIImage *newImage = change[NSKeyValueChangeNewKey];
        UIImage *oldImage = change[NSKeyValueChangeOldKey];
        
        if (![newImage isEqual:oldImage]) {
            [self slk_updateConstraintConstants];
        }
    }
    else if ([object isEqual:self.rightButton.titleLabel] && [keyPath isEqualToString:NSStringFromSelector(@selector(font))]) {
        
        [self slk_updateConstraintConstants];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - NSNotificationCenter register/unregister

- (void)slk_registerNotifications
{
    [self slk_unregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeContentSizeCategory:) name:UIContentSizeCategoryDidChangeNotification object:nil];
}

- (void)slk_unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewContentSizeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [self slk_unregisterNotifications];
    
    [self slk_unregisterFrom:self.layer forSelector:@selector(position)];
    [self slk_unregisterFrom:self.leftButton.imageView forSelector:@selector(image)];
    [self slk_unregisterFrom:self.rightButton.titleLabel forSelector:@selector(font)];
    
    _leftButton = nil;
    _rightButton = nil;
    
    _inputAccessoryView = nil;
    _textView.delegate = nil;
    _textView = nil;
    
    _editorContentView = nil;
    _editorTitle = nil;
    _editorLeftButton = nil;
    _editorRightButton = nil;
    
    _leftButtonWC = nil;
    _leftButtonHC = nil;
    _leftMarginWC = nil;
    _bottomMarginWC = nil;
    _rightButtonWC = nil;
    _rightMarginWC = nil;
    _rightButtonTopMarginC = nil;
    _rightButtonBottomMarginC = nil;
    _editorContentViewHC = nil;
}

@end
