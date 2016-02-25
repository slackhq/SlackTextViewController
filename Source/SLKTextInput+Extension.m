//
//  UITextInput+Processing.m
//  Pods
//
//  Created by Ignacio Romero on 2/20/16.
//
//

#import "SLKTextInput.h"

// Helps preventing the UITextInput's warnings for missing implementations. We assume they are all implemented already.
#pragma GCC diagnostic ignored "-Wprotocol"
#pragma GCC diagnostic ignored "-Wobjc-property-implementation"

/**
 Implementing SLKTextInput methods in a generic NSObject helps reusing the same logic for any SLKTextInput conformant class.
 This is the closest and cleanest technique to extend protocol's default implementations, like you'd do in Swift.
 */
@interface NSObject (SLKTextInput) <SLKTextInput>
@end

@implementation NSObject (SLKTextInput)

#pragma mark - Public Methods

- (void)lookForPrefixes:(NSSet *)prefixes completion:(void (^)(NSString *prefix, NSString *word, NSRange wordRange))completion
{
    NSAssert([prefixes isKindOfClass:[NSSet class]], @"You must provide a set containing String prefixes.");
    NSAssert(completion != nil, @"You must provide a non-nil completion block.");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Skip when there is no prefixes to look for.
        if (prefixes.count > 0) {
            NSRange wordRange;
            NSString *word = [self wordAtCaretRange:&wordRange];
            
            if (word.length > 0) {

                for (NSString *prefix in prefixes) {
                    
                    if ([word hasPrefix:prefix]) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) {
                                completion(prefix, word, wordRange);
                            }
                        });
                        
                        return;
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil, nil, NSMakeRange(0,0));
            }
        });
    });
}

- (NSString *)wordAtCaretRange:(NSRangePointer)range
{
    return [self wordAtRange:[self slk_caretRange] rangeInText:range];
}

- (NSString *)wordAtRange:(NSRange)range rangeInText:(NSRangePointer)rangePointer
{
    NSString *text = [self slk_text];
    NSInteger location = range.location;
    
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


#pragma mark - Private Methods

- (NSString *)slk_text
{
    UITextRange *textRange = [self textRangeFromPosition:self.beginningOfDocument toPosition:self.endOfDocument];
    return [self textInRange:textRange];
}

- (NSRange)slk_caretRange
{
    UITextPosition *beginning = self.beginningOfDocument;
    
    UITextRange *selectedRange = self.selectedTextRange;
    UITextPosition *selectionStart = selectedRange.start;
    UITextPosition *selectionEnd = selectedRange.end;
    
    const NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}

@end
