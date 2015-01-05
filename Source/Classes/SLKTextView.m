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
NSString * const SLKTextViewDidFinishDeletingNotification =     @"SLKTextViewDidFinishDeletingNotification";

NSString * const SLKTextViewPastedItemContentType =             @"SLKTextViewPastedItemContentType";
NSString * const SLKTextViewPastedItemMediaType =               @"SLKTextViewPastedItemMediaType";
NSString * const SLKTextViewPastedItemData =                    @"SLKTextViewPastedItemData";

static NSTimeInterval kDeleteMaxTimeInterval = 0.5;

@interface SLKTextView ()
{
    NSTimeInterval _lastDeletionTimeInterval;
}

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

// Used to refresh the first responder's
@property (nonatomic, strong) NSTimer *deletionTimer;

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
    self.placeholderLabel.frame = [self placeholderRectThatFits:self.bounds];
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
    if (SLK_IS_IPHONE && SLK_IS_LANDSCAPE) {
        return 2.0;
    }
    return _maxNumberOfLines;
}

// Returns only a supported pasted item
- (id)pastedItem
{
    NSString *contentType = [self pasteboardContentType];
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
- (BOOL)isPasteboardItemSupported
{
    if ([self pasteboardContentType].length > 0) {
        return YES;
    }
    return NO;
}

- (NSString *)pasteboardContentType
{
    NSArray *pasteboardTypes = [[UIPasteboard generalPasteboard] pasteboardTypes];
    NSMutableArray *subpredicates = [NSMutableArray new];
    
    for (NSString *type in [self supportedMediaTypes]) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"SELF == %@", type]];
    }
    
    return [[pasteboardTypes filteredArrayUsingPredicate:[NSCompoundPredicate orPredicateWithSubpredicates:subpredicates]] firstObject];
}

- (NSArray *)supportedMediaTypes
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

- (BOOL)shouldHidePlaceholder
{
    if (self.placeholder.length == 0 || self.text.length > 0) {
        return YES;
    }
    return NO;
}

- (CGRect)placeholderRectThatFits:(CGRect)bounds
{
    CGRect rect = CGRectZero;
    rect.size = [self.placeholderLabel sizeThatFits:bounds.size];
    rect.origin = UIEdgeInsetsInsetRect(bounds, self.textContainerInset).origin;
    
    CGFloat padding = self.textContainer.lineFragmentPadding;
    rect.origin.x += padding;
    
    return rect;
}

- (NSTimer *)deletionTimer
{
    if (!_deletionTimer) {
        _deletionTimer = [NSTimer timerWithTimeInterval:kDeleteMaxTimeInterval target:self selector:@selector(shouldRefreshFirstResponder:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_deletionTimer forMode:NSRunLoopCommonModes];
    }
    return _deletionTimer;
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

- (void)invalidateDeletionTimer
{
    if (!_deletionTimer) {
        return;
    }
    
    [_deletionTimer invalidate];
    _deletionTimer = nil;
}

- (void)invalidateFastDeletion
{
    _fastDeleting = NO;
    _lastDeletionTimeInterval = 0;
}


#pragma mark - UITextView Overrides

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

// Safer cursor range (it sometimes exceeds the lenght of the text property).
- (NSRange)selectedRange
{
    NSString *text = self.text;
    NSRange range = [super selectedRange];
    
    if (range.location > text.length) {
        range.location = text.length;
    }
    
    if (range.length > text.length) {
        range.length = text.length;
    }
    
    return range;
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
    
    [self invalidateFastDeletion];
}

- (void)deleteBackward
{
    // No need to call super on iOS8, or it will delete 2 characters at once
    if (!SLK_IS_IOS8_AND_HIGHER) {
        [super deleteBackward];
    }
    
    NSTimeInterval deletionTimestamp = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval delta = roundf(100.0 * (deletionTimestamp - _lastDeletionTimeInterval)) / 100.0;
    
    _fastDeleting = (self.hasText && delta <= kDeleteMaxTimeInterval);
    _lastDeletionTimeInterval = deletionTimestamp;

    // Makes sure the first responder is refreshed when the user released the backward key
    if (self.isFastDeleting) {
        [self invalidateDeletionTimer];
        [self deletionTimer];
    }
}

// Used on iOS8 to trigger 'deleteBackward' since it's no longer called by super.
// 'keyboardInputShouldDelete:' should be safe, since it doesn't call super, but it is still considered a private API.
- (BOOL)keyboardInputShouldDelete:(__unused id <UITextInput>)textInput
{
    if (SLK_IS_IOS8_AND_HIGHER) {
        [self deleteBackward];
    }
    
    return self.hasText;
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

    if (action == @selector(paste:) && [self isPasteboardItemSupported]) {
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
    id pastedItem = [self pastedItem];
    
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

- (void)setTypingSuggestionEnabled:(BOOL)enabled
{
    if (self.isTypingSuggestionEnabled == enabled) {
        return;
    }

    _typingSuggestionEnabled = enabled;
    
    self.autocorrectionType = enabled ? UITextAutocorrectionTypeDefault : UITextAutocorrectionTypeNo;
    self.spellCheckingType = enabled ? UITextSpellCheckingTypeDefault : UITextSpellCheckingTypeNo;
    
    if (!self.isFastDeleting) {
        [self refreshFirstResponder];
    }
}

- (void)shouldRefreshFirstResponder:(NSTimer *)timer
{
    [self refreshFirstResponder];
    [self invalidateDeletionTimer];
    [self invalidateFastDeletion];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewDidFinishDeletingNotification object:self];
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
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierShift action:@selector(didPressLineBreakKeys:)],
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierAlternate action:@selector(didPressLineBreakKeys:)],
         [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:UIKeyModifierControl action:@selector(didPressLineBreakKeys:)],
         
         // Undo/Redo
         [UIKeyCommand keyCommandWithInput:@"z" modifierFlags:UIKeyModifierCommand action:@selector(didPressCommandZKeys:)],
         [UIKeyCommand keyCommandWithInput:@"z" modifierFlags:UIKeyModifierShift|UIKeyModifierCommand action:@selector(didPressCommandZKeys:)],
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
        [self moveCursorTodirection:UITextLayoutDirectionUp];
    }
    else if ([keyCommand.input isEqualToString:UIKeyInputDownArrow]) {
        [self moveCursorTodirection:UITextLayoutDirectionDown];
    }
}

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

// Based on code from Ruben Cabaco
// https://gist.github.com/rcabaco/6765778

- (UITextPosition *)closestPositionToPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
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
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
    
    _placeholderLabel = nil;
}

@end
