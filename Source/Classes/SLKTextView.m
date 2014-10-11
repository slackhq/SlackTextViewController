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

// The label used as placeholder
@property (nonatomic, strong) UILabel *placeholderLabel;

// The keyboard commands available for external keyboards
@property (nonatomic, strong) NSArray *keyboardCommands;

// Used for moving the care up/down
@property (nonatomic) UITextLayoutDirection verticalMoveDirection;
@property (nonatomic) CGRect verticalMoveStartCaretRect;
@property (nonatomic) CGRect verticalMoveLastCaretRect;

// Used for detecting if the scroll indicator was previously flashed
@property (nonatomic) BOOL didFlashScrollIndicators;

@end

@implementation SLKTextView

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
    
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

// Returns a supported pasteboard item (image or text)
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
    // Registers for undo management
    [self prepareForUndo:@"Text Set"];
    
    [super setText:text];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    // Registers for undo management
    [self prepareForUndo:@"Attributed Text Set"];
    
    [super setAttributedText:attributedText];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(delete:)) {
        return NO;
    }
    
    if ((action == @selector(copy:) || action == @selector(cut:))
        && self.selectedRange.length > 0) {
        return YES;
    }
    
    if (action == @selector(paste:) && [self pasteboardItem]) {
        return YES;
    }
    
    if ((action == @selector(undo:) && ![self.undoManager canUndo]) ||
        (action == @selector(redo:) && ![self.undoManager canRedo])) {
        return NO;
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

- (void)undo:(id)sender
{
    [self.undoManager undo];
}

- (void)redo:(id)sender
{
    [self.undoManager redo];
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


#pragma mark - Notification Events

- (void)didBeginEditing:(NSNotification *)notification
{
    if (![notification.object isEqual:self]) {
        return;
    }
    
    // Do something
}

- (void)didChangeText:(NSNotification *)notification
{
    if (![notification.object isEqual:self]) {
        return;
    }
    
    if (self.placeholderLabel.hidden != [self shouldHidePlaceholder]) {
        [self setNeedsDisplay];
    }
    
    [self flashScrollIndicatorsIfNeeded];
}

- (void)didEndEditing:(NSNotification *)notification
{
    if (![notification.object isEqual:self]) {
        return;
    }
    
    // Do something
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewContentSizeDidChangeNotification object:self userInfo:nil];
    }
}


#pragma mark - Motion Events

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewDidShakeNotification object:self];
    }
}


#pragma mark - External Keyboard Support

- (NSArray *)keyCommands
{
    if (_keyboardCommands) {
        return _keyboardCommands;
    }
    
    _keyboardCommands = @[
         // Return
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierShift action:@selector(didPressLineBreakKeys:)],
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierAlternate action:@selector(didPressLineBreakKeys:)],
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierControl action:@selector(didPressLineBreakKeys:)],
         
         // Undo/Redo
         [UIKeyCommand keyCommandWithInput:@"z" modifierFlags:UIKeyModifierCommand action:@selector(didPressCommandZKeys:)],
         [UIKeyCommand keyCommandWithInput:@"z" modifierFlags:UIKeyModifierShift|UIKeyModifierCommand action:@selector(didPressCommandZKeys:)],
         
         // Up/Down
         [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didPressArrowKey:)],
         [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(didPressArrowKey:)]
         ];
    
    return _keyboardCommands;
}


#pragma mark Line Break

- (void)didPressLineBreakKeys:(id)sender
{
    [self slk_insertNewLineBreak];
}

#pragma mark Undo/Redo Text

- (void)didPressCommandZKeys:(id)sender
{
    UIKeyCommand *keyCommand = (UIKeyCommand *)sender;
    
    if ((keyCommand.modifierFlags & UIKeyModifierShift) > 0) {
        
        if ([self.undoManager canRedo]) {
            [self.undoManager redo];
        }
    }
    else if ([self.undoManager canUndo]) {
        [self.undoManager undo];
    }
}

#pragma mark Up/Down Cursor Movement

- (void)didPressArrowKey:(id)sender
{
    if (self.text.length == 0 || self.numberOfLines < 2) {
        return;
    }
    
    UIKeyCommand *keyCommand = (UIKeyCommand *)sender;
    
    if ([keyCommand.input isEqualToString:UIKeyInputUpArrow]) {
        [self moveCursorTodirection:UITextLayoutDirectionUp];
    }
    else {
        [self moveCursorTodirection:UITextLayoutDirectionDown];
    }
}

// Based on code from Ruben Cabaco
// https://gist.github.com/rcabaco/6765778
//UITextPosition *p0 = (direction = UITextLayoutDirectionUp) ? self.selectedTextRange.start : self.selectedTextRange.end;

- (void)moveCursorTodirection:(UITextLayoutDirection)direction
{
    UITextPosition *start = (direction == UITextLayoutDirectionUp) ? self.selectedTextRange.start : self.selectedTextRange.end;
    
    if ([self isNewVerticalMovementForPosition:start inDirection:direction]) {
        self.verticalMoveDirection = direction;
        self.verticalMoveStartCaretRect = [self caretRectForPosition:start];
    }
    
    if (start) {
        
        UITextPosition *end = [self closestPositionToPosition:start inDirection:direction];
        
        if (end) {
            self.verticalMoveLastCaretRect = [self caretRectForPosition:end];
            self.selectedTextRange = [self textRangeFromPosition:end toPosition:end];
            
            [self slk_scrollToCaretPositonAnimated:NO];
        }
    }
}

- (UITextPosition *)closestPositionToPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    // Currently only up and down are implemented.
    NSParameterAssert(direction == UITextLayoutDirectionUp || direction == UITextLayoutDirectionDown);
    
    // Translate the vertical direction to a horizontal direction.
    UITextLayoutDirection lookupDirection = (direction == UITextLayoutDirectionUp) ? UITextLayoutDirectionLeft : UITextLayoutDirectionRight;
    
    // Walk one character at a time in `lookupDirection` until the next line is reached.
    UITextPosition *checkPosition = position;
    UITextPosition *closestPosition = position;
    CGRect startingCaretRect = [self caretRectForPosition:position];
    CGRect nextLineCaretRect;
    BOOL isInNextLine = NO;
    
    while (YES) {
        UITextPosition *nextPosition = [self positionFromPosition:checkPosition inDirection:lookupDirection offset:1];
        
        // End of line.
        if (!nextPosition || [self comparePosition:checkPosition toPosition:nextPosition] == NSOrderedSame) {
            break;
        }
        
        checkPosition = nextPosition;
        CGRect checkRect = [self caretRectForPosition:checkPosition];
        if (CGRectGetMidY(startingCaretRect) != CGRectGetMidY(checkRect)) {
            // While on the next line stop just above/below the starting position.
            if (lookupDirection == UITextLayoutDirectionLeft && CGRectGetMidX(checkRect) <= CGRectGetMidX(self.verticalMoveStartCaretRect)) {
                closestPosition = checkPosition;
                break;
            }
            if (lookupDirection == UITextLayoutDirectionRight && CGRectGetMidX(checkRect) >= CGRectGetMidX(self.verticalMoveStartCaretRect)) {
                closestPosition = checkPosition;
                break;
            }
            // But don't skip lines.
            if (isInNextLine && CGRectGetMidY(checkRect) != CGRectGetMidY(nextLineCaretRect)) {
                break;
            }
            
            isInNextLine = YES;
            nextLineCaretRect = checkRect;
            closestPosition = checkPosition;
        }
    }
    return closestPosition;
}

- (BOOL)isNewVerticalMovementForPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    CGRect caretRect = [self caretRectForPosition:position];
    BOOL noPreviousStartPosition = CGRectEqualToRect(self.verticalMoveStartCaretRect, CGRectZero);
    BOOL caretMovedSinceLastPosition = !CGRectEqualToRect(caretRect, self.verticalMoveLastCaretRect);
    BOOL directionChanged = self.verticalMoveDirection != direction;
    
    BOOL newMovement = noPreviousStartPosition || caretMovedSinceLastPosition || directionChanged;
    return newMovement;
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    @try {
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
    }
    @catch(id anException) {
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    
    _placeholderLabel = nil;
}

@end
