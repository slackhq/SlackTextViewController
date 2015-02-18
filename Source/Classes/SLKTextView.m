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
#import "SLKTextView+SLKAdditions.h"
#import "SLKUIConstants.h"

NSString * const SLKTextViewTextWillChangeNotification =        @"SLKTextViewTextWillChangeNotification";
NSString * const SLKTextViewContentSizeDidChangeNotification =  @"SLKTextViewContentSizeDidChangeNotification";
NSString * const SLKTextViewDidPasteItemNotification =          @"SLKTextViewDidPasteItemNotification";
NSString * const SLKTextViewDidShakeNotification =              @"SLKTextViewDidShakeNotification";

NSString * const SLKTextViewPastedItemContentType =             @"SLKTextViewPastedItemContentType";
NSString * const SLKTextViewPastedItemMediaType =               @"SLKTextViewPastedItemMediaType";
NSString * const SLKTextViewPastedItemData =                    @"SLKTextViewPastedItemData";

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
    self.placeholderColor = [UIColor lightGrayColor];
    self.pastableMediaTypes = SLKPastableMediaTypeNone;
    self.undoManagerEnabled = YES;
    
    self.font = [UIFont systemFontOfSize:14.0];
    self.editable = YES;
    self.selectable = YES;
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.directionalLockEnabled = YES;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    
    // UITextView notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:NULL];
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

- (void)layoutIfNeeded
{
    [super layoutIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.placeholderLabel.hidden = [self slk_shouldHidePlaceholder];
    if (!self.placeholderLabel.hidden) {
        self.placeholderLabel.frame = [self slk_placeholderRectThatFits:self.bounds];
        [self sendSubviewToBack:self.placeholderLabel];
    }
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
    if (SLK_IS_IPHONE && SLK_IS_LANDSCAPE) {
        return 2.0;
    }
    return _maxNumberOfLines;
}

// Returns only a supported pasted item
- (id)slk_pastedItem
{
    NSString *contentType = [self slk_pasteboardContentType];
    NSData *data = [[UIPasteboard generalPasteboard] dataForPasteboardType:contentType];

    if (data && [data isKindOfClass:[NSData class]])
    {
        SLKPastableMediaType mediaType = SLKPastableMediaTypeFromNSString(contentType);
        
        NSDictionary *userInfo = @{SLKTextViewPastedItemContentType: contentType,
                                   SLKTextViewPastedItemMediaType: @(mediaType),
                                   SLKTextViewPastedItemData: data};
        return userInfo;
    }
    if ([[UIPasteboard generalPasteboard] URL]) {
        return [[[UIPasteboard generalPasteboard] URL] absoluteString];
    }
    if ([[UIPasteboard generalPasteboard] string]) {
        return [[UIPasteboard generalPasteboard] string];
    }
    
    return nil;
}

// Checks if any supported media found in the general pasteboard
- (BOOL)slk_isPasteboardItemSupported
{
    if ([self slk_pasteboardContentType].length > 0) {
        return YES;
    }
    return NO;
}

- (NSString *)slk_pasteboardContentType
{
    NSArray *pasteboardTypes = [[UIPasteboard generalPasteboard] pasteboardTypes];
    NSMutableArray *subpredicates = [NSMutableArray new];
    
    for (NSString *type in [self slk_supportedMediaTypes]) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"SELF == %@", type]];
    }
    
    return [[pasteboardTypes filteredArrayUsingPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:subpredicates]] firstObject];
}

- (NSArray *)slk_supportedMediaTypes
{
    if (self.pastableMediaTypes == SLKPastableMediaTypeNone) {
        return nil;
    }
    
    NSMutableArray *types = [NSMutableArray new];
    
    if (self.pastableMediaTypes & SLKPastableMediaTypePNG) {
        [types addObject:NSStringFromSLKPastableMediaType(SLKPastableMediaTypePNG)];
    }
    if (self.pastableMediaTypes & SLKPastableMediaTypeJPEG) {
        [types addObject:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeJPEG)];
    }
    if (self.pastableMediaTypes & SLKPastableMediaTypeTIFF) {
        [types addObject:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeTIFF)];
    }
    if (self.pastableMediaTypes & SLKPastableMediaTypeGIF) {
        [types addObject:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeGIF)];
    }
    if (self.pastableMediaTypes & SLKPastableMediaTypeMOV) {
        [types addObject:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeMOV)];
    }
    if (self.pastableMediaTypes & SLKPastableMediaTypePassbook) {
        [types addObject:NSStringFromSLKPastableMediaType(SLKPastableMediaTypePassbook)];
    }
    
    if (self.pastableMediaTypes & SLKPastableMediaTypeImages) {
        [types addObject:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeImages)];
    }
    
    
    return types;
}

NSString *NSStringFromSLKPastableMediaType(SLKPastableMediaType type)
{
    if (type == SLKPastableMediaTypePNG) {
        return @"public.png";
    }
    if (type == SLKPastableMediaTypeJPEG) {
        return @"public.jpeg";
    }
    if (type == SLKPastableMediaTypeTIFF) {
        return @"public.tiff";
    }
    if (type == SLKPastableMediaTypeGIF) {
        return @"com.compuserve.gif";
    }
    if (type == SLKPastableMediaTypeMOV) {
        return @"com.apple.quicktime";
    }
    if (type == SLKPastableMediaTypePassbook) {
        return @"com.apple.pkpass";
    }
    if (type == SLKPastableMediaTypeImages) {
        return @"com.apple.uikit.image";
    }
    
    return nil;
}

SLKPastableMediaType SLKPastableMediaTypeFromNSString(NSString *string)
{
    if ([string isEqualToString:NSStringFromSLKPastableMediaType(SLKPastableMediaTypePNG)]) {
        return SLKPastableMediaTypePNG;
    }
    if ([string isEqualToString:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeJPEG)]) {
        return SLKPastableMediaTypeJPEG;
    }
    if ([string isEqualToString:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeTIFF)]) {
        return SLKPastableMediaTypeTIFF;
    }
    if ([string isEqualToString:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeGIF)]) {
        return SLKPastableMediaTypeGIF;
    }
    if ([string isEqualToString:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeMOV)]) {
        return SLKPastableMediaTypeMOV;
    }
    if ([string isEqualToString:NSStringFromSLKPastableMediaType(SLKPastableMediaTypePassbook)]) {
        return SLKPastableMediaTypePassbook;
    }
    if ([string isEqualToString:NSStringFromSLKPastableMediaType(SLKPastableMediaTypeImages)]) {
        return SLKPastableMediaTypeImages;
    }
    return SLKPastableMediaTypeNone;
}

- (BOOL)isExpanding
{
    if (self.numberOfLines >= self.maxNumberOfLines) {
        return YES;
    }
    return NO;
}

- (BOOL)slk_shouldHidePlaceholder
{
    if (self.placeholder.length == 0 || self.text.length > 0) {
        return YES;
    }
    return NO;
}

- (CGRect)slk_placeholderRectThatFits:(CGRect)bounds
{
    CGRect rect = CGRectZero;
    rect.size = [self.placeholderLabel sizeThatFits:bounds.size];
    rect.origin = UIEdgeInsetsInsetRect(bounds, self.textContainerInset).origin;
    
    CGFloat padding = self.textContainer.lineFragmentPadding;
    rect.origin.x += padding;
    
    return rect;
}


#pragma mark - Setters

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeholderLabel.text = placeholder;
    
    [self setNeedsLayout];
}

- (void)setPlaceholderColor:(UIColor *)color
{
    self.placeholderLabel.textColor = color;
}

- (void)setUndoManagerEnabled:(BOOL)enabled
{
    if (self.undoManagerEnabled == enabled) {
        return;
    }
    
    self.undoManager.levelsOfUndo = 10;
    [self.undoManager removeAllActions];
    [self.undoManager setActionIsDiscardable:YES];
    
    _undoManagerEnabled = enabled;
}

- (void)setTypingSuggestionEnabled:(BOOL)enabled
{
    if (self.isTypingSuggestionEnabled == enabled) {
        return;
    }
    
    _typingSuggestionEnabled = enabled;
    
    self.autocorrectionType = enabled ? UITextAutocorrectionTypeDefault : UITextAutocorrectionTypeNo;
    self.spellCheckingType = enabled ? UITextSpellCheckingTypeDefault : UITextSpellCheckingTypeNo;
    
    [self refreshFirstResponder];
}


#pragma mark - UITextView Overrides

- (void)setText:(NSString *)text
{
    // Registers for undo management
    [self slk_prepareForUndo:@"Text Set"];
    
    [super setText:text];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    // Registers for undo management
    [self slk_prepareForUndo:@"Attributed Text Set"];
    
    [super setAttributedText:attributedText];
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


#pragma mark - UITextInputTraits Overrides

- (void)insertText:(NSString *)text
{
    [super insertText:text];
}


#pragma mark - UIResponder Overrides

- (BOOL)canBecomeFirstResponder
{
    // Adds undo/redo items to the Menu Controller
    if (self.undoManagerEnabled) {
        UIMenuItem *undo = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Undo", nil) action:@selector(slk_undo:)];
        UIMenuItem *redo = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Redo", nil) action:@selector(slk_redo:)];
        [[UIMenuController sharedMenuController] setMenuItems:@[undo,redo]];
    }
    
    return [super canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    return [super becomeFirstResponder];
}

- (BOOL)canResignFirstResponder
{
    // Removes undo/redo items
    if (self.undoManagerEnabled) {
        [[UIMenuController sharedMenuController] setMenuItems:@[]];
        [self.undoManager removeAllActions];
    }
    
    return [super canResignFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [super resignFirstResponder];
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

    if (action == @selector(paste:) && [self slk_isPasteboardItemSupported]) {
        return YES;
    }
    
    if (self.undoManagerEnabled) {
        if (action == @selector(slk_undo:)) {
            if (self.undoManager.undoActionIsDiscardable) {
                return NO;
            }
            return [self.undoManager canUndo];
        }
        if (action == @selector(slk_redo:)) {
            if (self.undoManager.redoActionIsDiscardable) {
                return NO;
            }
            return [self.undoManager canRedo];
        }
    }
    
    return [super canPerformAction:action withSender:sender];
}

- (void)paste:(id)sender
{
    id pastedItem = [self slk_pastedItem];
    
    if ([pastedItem isKindOfClass:[NSDictionary class]])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewDidPasteItemNotification object:nil userInfo:pastedItem];
    }
    else if ([pastedItem isKindOfClass:[NSString class]]) {
        // Respect the delegate yo!
        if (self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            if (![self.delegate textView:self shouldChangeTextInRange:self.selectedRange replacementText:pastedItem]) {
                return;
            }
        }
        
        // Inserting the text fixes a UITextView bug whitch automatically scrolls to the bottom
        // and beyond scroll content size sometimes when the text is too long
        [self slk_insertTextAtCaretRange:pastedItem];
    }
}


#pragma mark - Custom Actions

- (void)slk_flashScrollIndicatorsIfNeeded
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

- (void)refreshInputViews
{
    _didNotResignFirstResponder = YES;
    
    [super reloadInputViews];
    
    _didNotResignFirstResponder = NO;
}

- (void)slk_undo:(id)sender
{
    [self.undoManager undo];
}

- (void)slk_redo:(id)sender
{
    [self.undoManager redo];
}


#pragma mark - Notification Events

- (void)slk_didBeginEditing:(NSNotification *)notification
{
    if (![notification.object isEqual:self]) {
        return;
    }
    
    // Do something
}

- (void)slk_didChangeText:(NSNotification *)notification
{
    if (![notification.object isEqual:self]) {
        return;
    }
    
    if (self.placeholderLabel.hidden != [self slk_shouldHidePlaceholder]) {
        [self setNeedsLayout];
    }
    
    [self slk_flashScrollIndicatorsIfNeeded];
}

- (void)slk_didEndEditing:(NSNotification *)notification
{
    if (![notification.object isEqual:self]) {
        return;
    }
    
    // Do something
}


#pragma mark - KVO Listener

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewContentSizeDidChangeNotification object:self userInfo:nil];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
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
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierShift action:@selector(slk_didPressLineBreakKeys:)],
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierAlternate action:@selector(slk_didPressLineBreakKeys:)],
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierControl action:@selector(slk_didPressLineBreakKeys:)],
         
         // Undo/Redo
         [UIKeyCommand keyCommandWithInput:@"z" modifierFlags:UIKeyModifierCommand action:@selector(slk_didPressCommandZKeys:)],
         [UIKeyCommand keyCommandWithInput:@"z" modifierFlags:UIKeyModifierShift|UIKeyModifierCommand action:@selector(slk_didPressCommandZKeys:)],
         ];
    
    return _keyboardCommands;
}


#pragma mark Line Break

- (void)slk_didPressLineBreakKeys:(id)sender
{
    [self slk_insertNewLineBreak];
}


#pragma mark Undo/Redo Text

- (void)slk_didPressCommandZKeys:(id)sender
{
    if (!self.undoManagerEnabled) {
        return;
    }
    
    UIKeyCommand *keyCommand = (UIKeyCommand *)sender;
    
    if ((keyCommand.modifierFlags & UIKeyModifierShift) > 0) {
        
        if ([self.undoManager canRedo]) {
            [self.undoManager redo];
        }
    }
    else {
        if ([self.undoManager canUndo]) {
            [self.undoManager undo];
        }
    }
}

#pragma mark Up/Down Cursor Movement

- (void)didPressAnyArrowKey:(id)sender
{
    if (self.text.length == 0 || self.numberOfLines < 2) {
        return;
    }
    
    UIKeyCommand *keyCommand = (UIKeyCommand *)sender;
    
    if ([keyCommand.input isEqualToString:UIKeyInputUpArrow]) {
        [self slk_moveCursorTodirection:UITextLayoutDirectionUp];
    }
    else if ([keyCommand.input isEqualToString:UIKeyInputDownArrow]) {
        [self slk_moveCursorTodirection:UITextLayoutDirectionDown];
    }
}

- (void)slk_moveCursorTodirection:(UITextLayoutDirection)direction
{
    UITextPosition *start = (direction == UITextLayoutDirectionUp) ? self.selectedTextRange.start : self.selectedTextRange.end;
    
    if ([self slk_isNewVerticalMovementForPosition:start inDirection:direction]) {
        self.verticalMoveDirection = direction;
        self.verticalMoveStartCaretRect = [self caretRectForPosition:start];
    }
    
    if (start) {
        
        UITextPosition *end = [self slk_closestPositionToPosition:start inDirection:direction];
        
        if (end) {
            self.verticalMoveLastCaretRect = [self caretRectForPosition:end];
            self.selectedTextRange = [self textRangeFromPosition:end toPosition:end];
            
            [self slk_scrollToCaretPositonAnimated:NO];
        }
    }
}

// Based on code from Ruben Cabaco
// https://gist.github.com/rcabaco/6765778

- (UITextPosition *)slk_closestPositionToPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    // Only up/down are implemented. No real need for left/right since that is native to UITextInput.
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

- (BOOL)slk_isNewVerticalMovementForPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
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
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
    
    _placeholderLabel = nil;
}

@end
