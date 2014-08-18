//
//  SCKTextView.h
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKTextView.h"

NSString * const SCKTextViewContentSizeDidChangeNotification = @"com.slack.chatkit.text_view.content_size.did_change";

@interface SCKTextView ()
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

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configure];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self configure];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
}


#pragma mark - Setup

- (void)configure
{
    self.placeholderColor = [UIColor lightGrayColor];
    self.font = [UIFont systemFontOfSize:14.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChange:) name:UITextViewTextDidChangeNotification object:nil];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:0 context:NULL];
}


#pragma mark - Getters

- (UILabel *)placeholderLabel
{
    if (!_placeholder) {
        return nil;
    }
    
    if (!_placeholderLabel) {
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
    return self.contentSize.height/self.font.lineHeight;
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

- (void)setText:(NSString *)text
{
    NSLog(@"%s",__FUNCTION__);
    
//    if (!self.isFirstResponder) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:self];
//    }
    
    [super setText:text];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    
    [self textViewDidChange:nil];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    
    self.placeholderLabel.font = self.font;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    
    self.placeholderLabel.textAlignment = textAlignment;
}


#pragma mark - Notifications

- (void)textViewDidChange:(NSNotification *)notification
{
    if (self.placeholder.length == 0) {
        return;
    }

    self.placeholderLabel.hidden = (self.text.length > 0) ? YES : NO;
}


#pragma mark - Rendering

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!self.placeholder) {
        return;
    }
    
    if (self.text.length == 0 && self.placeholder) {
        self.placeholderLabel.frame = CGRectInset(rect, 5.0f, 5.0f);
        self.placeholderLabel.textColor = self.placeholderColor;
        self.placeholderLabel.hidden = NO;
        [self sendSubviewToBack:self.placeholderLabel];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SCKTextViewContentSizeDidChangeNotification object:self userInfo:nil];
    }
}

@end
