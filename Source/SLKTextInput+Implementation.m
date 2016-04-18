//
//  SlackTextViewController
//  https://github.com/slackhq/SlackTextViewController
//
//  Copyright 2014-2016 Slack Technologies, Inc.
//  Licence: MIT-Licence
//

#import "SLKTextInput.h"

/**
 Implementing SLKTextInput methods in a generic NSObject helps reusing the same logic for any SLKTextInput conformant class.
 This is the closest and cleanest technique to extend protocol's default implementations, like you'd do in Swift.
 */
@interface NSObject (SLKTextInput)
@end

@implementation NSObject (SLKTextInput)

#pragma mark - Public Methods

- (void)lookForPrefixes:(NSSet<NSString *> *)prefixes completion:(void (^)(NSString *prefix, NSString *word, NSRange wordRange))completion
{
    if (![self conformsToProtocol:@protocol(SLKTextInput)]) {
        return;
    }
    
    NSAssert([prefixes isKindOfClass:[NSSet class]], @"You must provide a set containing String prefixes.");
    NSAssert(completion != nil, @"You must provide a non-nil completion block.");
    
    // Skip when there is no prefixes to look for.
    if (prefixes.count == 0) {
        return;
    }
    
    NSRange wordRange;
    NSString *word = [self wordAtCaretRange:&wordRange];
    
    if (word.length > 0) {
        for (NSString *prefix in prefixes) {
            if ([word hasPrefix:prefix]) {
                
                if (completion) {
                    completion(prefix, word, wordRange);
                }
                
                return;
            }
        }
    }
    
    // Fallback to an empty callback
    if (completion) {
        completion(nil, nil, NSMakeRange(0,0));
    }
}

- (NSString *)wordAtCaretRange:(NSRangePointer)range
{
    return [self wordAtRange:[self slk_caretRange] rangeInText:range];
}

- (NSString *)wordAtRange:(NSRange)range rangeInText:(NSRangePointer)rangePointer
{
    if (![self conformsToProtocol:@protocol(SLKTextInput)]) {
        return nil;
    }
    
    NSInteger location = range.location;
    
    if (location == NSNotFound) {
        return nil;
    }
    
    NSString *text = [self slk_text];
    
    // Aborts in case minimum requieres are not fufilled
    if (text.length == 0 || location < 0 || (range.location+range.length) > text.length) {
        *rangePointer = NSMakeRange(0, 0);
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
        NSRange whitespaceRange = [characterBeforeCursor rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (whitespaceRange.length == 1) {
            // At the start of a word, just use the word behind the cursor for the current word
            *rangePointer = NSMakeRange(location, rightPart.length);
            
            return rightPart;
        }
    }
    
    // In the middle of a word, so combine the part of the word before the cursor, and after the cursor to get the current word
    *rangePointer = NSMakeRange(location-leftWordPart.length, leftWordPart.length+rightPart.length);
    
    NSString *word = [leftWordPart stringByAppendingString:rightPart];
    NSString *linebreak = @"\n";
    
    // If a break is detected, return the last component of the string
    if ([word rangeOfString:linebreak].location != NSNotFound) {
        *rangePointer = [text rangeOfString:word];
        word = [[word componentsSeparatedByString:linebreak] lastObject];
    }
    
    return word;
}


#pragma mark - Private Methods

- (NSString *)slk_text
{
    if (![self conformsToProtocol:@protocol(SLKTextInput)]) {
        return nil;
    }
    
    id<SLKTextInput>input = (id<SLKTextInput>)self;
    
    UITextRange *textRange = [input textRangeFromPosition:input.beginningOfDocument toPosition:input.endOfDocument];
    return [input textInRange:textRange];
}

- (NSRange)slk_caretRange
{
    if (![self conformsToProtocol:@protocol(SLKTextInput)]) {
        return NSMakeRange(0,0);
    }
    
    id<SLKTextInput>input = (id<SLKTextInput>)self;
    
    UITextPosition *beginning = input.beginningOfDocument;
    
    UITextRange *selectedRange = input.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    
    const NSInteger location = [input offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [input offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

@end
