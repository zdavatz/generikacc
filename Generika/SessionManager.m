//
//  SessionManager.m
//  Generika
//
//  Created by b123400 on 2025/07/10.
//  Copyright © 2025 ywesee GmbH. All rights reserved.
//

#import "SessionManager.h"
#import <AuthenticationServices/AuthenticationServices.h>

#define YWESEE_KEYCLOAK_CLIENT_ID @"generikacc-ios"
#ifdef DEBUG
#define YWESEE_KEYCLOAK_REALM @"test"
#else
#define YWESEE_KEYCLOAK_REALM @"master"
#endif

@interface SessionManager ()

@property (nonatomic, strong) ASWebAuthenticationSession *loginSession;

@end

@implementation SessionManager

static SessionManager *sharedManager = nil;

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[SessionManager alloc] init];
    });
    return sharedManager;
}

- (void)loginWithViewController:(UIViewController *)vc callback:(void (^)(SessionToken *token, NSError *error))completionHandler {
    __weak typeof(self) _self = self;
    ASWebAuthenticationSessionCallback *callback = [ASWebAuthenticationSessionCallback callbackWithCustomScheme:@"generikacc"];
    ASWebAuthenticationSession *session = [[ASWebAuthenticationSession alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kc.ywesee.ch/realms/%@/protocol/openid-connect/auth?client_id=%@&response_type=code", YWESEE_KEYCLOAK_REALM, YWESEE_KEYCLOAK_CLIENT_ID]]
                                           callback:callback
                                  completionHandler:^(NSURL * _Nullable callbackURL, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error);
            completionHandler(nil, error);
            return;
        }
        NSURLComponents *components = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
        NSString *code = nil;
        for (NSURLQueryItem *item in [components queryItems]) {
            if ([[item name] isEqual:@"code"]) {
                code = [item value];
            }
        }
        if (code) {
            [_self exchangeTokenWithCode:code callback:^(SessionToken *token, NSError *error) {
                completionHandler(token, error);
            }];
        }
    }];
    session.presentationContextProvider = vc;
    self.loginSession = session;
    [session start];
}

- (void)exchangeTokenWithCode:(NSString *)code callback:(void (^)(SessionToken *token, NSError *error))callback {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kc.ywesee.ch/realms/%@/protocol/openid-connect/token", YWESEE_KEYCLOAK_REALM]]];
    
    NSURLComponents *components = [[NSURLComponents alloc] init];
    [components setQueryItems:@[
        [NSURLQueryItem queryItemWithName:@"code" value:code],
        [NSURLQueryItem queryItemWithName:@"grant_type" value:@"authorization_code"],
        [NSURLQueryItem queryItemWithName:@"client_id" value:YWESEE_KEYCLOAK_CLIENT_ID]
    ]];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[components query] dataUsingEncoding:NSUTF8StringEncoding]];

    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            callback(nil, error);
            return;
        }
        NSError *err = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (err != nil) {
            callback(nil, err);
            return;
        }
        SessionToken *token = [[SessionToken alloc] initWithJson:jsonObj];
        callback(token, nil);
    }];
    [task resume];
}

- (void)useToken:(SessionToken *)token refreshIfNeeded:(BOOL)refreshIfNeeded callback:(void (^)(SessionToken *newToken, NSError *error))callback {
    if (!token.expired) {
        callback(token, nil);
        return;
    }
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kc.ywesee.ch/realms/%@/protocol/openid-connect/token", YWESEE_KEYCLOAK_REALM]]];
    
    NSURLComponents *components = [[NSURLComponents alloc] init];
    [components setQueryItems:@[
        [NSURLQueryItem queryItemWithName:@"refresh_token" value:token.refreshToken],
        [NSURLQueryItem queryItemWithName:@"grant_type" value:@"refresh_token"],
        [NSURLQueryItem queryItemWithName:@"client_id" value:YWESEE_KEYCLOAK_CLIENT_ID]
    ]];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[components query] dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            callback(nil, error);
            return;
        }
        NSError *err = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (err != nil) {
            callback(nil, err);
            return;
        }
        SessionToken *token = [[SessionToken alloc] initWithJson:jsonObj];
        callback(token, nil);
    }];
    [task resume];
}

- (void)fetchAccountWithToken:(SessionToken *)token callback:(void (^)(SessionAccount *userInfo, NSError *error))callback {
    [self useToken:token
   refreshIfNeeded:YES
          callback:^(SessionToken *newToken, NSError *error) {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kc.ywesee.ch/realms/%@/account", YWESEE_KEYCLOAK_REALM]]];
        
        [request setValue:[NSString stringWithFormat:@"Bearer %@", token.accessToken] forHTTPHeaderField:@"Authorization"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil) {
                callback(nil, error);
                return;
            }
            NSError *err = nil;
            id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
            if (err != nil) {
                callback(nil, err);
                return;
            }
            SessionAccount *account = [[SessionAccount alloc] initWithJson:jsonObj];
            callback(account, nil);
        }];
        [task resume];
    }];
}

@end
