/*
 * TIBCO JasperMobile for iOS
 * Copyright © 2005-2015 TIBCO Software, Inc. All rights reserved.
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
//  JMWebViewManager.h
//  TIBCO JasperMobile
//

#import "JMWebViewManager.h"
#import "JMUtils.h"
#import "JMWebEnvironment.h"

@interface JMWebViewManager()
//@property (nonatomic, strong, readwrite) WKWebView *primaryWebView;
//@property (nonatomic, strong, readwrite) WKWebView *secondaryWebView;
@property (nonatomic, strong) NSMutableArray *webEnvironments;
@end

@implementation JMWebViewManager

#pragma mark - Handle Memory Warnings
- (void)handleMemoryWarnings
{
    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    self.webEnvironments = [NSMutableArray array];
}

#pragma mark - Lifecycle
- (void)dealloc
{
    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

+ (instancetype)sharedInstance {
    static JMWebViewManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _webEnvironments = [NSMutableArray array];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMemoryWarnings)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Public API
- (JMWebEnvironment *)webEnvironmentForId:(NSString *)identifier
{
//    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
//    JMLog(@"identifier: %@", identifier);
    JMWebEnvironment *webEnvironment;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.identifier == %@", identifier];
    NSArray *filtredWebEnvironments = [self.webEnvironments filteredArrayUsingPredicate:predicate];

    if ( filtredWebEnvironments.count == 0 ) {
        webEnvironment = [self createNewWebEnvironmentWithId:identifier];
        [self.webEnvironments addObject:webEnvironment];
    } else if ( filtredWebEnvironments.count > 1 ) {
        return nil;
    } else {
        webEnvironment = [filtredWebEnvironments firstObject];
    }

    return webEnvironment;
}

- (void)removeWebEnvironmentForId:(NSString *)identifier
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.identifier == %@", identifier];
    NSArray *filtredWebEnvironments = [self.webEnvironments filteredArrayUsingPredicate:predicate];

    if ( filtredWebEnvironments.count == 0 ) {
        return;
    } else if ( filtredWebEnvironments.count > 1 ) {
        // TODO: need error?
    } else {
        JMWebEnvironment *webEnvironment = filtredWebEnvironments.firstObject;
        [self.webEnvironments removeObject:webEnvironment];
    }
}

- (JMWebEnvironment *)createNewWebEnvironmentWithId:(NSString *)identifier
{
    JMWebEnvironment *webEnvironment = [JMWebEnvironment webEnvironmentWithId:identifier];
    return webEnvironment;
}

- (void)reset
{
    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    // TODO: need reset?
//    [self.webEnvironments makeObjectsPerformSelector:@selector(reset)];

    self.webEnvironments = [NSMutableArray array];
}

@end
