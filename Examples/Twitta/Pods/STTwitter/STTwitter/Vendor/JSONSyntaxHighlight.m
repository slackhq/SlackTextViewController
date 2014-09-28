/**
 * JSONSyntaxHighlight.h
 * JSONSyntaxHighlight
 *
 * Syntax highlight JSON
 *
 * Created by Dave Eddy on 8/3/13.
 * Copyright (c) 2013 Dave Eddy. All rights reserved.
 *
 * The MIT License (MIT)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "JSONSyntaxHighlight.h"

@implementation JSONSyntaxHighlight {
    NSRegularExpression *regex;
}

#pragma mark Object Initializer
// Must init with a JSON object
- (JSONSyntaxHighlight *)init
{
    return nil;
}

- (JSONSyntaxHighlight *)initWithJSON:(id)JSON
{
    self = [super init];
    if (self) {
        // save the origin JSON
        _JSON = JSON;
        
        // create the object local regex
	regex = [NSRegularExpression regularExpressionWithPattern:@"^( *)(\".+\" : )?(\"[^\"]*\"|[\\w.+-]*)?([,\\[\\]{}]?,?$)"
                                                          options:NSRegularExpressionAnchorsMatchLines
                                                            error:nil];
        
        // parse the JSON if possible
        if ([NSJSONSerialization isValidJSONObject:self.JSON]) {
            NSJSONWritingOptions options = NSJSONWritingPrettyPrinted;
            NSData *data = [NSJSONSerialization dataWithJSONObject:self.JSON options:options error:nil];
            NSString *o = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            _parsedJSON = o;
        } else {
            _parsedJSON = [NSString stringWithFormat:@"%@", self.JSON];
        }
        
        // set the default attributes
        self.nonStringAttributes = @{NSForegroundColorAttributeName: [self.class colorWithRGB:0x000080]};
        self.stringAttributes = @{NSForegroundColorAttributeName: [self.class colorWithRGB:0x808000]};
        self.keyAttributes = @{NSForegroundColorAttributeName: [self.class colorWithRGB:0xa52a2a]};
    }
    return self;
}

#pragma mark -
#pragma mark JSON Highlighting
- (NSAttributedString *)highlightJSON
{
    return [self highlightJSONWithPrettyPrint:YES];
}

- (NSAttributedString *)highlightJSONWithPrettyPrint:(BOOL)prettyPrint
{
    NSMutableAttributedString *line = [[NSMutableAttributedString alloc] initWithString:@""];
    [self enumerateMatchesWithIndentBlock:
     // The indent
     ^(NSRange range, NSString *s) {
         NSAttributedString *as = [[NSAttributedString alloc] initWithString:s attributes:@{}];
         if (prettyPrint) [line appendAttributedString:as];
     }
                                 keyBlock:
     // The key (with quotes and colon)
     ^(NSRange range, NSString *s) {
         // I hate this: this changes `"key" : ` to `"key"`
         NSString *key = [s substringToIndex:s.length - 3];
         [line appendAttributedString:[[NSAttributedString alloc] initWithString:key attributes:self.keyAttributes]];
         NSString *colon = prettyPrint ? @" : " : @":";
         [line appendAttributedString:[[NSAttributedString alloc] initWithString:colon attributes:@{}]];
     }
                               valueBlock:
     // The value
     ^(NSRange range, NSString *s) {
         NSAttributedString *as;
         if ([s rangeOfString:@"\""].location == NSNotFound) // literal or number
             as = [[NSAttributedString alloc] initWithString:s attributes:self.nonStringAttributes];
         else // string
             as = [[NSAttributedString alloc] initWithString:s attributes:self.stringAttributes];
         
         [line appendAttributedString:as];
     }
                                 endBlock:
     // The final comma, or ending character
     ^(NSRange range, NSString *s) {
         NSAttributedString *as = [[NSAttributedString alloc] initWithString:s attributes:@{}];
         [line appendAttributedString:as];
         if (prettyPrint) [line appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
     }];
    
    if ([line isEqualToAttributedString:[[NSAttributedString alloc] initWithString:@""]])
        line = [[NSMutableAttributedString alloc] initWithString:self.parsedJSON];
    return line;
}

#pragma mark JSON Parser
- (void)enumerateMatchesWithIndentBlock:(void(^)(NSRange, NSString*))indentBlock
                               keyBlock:(void(^)(NSRange, NSString*))keyBlock
                             valueBlock:(void(^)(NSRange, NSString*))valueBlock
                               endBlock:(void(^)(NSRange, NSString*))endBlock
{
    [regex enumerateMatchesInString:self.parsedJSON
                            options:0
                              range:NSMakeRange(0, self.parsedJSON.length)
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                             
        NSRange indentRange = [match rangeAtIndex:1];
        NSRange keyRange = [match rangeAtIndex:2];
        NSRange valueRange = [match rangeAtIndex:3];
        NSRange endRange = [match rangeAtIndex:4];
        
        if (indentRange.location != NSNotFound)
            indentBlock(indentRange, [self.parsedJSON substringWithRange:indentRange]);
        if (keyRange.location != NSNotFound)
            keyBlock(keyRange, [self.parsedJSON substringWithRange:keyRange]);
        if (valueRange.location != NSNotFound)
            valueBlock(valueRange, [self.parsedJSON substringWithRange:valueRange]);
        if (endRange.location != NSNotFound)
            endBlock(endRange, [self.parsedJSON substringWithRange:endRange]);
    }];
}

#pragma mark -
#pragma mark Color Helper Functions
#if (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
+ (UIColor *)colorWithRGB:(NSInteger)rgbValue
{
    return [self.class colorWithRGB:rgbValue alpha:1.0];
}

+ (UIColor *)colorWithRGB:(NSInteger)rgbValue alpha:(CGFloat)alpha
{
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0
                           green:((float)((rgbValue & 0x00FF00) >> 8 )) / 255.0
                            blue:((float)((rgbValue & 0x0000FF) >> 0 )) / 255.0
                           alpha:alpha];
}
#else
+ (NSColor *)colorWithRGB:(NSInteger)rgbValue
{
    return [self.class colorWithRGB:rgbValue alpha:1.0];
}

+ (NSColor *)colorWithRGB:(NSInteger)rgbValue alpha:(CGFloat)alpha
{
    return [NSColor colorWithCalibratedRed:((float)((rgbValue & 0xFF0000) >> 16)) / 255.0
                                     green:((float)((rgbValue & 0x00FF00) >> 8 )) / 255.0
                                      blue:((float)((rgbValue & 0x0000FF) >> 0 )) / 255.0
                                     alpha:alpha];
}
#endif

@end
