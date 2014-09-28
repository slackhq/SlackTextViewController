//
//  STTwitterWeb.m
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/13/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import "STTwitterHTML.h"
#import "STHTTPRequest.h"
#import "NSString+STTwitter.h"

@implementation STTwitterHTML

- (void)getLoginForm:(void(^)(NSString *authenticityToken))successBlock errorBlock:(void(^)(NSError *error))errorBlock {
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:@"https://twitter.com/login"];
    
    r.completionBlock = ^(NSDictionary *headers, NSString *body) {
        
        NSError *error = nil;
        //        NSString *token = [body firstMatchWithRegex:@"<input type=\"hidden\" value=\"(\\S+)\" name=\"authenticity_token\"/>" error:&error];
        NSString *token = [body st_firstMatchWithRegex:@"formAuthenticityToken&quot;:&quot;(\\S+?)&quot" error:&error];
        
        if(token == nil) {
            errorBlock(error);
            return;
        }
        
        successBlock(token);
    };
    
    r.errorBlock = ^(NSError *error) {
        errorBlock(error);
    };
    
    [r startAsynchronous];
}

- (void)postLoginFormWithUsername:(NSString *)username
                         password:(NSString *)password
                authenticityToken:(NSString *)authenticityToken
                     successBlock:(void(^)(NSString *body))successBlock
                       errorBlock:(void(^)(NSError *error))errorBlock {
    
    if([username length] == 0 || [password length] == 0) {
        NSString *errorDescription = [NSString stringWithFormat:@"Missing credentials"];
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:STTwitterHTMLCannotPostWithoutCredentials userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
        errorBlock(error);
        return;
    }
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:@"https://twitter.com/sessions"];
    
    r.POSTDictionary = @{@"authenticity_token" : authenticityToken,
                         @"session[username_or_email]" : username,
                         @"session[password]" : password,
                         @"remember_me" : @"1",
                         @"commit" : @"Sign in"};
    
    r.completionBlock = ^(NSDictionary *headers, NSString *body) {
        successBlock(body);
    };
    
    r.errorBlock = ^(NSError *error) {
        errorBlock(error);
    };
    
    [r startAsynchronous];
}

- (void)getAuthorizeFormAtURL:(NSURL *)url successBlock:(void(^)(NSString *authenticityToken, NSString *oauthToken))successBlock errorBlock:(void(^)(NSError *error))errorBlock {
    
    STHTTPRequest *r = [STHTTPRequest requestWithURL:url];
    
    r.completionBlock = ^(NSDictionary *headers, NSString *body) {
        /*
         <form action="https://api.twitter.com/oauth/authorize" id="oauth_form" method="post"><div style="margin:0;padding:0"><input name="authenticity_token" type="hidden" value="dacd811cf06655518633ad93e950132614eab7f4" /></div>
         
         <input id="oauth_token" name="oauth_token" type="hidden" value="3qp5r3Ya65aVks8lNZEZm7313080zTdMQTOplalzQI" />
         */
        
        NSError *error1 = nil;
        NSString *authenticityToken = [body st_firstMatchWithRegex:@"<input name=\"authenticity_token\" type=\"hidden\" value=\"(\\S+)\" />" error:&error1];
        
        if(authenticityToken == nil) {
            errorBlock(error1);
            return;
        }
        
        /**/
        
        NSError *error2 = nil;
        
        NSString *oauthToken = [body st_firstMatchWithRegex:@"<input id=\"oauth_token\" name=\"oauth_token\" type=\"hidden\" value=\"(\\S+)\" />" error:&error2];
        
        if(oauthToken == nil) {
            errorBlock(error2);
            return;
        }
        
        /**/
        
        successBlock(authenticityToken, oauthToken);
    };
    
    r.errorBlock = ^(NSError *error) {
        errorBlock(error);
    };
    
    [r startAsynchronous];
}

- (void)postAuthorizeFormResultsAtURL:(NSURL *)url authenticityToken:(NSString *)authenticityToken oauthToken:(NSString *)oauthToken successBlock:(void(^)(NSString *PIN))successBlock errorBlock:(void(^)(NSError *error))errorBlock {
    
    STHTTPRequest *r = [STHTTPRequest requestWithURL:url];
    
    r.POSTDictionary = @{@"authenticity_token" : authenticityToken,
                         @"oauth_token" : oauthToken};
    
    r.completionBlock = ^(NSDictionary *headers, NSString *body) {
        
        NSError *error = nil;
        NSString *pin = [body st_firstMatchWithRegex:@"<code>(\\d+)</code>" error:&error];
        
        if(pin == nil) {
            errorBlock(error);
            return;
        }
        
        successBlock(pin);
    };
    
    r.errorBlock = ^(NSError *error) {
        errorBlock(error);
    };
    
    [r startAsynchronous];
}

@end

