#import <XCTest/XCTest.h>

#define SpecBegin(name) _SPTSpecBegin(name, __FILE__, __LINE__)
#define SpecEnd         _SPTSpecEnd

#define SharedExamplesBegin(name)      _SPTSharedExampleGroupsBegin(name)
#define SharedExamplesEnd              _SPTSharedExampleGroupsEnd
#define SharedExampleGroupsBegin(name) _SPTSharedExampleGroupsBegin(name)
#define SharedExampleGroupsEnd         _SPTSharedExampleGroupsEnd

typedef void (^DoneCallback)(void);

void describe(NSString *name, void (^block)());
void fdescribe(NSString *name, void (^block)());

void context(NSString *name, void (^block)());
void fcontext(NSString *name, void (^block)());

void it(NSString *name, void (^block)());
void fit(NSString *name, void (^block)());

void example(NSString *name, void (^block)());
void fexample(NSString *name, void (^block)());

void specify(NSString *name, void (^block)());
void fspecify(NSString *name, void (^block)());

#define   pending(...) spt_pending_(__VA_ARGS__, nil)
#define xdescribe(...) spt_pending_(__VA_ARGS__, nil)
#define  xcontext(...) spt_pending_(__VA_ARGS__, nil)
#define  xexample(...) spt_pending_(__VA_ARGS__, nil)
#define       xit(...) spt_pending_(__VA_ARGS__, nil)
#define  xspecify(...) spt_pending_(__VA_ARGS__, nil)

void beforeAll(void (^block)());
void afterAll(void (^block)());

void beforeEach(void (^block)());
void afterEach(void (^block)());

void before(void (^block)());
void after(void (^block)());

void sharedExamplesFor(NSString *name, void (^block)(NSDictionary *data));
void sharedExamples(NSString *name, void (^block)(NSDictionary *data));

#define itShouldBehaveLike(...) spt_itShouldBehaveLike_(@(__FILE__), __LINE__, __VA_ARGS__)
#define      itBehavesLike(...) spt_itShouldBehaveLike_(@(__FILE__), __LINE__, __VA_ARGS__)

void waitUntil(void (^block)(DoneCallback done));

void setAsyncSpecTimeout(NSTimeInterval timeout);

// ----------------------------------------------------------------------------

#define _SPTSpecBegin(name, file, line) \
@interface name##Spec : SPTSpec \
@end \
@implementation name##Spec \
- (void)spec { \
  [[self class] spt_setCurrentTestSuiteFileName:(@(file)) lineNumber:(line)];

#define _SPTSpecEnd \
} \
@end

#define _SPTSharedExampleGroupsBegin(name) \
@interface name##SharedExampleGroups : SPTSharedExampleGroups \
@end \
@implementation name##SharedExampleGroups \
- (void)sharedExampleGroups {

#define _SPTSharedExampleGroupsEnd \
} \
@end

void spt_it_(NSString *name, NSString *fileName, NSUInteger lineNumber, void (^block)());
void spt_fit_(NSString *name, NSString *fileName, NSUInteger lineNumber, void (^block)());
void spt_pending_(NSString *name, ...);
void spt_itShouldBehaveLike_(NSString *fileName, NSUInteger lineNumber, NSString *name, id dictionaryOrBlock);
void spt_itShouldBehaveLike_block(NSString *fileName, NSUInteger lineNumber, NSString *name, NSDictionary *(^block)());