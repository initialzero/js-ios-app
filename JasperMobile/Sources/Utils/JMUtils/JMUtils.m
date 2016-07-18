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
//  JMUtils.m
//  TIBCO JasperMobile
//

#import "JMUtils.h"
#import "JMConstants.h"
#import "JMLocalization.h"
#import "JMSavedResources+Helpers.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "JasperMobileAppDelegate.h"
#import "JMMainNavigationController.h"
#import "SWRevealViewController.h"
#import "JMMenuViewController.h"
#import "JMEULAViewController.h"
#import "JMServerProfile+Helpers.h"
#import "JSConstants.h"
#import "JMServersGridViewController.h"
#import "JMServerOptionsViewController.h"


void jmDebugLog(NSString *format, ...) {
#ifndef __RELEASE__
    va_list argumentList;
    va_start(argumentList, format);
    NSMutableString * message = [[NSMutableString alloc] initWithFormat:format
                                                              arguments:argumentList];
    
    [message insertString:@"<JM Debug> " atIndex:0]; //
    NSLogv(message, argumentList); // Originally NSLog is a wrapper around NSLogv.
    va_end(argumentList);
#endif
}

@implementation JMUtils

#define kJMNameMin 1
#define kJMNameMax 250
#define kJMInvalidCharacters     @"~!#$%^`@&*()-+={}[]:;\"'<>,?/|\\"

+ (BOOL)validateResourceName:(NSString *)resourceName errorMessage:(NSString *__autoreleasing  _Nullable *)errorMessage
{
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:kJMInvalidCharacters];
    resourceName = [resourceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (resourceName.length < kJMNameMin) {
        *errorMessage = JMCustomLocalizedString(@"resource_viewer_save_name_errmsg_empty", nil);
    } else if (resourceName.length > kJMNameMax) {
        *errorMessage = [NSString stringWithFormat:JMCustomLocalizedString(@"resource_viewer_save_name_errmsg_maxlength", nil), kJMNameMax];
    } else if ([resourceName rangeOfCharacterFromSet:characterSet].location != NSNotFound) {
        *errorMessage = [NSString stringWithFormat:JMCustomLocalizedString(@"resource_viewer_save_name_errmsg_characters", nil), kJMInvalidCharacters];
    }
    return [*errorMessage length] == 0;
}

+ (NSString *)applicationDocumentsDirectory
{
    static NSString *reportDirectory;
    if (!reportDirectory) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        reportDirectory = paths[0];
    }
    return reportDirectory;
}

+ (NSString *)applicationTempDirectory
{
    static NSString *tempDirectory;
    if (!tempDirectory) {
        tempDirectory = NSTemporaryDirectory();
    }
    return tempDirectory;
}

+ (void)showNetworkActivityIndicator
{
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
}

+ (void)hideNetworkActivityIndicator
{
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
}

+ (BOOL)isIphone
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

+ (BOOL)isSystemVersion9
{
    return [UIDevice currentDevice].systemVersion.integerValue == 9;
}

+ (BOOL)crashReportsSendingEnable
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kJMDefaultSendingCrashReport]) {
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:kJMDefaultSendingCrashReport];
    }

    id crashReportsSettings = [[NSUserDefaults standardUserDefaults] objectForKey:kJMDefaultSendingCrashReport];
    if (crashReportsSettings) {
        return [crashReportsSettings boolValue];
    }
    return YES;
}

+ (BOOL)isAutofillLoginDataEnable
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kJMDefaultSendingAutoFillLoginData]) {
        [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:kJMDefaultSendingAutoFillLoginData];
    }

    id autofillLoginData = [[NSUserDefaults standardUserDefaults] objectForKey:kJMDefaultSendingAutoFillLoginData];
    if (autofillLoginData) {
        return [autofillLoginData boolValue];
    }
    return NO;
}

+ (void)activateCrashReportSendingIfNeeded
{
    if ([self crashReportsSendingEnable]) {
        [Fabric with:@[
                       [Crashlytics class]
                       ]];
    }
}

+ (NSArray *)supportedFormatsForReportSaving
{
    static NSArray *reportFormats;
    if (!reportFormats) {
        reportFormats = @[
                           kJS_CONTENT_TYPE_HTML,
                           kJS_CONTENT_TYPE_PDF,
                           kJS_CONTENT_TYPE_XLS,
                           ];
    }
    return reportFormats;
}

+ (NSArray *)supportedFormatsForDashboardSaving
{
    static NSArray *dashboardFormats;
    if (!dashboardFormats) {
        dashboardFormats = @[
                          kJS_CONTENT_TYPE_PDF,
                          kJS_CONTENT_TYPE_PNG,
                          ];
    }
    return dashboardFormats;
}

+ (NSString *)buildVersion
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    return infoDictionary[(NSString*)kCFBundleVersionKey];
}

#pragma mark - Login VC

+ (void)showLoginViewAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    [self showLoginViewAnimated:animated completion:completion loginCompletion:nil];
}

+ (void)showLoginViewAnimated:(BOOL)animated completion:(void (^)(void))completion loginCompletion:(LoginCompletionBlock)loginCompletion
{
    [self showLoginViewWithRestoreSession:NO animated:animated completion:completion loginCompletion:loginCompletion];
}

+ (void)showLoginViewForRestoreSessionWithCompletion:(LoginCompletionBlock)loginCompletion
{
    [self showLoginViewWithRestoreSession:YES animated:YES completion:nil loginCompletion:loginCompletion];
}

+ (void)showLoginViewWithRestoreSession:(BOOL)restoreSession animated:(BOOL)animated completion:(void (^)(void))completion loginCompletion:(LoginCompletionBlock)loginCompletion
{
    if (!restoreSession && self.restClient) {
        [[JMSessionManager sharedManager] logout];
    } else {
        [[JMSessionManager sharedManager] reset];
    }

    SWRevealViewController *revealViewController = (SWRevealViewController *) [UIApplication sharedApplication].delegate.window.rootViewController;
    JMMenuViewController *menuViewController = (JMMenuViewController *) revealViewController.rearViewController;

    UIViewController *presentedVC = revealViewController.presentedViewController;

    BOOL isPresentedByNavVC = [presentedVC isKindOfClass:[UINavigationController class]];
    if (isPresentedByNavVC) {
        // if a nav view controller was loaded previously
        UINavigationController *navController = (UINavigationController *) presentedVC;
        BOOL isLoginVC     = [navController.topViewController isKindOfClass:[JMLoginViewController class]];
        BOOL isServersVC   = [navController.topViewController isKindOfClass:[JMServersGridViewController class]];
        BOOL isNewServerVC = [navController.topViewController isKindOfClass:[JMServerOptionsViewController class]];
        if (isLoginVC || isServersVC || isNewServerVC) {
            return;
        }
    }

    [presentedVC dismissViewControllerAnimated:NO completion:nil];

    UINavigationController *loginNavController = [revealViewController.storyboard instantiateViewControllerWithIdentifier:@"JMLoginNavigationViewController"];
    JMLoginViewController *loginViewController = (JMLoginViewController *)loginNavController.topViewController;
    loginViewController.showForRestoreSession = restoreSession;
    loginViewController.completion = ^(void){
        [menuViewController reset];

        if (loginCompletion) {
            loginCompletion();
        }
    };

    [revealViewController presentViewController:loginNavController animated:animated completion:completion];
}

+ (NSString *)lastUserName
{
    NSString *lastUserName;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:JMLoginVCLastUserNameKey]) {
        lastUserName = [[NSUserDefaults standardUserDefaults] objectForKey:JMLoginVCLastUserNameKey];
    }
    return lastUserName;
}

+ (void)saveLastUserName:(NSString *)userName
{
    [[NSUserDefaults standardUserDefaults] setObject:userName
                                              forKey:JMLoginVCLastUserNameKey];
}

+ (JMServerProfile *)lastServerProfile
{
    JMServerProfile *lastServerProfile;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:JMLoginVCLastServerProfileAliasKey]) {
        NSString *lastServerProfileAliase = [[NSUserDefaults standardUserDefaults] objectForKey:JMLoginVCLastServerProfileAliasKey];
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ServerProfile"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"alias = %@", lastServerProfileAliase];
        NSArray *serverProfiles = [[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
        lastServerProfile = serverProfiles.firstObject;
    }
    return lastServerProfile;
}

+ (void)saveLastServerProfile:(JMServerProfile *)serverProfile
{
    [[NSUserDefaults standardUserDefaults] setObject:serverProfile.alias
                                              forKey:JMLoginVCLastServerProfileAliasKey];
}

#pragma mark - EULA
+ (void)askUserAgreementWithCompletion:(void(^ __nonnull)(BOOL isAgree))completion
{
    // get key
    BOOL isAccept = [self isUserAcceptAgreement];
    if (isAccept) {
        completion(YES);
    } else {
        // show text of agreement
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;

        JMEULAViewController *EULAViewController = (JMEULAViewController *) [rootViewController.storyboard instantiateViewControllerWithIdentifier:@"JMEULAViewController"];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:EULAViewController];
        EULAViewController.shouldUserAccept = YES;
        EULAViewController.completion = ^{
            [rootViewController dismissViewControllerAnimated:YES completion:nil];
            [self setUserAcceptAgreement:YES];
            completion(YES);
        };

        if (rootViewController.presentedViewController && [rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
            return;
        } else if (rootViewController.presentedViewController && ![rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
            [rootViewController dismissViewControllerAnimated:YES completion:nil];
        }

        [rootViewController presentViewController:navController
                                         animated:YES
                                       completion:nil];
    }
}

+ (BOOL)isUserAcceptAgreement
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kJMUserAcceptAgreement]) {
        [[NSUserDefaults standardUserDefaults] setObject:@(NO)
                                                  forKey:kJMUserAcceptAgreement];
    }

    BOOL isAccept = ((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:kJMUserAcceptAgreement]).boolValue;

    return isAccept;
}

+ (void)setUserAcceptAgreement:(BOOL)isAccept
{
    [[NSUserDefaults standardUserDefaults] setObject:@(isAccept)
                                              forKey:kJMUserAcceptAgreement];
}

#pragma mark - Alerts

+ (void)presentAlertControllerWithError:(NSError *)error completion:(void (^)(void))completion
{
    NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
    
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
    [array removeObject:@""];
    
    NSLog(@"Class caller = %@", [array objectAtIndex:3]);
    NSLog(@"Method caller = %@", [array objectAtIndex:4]);
    
    NSString *title = error.domain;
    NSString *message = error.localizedDescription;
//    if (![title isEqualToString:@"dialod.title.error"]) {
//        title = @"error.readingresponse.dialog.msg";
//    }
    if (error.code == JSInvalidCredentialsErrorCode) {
        title = @"error_authenication_dialog_title";
        message = @"error_authenication_dialog_msg";
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:title message:message cancelButtonTitle:@"dialog_button_ok" cancelCompletionHandler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }];

    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if (rootViewController.presentedViewController) {
        rootViewController = rootViewController.presentedViewController;
    }
    [rootViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Helpers

+ (BOOL)isSupportNewRESTFlow
{
    return [self isServerVersionUpOrEqual6];
}

+ (BOOL)isSupportVisualize
{
    return [self isServerVersionUpOrEqual6] && [self isServerProEdition];
}

+ (BOOL)isSupportSearchInSchedules
{
    return self.restClient.serverProfile.serverInfo.versionAsFloat >= kJS_SERVER_VERSION_CODE_JADE_6_2_0;
}

+ (BOOL)isServerVersionUpOrEqual6
{
    return self.restClient.serverProfile.serverInfo.versionAsFloat >= kJS_SERVER_VERSION_CODE_AMBER_6_0_0;
}

+ (BOOL)isServerAmber
{
    BOOL isAmberServer = NO;
    CGFloat versionNumber = self.restClient.serverProfile.serverInfo.versionAsFloat;
    if (versionNumber >= 6.0 && versionNumber < 6.1f) {
        isAmberServer = YES;
    }
    return isAmberServer;
}

+ (BOOL)isServerProEdition
{
    return [self.restClient.serverProfile.serverInfo.edition isEqualToString: kJS_SERVER_EDITION_PRO];
}

+ (NSString *)localizedStringFromDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    return [dateFormatter stringFromDate:date];
}

+ (NSDateFormatter *)formatterForSimpleDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    return dateFormatter;
}

+ (NSDateFormatter *)formatterForSimpleTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    return dateFormatter;
}

+ (NSDateFormatter *)formatterForSimpleDateTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    return dateFormatter;
}

+ (UIStoryboard *)mainStoryBoard
{
    static dispatch_once_t onceToken;
    static UIStoryboard * mainStoryboard;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *storyboardName = [bundle objectForInfoDictionaryKey:@"UIMainStoryboardFile"];
        mainStoryboard = [UIStoryboard storyboardWithName:storyboardName bundle:bundle];
    });
    return mainStoryboard;
}

+ (UIViewController *)launchScreenViewController
{
    static dispatch_once_t onceToken;
    static UIStoryboard * launchStoryboard;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *storyboardName = [bundle objectForInfoDictionaryKey:@"UILaunchStoryboardName"];
        launchStoryboard = [UIStoryboard storyboardWithName:storyboardName bundle:bundle];
    });
    return [launchStoryboard instantiateInitialViewController];
}

+ (BOOL)isCompactWidth
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return (rootViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
}

+ (BOOL)isCompactHeight
{
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return (rootViewController.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact);
}

+ (BOOL)isDemoAccount
{
    NSURL *demoURL = [NSURL URLWithString:kJMDemoServerUrl];
    NSURL *serverURL = [NSURL URLWithString:self.restClient.serverProfile.serverUrl];
    BOOL isDemoServer = [serverURL.host isEqualToString:demoURL.host];
    BOOL isDemoUser = [self.restClient.serverProfile.username isEqualToString:kJMDemoServerUsername];
    BOOL isDemoOrganization = [self.restClient.serverProfile.organization isEqualToString:kJMDemoServerOrganization];
    BOOL isDemoAccount = isDemoServer && isDemoUser && isDemoOrganization;
    return isDemoAccount;
}

+ (JMServerProfile * __nullable)activeServerProfile
{
    JMServerProfile *activeServerProfile = [JMServerProfile serverProfileForJSProfile:self.restClient.serverProfile];
    return activeServerProfile;
}

+ (float)minSupportedServerVersion
{
    return kJS_SERVER_VERSION_CODE_AMBER_6_0_0;
}

@end
