## STTwitter

_A stable, mature and comprehensive Objective-C library for Twitter REST API 1.1_

**[2014-06-18]** [Swifter](https://github.com/mattdonnelly/Swifter), A Twitter framework for iOS & OS X written in Swift, by [@MatthewDonnelly](htps://www.twitter.com/MatthewDonnelly/)  
**[2014-05-31]** Follow STTwitter on Twitter: [@STTLibrary](https://www.twitter.com/STTLibrary/)  
**[2014-05-22]** STTwitter was presented at [CocoaHeads Lausanne](https://www.facebook.com/events/732041160150290/) ([slides](http://seriot.ch/resources/abusing_twitter_api/sttwitter_cocoaheads.pdf))  
**[2013-10-24]** STTwitter was presented at [SoftShake 2013](http://soft-shake.ch) ([slides](http://seriot.ch/resources/abusing_twitter_api/ios_twitter_integration_sos13.pdf)).

[![Build Status](https://travis-ci.org/nst/STTwitter.svg?branch=master)](https://travis-ci.org/nst/STTwitter)

1. [Testimonials](#testimonials)
2. [Installation](#installation)
3. [Code Snippets](#code-snippets)
4. [Various Kinds of OAuth Connections](#various-kinds-of-oauth-connections)
5. [OAuth Consumer Tokens](#oauth-consumer-tokens)
6. [Demo / Test Project](#demo--test-project)
7. [Integration Tips](#integration-tips)
8. [Troubleshooting](#troubleshooting)
9. [Developers](#developers)
10. [BSD 3-Clause License](#bsd-3-clause-license)  

### Testimonials

> "We are now using STTwitter"
[Adium developers](https://adium.im/blog/2013/07/adium-1-5-7-released/)

> "An awesome Objective-C wrapper for Twitter’s HTTP API? Yes please!"
[@nilsou](https://twitter.com/nilsou/status/392364862472736768)

> "Your Library is really great, I stopped the development of my client because I was hating twitter APIs for some reasons, this Library make me want to continue, seriously thank you!"
[MP0w](https://github.com/nst/STTwitter/pull/49#issuecomment-28746249)

> "Powered by his own backend wrapper for HTTP calls, STTwitter writes most of the code for you for oAuth based authentication and API resource access like statuses, mentions, users, searches, friends & followers, favorites, lists, places, trends. The documentation is also excellent."
[STTwitter - Delightful Twitter Library for iOS / buddingdevelopers.com](http://buddingdevelopers.com/sttwitter-delightful-twitter-library-for-ios/)

### Installation

Drag and drop STTwitter directory into your project.

Link your project with the following frameworks:

- Accounts.framework
- Social.framework
- Twitter.framework (iOS only)
- Security.framework (OS X only)

If you want to use CocoaPods, add the following two lines to your Podfile:

    pod 'STTwitter'

Then, run the following command to install the STTwitter pod:

    pod install

STTwitter does not depend on AppKit or UIKit and hence can be used in a command-line Twitter client.

STTwitter requires iOS 5+ or OS X 10.7+.

Vea Software has a great written + live-demo [tutorial](http://tutorials.veasoftware.com/2013/12/23/twitter-api-version-1-1-app-authentication/) about creating a simple iOS app using STTwitter's app only mode.

### Code Snippets

Here are several ways to use STTwitter.

You'll find complete, minimal, command-line projects in the `demo_cli` directory:

- [streaming](https://github.com/nst/STTwitter/blob/master/demo_cli/streaming/main.m) use the streaming API to filter all tweets with some word
- [streaming_with_bot](https://github.com/nst/STTwitter/blob/master/demo_cli/streaming_with_bot/main.m) same as above, but reply instantly from another account
- [reverse_auth](https://github.com/nst/STTwitter/blob/master/demo_cli/reverse_auth/main.m) perform reverse authentication
- [followers](https://github.com/nst/STTwitter/blob/master/demo_cli/followers/main.m) display your followers by following Twitter's API cursors, and waiting for a while before reaching rate limits
- [favorites](https://github.com/nst/STTwitter/blob/master/demo_cli/favorites/main.m) display tweets favorited by people you follow, set a tweet's favorite status
- [conversation](https://github.com/nst/STTwitter/blob/master/demo_cli/conversation/main.m) post several tweets in the same conversation
- [t2rss](https://github.com/nst/STTwitter/blob/master/demo_cli/t2rss/main.m) convert your timeline into an RSS feed

##### Instantiate STTwitterAPI

```Objective-C
STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:@""
                                                      consumerSecret:@""
                                                            username:@""
                                                            password:@""];
```

##### Verify the credentials

```Objective-C
[twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
    // ...
} errorBlock:^(NSError *error) {
    // ...
}];
```

##### Get the timeline statuses

```Objective-C
[twitter getHomeTimelineSinceID:nil
                          count:100
                   successBlock:^(NSArray *statuses) {
    // ...
} errorBlock:^(NSError *error) {
    // ...
}];
```

##### Streaming API

```Objective-C
id request = [twitter getStatusesSampleDelimited:nil
                                   stallWarnings:nil
                                   progressBlock:^(id response) {
    // ...
} stallWarningBlock:nil
         errorBlock:^(NSError *error) {
    // ...
}];

// ...

[request cancel]; // when you're done with it
```

##### App Only Authentication

```Objective-C
STTwitterAPI *twitter = [STTwitterAPI twitterAPIAppOnlyWithConsumerKey:@""
                                                        consumerSecret:@""];

[twitter verifyCredentialsWithSuccessBlock:^(NSString *bearerToken) {

    [twitter getUserTimelineWithScreenName:@"barackobama"
                              successBlock:^(NSArray *statuses) {
        // ...
    } errorBlock:^(NSError *error) {
        // ...
    }];

} errorBlock:^(NSError *error) {
    // ...
}];
```

### Various Kinds of OAuth Connections

You can instantiate `STTwitterAPI` in three ways:

- use the Twitter account set in OS X Preferences or iOS Settings
- use a custom `consumer key` and `consumer secret` (three flavors)
  - get an URL, fetch a PIN, enter it in your app, get oauth access tokens  
  - set `username` and `password`, get oauth access tokens with XAuth, if the app is entitled to
  - set `oauth token` and `oauth token secret` directly
- use the [Application Only](https://dev.twitter.com/docs/auth/application-only-auth) authentication and get / use a "bearer token"

So there are five cases altogether, hence these five methods:

```Objective-C
+ (STTwitterAPI *)twitterAPIOSWithFirstAccount;

+ (STTwitterAPI *)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                  consumerSecret:(NSString *)consumerSecret;

+ (STTwitterAPI *)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                  consumerSecret:(NSString *)consumerSecret
                                        username:(NSString *)username
                                        password:(NSString *)password;

+ (STTwitterAPI *)twitterAPIWithOAuthConsumerKey:(NSString *)consumerKey
                                  consumerSecret:(NSString *)consumerSecret
                                      oauthToken:(NSString *)oauthToken
                                oauthTokenSecret:(NSString *)oauthTokenSecret;

+ (STTwitterAPI *)twitterAPIAppOnlyWithConsumerKey:(NSString *)consumerKey
                                    consumerSecret:(NSString *)consumerSecret;
```

##### Reverse Authentication

Reference: [https://dev.twitter.com/docs/ios/using-reverse-auth](https://dev.twitter.com/docs/ios/using-reverse-auth)

The most common use case of reverse authentication is letting users register/login to a remote service with their OS X or iOS Twitter account.

    iOS/OSX     Twitter     Server
    -------------->                 reverse auth.
    < - - - - - - -                 access tokens

    ----------------------------->  access tokens

                   <--------------  access Twitter on user's behalf
                    - - - - - - ->

Here is how to use reverse authentication with STTwitter:

```Objective-C
STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerName:nil
                                                          consumerKey:@"CONSUMER_KEY"
                                                       consumerSecret:@"CONSUMER_SECRET"];

[twitter postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {

    STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithFirstAccount];

    [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {

        [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader
                                                            successBlock:^(NSString *oAuthToken,
                                                                           NSString *oAuthTokenSecret,
                                                                           NSString *userID,
                                                                           NSString *screenName) {

                                                                // use the tokens...

                                                            } errorBlock:^(NSError *error) {
                                                                // ...
                                                            }];

    } errorBlock:^(NSError *error) {
        // ...
    }];

} errorBlock:^(NSError *error) {
    // ...
}];
```

Contrary to what can be read here and there, you can perfectly [access direct messages from iOS Twitter accounts](http://stackoverflow.com/questions/17990484/accessing-twitter-direct-messages-using-slrequest-ios/18760445#18760445).

### OAuth Consumer Tokens

In Twitter REST API v1.1, each client application must authenticate itself with `consumer key` and `consumer secret` tokens. You can request consumer tokens for your app on Twitter's website: [https://dev.twitter.com/apps](https://dev.twitter.com/apps).

STTwitter demo project comes with `TwitterClients.plist` where you can enter your own consumer tokens.

### Demo / Test Project

There is a demo project for OS X in `demo_osx`, which lets you choose how to get the OAuth tokens (see below).

An archive generated on 2013-10-20 10:35 is available at [http://seriot.ch/temp/STTwitterDemoOSX.app.zip](http://seriot.ch/temp/STTwitterDemoOSX.app.zip).

Once you got the OAuth tokens, you can get your timeline and post a new status.

There is also a simple iOS demo project in `demo_ios`.

<img border="1" src="Art/osx.png" width="840" alt="STTwitter Demo iOS"></img>
<img border="1" src="Art/ios.png" alt="STTwitter Demo iOS"></img>
<img border="1" src="Art/tweet.png" alt="sample tweet"></img>

### Integration Tips

##### Concurrency

STTwitter is supposed to be used from the main thread. The HTTP requests are performed anychronously and the callbacks are guaranteed to be called on main thread.

##### Remove Asserts in Release Mode

There are several asserts in the code. They are very useful in debug mode but you should not include them in release.

New projects created with Xcode 5 already remove NSAssert logic by default in release.

In older projects, you can set the compilation flag `-DNS_BLOCK_ASSERTIONS=1`.

##### Number of Characters in a Tweet

Use the method `-[NSString st_numberOfCharactersInATweet]` to let the user know how many characters she can enter before the end of the Tweet. The method may also return a negative value if the string exceeds a tweet's maximum length. The method considers the shortened URL lengths.

##### Date Formatter

In order to convert the string in the `created_at` field from Twitter's JSON into an NSDate instance, you can use the `+[NSDateFormatter st_TwitterDateFormatter]`.

```Objective-C
NSDateFormatter *df = [NSDateFormatter st_TwitterDateFormatter];
NSString *dateString = [d valueForKey:@"created_at"]; // "Sun Jun 28 20:33:01 +0000 2009"
NSDate *date = [df dateFromString:dateString];
```

##### URLs Shorteners

In order to expand shortened URLs such as Twitter's `t.co` service, use:

```Objective-C
[STHTTPRequest expandedURLStringForShortenedURLString:@"http://t.co/tmoxbSfDWc" successBlock:^(NSString *expandedURLString) {
    //
} errorBlock:^(NSError *error) {
    //
}];
```

##### API Responses Text Processing

You may want to use Twitter's own Objective-C library for text processing: [https://github.com/twitter/twitter-text-objc/](https://github.com/twitter/twitter-text-objc/).

`twitter-text-objc` provides you with methods such as:

```Objective-C
+ (NSArray*)entitiesInText:(NSString*)text;
+ (NSArray*)URLsInText:(NSString*)text;
+ (NSArray*)hashtagsInText:(NSString*)text checkingURLOverlap:(BOOL)checkingURLOverlap;
+ (NSArray*)symbolsInText:(NSString*)text checkingURLOverlap:(BOOL)checkingURLOverlap;
+ (NSArray*)mentionedScreenNamesInText:(NSString*)text;
+ (NSArray*)mentionsOrListsInText:(NSString*)text;
+ (TwitterTextEntity*)repliedScreenNameInText:(NSString*)text;
```

##### Logout

The correct approach to logout a user is setint the `STTwitterAPI` instance to nil.

You'll create a new one at the next login.

##### Boolean Parameters

There are a lot of optional parameters in Twitter API. In STTwitter, you can ignore such parameters by passing `nil`. Regarding boolean parameters, STTwitter can't just use Objective-C `YES` and `NO` because `NO` has the same value as `nil` (zero). So boolean parameters are wrapped into `NSNumber` objects, which are pretty easy to use with boolean values thanks to Objective-C literals. So, with STTwitter, you will assign an optional parameter of Twitter API either as `@(YES)`, `@(NO)` or `nil`.

##### Long Methods

STTwitter provides a full, "one-to-one" Objective-C front-end to Twitter REST API. It often results in long methd names with many parameters. In your application, you may want to add your own, simplified methods on top of STTwitterAPI. A good idea is to create an Objective-C category for your application, such as in the following code.

`STTwitterAPI+MyApp.h`

```Objective-C
#import "STTwitterAPI.h"

@interface STTwitterAPI (MyApp)

- (void)getStatusesShowID:(NSString *)statusID
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

@end
```

`STTwitterAPI+MyApp.m`

```Objective-C
#import "STTwitterAPI+MyApp.h"

@implementation STTwitterAPI (MyApp)

- (void)getStatusesShowID:(NSString *)statusID
             successBlock:(void(^)(NSDictionary *status))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock {

    [self getStatusesShowID:statusID
                   trimUser:@(YES)
           includeMyRetweet:nil
            includeEntities:@(NO)
               successBlock:^(NSDictionary *status) {

                   successBlock(status);

               } errorBlock:^(NSError *error) {

                   errorBlock(error);

               }];
}

@end
```

##### Stream Request and Connection Losses

Streaming requests may be lost when your iOS application comes back to foreground after a while in background. In order to handle this case properly, you can detect the connection loss in the error block and restart the stream request from there.

```Objective-C
// ...
} errorBlock:^(NSError *error) {

    if([[error domain] isEqualToString:NSURLErrorDomain] && [error code] == NSURLErrorNetworkConnectionLost) {
        [self startStreamRequest];
    }

}];
```

### Troubleshooting

##### xAuth

Twitter restricts the xAuth authentication process to xAuth-enabled consumer tokens only. So, if you get an error like `The consumer tokens are probably not xAuth enabled.` while accessing `https://api.twitter.com/oauth/access_token`, see Twitter's website [https://dev.twitter.com/docs/oauth/xauth](https://dev.twitter.com/docs/oauth/xauth) and ask Twitter to enable the xAuth authentication process for your consumer tokens.

##### Anything Else

Please [fill an issue](https://github.com/nst/STTwitter/issues) on GitHub or use the [STTwitter tag](http://stackoverflow.com/questions/tagged/sttwitter) on StackOverflow.

### Developers

The application only interacts with `STTwitterAPI`.

`STTwitterAPI` maps Objective-C methods with all Twitter API endpoints.

You can create your own convenience methods with fewer parameters. You can also use this generic method directly:

```Objective-C
  - (id)fetchResource:(NSString *)resource
           HTTPMethod:(NSString *)HTTPMethod
        baseURLString:(NSString *)baseURLString
           parameters:(NSDictionary *)params
  uploadProgressBlock:(void(^)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite))uploadProgressBlock
downloadProgressBlock:(void (^)(id request, id response))downloadProgressBlock
         successBlock:(void (^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id response))successBlock
           errorBlock:(void (^)(id request, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock;
```

##### Layer Model

     +------------------------------------------------------------------------+
     |                         Your Application                               |
     +--------------------------------------------------------+---------------+
     |                  STTwitterAPI                          | STTwitterHTML |
     +--------------------------------------------------------+               |
     + - - - - - - - - - - - - - - - - - - - - - - - - - - - -+               |
     |              STTwitterOAuthProtocol                    |               |
     + - - - - - - - - - - - - - - - - - - - - - - - - - - - -+               |
     +--------------------+----------------+------------------+               |
     |    STTwitterOS     | STTwitterOAuth | STTwitterAppOnly |               |
     +--------------------+----------------+------------------+---------------+
     | STTwitterOSRequest |                   STHTTPRequest                   |
     +--------------------+---------------------------------------------------+
      |
      + Accounts.framework
      + Social.framework

##### Summary

     * STTwitterAPI
        - can be instantiated with the authentication mode you want
        - provides methods to interact with each Twitter API endpoint

     * STTwitterHTML
        - a hackish class to login on Twitter by parsing the HTML code and get a PIN
        - it can break at anytime, your app should not rely on it in production

     * STTwitterOAuthProtocol
        - provides generic methods to POST and GET resources on Twitter's hosts

     * STTwitterOS
        - uses Twitter accounts defined in OS X Preferences or iOS Settings
        - uses OS X / iOS frameworks to interact with Twitter API

     * STTwitterOSRequest
        - black-based wrapper around SLRequest's underlying NSURLRequest
        
     * STTwitterOAuth
        - implements OAuth and xAuth authentication

     * STTwitterAppOnly
        - implements the 'app only' authentication
        - https://dev.twitter.com/docs/auth/application-only-auth

     * STHTTPRequest
        - block-based wrapper around NSURLConnection
        - https://github.com/nst/STHTTPRequest

### BSD 3-Clause License

See [LICENCE.txt](LICENCE.txt).
