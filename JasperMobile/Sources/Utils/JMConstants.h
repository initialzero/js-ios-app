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
//  JMConstants.h
//  TIBCO JasperMobile
//
//  Created by Vlad Zavadskii vzavadskii@jaspersoft.com
//  Since 1.6
//

#import <Foundation/Foundation.h>
#import "UIColor+RGBComponent.h"

// Constants for NSUserDefaults
extern NSString * const kJMDefaultsActiveServer;
extern NSString * const kJMDefaultsCurrentVersion;
extern NSString * const kJMDefaultsFavorites;
extern NSString * const kJMDefaultsServerAlias;
extern NSString * const kJMDefaultsServerAlwaysAskPassword;
extern NSString * const kJMDefaultsServerBaseUrl;
extern NSString * const kJMDefaultsServerOrganization;
extern NSString * const kJMDefaultsServerPassword;
extern NSString * const kJMDefaultsServerUsername;


// Notifications
extern NSString * const kJMChangeServerProfileNotification;
extern NSString * const kJMResetApplicationNotification;
extern NSString * const kJMFavoritesDidChangedNotification;
extern NSString * const kJMSavedResourcesDidChangedNotification;

// Shared keys for dictionary
extern NSString * const kJMServerProfileKey;
extern NSString * const kJMResourceLookup;
extern NSString * const kJMInputControls;
extern NSString * const kJMLoadRecursively;
extern NSString * const kJMResourcesTypes;
extern NSString * const kJMSearchQuery;
extern NSString * const kJMSortBy;
extern NSString * const kJMFilterByTag;

// Settings keys
extern NSString * const kJMDefaultRequestTimeout;
extern NSString * const kJMReportRequestTimeout;
extern NSString * const kJMDefaultSendingCrashReport;

// Report directory
extern NSString * const kJMReportsDirectory;

// Name of the main report file (outputResource)
extern NSString * const kJMReportFilename;

// Mint Splunk (Bug Sence) API KEY
extern NSString * const kJMMintSplunkApiKey;


enum {kJMCountOfPagesUnknown = NSIntegerMax};


#define kJMResourceLimit                                15
#define kJMMasterViewWidth                              [JMUtils isIphone] ? 210.f : 240.f
#define kJMMasterViewAnimationDuration                  0.2f

#define kJMDetailViewLightBackgroundColor               [UIColor colorFromHexString:@"#E5E9EB"]
#define kJMDetailViewLightTextColor                     [UIColor colorFromHexString:@"#8F8F8F"]
#define kJMSearchBarBackgroundColor                     [UIColor colorFromHexString:@"#26282D"]

#define kJMMainNavigationBarBackgroundColor             [UIColor colorFromHexString:@"#343841"]
#define kJMMainCollectionViewBackgroundColor            [UIColor colorWithPatternImage:[UIImage imageNamed:@"list_background_pattern"]]

#define kJMResourcePreviewBackgroundColor               [UIColor colorFromHexString:@"#428EC0"]

#define kJMMasterResourceCellDefaultBackgroundColor     [UIColor colorFromHexString:@"#2E3138"]
#define kJMMasterResourceCellSelectedBackgroundColor    [UIColor colorFromHexString:@"#484F59"]
