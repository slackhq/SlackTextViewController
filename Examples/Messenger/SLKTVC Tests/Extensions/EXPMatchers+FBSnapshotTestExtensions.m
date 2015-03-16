//
//  EXPMatchers+FBSnapshotTestExtensions.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/14/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "EXPMatchers+FBSnapshotTestExtensions.h"
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

NSString *_specName(NSString *name) {
    return [[name stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString];
}

NSString *_imagePathForTestSpec(NSString *test, NSString *spec) {
    NSString *folderName = [NSString stringWithFormat:@"%@Spec", [test stringByDeletingPathExtension]];
    return [NSString stringWithFormat:@"%s/%@/%@", FB_REFERENCE_IMAGE_DIR, folderName, _specName(spec)];
}

BOOL _doRecordSnapshotForSpec(Class specClass, NSString *specName) {
    return YES;
}

void _itTests(id self, int lineNumber, const char *fileName, BOOL asynch, NSString *spec, id (^block)()) {
    it(spec, ^{

        EXPExpect *expectation = _EXP_expect(self, lineNumber, fileName, ^id{ return EXPObjectify((block())); });
        
        NSString *imagePath = _imagePathForTestSpec([NSString stringWithUTF8String:fileName], spec);
        NSLog(@"imagesDirectoryForTestSpec : %@", imagePath);
        
        BOOL record = YES;
        
        if (record) {
            if (asynch) expectation.will.recordSnapshotNamed(spec);
            else expectation.to.recordSnapshotNamed(spec);
        }
        else {
            if (asynch) expectation.will.haveValidSnapshotNamed(spec);
            else expectation.to.haveValidSnapshotNamed(spec);
        }
    });
}

void _itTestsAsyncronously(id self, int lineNumber, const char *fileName, NSString *name, id (^block)()) {
    _itTests(self, lineNumber, fileName, YES, _specName(name), block);
}

void _itTestsSyncronously(id self, int lineNumber, const char *fileName, NSString *name, id (^block)()) {
    _itTests(self, lineNumber, fileName, NO, _specName(name), block);
}
