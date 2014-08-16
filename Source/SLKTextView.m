//
//  SLKTextView.h
//  SLKChatKit
//
//  Created by Ignacio Romero Z. on 8/15/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SLKTextView.h"

@interface SLKTextView ()
@property (nonatomic, strong) UILabel *placeholderLabel;
@end

@implementation SLKTextView

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)configure
{
    self.contentInset = UIEdgeInsetsMake(-2.0, 0.0, 0.0, 0.0);
    
    self.placeholderColor = [UIColor lightGrayColor];
    self.font = [UIFont systemFontOfSize:14.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChange:) name:UITextViewTextDidChangeNotification object:nil];
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

#pragma mark - Setters

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self textViewDidChange:nil];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    self.placeholderLabel.font = self.font;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    if ([placeholder isEqualToString:_placeholder]) {
        return;
    }
    
    _placeholder = placeholder;
    self.placeholderLabel.text = placeholder;
}

#pragma mark - Auto-Layout

- (void)updateConstraints
{
    [super updateConstraints];
}

- (void)updateConstraintsIfNeeded
{
    [super updateConstraintsIfNeeded];
}

#pragma mark - Notifications

- (void)textViewDidChange:(NSNotification *)notification
{
    if (self.placeholder.length == 0) {
        return;
    }

    _placeholderLabel.hidden = (self.text.length > 0) ? YES : NO;
}

- (BOOL)shouldRenderPlaceholder
{
    if (_placeholderLabel.hidden && self.placeholder.length > 0 && self.text.length == 0) {
        return YES;
    }
    return NO;
}

#pragma mark - UIViewRendering

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!_placeholder) {
        return;
    }
    
    if ([self shouldRenderPlaceholder]) {
        CGRect frame = self.bounds;
        frame.origin.x += 5.0;
        _placeholderLabel.frame = frame;
        _placeholderLabel.textColor = _placeholderColor;
        _placeholderLabel.hidden = NO;
        
        [self sendSubviewToBack:_placeholderLabel];
    }
}

@end
