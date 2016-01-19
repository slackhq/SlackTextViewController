//
//  EXPMatchers+FBSnapshotTestExtensions.h
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/14/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Expecta/Expecta.h>
#import <Expecta+Snapshots/EXPMatchers+FBSnapshotTest.h>

#define RECORD_ONLY NO

#if !defined(itShould)
    #if RECORD_ONLY
        #define itShould(name, ...)                 _itTestsOrRecords(self, __LINE__, __FILE__, YES, YES, name, (__VA_ARGS__))
    #else
        #define itShould(name, ...)                 _itTests(self, __LINE__, __FILE__, YES, name, (__VA_ARGS__))
    #endif
#endif

#define itRecordsSnapshotsAsync(name, ...)          _itTestsOrRecords(self, __LINE__, __FILE__, YES, YES, name, (__VA_ARGS__))
#define itRecordsSnapshotsSync(name, ...)           _itTestsOrRecords(self, __LINE__, __FILE__, NO, YES, name, (__VA_ARGS__))

#define itTestsOrRecordsSnapshotsAsync(name, ...)   _itTests(self, __LINE__, __FILE__, YES, name, (__VA_ARGS__))
#define itTestsOrRecordsSnapshotsSync(name, ...)    _itTests(self, __LINE__, __FILE__, NO, name, (__VA_ARGS__))

void _itTestsOrRecords(id self, int lineNumber, const char *fileName, BOOL asynch, BOOL record, NSString *spec, id (^block)());
void _itTests(id self, int lineNumber, const char *fileName, BOOL asynch, NSString *spec, id (^block)());