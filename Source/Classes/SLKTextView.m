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

#import "SLKTextView.h"
#import "UITextView+SLKAdditions.h"

#import "SLKUIConstants.h"

NSString * const SLKTextViewTextWillChangeNotification = @"com.slack.TextViewController.TextView.WillChangeText";
NSString * const SLKTextViewSelectionDidChangeNotification = @"com.slack.TextViewController.TextView.DidChangeSelection";
NSString * const SLKTextViewContentSizeDidChangeNotification = @"com.slack.TextViewController.TextView.DidChangeContentSize";
NSString * const SLKTextViewDidPasteImageNotification = @"com.slack.TextViewController.TextView.DidPasteImage";
NSString * const SLKTextViewDidShakeNotification = @"com.slack.TextViewController.TextView.DidShake";

@interface SLKTextView ()
{
    BOOL _didFlashScrollIndicators;
}
@property (nonatomic, strong) UILabel *placeholderLabel;
@end

@implementation SLKTextView

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
    
    self.placeholderLabel.hidden = [self shouldHidePlaceholder];
    self.placeholderLabel.frame = [self placeholderRectForBounds:self.bounds];
    [self sendSubviewToBack:self.placeholderLabel];
}


#pragma mark - UIView Overrides

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(UIViewNoIntrinsicMetric, 34.0);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}


#pragma mark - Getters

- (UILabel *)placeholderLabel
{
    if (!_placeholderLabel)
    {
        _placeholderLabel = [UILabel new];
        _placeholderLabel.clipsToBounds = NO;
        _placeholderLabel.autoresizesSubviews = NO;
        _placeholderLabel.numberOfLines = 1;
        _placeholderLabel.font = self.font;
        _placeholderLabel.backgroundColor = [UIColor clearColor];
        _placeholderLabel.textColor = self.placeholderColor;
        _placeholderLabel.hidden = YES;
        
        [self addSubview:_placeholderLabel];
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

- (NSUInteger)numberOfLines
{
    return abs(self.contentSize.height/self.font.lineHeight);
}

// Returns a different number of lines when landscape and only on iPhone
- (NSUInteger)maxNumberOfLines
{
    if (UI_IS_IPHONE && UI_IS_LANDSCAPE) {
        return 2.0;
    }
    return _maxNumberOfLines;
}

// Returns a valid pasteboard item (image or text)
- (id)pasteboardItem
{
    UIImage *image = [[UIPasteboard generalPasteboard] image];
    NSString *text = [[UIPasteboard generalPasteboard] string];
    
    // Gives priority to images
    if (image) {
        return image;
    }
    else if (text.length > 0) {
        return text;
    }
    else {
        return nil;
    }
}

- (BOOL)isExpanding
{
    if (self.numberOfLines >= self.maxNumberOfLines) {
        return YES;
    }
    return NO;
}

- (BOOL)shouldHidePlaceholder
{
    if (self.placeholder.length == 0 || self.text.length > 0) {
        return YES;
    }
    return NO;
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds
{
    CGRect rect = UIEdgeInsetsInsetRect(bounds, self.textContainerInset);
    CGFloat padding = self.textContainer.lineFragmentPadding;
    rect.origin.x += padding;
    rect.size.width -= padding * 2.0f;
    
    return rect;
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
    
    if (action == @selector(paste:) && [self pasteboardItem]) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)paste:(id)sender
{
    id item = [self pasteboardItem];
    
    if ([item isKindOfClass:[UIImage class]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewDidPasteImageNotification object:item];
    }
    else if ([item isKindOfClass:[NSString class]]){
        
        // Inserting the text fixes a UITextView bug whitch automatically scrolls to the bottom
        // and beyond scroll content size sometimes when the text is too long
        [self slk_insertTextAtCaretRange:item];
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

- (void)disableQuicktypeBar:(BOOL)disable
{
    if ((disable && self.autocorrectionType == UITextAutocorrectionTypeNo) ||
        (!disable && self.autocorrectionType == UITextAutocorrectionTypeDefault)) {
        return;
    }
    
    self.autocorrectionType = disable ? UITextAutocorrectionTypeNo : UITextAutocorrectionTypeDefault;
    self.spellCheckingType = disable ? UITextSpellCheckingTypeNo : UITextSpellCheckingTypeDefault;
    
    [self refreshFirstResponder];
}

- (void)refreshFirstResponder
{
    if (!self.isFirstResponder) {
        return;
    }
    
    _didNotResignFirstResponder = YES;
    [self resignFirstResponder];
    
    _didNotResignFirstResponder = NO;
    [self becomeFirstResponder];
}


#pragma mark - Observers & Notifications

- (void)didChangeTextView:(NSNotification *)notification
{
    if (self.placeholderLabel.hidden != [self shouldHidePlaceholder]) {
        [self setNeedsDisplay];
    }
    
    [self flashScrollIndicatorsIfNeeded];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewContentSizeDidChangeNotification object:self userInfo:nil];
    }
}


#pragma mark - Motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
		[[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewDidShakeNotification object:self];
	}
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
    
    _placeholderLabel = nil;
}

@end
