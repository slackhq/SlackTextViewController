//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextView+SLKAdditions.h"

@implementation SLKTextView (SLKAdditions)

- (void)slk_clearText:(BOOL)clearUndo
{
    // Important to call self implementation, as SLKTextView overrides setText: to add additional features.
    
    [self setAttributedText:nil];
    
    if (self.undoManagerEnabled && clearUndo) {
        [self.undoManager removeAllActions];
    }
}

- (void)slk_scrollToCaretPositonAnimated:(BOOL)animated
{
    if (animated) {
        [self scrollRangeToVisible:self.selectedRange];
    }
    else {
        [UIView performWithoutAnimation:^{
            [self scrollRangeToVisible:self.selectedRange];
        }];
    }
}

- (void)slk_scrollToBottomAnimated:(BOOL)animated
{
    CGRect rect = [self caretRectForPosition:self.selectedTextRange.end];
    rect.size.height += self.textContainerInset.bottom;
    
    if (animated) {
        [self scrollRectToVisible:rect animated:animated];
    }
    else {
        [UIView performWithoutAnimation:^{
            [self scrollRectToVisible:rect animated:NO];
        }];
    }
}

- (void)slk_insertNewLineBreak
{
    [self slk_insertTextAtCaretRange:@"\n"];
    
    // if the text view cannot expand anymore, scrolling to bottom are not animated to fix a UITextView issue scrolling twice.
    BOOL animated = !self.isExpanding;
    
    //Detected break. Should scroll to bottom if needed.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0125 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self slk_scrollToBottomAnimated:animated];
    });
}

- (void)slk_insertTextAtCaretRange:(NSString *)text
{
    NSRange range = [self slk_insertText:text inRange:self.selectedRange];
    self.selectedRange = NSMakeRange(range.location, 0);
}

- (void)slk_insertTextAtCaretRange:(NSString *)text withAttributes:(NSDictionary<NSString *, id> *)attributes
{
    NSRange range = [self slk_insertText:text withAttributes:attributes inRange:self.selectedRange];
    self.selectedRange = NSMakeRange(range.location, 0);
}

- (NSRange)slk_insertText:(NSString *)text inRange:(NSRange)range
{
    NSAttributedString *attributedText = [self slk_defaultAttributedStringForText:text];
    
    return [self slk_insertAttributedText:attributedText inRange:range];
}

- (NSRange)slk_insertText:(NSString *)text withAttributes:(NSDictionary<NSString *, id> *)attributes inRange:(NSRange)range
{
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];
    
    return [self slk_insertAttributedText:attributedText inRange:range];
}

- (NSAttributedString *)slk_setAttributes:(NSDictionary<NSString *, id> *)attributes
                                  inRange:(NSRange)range
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    
    [attributedText setAttributes:attributes range:range];
    [self setAttributedText:attributedText];
    
    return self.attributedText;
}

- (void)slk_insertAttributedTextAtCaretRange:(NSAttributedString *)attributedText
{
    NSRange range = [self slk_insertAttributedText:attributedText inRange:self.selectedRange];
    self.selectedRange = NSMakeRange(range.location, 0);
}

- (NSRange)slk_insertAttributedText:(NSAttributedString *)attributedText inRange:(NSRange)range
{
    // Skip if the attributed text is empty
    if (attributedText.length == 0) {
        return NSMakeRange(0, 0);
    }
    
    // Registers for undo management
    [self slk_prepareForUndo:@"Attributed text appending"];
    
    // Append the new string at the caret position
    if (range.length == 0)
    {
        NSAttributedString *leftAttributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(0, range.location)];
        
        NSAttributedString *rightAttributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(range.location, self.attributedText.length-range.location)];
        
        NSMutableAttributedString *newAttributedText = [NSMutableAttributedString new];
        [newAttributedText appendAttributedString:leftAttributedString];
        [newAttributedText appendAttributedString:attributedText];
        [newAttributedText appendAttributedString:rightAttributedString];
        
        [self setAttributedText:newAttributedText];
        range.location += attributedText.length;
        
        return range;
    }
    // Some text is selected, so we replace it with the new text
    else if (range.location != NSNotFound && range.length > 0)
    {
        NSMutableAttributedString *mutableAttributeText = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        
        [mutableAttributeText replaceCharactersInRange:range withAttributedString:attributedText];
    
        [self setAttributedText:mutableAttributeText];
        range.location += self.attributedText.length;
        
        return range;
    }
    
    // No text has been inserted, but still return the caret range
    return self.selectedRange;
}

- (void)slk_clearAllAttributesInRange:(NSRange)range
{
    NSMutableAttributedString *mutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    
    [mutableAttributedText setAttributes:nil range:range];
    [self setAttributedText:mutableAttributedText];
}

- (NSAttributedString *)slk_defaultAttributedStringForText:(NSString *)text
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    if (self.textColor) {
        attributes[NSForegroundColorAttributeName] = self.textColor;
    }
    
    if (self.font) {
        attributes[NSFontAttributeName] = self.font;
    }
        
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (void)slk_prepareForUndo:(NSString *)description
{
    if (!self.undoManagerEnabled) {
        return;
    }
    
    SLKTextView *prepareInvocation = [self.undoManager prepareWithInvocationTarget:self];
    [prepareInvocation setText:self.text];
    [self.undoManager setActionName:description];
}

@end
