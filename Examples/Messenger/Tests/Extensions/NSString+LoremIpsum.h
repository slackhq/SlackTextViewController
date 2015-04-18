//
//  NSString+LoremIpsum.h
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/28/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (LoremIpsum)

+ (NSString *)word;
+ (NSString *)wordsWithNumber:(NSInteger)numberOfWords;

+ (NSString *)sentence;
+ (NSString *)sentencesWithNumber:(NSInteger)numberOfSentences;

@end
