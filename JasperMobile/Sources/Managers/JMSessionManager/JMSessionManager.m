/*
 * TIBCO JasperMobile for iOS
 * Copyright © 2005-2014 TIBCO Software, Inc. All rights reserved.
 * http://community.jaspersoft.com/project/jaspermobile-ios
 *
 * Unless you have purchased a commercial license agreement from Jaspersoft,
 * the following license terms apply:
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/lgpl>.
 */


//
//  JMSessionManager.m
//  TIBCO JasperMobile
//

#import "JMSessionManager.h"
#import "JMServerProfile+Helpers.h"
#import "JMCancelRequestPopup.h"
#import "JMWebViewManager.h"

NSString * const kJMSavedSessionKey = @"JMSavedSessionKey";

static JMSessionManager *_sharedManager = nil;

@interface JMSessionManager ()
@property (nonatomic, strong, readwrite) JSRESTBase *restClient;

@end

@implementation JMSessionManager

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [JMSessionManager new];
    });
    
    return _sharedManager;
}

- (void) createSessionWithServerProfile:(JSProfile *)serverProfile keepLogged:(BOOL)keepLogged completion:(void(^)(BOOL success))completionBlock
{
    self.restClient = [[JSRESTBase alloc] initWithServerProfile:serverProfile keepLogged:keepLogged];
    if ([self.restClient isSessionAuthorized] && self.restClient.serverInfo) {
        [self saveActiveSessionIfNeeded];
        if (completionBlock) {
            completionBlock(YES);
        }
    } else if (completionBlock) {
        completionBlock(NO);
    }
}

- (void) saveActiveSessionIfNeeded {
    if (self.restClient && self.restClient.keepSession) {
        NSData *archivedSession = [NSKeyedArchiver archivedDataWithRootObject:self.restClient];
        [[NSUserDefaults standardUserDefaults] setObject:archivedSession forKey:kJMSavedSessionKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kJMSavedSessionKey];
    }
}

- (BOOL) restoreLastSession
{
    BOOL isRestoredSession = NO;
    if (!self.restClient) {
        NSData *savedSession = [[NSUserDefaults standardUserDefaults] objectForKey:kJMSavedSessionKey];
        if (savedSession) {
            id unarchivedSession = [NSKeyedUnarchiver unarchiveObjectWithData:savedSession];
            if (unarchivedSession && [unarchivedSession isKindOfClass:[JSRESTBase class]]) {
                self.restClient = unarchivedSession;
            }
        }
    }
    if (self.restClient && self.restClient.keepSession) {
        [self.restClient resetReachabilityStatus];
        JMServerProfile *activeServerProfile = [JMServerProfile serverProfileForname:self.restClient.serverProfile.alias];
        if (activeServerProfile && !activeServerProfile.askPassword.boolValue) {
            [JMCancelRequestPopup presentWithMessage:@"status.loading" cancelBlock:nil];
            isRestoredSession = ([self.restClient isSessionAuthorized] && self.restClient.serverInfo);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [JMCancelRequestPopup dismiss];
            });
        }
    }
    return isRestoredSession;
}

- (void) logout
{
    [self.restClient cancelAllRequests];
    [self.restClient deleteCookies];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kJMSavedSessionKey];
    self.restClient = nil;
    
    // Clear webView
    [[JMWebViewManager sharedInstance] reset];
    [[JMVisualizeWebViewManager sharedInstance] reset];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (NSPredicate *)predicateForCurrentServerProfile
{
    JMServerProfile *activaServerProfile = [JMServerProfile serverProfileForname:self.restClient.serverProfile.alias];
    NSMutableArray *currentServerProfilepredicates = [NSMutableArray array];
    [currentServerProfilepredicates addObject:[NSPredicate predicateWithFormat:@"serverProfile = %@", activaServerProfile]];
    [currentServerProfilepredicates addObject:[NSPredicate predicateWithFormat:@"username = %@", self.restClient.serverProfile.username]];

    NSMutableArray *nilServerProfilepredicates = [NSMutableArray array];
    [nilServerProfilepredicates addObject:[NSPredicate predicateWithFormat:@"serverProfile = nil"]];
    [nilServerProfilepredicates addObject:[NSPredicate predicateWithFormat:@"username = nil"]];
    
    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:currentServerProfilepredicates]];
    [predicates addObject:[[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:nilServerProfilepredicates]];
    
    return [[NSCompoundPredicate alloc] initWithType:NSOrPredicateType subpredicates:predicates];
}

@end