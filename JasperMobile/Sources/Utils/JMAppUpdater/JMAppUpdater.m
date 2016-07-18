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
//  JMAppUpdater.m
//  TIBCO JasperMobile
//

#import "JMAppUpdater.h"
#import "JMConstants.h"
#import "JMFavorites.h"
#import "JMServerProfile+Helpers.h"
#import "JMSavedResources+Helpers.h"
#import "JMFavorites+Helpers.h"
#import "JMExportResource.h"

// Old constants used in previous versions of application
static NSString * const kJMDefaultsUpdatedVersions = @"jaspersoft.mobile.updated.versions";

@interface JMAppUpdater()

@end

@implementation JMAppUpdater

// Fill migrations with update methods for different versions

#pragma mark - Class methods

+ (void)update
{
    NSNumber *latestAppVersion = [self latestAppVersion];
    NSNumber *currentAppVersion = [self currentAppVersion];
    if (currentAppVersion != nil && [currentAppVersion compare:latestAppVersion] == NSOrderedSame) return;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kJMDefaultsIntroDidApear];
    [[JMSessionManager sharedManager] logout];

    if ([[JMCoreDataManager sharedInstance] isMigrationNeeded]) {
        [[JMCoreDataManager sharedInstance] migrate:nil];
    }

    NSMutableDictionary *versionsToUpdate = [NSMutableDictionary dictionary];

    // Add update methods
    versionsToUpdate[@1.9] = [NSValue valueWithPointer:@selector(update_1_9)];
    BOOL updateDidSuccess = YES;
    for (NSNumber *version in versionsToUpdate.allKeys) {
        if (version.doubleValue <= currentAppVersion.doubleValue) continue;

        SEL selector = [versionsToUpdate[version] pointerValue];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
        invocation.selector = selector;
        invocation.target = self;
        [invocation invoke];

        [invocation getReturnValue:&updateDidSuccess];

        if (updateDidSuccess) {
            // Update app version for each migration. This allows to track which migration was failed
            [self updateAppVersionTo:version];
        } else {
            break;
        }
    }

    if (!updateDidSuccess) {
        [self showErrors];
    } else {
        [self removeOldMobileDemo];
        [self updateSavedItems];
        // skip user agreement
        [JMUtils setUserAcceptAgreement:NO];
    }
}

+ (void)updateAppVersionTo:(NSNumber *)appVersion
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:appVersion forKey:kJMDefaultsCurrentVersion];
    [defaults synchronize];
}

+ (NSNumber *)latestAppVersion
{
    NSString *appVersion = [self latestAppVersionAsString];
    return @([appVersion doubleValue]);
}

+ (NSString *)latestAppVersionAsString
{
    return [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
}

+ (NSNumber *)currentAppVersion
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kJMDefaultsCurrentVersion];
}

+ (BOOL)isRunningForTheFirstTime
{
    return (![self currentAppVersion]);
}

#pragma mark - Migration methods

// Add saved report to CoreData
+ (BOOL)update_1_9
{
    NSString *reportsDirectory = [[JMUtils applicationDocumentsDirectory] stringByAppendingPathComponent:kJMReportsDirectory];
    NSMutableArray *reports = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:reportsDirectory error:nil] mutableCopy];
    [reports removeObject:@".DS_Store"];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *report in reports) {
        BOOL isReportDirectory = NO;
        if ([fileManager fileExistsAtPath:[reportsDirectory stringByAppendingPathComponent:report] isDirectory:&isReportDirectory] && isReportDirectory) {
            NSRange reportExtensionRange = [report rangeOfString:@"." options:NSBackwardsSearch];
            NSString *reportExtension = [report substringFromIndex:reportExtensionRange.location];
            NSString *reportName = [report stringByReplacingOccurrencesOfString:reportExtension withString:@""];
            
            JSResourceLookup *resourceLookup = [JSResourceLookup new];
            resourceLookup.label = reportName;
            resourceLookup.resourceType = kJS_WS_TYPE_REPORT_UNIT;
            resourceLookup.version = @(0);
            JMExportResource *resource = [JMExportResource resourceWithResourceLookup:resourceLookup];
            resource.format = [reportExtension stringByReplacingOccurrencesOfString:@"." withString:@""];
            NSURL *reportSourcesURL = [NSURL fileURLWithPath:[reportsDirectory stringByAppendingPathComponent:report] isDirectory:YES];
            [JMSavedResources addResource:resource
                               sourcesURL:reportSourcesURL];
        }
    }

    return YES;
}

#pragma mark - Private

+ (void)showErrors
{
    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"error_upgrade_data_title"
                                                                                      message:@"error_upgrade_data_msg"
                                                                            cancelButtonTitle:@"dialog_button_cancel"
                                                                      cancelCompletionHandler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                                                                          abort();
                                                                      }];
    
    __weak typeof(self) weakSelf = self;
    [alertController addActionWithLocalizedTitle:@"dialog_button_retry" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf update];
    }];
    
    [alertController addActionWithLocalizedTitle:@"dialog_button_applyUpdate" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJMResetApplicationNotification object:nil];
    }];
    
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Helpers
+ (void)removeOldMobileDemo
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ServerProfile"];
    NSMutableArray *predicates = [NSMutableArray array];
    NSString *mobileDemoServerURLString = @"http://mobiledemo.jaspersoft.com/jasperserver-pro";
    [predicates addObject:[NSPredicate predicateWithFormat:@"serverUrl == %@", mobileDemoServerURLString]];
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    NSArray *serverProfiles = [[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (serverProfiles.count == 1) {
        JMServerProfile *serverProfile = serverProfiles.firstObject;
        [[JMCoreDataManager sharedInstance].managedObjectContext deleteObject:serverProfile];
        [[JMCoreDataManager sharedInstance] save:nil];
    }
}

+ (void)updateSavedItems
{
    NSArray *savedItems = [JMSavedResources allSavedItems];
    for (JMSavedResources *savedResource in savedItems) {
        // 1. get old path
        NSString *oldPath = [JMSavedResources oldPathForSavedResource:savedResource];
        NSString *oldURI = savedResource.uri;

        // 2. create new path
        NSString *documentPath = [JMUtils applicationDocumentsDirectory];
        NSString *newURI = [JMSavedResources newURIForSavedResource:savedResource];
        NSString *newPath = [documentPath stringByAppendingPathComponent:newURI];

        // 3. move from old path to new path
        [JMSavedResources migrateSavedItemFromPath:oldPath toPath:newPath];

        // 4. save new uri
        savedResource.uri = newURI;
        // 5. update uri if saved item was marked as favorites
        NSArray *allFavorites = [JMFavorites allFavorites];
        for (JMFavorites *favorites in allFavorites) {
            if ([favorites.uri isEqualToString:oldURI]) {
                favorites.uri = newURI;
            }
        }
    }
}

@end
