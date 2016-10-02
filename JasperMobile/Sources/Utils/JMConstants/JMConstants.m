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
//  JMConstants.m
//  TIBCO JasperMobile
//

#import "JMConstants.h"

NSString * const kJMAppName = @"TIBCO\u00AE JasperMobile\u2122";

// Constants for NSUserDefaults
NSString * const kJMDefaultsCurrentVersion = @"jaspersoft.mobile.current.version";
NSString * const kJMDefaultsIntroDidApear = @"JMDefaultsIntroDidApear";

// Notifications
NSString * const kJMResetApplicationNotification = @"resetApplication";
NSString * const kJMFavoritesDidChangedNotification = @"JMFavoritesDidChangedNotification";
NSString * const kJMSavedResourcesDidChangedNotification = @"JMSavedResourcesDidChangedNotification";
NSString * const kJMExportedResourceDidLoadNotification = @"kJMExportedResourceDidLoadNotification";
NSString * const kJMExportedResourceDidCancelNotification = @"kJMExportedResourceDidCancelNotification";
NSString * const JMServerProfileDidChangeNotification = @"JMServerProfileDidChangeNotification";

// Shared keys for NSDictionary
NSString * const kJMTitleKey = @"title";
NSString * const kJMValueKey = @"value";
NSString * const kJMAccessibilityIDKey = @"value";
NSString * const kJMServerProfileKey = @"serverProfile";
NSString * const kJMResourceLookup = @"resourceLookup";
NSString * const kJMInputControls = @"inputControls";
NSString * const kJMLoadRecursively = @"loadRecursively";
NSString * const kJMResourcesTypes = @"resourcesTypes";
NSString * const kJMSearchQuery = @"searchQuery";
NSString * const kJMSortBy = @"sortBy";
NSString * const kJMFilterByTag = @"filterByTag";
NSString * const kJMReportKey = @"reportKey";
NSString * const kJMDashboardKey = @"dashboardKey";

// Settings keys
NSString * const kJMDefaultSendingCrashReport = @"jaspersoft.crashreportsending.enabled";
NSString * const kJMUserAcceptAgreement = @"kJMUserAcceptAgreement";
NSString * const kJMDefaultSendingAutoFillLoginData = @"jaspersoft.autofill.login.data.enabled";

// Demo server parameters
NSString * const kJMDemoServerAlias = @"Jaspersoft Mobile Demo";
NSString * const kJMDemoServerUrl = @"https://mobiledemo.jaspersoft.com/jasperserver-pro";
NSString * const kJMDemoServerOrganization = @"organization_1";
NSString * const kJMDemoServerUsername = @"phoneuser";
NSString * const kJMDemoServerPassword = @"phoneuser";


// Emails for feedbacks
NSString * const kFeedbackPrimaryEmail = @"js-dev-mobile@tibco.com";
NSString * const kFeedbackSecondaryEmail = @"js.testdevice@gmail.com";


// Directory to store downloaded reports
NSString * const kJMReportsDirectory = @"reports";

// Saved Items ws types
NSString * const kJMSavedReportUnit = @"savedReportUnit";
NSString * const kJMTempExportedReportUnit = @"kJMTempExportedReportUnit";

// Schedules Items
NSString * const kJMScheduleUnit = @"kJMScheduleUnit";

// Name of the main report file (outputResource)
NSString * const kJMReportFilename = @"report";

// Name of the thumbnail image file for saved reports
NSString * const kJMThumbnailImageFileName = @"_jaspersoftMobileThumbnailImageFile";

// Error domain for report loader
NSString * const kJMReportLoaderErrorDomain = @"JMReportLoaderErrorDomain";

// Privacy Policy Link
NSString * const kJMPrivacyPolicyURI = @"http://www.tibco.com/company/privacy-cma";

// Limit of pages for saving report to HTML format
NSInteger  const kJMSaveReportMaxRangePages = 500;

// Limit of resource for loading from JRS
NSInteger  const kJMResourceLimit = 100;
NSInteger  const kJMRecentResourcesLimit = 10;


// Name of the default theme file
NSString * const kJMDefaultThemeFileName = @"DefaultTheme";
NSString * const kJMThemesFileFormat= @"plist";
NSString * const kJMCurrentThemeFileName = @"CurrentTheme";

// Analytics - Common
NSString * const kJMAnalyticsServerVersionKey = @"kJMAnalyticsServerVersionKey";
NSString * const kJMAnalyticsServerEditionKey = @"kJMAnalyticsServerEditionKey";
NSString * const kJMAnalyticsCategoryKey      = @"kJMAnalyticsCategoryKey";
NSString * const kJMAnalyticsActionKey        = @"kJMAnalyticsActionKey";
NSString * const kJMAnalyticsLabelKey         = @"kJMAnalyticsLabelKey";

// Analytics - Authentication
NSString * const kJMAnalyticsAuthenticationEventCategoryTitle     = @"Authentication";
NSString * const kJMAnalyticsAuthenticationEventActionLoginTitle  = @"Login";
NSString * const kJMAnalyticsAuthenticationEventLabelSuccess      = @"Success";
NSString * const kJMAnalyticsAuthenticationEventLabelFailure      = @"Failure";

// Analytics - Resource
NSString * const kJMAnalyticsEventCategoryResource           = @"Resource";
NSString * const kJMAnalyticsEventCategoryOther              = @"Other";

NSString * const kJMAnalyticsEventActionOpen         = @"Open";
NSString * const kJMAnalyticsEventActionPrint        = @"Print";
NSString * const kJMAnalyticsEventActionExport       = @"Export";
NSString * const kJMAnalyticsEventActionViewed       = @"Viewed";

NSString * const kJMAnalyticsResourceLabelReportREST         = @"Report (REST)";
NSString * const kJMAnalyticsResourceLabelReportVisualize    = @"Report (Visualize)";
NSString * const kJMAnalyticsResourceLabelDashboardFlow      = @"Dashboard (Flow)";
NSString * const kJMAnalyticsResourceLabelDashboardVisualize = @"Dashboard (Visualize)";
NSString * const kJMAnalyticsResourceLabelSavedResource      = @"Saved Resource";
NSString * const kJMAnalyticsLabelThumbnail          = @"Thumbnail";

// Analytics - Repository
NSString * const kJMAnalyticsRepositoryEventCategoryTitle     = @"Repository";
NSString * const kJMAnalyticsRepositoryEventActionOpen        = @"Open";
NSUInteger  const kJMAnalyticsCustomDimensionServerVersionIndex = 1;
NSUInteger  const kJMAnalyticsCustomDimensionServerEditionIndex = 2;

// Login VC
NSString *const JMLoginVCLastUserNameKey           = @"JMLoginVCLastUserNameKey";
NSString *const JMLoginVCLastServerProfileAliasKey = @"JMLoginVCLastServerProfileAliasKey";

// Accessibility Identifiers
NSString *const JMBackButtonAccessibilityId = @"JMBackButtonAccessibilityId";
NSString *const JMCancelRequestPopupAccessibilityId = @"JMCancelRequestPopupAccessibilityId";
NSString *const JMMenuActionsViewActionButtonAccessibilityId = @"JMMenuActionsViewActionButtonAccessibilityId";
NSString *const JMMenuActionsViewAccessibilityId = @"JMMenuActionsViewAccessibilityId";
NSString *const JMMenuActionsViewFilterActionAccessibilityId = @"JMMenuActionsViewFilterActionAccessibilityId";
NSString *const JMMenuActionsViewSortActionAccessibilityId = @"JMMenuActionsViewSortActionAccessibilityId";
NSString *const JMMenuActionsViewMarkAsFavoriteActionAccessibilityId = @"JMMenuActionsViewMarkAsFavoriteActionAccessibilityId";
NSString *const JMMenuActionsViewMarkAsUnFavoriteActionAccessibilityId = @"JMMenuActionsViewMarkAsUnFavoriteActionAccessibilityId";

NSString *const JMMenuActionsViewRefreshActionAccessibilityId = @"JMMenuActionsViewRefreshActionAccessibilityId";
NSString *const JMMenuActionsViewSaveActionAccessibilityId = @"JMMenuActionsViewSaveActionAccessibilityId";
NSString *const JMMenuActionsViewEditActionAccessibilityId = @"JMMenuActionsViewEditActionAccessibilityId";
NSString *const JMMenuActionsViewEditFiltersActionAccessibilityId = @"JMMenuActionsViewEditFiltersActionAccessibilityId";
NSString *const JMMenuActionsViewDeleteActionAccessibilityId = @"JMMenuActionsViewDeleteActionAccessibilityId";
NSString *const JMMenuActionsViewRenameActionAccessibilityId = @"JMMenuActionsViewRenameActionAccessibilityId";
NSString *const JMMenuActionsViewInfoActionAccessibilityId = @"JMMenuActionsViewInfoActionAccessibilityId";
NSString *const JMMenuActionsViewSelectAllActionAccessibilityId = @"JMMenuActionsViewSelectAllActionAccessibilityId";
NSString *const JMMenuActionsViewClearSelectionActionAccessibilityId = @"JMMenuActionsViewClearSelectionActionAccessibilityId";
NSString *const JMMenuActionsViewRunActionAccessibilityId = @"JMMenuActionsViewRunActionAccessibilityId";
NSString *const JMMenuActionsViewPrintActionAccessibilityId = @"JMMenuActionsViewPrintActionAccessibilityId";
NSString *const JMMenuActionsViewOpenInActionAccessibilityId = @"JMMenuActionsViewOpenInActionAccessibilityId";
NSString *const JMMenuActionsViewAcceptActionAccessibilityId = @"JMMenuActionsViewAcceptActionAccessibilityId";
NSString *const JMMenuActionsViewScheduleActionAccessibilityId = @"JMMenuActionsViewScheduleActionAccessibilityId";
NSString *const JMMenuActionsViewShareActionAccessibilityId = @"JMMenuActionsViewShareActionAccessibilityId";
NSString *const JMMenuActionsViewBookmarksActionAccessibilityId = @"JMMenuActionsViewBookmarksActionAccessibilityId";
NSString *const JMMenuActionsViewChartTypesActionAccessibilityId = @"JMMenuActionsViewChartTypesActionAccessibilityId";
NSString *const JMMenuActionsViewShowExternalDisplayActionAccessibilityId = @"JMMenuActionsViewShowExternalDisplayActionAccessibilityId";
NSString *const JMMenuActionsViewHideExternalDisplayActionAccessibilityId = @"JMMenuActionsViewHideExternalDisplayActionAccessibilityId";


NSString *const JMOnboardIntroPageAccessibilityID = @"JMOnboardIntroPageAccessibilityID";
NSString *const JMOnboardIntroPageTitleAccessibilityID = @"JMOnboardIntroPageTitleAccessibilityID";
NSString *const JMOnboardIntroPageDescriptionAccessibilityID = @"JMOnboardIntroPageDescriptionAccessibilityID";
NSString *const JMOnboardIntroPageSkipIntroButtonAccessibilityID = @"JMOnboardIntroPageSkipIntroButtonAccessibilityID";

NSString *const JMServerProfilesPageAccessibilityId = @"JMServerProfilesPageAccessibilityId";
NSString *const JMServerProfilesPageAddNewProfileButtonAccessibilityId = @"JMServerProfilesPageAddNewProfileButtonAccessibilityId";
NSString *const JMServerProfilesPageServerCellAccessibilityId = @"JMServerProfilesPageServerCellAccessibilityId";
NSString *const JMServerProfilesPageListEmptyAccessibilityId = @"JMServerProfilesPageListEmptyAccessibilityId";
NSString *const JMServerProfilesPageEditProfileAccessibilityId = @"JMServerProfilesPageEditProfileAccessibilityId";
NSString *const JMServerProfilesPageDeleteProfileAccessibilityId = @"JMServerProfilesPageDeleteProfileAccessibilityId";
NSString *const JMServerProfilesPageCloneProfileAccessibilityId = @"JMServerProfilesPageCloneProfileAccessibilityId";


NSString *const JMLoginPageAccessibilityId = @"JMLoginPageAccessibilityId";
NSString *const JMLoginPageUserNameTextFieldAccessibilityId = @"JMLoginPageUserNameTextFieldAccessibilityId";
NSString *const JMLoginPagePasswordTextFieldAccessibilityId = @"JMLoginPagePasswordTextFieldAccessibilityId";
NSString *const JMLoginPageServerProfileTextFieldAccessibilityId = @"JMLoginPageServerProfileTextFieldAccessibilityId";
NSString *const JMLoginPageTryButtonAccessibilityId = @"JMLoginPageTryButtonAccessibilityId";
NSString *const JMLoginPageLoginButtonAccessibilityId = @"JMLoginPageLoginButtonAccessibilityId";

NSString *const JMNewServerProfilePageAccessibilityId = @"JMNewServerProfilePageAccessibilityId";
NSString *const JMNewServerProfilePageSaveAccessibilityId = @"JMNewServerProfilePageSaveAccessibilityId";
NSString *const JMNewServerProfilePageNameAccessibilityId = @"JMNewServerProfilePageNameAccessibilityId";
NSString *const JMNewServerProfilePageServerURLAccessibilityId = @"JMNewServerProfilePageServerURLAccessibilityId";
NSString *const JMNewServerProfilePageOrganizationAccessibilityId = @"JMNewServerProfilePageOrganizationAccessibilityId";
NSString *const JMNewServerProfilePageAskPasswordAccessibilityId = @"JMNewServerProfilePageAskPasswordAccessibilityId";
NSString *const JMNewServerProfilePageKeepSessionAccessibilityId = @"JMNewServerProfilePageKeepSessionAccessibilityId";
NSString *const JMNewServerProfilePageUseVisualizeAccessibilityId = @"JMNewServerProfilePageUseVisualizeAccessibilityId";
NSString *const JMNewServerProfilePageUseCacheReportAccessibilityId = @"JMNewServerProfilePageUseCacheReportAccessibilityId";

NSString *const JMSideApplicationMenuAccessibilityId = @"JMSideApplicationMenuAccessibilityId";
NSString *const JMSideApplicationMenuVersionLabelAccessibilityId = @"JMSideApplicationMenuVersionLabelAccessibilityId";
NSString *const JMSideApplicationMenuMenuButtonAccessibilityId = @"JMSideApplicationMenuMenuButtonAccessibilityId";

NSString *const JMLibraryPageAccessibilityId = @"JMLibraryPageAccessibilityId";
NSString *const JMRepositoryPageAccessibilityId = @"JMRepositoryPageAccessibilityId";
NSString *const JMFavoritesPageAccessibilityId = @"JMFavoritesPageAccessibilityId";
NSString *const JMSavedItemsPageAccessibilityId = @"JMSavedItemsPageAccessibilityId";
NSString *const JMSchedulesPageAccessibilityId = @"JMSchedulesPageAccessibilityId";
NSString *const JMAppAboutPageAccessibilityId = @"JMAppAboutPageAccessibilityId";
NSString *const JMSettingsPageAccessibilityId = @"JMSettingsPageAccessibilityId";
NSString *const JMFeedbackPageAccessibilityID = @"JMFeedbackPageAccessibilityID";
NSString *const JMLogoutAccessibilityID = @"JMLogoutAccessibilityID";

NSString *const JMResourceCollectionPageSearchBarAccessibilityID = @"JMResourceCollectionPageSearchBarAccessibilityID";
NSString *const JMResourceCollectionPageActivityLabelAccessibilityID = @"JMResourceCollectionPageActivityLabelAccessibilityID";
NSString *const JMResourceCollectionPageNoResultLabelAccessibilityID = @"JMResourceCollectionPageNoResultLabelAccessibilityID";
NSString *const JMResourceCollectionPageSortByPopupViewAccessibilityID = @"JMResourceCollectionPageSortByPopupViewAccessibilityID";
NSString *const JMResourceCollectionPageFilterByPopupViewAccessibilityID = @"JMResourceCollectionPageFilterByPopupViewAccessibilityID";
NSString *const JMResourceCollectionPageRepresentationButtonViewAccessibilityID = @"JMResourceCollectionPageRepresentationButtonViewAccessibilityID";
NSString *const JMResourceCollectionPageListCellAccessibilityId = @"JMResourceCollectionPageListCellAccessibilityId";
NSString *const JMResourceCollectionPageGridCellAccessibilityId = @"JMResourceCollectionPageGridCellAccessibilityId";
NSString *const JMResourceCellResourceNameLabelAccessibilityId = @"JMResourceCellResourceNameLabelAccessibilityId";
NSString *const JMResourceCellResourceInfoButtonAccessibilityId = @"JMResourceCellResourceInfoButtonAccessibilityId";

NSString *const JMResourceLoaderSortByNameAccessibilityID = @"JMResourceLoaderSortByNameAccessibilityID";
NSString *const JMResourceLoaderSortByCreationDateAccessibilityID = @"JMResourceLoaderSortByCreationDateAccessibilityID";
NSString *const JMResourceLoaderSortByModifiedDateAccessibilityID = @"JMResourceLoaderSortByModifiedDateAccessibilityID";
NSString *const JMResourceLoaderSortByAccessTimeAccessibilityID = @"JMResourceLoaderSortByAccessTimeAccessibilityID";
NSString *const JMResourceLoaderFilterByAllAccessibilityID = @"JMResourceLoaderFilterByAllAccessibilityID";
NSString *const JMResourceLoaderFilterByReportUnitAccessibilityID = @"JMResourceLoaderFilterByReportUnitAccessibilityID";
NSString *const JMResourceLoaderFilterByDashboardAccessibilityID = @"JMResourceLoaderFilterByDashboardAccessibilityID";
NSString *const JMResourceLoaderFilterByFolderAccessibilityID = @"JMResourceLoaderFilterByFolderAccessibilityID";
NSString *const JMResourceLoaderFilterByFileAccessibilityID = @"JMResourceLoaderFilterByFileAccessibilityID";
NSString *const JMResourceLoaderFilterBySavedItemAccessibilityID = @"JMResourceLoaderFilterBySavedItemAccessibilityID";
NSString *const JMResourceLoaderFilterByHTMLAccessibilityID = @"JMResourceLoaderFilterByHTMLAccessibilityID";
NSString *const JMResourceLoaderFilterByPDFAccessibilityID = @"JMResourceLoaderFilterByPDFAccessibilityID";
NSString *const JMResourceLoaderFilterByXLSAccessibilityID = @"JMResourceLoaderFilterByXLSAccessibilityID";

// Info Pages Accessibility IDs
NSString *const JMResourceInfoPageAccessibilityID = @"JMResourceInfoPageAccessibilityID";
NSString *const JMRepositoryInfoPageAccessibilityID = @"JMRepositoryInfoPageAccessibilityID";
NSString *const JMSavedItemsInfoPageAccessibilityID = @"JMSavedItemsInfoPageAccessibilityID";
NSString *const JMReportInfoPageAccessibilityID = @"JMReportInfoPageAccessibilityID";
NSString *const JMDashboardInfoPageAccessibilityID = @"JMDashboardInfoPageAccessibilityID";
NSString *const JMScheduleInfoPageAccessibilityID = @"JMScheduleInfoPageAccessibilityID";
NSString *const JMResourceInfoPageCancelButtonAccessibilityID = @"JMResourceInfoPageCancelButtonAccessibilityID";

NSString *const JMResourceInfoPageTitleLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageDescriptionLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageTypeLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageUriLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageVersionLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageCreationDateLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageModifiedDateLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageFormatLabelAccessibilityID = @"JMResourceInfoPageTitleLabelAccessibilityID";
NSString *const JMResourceInfoPageScheduleOwnerLabelAccessibilityID = @"JMResourceInfoPageScheduleOwnerLabelAccessibilityID";
NSString *const JMResourceInfoPageScheduleStateLabelAccessibilityID = @"JMResourceInfoPageScheduleStateLabelAccessibilityID";
NSString *const JMResourceInfoPageSchedulePreviousFireTimeLabelAccessibilityID = @"JMResourceInfoPageSchedulePreviousFireTimeLabelAccessibilityID";


/*

NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";
NSString *const  = @"";



*/
