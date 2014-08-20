//
//  SCKTextContainerView.m
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/16/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKTextContainerView.h"

NSString * const SCKInputAccessoryViewKeyboardFrameDidChangeNotification = @"com.slack.chatkit.SCKTextContainerView.frameDidChange";

@interface SCKInputAccessoryView : UIView
@end

@interface SCKTextContainerView () <UITextViewDelegate>
@property (nonatomic, copy) NSString *rightButtonTitle;

@property (nonatomic, strong) NSLayoutConstraint *rightButtonWC;

@end

@implementation SCKTextContainerView

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure
{
    self.translucent = NO;
    self.autoHideRightButton = YES;
    
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    
    [self setupViewConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    _leftButton = nil;
    _rightButton = nil;
    _textView = nil;
}


#pragma mark - Getters

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(CGRectGetWidth(self.superview.frame), 44.0);
}

- (SCKTextView *)textView
{
    if (!_textView)
    {
        _textView = [[SCKTextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:15.0f];
        _textView.maxNumberOfLines = 6;
        _textView.autocorrectionType = UITextAutocorrectionTypeNo; // For debug purpose
        _textView.spellCheckingType = UITextSpellCheckingTypeNo; // For debug purpose
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, -1, 0, 1);
        _textView.inputAccessoryView = [SCKInputAccessoryView new];
        _textView.delegate = self;
        
        _textView.layer.cornerRadius = 4.0f;
        _textView.layer.borderWidth = 1.0f;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:205.0f/255.0f alpha:1.0f].CGColor;
    }
    return _textView;
}

- (UIButton *)leftButton
{
    if (!_leftButton)
    {
        _leftButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
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

- (CGFloat)minHeight
{
    return self.intrinsicContentSize.height;
}

- (CGFloat)maxHeight
{
    CGFloat height = 0.0;
    
    if (self.textView.maxNumberOfLines > 0) {
        height += self.textView.font.lineHeight*self.textView.maxNumberOfLines;
        height += (kTextViewVerticalPadding*2.0);
        
    }
    return height;
}

- (CGFloat)rightButtonWidth
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


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
    self.textView.inputAccessoryView.backgroundColor = color;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSDictionary *userInfo = @{@"text": text, @"range": [NSValue valueWithRange:range]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SCKTextViewTextWillChangeNotification object:self.textView userInfo:userInfo];
    
    return YES;
}

- (void)didChangeTextView:(NSNotification *)notification
{
    SCKTextView *textView = (SCKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    BOOL enableRightButton = (self.textView.text.length > 0) ? YES : NO;
    
    if (self.rightButton.enabled != enableRightButton) {
        [self.rightButton setEnabled:enableRightButton];
    }
    
    if (self.autoHideRightButton)
    {
        CGFloat rightButtonNewWidth = [self rightButtonWidth];
        
        if (self.rightButtonWC.constant == rightButtonNewWidth) {
            return;
        }
        
        self.rightButtonWC.constant = rightButtonNewWidth;
        
        if (rightButtonNewWidth > 0) {
            [self.rightButton sizeToFit];
        }
        
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.7
                            options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self layoutIfNeeded];
                         }
                         completion:NULL];
    }
}


#pragma mark - View Auto-Layout

- (void)setupViewConstraints
{
    // Removes all constraints
    [self removeConstraints:self.constraints];

    UIImage *leftButtonImg = [self.leftButton imageForState:UIControlStateNormal];
    
    [self.rightButton sizeToFit];
    
    CGFloat leftBottomMargin = roundf((self.minHeight - leftButtonImg.size.height) / 2.0f);
    CGFloat rightBottomMargin = roundf((self.minHeight - CGRectGetHeight(self.rightButton.frame)) / 2.0f);

    NSDictionary *views = @{@"textView": self.textView,
                            @"leftButton": self.leftButton,
                            @"rightButton": self.rightButton
                            };
    
    NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding),
                              @"ver" : @(kTextViewVerticalPadding),
                              @"leftBottomMargin" : @(leftBottomMargin),
                              @"rightBottomMargin" : @(roundf(rightBottomMargin)),
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[leftButton]-(==hor)-[textView]-(==hor)-[rightButton(==0)]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=leftBottomMargin)-[leftButton]-(==leftBottomMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightBottomMargin)-[rightButton]-(==rightBottomMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==ver)-[textView]-(==ver)-|" options:0 metrics:metrics views:views]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstAttribute = %d", NSLayoutAttributeWidth];
    NSArray *widthConstraints = [self.constraints filteredArrayUsingPredicate:predicate];

    self.rightButtonWC = widthConstraints[0];
    self.rightButtonWC.constant = [self rightButtonWidth];
    
    [self layoutIfNeeded];
}

@end

@implementation SCKInputAccessoryView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
    }
    
    [newSuperview addObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) options:0 context:NULL];
    
    [super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.superview] && [keyPath isEqualToString:NSStringFromSelector(@selector(frame))])
    {
        NSDictionary *userInfo = @{UIKeyboardFrameEndUserInfoKey:[NSValue valueWithCGRect:[object frame]]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil userInfo:userInfo];
    }
}

- (void)dealloc
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
    }
}

@end
