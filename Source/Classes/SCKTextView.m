//
//  SCKTextView.h
//  SlackChatKit
//  https://github.com/tinyspeck/slack-chat-kit
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//  Licence: MIT-Licence
//

#import "SCKTextView.h"

NSString * const SCKTextViewTextWillChangeNotification = @"com.slack.chatkit.SCKTextView.willChangeText";
NSString * const SCKTextViewSelectionDidChangeNotification = @"com.slack.chatkit.SCKTextView.didChangeSelection";
NSString * const SCKTextViewContentSizeDidChangeNotification = @"com.slack.chatkit.SCKTextView.didChangeContentSize";
NSString * const SCKTextViewDidPasteImageNotification = @"com.slack.chatkit.SCKTextView.didPasteImage";
NSString * const SCKTextViewDidShakeNotification = @"com.slack.chatkit.SCKTextView.didShake";

@interface SCKTextView ()
{
    BOOL _didFlashScrollIndicators;
}
@property (nonatomic, strong) UILabel *placeholderLabel;
@end

@implementation SCKTextView

#pragma mark - Initialization

- (id)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.placeholderColor = [UIColor lightGrayColor];
    
    self.font = [UIFont systemFontOfSize:14.0];
    self.editable = YES;
    self.selectable = YES;
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.directionalLockEnabled = YES;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:NULL];
}


#pragma mark - Rendering

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    // This covers a few edge cases where the hidden status hasn't yet changed before -setNeedsDisplay is called
    if (self.text.length == 0 && self.placeholder.length > 0) {
        self.placeholderLabel.hidden = NO;
        [self sendSubviewToBack:self.placeholderLabel];
    }
}


#pragma mark - Getters

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 32.0);
}

- (UILabel *)placeholderLabel
{
    if (!_placeholderLabel)
    {
        _placeholderLabel = [UILabel new];
        _placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _placeholderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _placeholderLabel.numberOfLines = 0;
        _placeholderLabel.font = self.font;
        _placeholderLabel.backgroundColor = [UIColor clearColor];
        _placeholderLabel.textColor = self.placeholderColor;
        _placeholderLabel.hidden = YES;
        
        [self addSubview:_placeholderLabel];
        
        NSDictionary *views = @{@"label": _placeholderLabel};
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[label]-5-|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[label]-8-|" options:0 metrics:nil views:views]];
    }
    return _placeholderLabel;
}

- (NSString *)placeholder
{
    return self.placeholderLabel.text;
}

- (UIColor *)placeholderColor
{
    return self.placeholderLabel.textColor;
}

- (BOOL)isExpanding
{
    if (self.numberOfLines >= self.maxNumberOfLines) {
        return YES;
    }
    return NO;
}


#pragma mark - Setters

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeholderLabel.text = placeholder;
}

- (void)setPlaceholderColor:(UIColor *)color
{
    self.placeholderLabel.textColor = color;
}


#pragma mark - Overrides

- (void)setText:(NSString *)text
{
    [super setText:text];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(delete:)) {
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)paste:(id)sender
{
    UIImage *image = [[UIPasteboard generalPasteboard] image];
    NSString *text = [[UIPasteboard generalPasteboard] string];
    
    if (image) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SCKTextViewDidPasteImageNotification object:image];
    }
    else if (text.length > 0){
        
        // Inserting the text fixes a UITextView bug whitch automatically scrolls to the bottom
        // and beyond scroll content size sometimes when the text is too long
        [self insertTextAtCaretRange:text];
    }
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    
    // Updates the placeholder font too
    self.placeholderLabel.font = self.font;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    
    // Updates the placeholder text alignment too
    self.placeholderLabel.textAlignment = textAlignment;
}


#pragma mark - Custom Actions

- (void)flashScrollIndicatorsIfNeeded
{
    if (self.numberOfLines == self.maxNumberOfLines+1) {
        if (!_didFlashScrollIndicators) {
            _didFlashScrollIndicators = YES;
            [super flashScrollIndicators];
        }
    }
    else if (_didFlashScrollIndicators) {
        _didFlashScrollIndicators = NO;
    }
}


#pragma mark - Observers & Notifications

- (void)didChangeTextView:(NSNotification *)notification
{
    if (self.placeholder.length > 0) {
        self.placeholderLabel.hidden = (self.text.length > 0) ? YES : NO;
    }
    
    [self flashScrollIndicatorsIfNeeded];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SCKTextViewContentSizeDidChangeNotification object:self userInfo:nil];
    }
}


#pragma mark - Motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SCKTextViewDidShakeNotification object:self];
	}
}


#pragma mark - Lifeterm

- (void)dealloc
{
    _placeholderLabel = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
}

@end
