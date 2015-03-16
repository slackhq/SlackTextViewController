//
//  EXPMatchers+FBSnapshotTestExtensions.h
//  Messenger
//
//  Created by Ignacio Romero Z. on 3/14/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <Expecta+Snapshots/EXPMatchers+FBSnapshotTest.h>

#define itTestsOrRecordsSnapshotsAsync(name, ...)   _itTestsAsyncronously(self, __LINE__, __FILE__, name, (__VA_ARGS__))
#define itTestsOrRecordsSnapshotsSync(name, ...)    _itTestsSyncronously(self, __LINE__, __FILE__, name, (__VA_ARGS__))

void _itTestsAsyncronously(id self, int lineNumber, const char *fileName, NSString *name, id (^block)());
void _itTestsSyncronously(id self, int lineNumber, const char *fileName, NSString *name, id (^block)());