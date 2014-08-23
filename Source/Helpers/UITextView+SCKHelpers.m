//
//  UITextView+SCKHelpers.m
//  Slack
//
//  Created by Ignacio on 8/19/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "UITextView+SCKHelpers.h"

@implementation UITextView (SCKHelpers)

- (BOOL)isCaretAtEnd
{
    if (self.selectedRange.location == self.text.length && self.selectedRange.length == 0) {
        return YES;
    }
    
    return NO;
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    CGRect caretRect = [self caretRectForPosition:self.endOfDocument];
    
    if (!animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.0];
        [UIView setAnimationDelay:0.0];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        
        [self scrollRectToVisible:caretRect animated:NO];
        
        [UIView commitAnimations];
    }
    else {
        [self scrollRectToVisible:caretRect animated:animated];
    }
    
//    NSUInteger lenght = self.text.length;
//    
//    if (lenght > 0) {
//        NSRange bottom = NSMakeRange(lenght-1.0, 1.0);
//        [self scrollRangeToVisible:bottom];
//    }
}

- (void)scrollToCaretPositonAnimated:(BOOL)animated
{
    if (!animated)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.0];
        [UIView setAnimationDelay:0.0];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        
        [self scrollRangeToVisible:self.selectedRange];
        
        [UIView commitAnimations];
    }
    else {
        [self scrollRangeToVisible:self.selectedRange];
    }
}

- (void)insertNewLineBreak
{
    [self insertTextAtCaretRange:@"\n"];
}

- (void)insertTextAtCaretRange:(NSString *)text
{
    NSRange range = [self insertText:text inRange:self.selectedRange];
    self.selectedRange = NSMakeRange(range.location, 0);
    
    [self scrollRangeToVisible:self.selectedRange];
}

- (NSRange)insertText:(NSString *)text inRange:(NSRange)range
{
    if (text.length == 0) {
        return NSMakeRange(0, 0);
    }
    
    // Append the new string at the caret position
    if (range.length == 0)
    {
        NSString *leftString = [self.text substringToIndex:range.location];
        NSString *rightString = [self.text substringFromIndex: range.location];
        
        self.text = [NSString stringWithFormat:@"%@%@%@", leftString, text, rightString];
        
        range.location += [text length];
        return range;
    }
    // Some text is selected, so we replace it with the new text
    else if (range.length > 0)
    {
        self.text = [self.text stringByReplacingCharactersInRange:range withString:text];
        
        return NSMakeRange(range.location+[self.text rangeOfString:text].length, text.length);
    }
    
    // No text has been inserted, but still return the caret range
    return self.selectedRange;
}

- (NSString *)wordAtCaretRange:(NSRangePointer)range
{
    return [self wordAtRange:self.selectedRange rangeInText:range];
}

- (NSString *)wordAtRange:(NSRange)range rangeInText:(NSRangePointer)rangePointer
{
    NSString *text = self.text;
    NSInteger location = range.location;
    
    if (text.length == 0) {
        *rangePointer = NSMakeRange(0.0, 0.0);
        return nil;
    }
    
    NSString *leftPortion = [text substringToIndex:location];
    NSArray *leftComponents = [leftPortion componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *leftWordPart = [leftComponents lastObject];
    
    NSString *rightPortion = [text substringFromIndex:location];
    NSArray *rightComponents = [rightPortion componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *rightPart = [rightComponents firstObject];
    
    if (location > 0) {
        NSString *characterBeforeCursor = [text substringWithRange:NSMakeRange(location-1, 1)];
        
        if ([characterBeforeCursor isEqualToString:@" "]) {
            // At the start of a word, just use the word behind the cursor for the current word
            *rangePointer = NSMakeRange(location, rightPart.length);
            return rightPart;
        }
    }
    
    // In the middle of a word, so combine the part of the word before the cursor, and after the cursor to get the current word
    *rangePointer = NSMakeRange(location-leftWordPart.length, leftWordPart.length+rightPart.length);
    NSString *word = [leftWordPart stringByAppendingString:rightPart];

    // If a break is detected, return the last component of the string
    if ([word rangeOfString:@"\n"].location != NSNotFound) {
        
        *rangePointer = [text rangeOfString:word];
        word = [[word componentsSeparatedByString:@"\n"] lastObject];
    }

    return word;
}

- (void)disableQuickTypeBar:(BOOL)disable
{
    self.autocorrectionType = disable ? UITextAutocorrectionTypeNo : UITextAutocorrectionTypeDefault;
    
    if (self.isFirstResponder) {
        [self resignFirstResponder];
        [self becomeFirstResponder];
    }
}

@end
