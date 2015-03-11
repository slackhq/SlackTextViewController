#import <objc/runtime.h>
#import "XCTestCase+Specta.h"
#import "SPTSpec.h"
#import "SPTExample.h"
#import "SPTSharedExampleGroups.h"
#import "SpectaUtility.h"
#import "XCTest+Private.h"

@interface XCTestCase (xct_allSubclasses)

- (NSArray *)allSubclasses;

@end

@implementation XCTestCase (Specta)

+ (void)load {
  Method allSubclasses = class_getClassMethod(self, @selector(allSubclasses));
  Method allSubclasses_swizzle = class_getClassMethod(self , @selector(spt_allSubclasses_swizzle));
  method_exchangeImplementations(allSubclasses, allSubclasses_swizzle);
}

+ (NSArray *)spt_allSubclasses_swizzle {
  NSArray *subclasses = [self spt_allSubclasses_swizzle]; // call original
  NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:[subclasses count]];
  // exclude SPTSpec base class and all subclasses of SPTSharedExampleGroups
  for (id subclass in subclasses) {
    if (subclass != [SPTSpec class] && ![subclass isKindOfClass:[SPTSharedExampleGroups class]]) {
      [filtered addObject:subclass];
    }
  }
  return spt_shuffle(filtered);
}

- (void)spt_handleException:(NSException *)exception {
  NSString *description = [exception reason];
  if ([exception userInfo]) {
    id line = [exception userInfo][@"line"];
    id file = [exception userInfo][@"file"];
    if ([line isKindOfClass:[NSNumber class]] && [file isKindOfClass:[NSString class]]) {
      [self recordFailureWithDescription:description inFile:file atLine:[line unsignedIntegerValue] expected:YES];
      return;
    }
  }
  [self _recordUnexpectedFailureWithDescription:description exception:exception];
}

@end