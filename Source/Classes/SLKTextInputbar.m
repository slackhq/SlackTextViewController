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
#import "SLKTextView+SLKAdditions.h"
#import "SLKUIConstants.h"
#import "UIView+SLKAdditions.h"

@interface SLKTextInputbar ()

@property (nonatomic, strong) NSLayoutConstraint *leftButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonHC;
@property (nonatomic, strong) NSLayoutConstraint *leftMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *bottomMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *rightMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *editorContentViewHC;

@property (nonatomic, strong) UILabel *charCountLabel;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextViewContentSize:) name:SLKTextViewContentSizeDidChangeNotification object:nil];
    
    [self.leftButton.imageView addObserver:self forKeyPath:NSStringFromSelector(@selector(image)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}


#pragma mark - UIView Overrides

- (void)layoutIfNeeded
{
    if (self.constraints.count == 0) {
        return;
    }
    
    [self slk_updateConstraintConstants];
    [super layoutIfNeeded];
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 44.0);
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
        Class class = self.textViewClass ? : [SLKTextView class];
        
        _textView = [class new];
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
        
        // Adds an aditional action to a private gesture to detect when the magnifying glass becomes visible
        for (UIGestureRecognizer *gesture in _textView.gestureRecognizers) {
            if ([gesture isKindOfClass:NSClassFromString(@"UIVariableDelayLoupeGesture")]) {
                [gesture addTarget:self action:@selector(slk_willShowLoupe:)];
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

- (UIView *)editorContentView
{
    if (!_editorContentView)
    {
        _editorContentView = [UIView new];
        _editorContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _editorContentView.backgroundColor = self.backgroundColor;
        _editorContentView.clipsToBounds = YES;
        _editorContentView.hidden = YES;
        
        _editorTitle = [UILabel new];
        _editorTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _editorTitle.text = NSLocalizedString(@"Editing Message", nil);
        _editorTitle.textAlignment = NSTextAlignmentCenter;
        _editorTitle.backgroundColor = [UIColor clearColor];
        _editorTitle.font = [UIFont boldSystemFontOfSize:15.0];
        [_editorContentView addSubview:self.editorTitle];
        
        _editortLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editortLeftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editortLeftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _editortLeftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_editortLeftButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [_editorContentView addSubview:self.editortLeftButton];
        
        _editortRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editortRightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editortRightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _editortRightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _editortRightButton.enabled = NO;
        [_editortRightButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateNormal];
        [_editorContentView addSubview:self.editortRightButton];
        
        NSDictionary *views = @{@"label": self.editorTitle,
                                @"leftButton": self.editortLeftButton,
                                @"rightButton": self.editortRightButton,
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

- (UILabel *)charCountLabel
{
    if (!_charCountLabel)
    {
        _charCountLabel = [UILabel new];
        _charCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _charCountLabel.backgroundColor = [UIColor clearColor];
        _charCountLabel.textAlignment = NSTextAlignmentRight;
        _charCountLabel.font = [UIFont systemFontOfSize:11.0];
        
        _charCountLabel.hidden = NO;
    }
    return _charCountLabel;
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

- (BOOL)slk_limitExceeded
{
    NSString *text = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (self.maxCharCount > 0 && text.length > self.maxCharCount) {
        return YES;
    }
    return NO;
}

- (CGFloat)slk_appropriateRightButtonWidth
{
    NSString *title = [self.rightButton titleForState:UIControlStateNormal];
    CGSize rigthButtonSize = [title sizeWithAttributes:@{NSFontAttributeName: self.rightButton.titleLabel.font}];
    
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    return rigthButtonSize.width+self.contentInset.right;
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

- (BOOL)isViewVisible
{
    SEL selector = NSSelectorFromString(@"isViewVisible");
    
    if ([self.controller respondsToSelector:selector]) {
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        BOOL visible = (BOOL)[self.controller performSelector:selector];
#pragma clang diagnostic pop
        
        return visible;
    }
    return NO;
}


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
    self.textView.inputAccessoryView.backgroundColor = color;
    self.editorContentView.backgroundColor = color;
}

- (void)setAutoHideRightButton:(BOOL)hide
{
    if (self.autoHideRightButton == hide) {
        return;
    }
    
    _autoHideRightButton = hide;
    
    self.rightButtonWC.constant = [self slk_appropriateRightButtonWidth];
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
    
    [self slk_updateConstraintConstants];
    
    if (!self.isFirstResponder) {
        [self layoutIfNeeded];
    }
}

- (void)endTextEdition
{
    if (!self.isEditing) {
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
    
    self.charCountLabel.text = counter;
    self.charCountLabel.textColor = [self slk_limitExceeded] ?  [UIColor redColor] : [UIColor lightGrayColor];
}


#pragma mark - Magnifying Glass handling

- (void)slk_willShowLoupe:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.textView.loupeVisible = YES;
    }
    else {
        self.textView.loupeVisible = NO;
    }
    
    // We still need to notify a selection change in the textview after the magnifying class is dismissed
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (self.textView.delegate && [self.textView.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
            [self.textView.delegate textViewDidChangeSelection:self.textView];
        }
    }
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
        
        if ([self isViewVisible]) {
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


#pragma mark - View Auto-Layout

- (void)slk_setupViewConstraints
{
    UIImage *leftButtonImg = [self.leftButton imageForState:UIControlStateNormal];
    
    [self.rightButton sizeToFit];
    
    CGFloat leftVerMargin = (self.intrinsicContentSize.height - leftButtonImg.size.height) / 2.0;
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
                              @"leftVerMargin" : @(leftVerMargin),
                              @"rightVerMargin" : @(rightVerMargin),
                              @"minTextViewHeight" : @(self.textView.intrinsicContentSize.height),
                              };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left)-[leftButton(0)]-(<=left)-[textView]-(right)-[rightButton(0)]-(right)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton(0)]-(0@750)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightVerMargin)-[rightButton]-(<=rightVerMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(<=top)-[charCountLabel]-(>=0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(left@250)-[charCountLabel(<=50@1000)]-(right@750)-|" options:0 metrics:metrics views:views]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[contentView(0)]-(<=top)-[textView(minTextViewHeight@250)]-(bottom)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:metrics views:views]];
    
    self.editorContentViewHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.editorContentView secondItem:nil];
    
    self.leftButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.leftButton secondItem:nil];
    self.leftButtonHC = [self slk_constraintForAttribute:NSLayoutAttributeHeight firstItem:self.leftButton secondItem:nil];
    
    self.leftMarginWC = [self slk_constraintsForAttribute:NSLayoutAttributeLeading][0];
    self.bottomMarginWC = [self slk_constraintForAttribute:NSLayoutAttributeBottom firstItem:self secondItem:self.leftButton];

    self.rightButtonWC = [self slk_constraintForAttribute:NSLayoutAttributeWidth firstItem:self.rightButton secondItem:nil];
    self.rightMarginWC = [self slk_constraintsForAttribute:NSLayoutAttributeTrailing][0];
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
    else
    {
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
        
        [self slk_updateConstraintConstants];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SLKTextViewContentSizeDidChangeNotification object:nil];
    
    [_leftButton.imageView removeObserver:self forKeyPath:NSStringFromSelector(@selector(image))];
    
    _leftButton = nil;
    _rightButton = nil;
    
    _textView.delegate = nil;
    _textView = nil;
    
    _editorContentView = nil;
    _editorTitle = nil;
    _editortLeftButton = nil;
    _editortRightButton = nil;
    
    _leftButtonWC = nil;
    _leftButtonHC = nil;
    _leftMarginWC = nil;
    _bottomMarginWC = nil;
    _rightButtonWC = nil;
    _rightMarginWC = nil;
    _editorContentViewHC = nil;
}

@end
