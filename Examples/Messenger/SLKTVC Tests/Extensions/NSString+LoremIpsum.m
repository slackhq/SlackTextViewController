//
//  NSString+LoremIpsum.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/28/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "NSString+LoremIpsum.h"

@implementation NSString (LoremIpsum)

+ (NSString *)loremIpsum
{
    return @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus a felis nec nisl tempus laoreet. Sed sollicitudin mauris sit amet neque faucibus, at faucibus tortor tincidunt. Maecenas facilisis, lectus eget volutpat ultricies, arcu libero sodales tellus, vel iaculis enim massa ac diam. Mauris volutpat tellus at est facilisis, non interdum metus interdum. Maecenas sit amet felis ac dolor consequat fringilla. Suspendisse tincidunt at dui a sodales. Morbi ullamcorper lacinia lorem non rhoncus. Phasellus pulvinar id sem sit amet tincidunt. In at feugiat nulla. Vivamus sit amet fringilla massa. Aenean imperdiet velit neque, ac iaculis nisl tempus vitae. Proin ornare volutpat semper. Vivamus vel scelerisque arcu, nec luctus risus. Maecenas iaculis justo lorem, et malesuada eros interdum et. In euismod finibus magna, nec viverra eros ornare non. Donec congue ligula et libero ultricies ornare. Nullam gravida justo commodo sollicitudin pellentesque. Curabitur eget sagittis justo, tempor volutpat orci. In non enim dui. Nunc maximus eros eu ligula tincidunt, vitae lobortis ipsum convallis. Pellentesque congue justo diam, egestas condimentum urna pellentesque ut. Proin et scelerisque diam. Integer condimentum auctor dolor quis ullamcorper. Suspendisse venenatis tellus ut ipsum euismod, interdum ullamcorper metus tristique. Nullam at tellus vel sapien lacinia gravida. Mauris eu magna malesuada, porttitor mauris mattis, venenatis dolor. Aenean bibendum eleifend ipsum, ac mollis felis rutrum sit amet. Fusce at enim ac felis molestie cursus nec ultrices odio. Duis varius purus vitae felis malesuada elementum. Quisque imperdiet, nulla eu dignissim pellentesque, diam diam maximus mi, at molestie quam libero quis elit. Cras volutpat lacinia dignissim. Suspendisse id arcu libero. Duis viverra, augue non fermentum lacinia, neque diam bibendum justo, ac egestas risus urna sagittis nulla. Curabitur dapibus vestibulum arcu sed scelerisque. Morbi nec lobortis orci. Sed ac augue neque.";
}

+ (NSString *)word
{
    return [self wordsWithNumber:1];
}

+ (NSString *)wordsWithNumber:(NSInteger)numberOfWords
{
    NSArray *allWords = [[[self loremIpsum] stringByReplacingOccurrencesOfString:@"." withString:@""] componentsSeparatedByString:@" "];
    
    if (numberOfWords > allWords.count) {
        numberOfWords = allWords.count -1;
    }
    
    NSMutableArray *words = [NSMutableArray arrayWithCapacity:numberOfWords];
    for (NSInteger i = 0; i < numberOfWords; i++) {
        [words addObject:[allWords objectAtIndex:i]];
    }
    return [words componentsJoinedByString:@" "];
}

+ (NSString *)sentence
{
    return [self sentencesWithNumber:1];
}

+ (NSString *)sentencesWithNumber:(NSInteger)numberOfSentences
{
    NSArray *allSentences = [[self loremIpsum] componentsSeparatedByString:@"."];
    
    if (numberOfSentences > allSentences.count) {
        numberOfSentences = allSentences.count -1;
    }
    
    NSMutableArray *sentences = [NSMutableArray arrayWithCapacity:numberOfSentences];
    for (NSInteger i = 0; i < numberOfSentences; i++) {
        [sentences addObject:[allSentences objectAtIndex:i]];
    }
    return [[sentences componentsJoinedByString:@". "] stringByAppendingString:@"."];
}

@end
