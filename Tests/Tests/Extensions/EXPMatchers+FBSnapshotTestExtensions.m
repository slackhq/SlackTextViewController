//
//  EXPMatchers+FBSnapshotTestExtensions.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/14/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "EXPMatchers+FBSnapshotTestExtensions.h"
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#import "SLKUIConstants.h"

static NSFileManager *_fileManager = nil;

NSString *_osSuffix() {
    
    if (SLK_IS_IOS8_AND_HIGHER) {
        return @"_ios8";
    }
    else {
        return @"_ios7";
    }
}

NSString *_densitySuffix() {
    if ([UIScreen mainScreen].scale > 2.0) {
        return @"@3x";
    }
    else if ([UIScreen mainScreen].scale == 2.0) {
        return @"@2x";
    }
    return @"";
}

NSString *_deviceSuffix() {
    
    NSMutableArray *strings = [NSMutableArray new];
    
    if (SLK_IS_IPHONE4) {
        [strings addObject:@"iphone4"];
    }
    else if (SLK_IS_IPHONE5) {
        [strings addObject:@"iphone5"];
    }
    else if (SLK_IS_IPHONE6) {
        [strings addObject:@"iphone6"];
    }
    else if (SLK_IS_IPHONE6PLUS) {
        [strings addObject:@"iphone6plus"];
    }
    else if (SLK_IS_IPAD) {
        [strings addObject:@"ipad"];
    }
    
    if (SLK_IS_LANDSCAPE) {
        [strings addObject:@"lanscape"];
    }
    else {
        [strings addObject:@"portrait"];
    }
    
    NSMutableString *suffix = [[strings componentsJoinedByString:@"_"] mutableCopy];
    [suffix insertString:@"_" atIndex:0];
    [suffix appendString:_osSuffix()];
    
    return suffix;
}

NSString *_specName(NSString *name) {
    return [[name stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString];
}

NSString *_imagePathForTestSpec(NSString *test, NSString *spec) {
    
    NSMutableArray *pathComponents = [[test componentsSeparatedByString:@"/"] mutableCopy];
    
    NSString *folderName = [NSString stringWithFormat:@"%@Spec", [[pathComponents lastObject] stringByDeletingPathExtension]];
    
    [pathComponents removeObjectsInRange:NSMakeRange([pathComponents count]-2, 2)];
    [pathComponents addObject:@"ReferenceImages"];
    
    NSString *path = [pathComponents componentsJoinedByString:@"/"];

    return [NSString stringWithFormat:@"%@/%@/%@%@.png", path, folderName, _specName(spec), _densitySuffix()];
}

void _itTestsOrRecords(id self, int lineNumber, const char *fileName, BOOL asynch, BOOL record, NSString *spec, id (^block)()) {

    void (^snapshot)(id, NSString *) = ^void (id sut, NSString *suffix) {
        
        EXPExpect *expectation = _EXP_expect(self, lineNumber, fileName, ^id{ return EXPObjectify((sut)); });
        
        NSString *specName = [_specName(spec) stringByAppendingString:suffix];
        
        if (record) {
            if (asynch) expectation.will.recordSnapshotNamed(specName);
            else expectation.to.recordSnapshotNamed(specName);
        }
        else {
            if (asynch) expectation.will.haveValidSnapshotNamed(specName);
            else expectation.to.haveValidSnapshotNamed(specName);
        }
    };
    
    NSString *suffix = _deviceSuffix();
    
    if (suffix.length > 0) {
        it([spec stringByAppendingString:suffix], ^{
            id sut = block();
            snapshot(sut, suffix);
        });
    }
}

void _itTests(id self, int lineNumber, const char *fileName, BOOL asynch, NSString *spec, id (^block)()) {
    
    if (!_fileManager) {
        _fileManager = [[NSFileManager alloc] init];
    }

    NSString *suffix = _deviceSuffix();
    
    NSString *specName = [spec stringByAppendingString:suffix];
    NSString *imagePath = _imagePathForTestSpec([NSString stringWithUTF8String:fileName], specName);
    
    BOOL record = ![_fileManager fileExistsAtPath:imagePath];
    
    _itTestsOrRecords(self, lineNumber, fileName, asynch, record, spec, block);
}
