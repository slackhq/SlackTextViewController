//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextView.h"
#import "SLKTextView+SLKAdditions.h"

#import "SLKUIConstants.h"

NSString * const SLKTextViewTextWillChangeNotification =            @"SLKTextViewTextWillChangeNotification";
NSString * const SLKTextViewContentSizeDidChangeNotification =      @"SLKTextViewContentSizeDidChangeNotification";
NSString * const SLKTextViewSelectedRangeDidChangeNotification =    @"SLKTextViewSelectedRangeDidChangeNotification";
NSString * const SLKTextViewDidPasteItemNotification =              @"SLKTextViewDidPasteItemNotification";
NSString * const SLKTextViewDidShakeNotification =                  @"SLKTextViewDidShakeNotification";

NSString * const SLKTextViewPastedItemContentType =                 @"SLKTextViewPastedItemContentType";
NSString * const SLKTextViewPastedItemMediaType =                   @"SLKTextViewPastedItemMediaType";
NSString * const SLKTextViewPastedItemData =                        @"SLKTextViewPastedItemData";

static NSString *const SLKTextViewGenericFormattingSelectorPrefix = @"slk_format_";

@interface SLKTextView ()

// The label used as placeholder
@property (nonatomic, strong) UILabel *placeholderLabel;

// The initial font point size, used for dynamic type calculations
@property (nonatomic) CGFloat initialFontSize;

// Used for moving the caret up/down
@property (nonatomic) UITextLayoutDirection verticalMoveDirection;
@property (nonatomic) CGRect verticalMoveStartCaretRect;
@property (nonatomic) CGRect verticalMoveLastCaretRect;

// Used for detecting if the scroll indicator was previously flashed
@property (nonatomic) BOOL didFlashScrollIndicators;

@property (nonatomic, strong) NSMutableArray *registeredFormattingTitles;
@property (nonatomic, strong) NSMutableArray *registeredFormattingSymbols;
@property (nonatomic, getter=isFormatting) BOOL formatting;

// The keyboard commands available for external keyboards
@property (nonatomic, strong) NSMutableDictionary *registeredKeyCommands;
@property (nonatomic, strong) NSMutableDictionary *registeredKeyCallbacks;

@end

@implementation SLKTextView
@dynamic delegate;

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    if (self = [super initWithFrame:frame textContainer:textContainer]) {
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
    _pastableMediaTypes = SLKPastableMediaTypeNone;
    _dynamicTypeEnabled = YES;

    self.undoManagerEnabled = YES;
    
    self.editable = YES;
    self.selectable = YES;
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.directionalLockEnabled = YES;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    
    [self slk_registerNotifications];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionNew context:NULL];
}


#pragma mark - UIView Overrides

- (CGSize)intrinsicContentSize
{
    CGFloat height = self.font.lineHeight;
    height += self.textContainerInset.top + self.textContainerInset.bottom;
    
    return CGSizeMake(UIViewNoIntrinsicMetric, height);
}

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (void)layoutIfNeeded
{
    if (!self.window) {
        return;
    }
    
    [super layoutIfNeeded];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.placeholderLabel.hidden = [self slk_shouldHidePlaceholder];
    
    if (!self.placeholderLabel.hidden) {
        
        [UIView performWithoutAnimation:^{
            self.placeholderLabel.frame = [self slk_placeholderRectThatFits:self.bounds];
            [self sendSubviewToBack:self.placeholderLabel];
        }];
    }
}


#pragma mark - Getters

- (UILabel *)placeholderLabel
{
    if (!_placeholderLabel) {
        _placeholderLabel = [UILabel new];
        _placeholderLabel.clipsToBounds = NO;
        _placeholderLabel.numberOfLines = 1;
        _placeholderLabel.autoresizesSubviews = NO;
        _placeholderLabel.font = self.font;
        _placeholderLabel.backgroundColor = [UIColor clearColor];
        _placeholderLabel.textColor = [UIColor lightGrayColor];
        _placeholderLabel.hidden = YES;
        _placeholderLabel.isAccessibilityElement = NO;
        
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
    CGSize contentSize = self.contentSize;
    
    CGFloat contentHeight = contentSize.height;
    contentHeight -= self.textContainerInset.top + self.textContainerInset.bottom;
    
    NSUInteger lines = fabs(contentHeight/self.font.lineHeight);
    
    // This helps preventing the content's height to be larger that the bounds' height
    // Avoiding this way to have unnecessary scrolling in the text view when there is only 1 line of content
    if (lines == 1 && contentSize.height > self.bounds.size.height) {
        contentSize.height = self.bounds.size.height;
        self.contentSize = contentSize;
    }
    
    // Let's fallback to the minimum line count
    if (lines == 0) {
        lines = 1;
    }
    
    return lines;
}

- (NSUInteger)maxNumberOfLines
{
    NSUInteger numberOfLines = _maxNumberOfLines;
    
    if (SLK_IS_LANDSCAPE) {
        if ((SLK_IS_IPHONE4 || SLK_IS_IPHONE5)) {
            numberOfLines = 2.0; // 2 lines max on smaller iPhones
        }
        else if (SLK_IS_IPHONE) {
            numberOfLines /= 2.0; // Half size on larger iPhone
        }
    }
    
    if (self.isDynamicTypeEnabled) {
        NSString *contentSizeCategory = [[UIApplication sharedApplication] preferredContentSizeCategory];
        CGFloat pointSizeDifference = SLKPointSizeDifferenceForCategory(contentSizeCategory);
        
        CGFloat factor = pointSizeDifference/self.initialFontSize;
        
        if (fabs(factor) > 0.75) {
            factor = 0.75;
        }
        
        numberOfLines -= floorf(numberOfLines * factor); // Calculates a dynamic number of lines depending of the user preferred font size
    }
    
    return numberOfLines;
}

- (BOOL)isTypingSuggestionEnabled
{
    return (self.autocorrectionType == UITextAutocorrectionTypeNo) ? NO : YES;
}

- (BOOL)isFormattingEnabled
{
    return (self.registeredFormattingSymbols.count > 0) ? YES : NO;
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
    CGFloat padding = self.textContainer.lineFragmentPadding;
    
    CGRect rect = CGRectZero;
    rect.size.height = [self.placeholderLabel sizeThatFits:bounds.size].height;
    rect.size.width = self.textContainer.size.width - padding*2.0;
    rect.origin = UIEdgeInsetsInsetRect(bounds, self.textContainerInset).origin;
    rect.origin.x += padding;
    
    return rect;
}


#pragma mark - Setters

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeholderLabel.text = placeholder;
    self.accessibilityLabel = placeholder;
    
    [self setNeedsLayout];
}

- (void)setPlaceholderColor:(UIColor *)color
{
    self.placeholderLabel.textColor = color;
}

- (void)setPlaceholderNumberOfLines:(NSInteger)numberOfLines
{
    self.placeholderLabel.numberOfLines = numberOfLines;
    
    [self setNeedsLayout];
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
    
    self.autocorrectionType = enabled ? UITextAutocorrectionTypeDefault : UITextAutocorrectionTypeNo;
    self.spellCheckingType = enabled ? UITextSpellCheckingTypeDefault : UITextSpellCheckingTypeNo;
    
    [self refreshFirstResponder];
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    // At times during a layout pass, the content offset's x value may change.
    // Since we only care about vertical offset, let's override its horizontal value to avoid other layout issues.
    [super setContentOffset:CGPointMake(0.0, contentOffset.y)];
}


#pragma mark - UITextView Overrides

- (void)setSelectedRange:(NSRange)selectedRange
{
    [super setSelectedRange:selectedRange];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewSelectedRangeDidChangeNotification object:self userInfo:nil];
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    [super setSelectedTextRange:selectedTextRange];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewSelectedRangeDidChangeNotification object:self userInfo:nil];
}

- (void)setText:(NSString *)text
{
    // Registers for undo management
    [self slk_prepareForUndo:@"Text Set"];

    if (text) {
        [self setAttributedText:[self slk_defaultAttributedStringForText:text]];
    }
    else {
        [self setAttributedText:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
}

- (NSString *)text
{
    return self.attributedText.string;
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    // Registers for undo management
    [self slk_prepareForUndo:@"Attributed Text Set"];
    
    [super setAttributedText:attributedText];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
}

- (void)setFont:(UIFont *)font
{
    NSString *contentSizeCategory = [[UIApplication sharedApplication] preferredContentSizeCategory];
    
    [self setFontName:font.fontName pointSize:font.pointSize withContentSizeCategory:contentSizeCategory];
    
    self.initialFontSize = font.pointSize;
}

- (void)setFontName:(NSString *)fontName pointSize:(CGFloat)pointSize withContentSizeCategory:(NSString *)contentSizeCategory
{
    if (self.isDynamicTypeEnabled) {
        pointSize += SLKPointSizeDifferenceForCategory(contentSizeCategory);
    }
    
    UIFont *dynamicFont = [UIFont fontWithName:fontName size:pointSize];
    
    [super setFont:dynamicFont];
    
    // Updates the placeholder font too
    self.placeholderLabel.font = dynamicFont;
}

- (void)setDynamicTypeEnabled:(BOOL)dynamicTypeEnabled
{
    if (self.isDynamicTypeEnabled == dynamicTypeEnabled) {
        return;
    }
    
    _dynamicTypeEnabled = dynamicTypeEnabled;
    
    NSString *contentSizeCategory = [[UIApplication sharedApplication] preferredContentSizeCategory];

    [self setFontName:self.font.fontName pointSize:self.initialFontSize withContentSizeCategory:contentSizeCategory];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    [super setTextAlignment:textAlignment];
    
    // Updates the placeholder text alignment too
    self.placeholderLabel.textAlignment = textAlignment;
}


#pragma mark - UITextInput Overrides

#ifdef __IPHONE_9_0
- (void)beginFloatingCursorAtPoint:(CGPoint)point
{
    [super beginFloatingCursorAtPoint:point];
    
    _trackpadEnabled = YES;
}

- (void)updateFloatingCursorAtPoint:(CGPoint)point
{
    [super updateFloatingCursorAtPoint:point];
}

- (void)endFloatingCursor
{
    [super endFloatingCursor];

    _trackpadEnabled = NO;
    
    // We still need to notify a selection change in the textview after the trackpad is disabled
    if (self.delegate && [self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.delegate textViewDidChangeSelection:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SLKTextViewSelectedRangeDidChangeNotification object:self userInfo:nil];
}
#endif

#pragma mark - UIResponder Overrides

- (BOOL)canBecomeFirstResponder
{
    [self slk_addCustomMenuControllerItems];
    
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
    if (self.isFormatting) {
        NSString *title = [self slk_formattingTitleFromSelector:action];
        NSString *symbol = [self slk_formattingSymbolWithTitle:title];
        
        if (symbol.length > 0) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldOfferFormattingForSymbol:)]) {
                return [self.delegate textView:self shouldOfferFormattingForSymbol:symbol];
            }
            else {
                return YES;
            }
        }
        
        return NO;
    }

    if (action == @selector(delete:)) {
        return NO;
    }
    
    if (action == @selector(slk_presentFormattingMenu:)) {
        return self.selectedRange.length > 0 ? YES : NO;
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
    
    if ([pastedItem isKindOfClass:[NSDictionary class]]) {
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


#pragma mark - NSObject Overrides

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if ([super methodSignatureForSelector:sel]) {
        return [super methodSignatureForSelector:sel];
    }
    return [super methodSignatureForSelector:@selector(slk_format:)];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    NSString *title = [self slk_formattingTitleFromSelector:[invocation selector]];
    
    if (title.length > 0) {
        [self slk_format:title];
    }
    else {
        [super forwardInvocation:invocation];
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

- (void)slk_addCustomMenuControllerItems
{
    UIMenuItem *undo = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Undo", nil) action:@selector(slk_undo:)];
    UIMenuItem *redo = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Redo", nil) action:@selector(slk_redo:)];
    UIMenuItem *format = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Format", nil) action:@selector(slk_presentFormattingMenu:)];
    
    [[UIMenuController sharedMenuController] setMenuItems:@[undo, redo, format]];
}

- (void)slk_undo:(id)sender
{
    [self.undoManager undo];
}

- (void)slk_redo:(id)sender
{
    [self.undoManager redo];
}

- (void)slk_presentFormattingMenu:(id)sender
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:self.registeredFormattingTitles.count];
    
    for (NSString *name in self.registeredFormattingTitles) {
        
        NSString *sel = [NSString stringWithFormat:@"%@%@", SLKTextViewGenericFormattingSelectorPrefix, name];
        
        UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:name action:NSSelectorFromString(sel)];
        [items addObject:item];
    }
    
    self.formatting = YES;
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuItems:items];
    
    NSLayoutManager *manager = self.layoutManager;
    CGRect targetRect = [manager boundingRectForGlyphRange:self.selectedRange inTextContainer:self.textContainer];
    
    [menu setTargetRect:targetRect inView:self];
    
    [menu setMenuVisible:YES animated:YES];
}

- (NSString *)slk_formattingTitleFromSelector:(SEL)selector
{
    NSString *selectorString = NSStringFromSelector(selector);
    NSRange match = [selectorString rangeOfString:SLKTextViewGenericFormattingSelectorPrefix];
    
    if (match.location != NSNotFound) {
        return [selectorString substringFromIndex:SLKTextViewGenericFormattingSelectorPrefix.length];
    }
    
    return nil;
}

- (NSString *)slk_formattingSymbolWithTitle:(NSString *)title
{
    NSUInteger idx = [self.registeredFormattingTitles indexOfObject:title];
    
    if (idx <= self.registeredFormattingSymbols.count -1) {
        return self.registeredFormattingSymbols[idx];
    }
    
    return nil;
}

- (void)slk_format:(NSString *)titles
{
    NSString *symbol = [self slk_formattingSymbolWithTitle:titles];
    
    if (symbol.length > 0) {
        NSRange selection = self.selectedRange;
        
        NSRange range = [self slk_insertText:symbol inRange:NSMakeRange(selection.location, 0)];
        range.location += selection.length;
        range.length = 0;
        
        // The default behavior is to add a closure
        BOOL addClosure = YES;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(textView:shouldInsertSuffixForFormattingWithSymbol:prefixRange:)]) {
            addClosure = [self.delegate textView:self shouldInsertSuffixForFormattingWithSymbol:symbol prefixRange:selection];
        }
        
        if (addClosure) {
            self.selectedRange = [self slk_insertText:symbol inRange:range];
        }
    }
}


#pragma mark - Markdown Formatting

- (void)registerMarkdownFormattingSymbol:(NSString *)symbol withTitle:(NSString *)title
{
    if (!symbol || !title) {
        return;
    }
    
    if (!_registeredFormattingTitles) {
        _registeredFormattingTitles = [NSMutableArray new];
        _registeredFormattingSymbols = [NSMutableArray new];
    }
    
    // Adds the symbol if not contained already
    if (![self.registeredSymbols containsObject:symbol]) {
        [self.registeredFormattingTitles addObject:title];
        [self.registeredFormattingSymbols addObject:symbol];
    }
}

- (NSArray *)registeredSymbols
{
    return self.registeredFormattingSymbols;
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

- (void)slk_didChangeTextInputMode:(NSNotification *)notification
{
    // Do something
}

- (void)slk_didChangeContentSizeCategory:(NSNotification *)notification
{
    if (!self.isDynamicTypeEnabled) {
        return;
    }
    
    NSString *contentSizeCategory = notification.userInfo[UIContentSizeCategoryNewValueKey];
    
    [self setFontName:self.font.fontName pointSize:self.initialFontSize withContentSizeCategory:contentSizeCategory];
    
    NSString *text = [self.text copy];
    
    // Reloads the content size of the text view
    [self setText:@" "];
    [self setText:text];
}

- (void)slk_willShowMenuController:(NSNotification *)notification
{
    // Do something
}

- (void)slk_didHideMenuController:(NSNotification *)notification
{
    self.formatting = NO;
    
    [self slk_addCustomMenuControllerItems];
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

typedef void (^SLKKeyCommandHandler)(UIKeyCommand *keyCommand);

- (void)observeKeyInput:(NSString *)input modifiers:(UIKeyModifierFlags)modifiers title:(NSString *_Nullable)title completion:(void (^)(UIKeyCommand *keyCommand))completion
{
    NSAssert([input isKindOfClass:[NSString class]], @"You must provide a string with one or more characters corresponding to the keys to observe.");
    NSAssert(completion != nil, @"You must provide a non-nil completion block.");
    
    if (!input || !completion) {
        return;
    }
    
    UIKeyCommand *keyCommand = [UIKeyCommand keyCommandWithInput:input modifierFlags:modifiers action:@selector(didDetectKeyCommand:)];
    
#ifdef __IPHONE_9_0
    if ([UIKeyCommand respondsToSelector:@selector(keyCommandWithInput:modifierFlags:action:discoverabilityTitle:)] ) {
        keyCommand.discoverabilityTitle = title;
    }
#endif
    
    if (!_registeredKeyCommands) {
        _registeredKeyCommands = [NSMutableDictionary new];
        _registeredKeyCallbacks = [NSMutableDictionary new];
    }
    
    NSString *key = [self keyForKeyCommand:keyCommand];
    
    self.registeredKeyCommands[key] = keyCommand;
    self.registeredKeyCallbacks[key] = completion;
}

- (void)didDetectKeyCommand:(UIKeyCommand *)keyCommand
{
    NSString *key = [self keyForKeyCommand:keyCommand];
    
    SLKKeyCommandHandler completion = self.registeredKeyCallbacks[key];
    
    if (completion) {
        completion(keyCommand);
    }
}

- (NSString *)keyForKeyCommand:(UIKeyCommand *)keyCommand
{
    return [NSString stringWithFormat:@"%@_%ld", keyCommand.input, (long)keyCommand.modifierFlags];
}

- (NSArray *)keyCommands
{
    if (self.registeredKeyCommands) {
        return [self.registeredKeyCommands allValues];
    }
    
    return nil;
}


#pragma mark Up/Down Cursor Movement

- (void)didPressArrowKey:(UIKeyCommand *)keyCommand
{
    if (![keyCommand isKindOfClass:[UIKeyCommand class]] || self.text.length == 0 || self.numberOfLines < 2) {
        return;
    }
    
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
    CGRect nextLineCaretRect = CGRectZero;
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


#pragma mark - NSNotificationCenter registration

- (void)slk_registerNotifications
{
    [self slk_unregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeText:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeTextInputMode:) name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didChangeContentSizeCategory:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_willShowMenuController:) name:UIMenuControllerWillShowMenuNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(slk_didHideMenuController:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)slk_unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
}


#pragma mark - Lifeterm

- (void)dealloc
{
    [self slk_unregisterNotifications];
    
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize))];
    
    _placeholderLabel = nil;
    
    _registeredFormattingTitles = nil;
    _registeredFormattingSymbols = nil;
    _registeredKeyCommands = nil;
    _registeredKeyCallbacks = nil;
}

@end
