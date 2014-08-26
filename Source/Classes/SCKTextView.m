//
//  SCKTextView.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
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
        [self configure];
    }
    return self;
}

- (void)configure
{
    self.placeholderColor = [UIColor lightGrayColor];
    
    self.font = [UIFont systemFontOfSize:14.0f];
    self.editable = YES;
    self.selectable = YES;
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
}


#pragma mark - Rendering

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (self.text.length == 0 && self.placeholder.length > 0) {
        self.placeholderLabel.frame = CGRectInset(rect, 5.0f, 5.0f);
        self.placeholderLabel.textColor = self.placeholderColor;
        self.placeholderLabel.hidden = NO;
        [self sendSubviewToBack:self.placeholderLabel];
    }
}


#pragma mark - Getters

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(CGRectGetWidth(self.superview.frame), 32.0);
}

- (UILabel *)placeholderLabel
{
    if (!_placeholderLabel && _placeholder) {
        _placeholderLabel = [UILabel new];
        _placeholderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _placeholderLabel.numberOfLines = 0;
        _placeholderLabel.font = self.font;
        _placeholderLabel.backgroundColor = [UIColor clearColor];
        _placeholderLabel.textColor = _placeholderColor;
        _placeholderLabel.hidden = YES;
        
        [self addSubview:_placeholderLabel];
    }
    return _placeholderLabel;
}

- (NSUInteger)numberOfLines
{
//    NSLog(@"%s",__FUNCTION__);
//    
//    UIFont *font = [UIFont boldSystemFontOfSize:11.0];
//    CGSize size = [self.text sizeWithFont:font
//                     constrainedToSize:CGSizeMake(self.contentSize.width, CGFLOAT_MAX)
//                         lineBreakMode:NSLineBreakByWordWrapping];
//    
//    NSLog(@"self.text : %@", self.text);
//
//    return abs(size.height / font.lineHeight);
    
    return abs(self.contentSize.height/self.font.lineHeight);
}


#pragma mark - Setters

- (void)setPlaceholder:(NSString *)placeholder
{
    if ([placeholder isEqualToString:self.placeholder]) {
        return;
    }
    
    _placeholder = placeholder;
    self.placeholderLabel.text = placeholder;
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


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL shouldChange = YES;
    
    NSLog(@"%s",__FUNCTION__);
    
    return shouldChange;
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
    
//    [self flashScrollIndicatorsIfNeeded];
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

@end
