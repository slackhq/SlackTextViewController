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

#import <Foundation/Foundation.h>

#if (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@interface JSONSyntaxHighlight : NSObject

// Create the object by giving a JSON object, nil will be returned
// if the object can't be serialized
- (JSONSyntaxHighlight *)init;
- (JSONSyntaxHighlight *)initWithJSON:(id)JSON;

// Return an NSAttributedString with the highlighted JSON in a pretty format
- (NSAttributedString *)highlightJSON;

// Return an NSAttributedString with the highlighted JSON optionally pretty formatted
- (NSAttributedString *)highlightJSONWithPrettyPrint:(BOOL)prettyPrint;

// Fire a callback for every key item found in the parsed JSON, each callback
// is fired with the NSRange the substring appears in `self.parsedJSON`, as well
// as the NSString at that location.
- (void)enumerateMatchesWithIndentBlock:(void(^)(NSRange, NSString*))indentBlock
                               keyBlock:(void(^)(NSRange, NSString*))keyBlock
                             valueBlock:(void(^)(NSRange, NSString*))valueBlock
                               endBlock:(void(^)(NSRange, NSString*))endBlock;

// The JSON object, unmodified
@property (readonly, nonatomic, strong) id JSON;

// The serialized JSON string
@property (readonly, nonatomic, strong) NSString *parsedJSON;

// The attributes for Attributed Text
@property (nonatomic, strong) NSDictionary *keyAttributes;
@property (nonatomic, strong) NSDictionary *stringAttributes;
@property (nonatomic, strong) NSDictionary *nonStringAttributes;

// Platform dependent helper functions
#if (TARGET_OS_EMBEDDED || TARGET_OS_IPHONE)
+ (UIColor *)colorWithRGB:(NSInteger)rgbValue;
+ (UIColor *)colorWithRGB:(NSInteger)rgbValue alpha:(CGFloat)alpha;
#else
+ (NSColor *)colorWithRGB:(NSInteger)rgbValue;
+ (NSColor *)colorWithRGB:(NSInteger)rgbValue alpha:(CGFloat)alpha;
#endif

@end