//
//  BAVPlistNode.m
//  Plistorious
//
//  Created by Bavarious on 01/10/2013.
//  Copyright (c) 2013 No Organisation. All rights reserved.
//

#import "BAVPlistNode.h"


static NSString *typeForObject(id object) {
    return ([object isKindOfClass:[NSArray class]] ? @"Array" :
            [object isKindOfClass:[NSDictionary class]] ? @"Dictionary" :
            [object isKindOfClass:[NSString class]] ? @"String" :
            [object isKindOfClass:[NSData class]] ? @"Data" :
            [object isKindOfClass:[NSDate class]] ? @"Date" :
            object == (id)kCFBooleanTrue || object == (id)kCFBooleanFalse ? @"Boolean" :
            [object isKindOfClass:[NSNumber class]] ? @"Number" :
            [object isKindOfClass:[NSNull class]] ? @"Null" :
            @"Unknown");
}

static NSString *formatItemCount(NSUInteger count) {
    return (count == 1 ? @"1 item" : [NSString stringWithFormat:@"%@ items", @(count)]);
}


@implementation BAVPlistNode

+ (instancetype)plistNodeFromObject:(id)object key:(NSString *)key
{
    BAVPlistNode *newNode = [BAVPlistNode new];
    newNode.key = key;
    newNode.type = typeForObject(object);

    if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = object;

        NSMutableArray *children = [NSMutableArray new];
        NSUInteger elementIndex = 0;
        for (id element in array) {
            NSString *elementKey = [NSString stringWithFormat:@"Item %@", @(elementIndex)];
            [children addObject:[self plistNodeFromObject:element key:elementKey]];
            elementIndex++;
        }

        newNode.value = formatItemCount(array.count);
        newNode.children = children;
    }
    else if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = object;
        NSArray *keys = [dictionary.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

        NSMutableArray *children = [NSMutableArray new];
        for (NSString *elementKey in keys)
            [children addObject:[self plistNodeFromObject:dictionary[elementKey] key:elementKey]];

        newNode.value = formatItemCount(keys.count);
        newNode.children = children;
    }
    else if ([object isKindOfClass:[NSNull class]]) {
        newNode.value = @"null";
    }
    else if (object == (id)kCFBooleanTrue) {
        newNode.value = @"true";
    }
    else if (object == (id)kCFBooleanFalse) {
        newNode.value = @"false";
    }
    else {
        newNode.value = [NSString stringWithFormat:@"%@", object];
    }
    
    return newNode;
}

- (bool)isCollection
{
    return [self.type isEqualToString:@"Array"] || [self.type isEqualToString:@"Dictionary"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ node with key %@", self.type, self.key];
}

@end
