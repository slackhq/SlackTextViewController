#import <XCTest/XCTest.h>

@interface XCTestObservationCenter : NSObject

+ (id)sharedObservationCenter;
- (void)_suspendObservationForBlock:(void (^)(void))block;

@end

@protocol XCTestObservation <NSObject>
@end

@interface _XCTestDriverTestObserver : NSObject <XCTestObservation>

- (void)stopObserving;
- (void)startObserving;

@end

@interface _XCTestCaseImplementation : NSObject
@end

@interface XCTestCase ()

- (_XCTestCaseImplementation *)internalImplementation;
- (void)_recordUnexpectedFailureWithDescription:(NSString *)description exception:(NSException *)exception;

@end