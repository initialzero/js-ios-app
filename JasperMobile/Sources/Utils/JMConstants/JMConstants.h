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
//  JMConstants.h
//  TIBCO JasperMobile
//

/**
 @author Vlad Zavadskii vzavadskii@jaspersoft.com
 @author Alexey Gubarev ogubarie@tibco.com
 @author Aleksandr Dakhno odahno@tibco.com
 
 @since 1.6
 */

// Application name with trademarks
extern NSString * const kJMAppName;

// Constants for NSUserDefaults
extern NSString * const kJMDefaultsCurrentVersion;
extern NSString * const kJMDefaultsIntroDidApear;

// Notifications
extern NSString * const kJMResetApplicationNotification;
extern NSString * const kJMFavoritesDidChangedNotification;
extern NSString * const kJMSavedResourcesDidChangedNotification;
extern NSString * const kJMExportedResourceDidLoadNotification;
extern NSString * const kJMExportedResourceDidCancelNotification;
extern NSString * const JMServerProfileDidChangeNotification;

// Shared keys for dictionary
extern NSString * const kJMTitleKey;
extern NSString * const kJMValueKey;
extern NSString * const kJMServerProfileKey;
extern NSString * const kJMResourceLookup;
extern NSString * const kJMInputControls;
extern NSString * const kJMLoadRecursively;
extern NSString * const kJMResourcesTypes;
extern NSString * const kJMSearchQuery;
extern NSString * const kJMSortBy;
extern NSString * const kJMFilterByTag;
extern NSString * const kJMReportKey;
extern NSString * const kJMDashboardKey;

// Settings keys
extern NSString * const kJMDefaultSendingCrashReport;
extern NSString * const kJMUserAcceptAgreement;
extern NSString * const kJMDefaultSendingAutoFillLoginData;

// Demo server parameters
extern NSString * const kJMDemoServerAlias;
extern NSString * const kJMDemoServerUrl;
extern NSString * const kJMDemoServerOrganization;
extern NSString * const kJMDemoServerUsername;
extern NSString * const kJMDemoServerPassword;

// Emails for feedbacks
extern NSString * const kFeedbackPrimaryEmail;
extern NSString * const kFeedbackSecondaryEmail;

// Resource directory
extern NSString * const kJMReportsDirectory;
extern NSString * const kJMDashboardsDirectory;

// Saved Items ws types
extern NSString * const kJMSavedReportUnit;
extern NSString * const kJMSavedDashboard;
extern NSString * const kJMTempExportedReportUnit;
extern NSString * const kJMTempExportedDashboard;

// Schedules Items
extern NSString * const kJMScheduleUnit;

// Name of the main report file (outputResource)
extern NSString * const kJMReportFilename;

// Name of the thumbnail image file for saved reports
extern NSString * const kJMThumbnailImageFileName;

// Error domain for report loader
extern NSString * const kJMReportLoaderErrorDomain;


// Privacy Policy Link
extern NSString * const kJMPrivacyPolicyURI;

// Limit of pages for saving report to HTML format
NSInteger  const kJMSaveReportMaxRangePages;

// Limit of resource for loading from JRS
NSInteger  const kJMResourceLimit;
NSInteger  const kJMRecentResourcesLimit;

// Name of the default theme file
extern NSString * const kJMDefaultThemeFileName;
extern NSString * const kJMThemesFileFormat;
extern NSString * const kJMCurrentThemeFileName;

// Analytics - Common
extern NSString * const kJMAnalyticsServerVersionKey;
extern NSString * const kJMAnalyticsServerEditionKey;
extern NSString * const kJMAnalyticsCategoryKey;
extern NSString * const kJMAnalyticsActionKey;
extern NSString * const kJMAnalyticsLabelKey;

// Analytics - Authentication
extern NSString * const kJMAnalyticsAuthenticationEventCategoryTitle;
extern NSString * const kJMAnalyticsAuthenticationEventActionLoginTitle;
extern NSString * const kJMAnalyticsAuthenticationEventLabelSuccess;
extern NSString * const kJMAnalyticsAuthenticationEventLabelFailure;

// Analytics - Categories
extern NSString * const kJMAnalyticsEventCategoryResource;
extern NSString * const kJMAnalyticsEventCategoryOther;
// Analytics - Resource Actions
extern NSString * const kJMAnalyticsEventActionOpen;
extern NSString * const kJMAnalyticsEventActionPrint;
extern NSString * const kJMAnalyticsEventActionExport;
extern NSString * const kJMAnalyticsEventActionViewed;
// Analytics - Resources Titles
extern NSString * const kJMAnalyticsResourceLabelReportREST;
extern NSString * const kJMAnalyticsResourceLabelReportVisualize;
extern NSString * const kJMAnalyticsResourceLabelDashboardFlow;
extern NSString * const kJMAnalyticsResourceLabelDashboardVisualize;
extern NSString * const kJMAnalyticsResourceLabelSavedResource;
extern NSString * const kJMAnalyticsLabelThumbnail;

// Analytics - Repository
extern NSString * const kJMAnalyticsRepositoryEventCategoryTitle;
extern NSString * const kJMAnalyticsRepositoryEventActionOpen;

// Custom Dimensions
extern NSUInteger  const kJMAnalyticsCustomDimensionServerVersionIndex;
extern NSUInteger  const kJMAnalyticsCustomDimensionServerEditionIndex;

// Login VC
extern NSString *const JMLoginVCLastUserNameKey;
extern NSString *const JMLoginVCLastServerProfileAliasKey;