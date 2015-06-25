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
//  JMDashboardLoader.h
//  TIBCO JasperMobile
//

/**
@author Aleksandr Dakhno odahno@tibco.com
@since 2.1
*/

@protocol JMJavascriptNativeBridgeProtocol;
@protocol JMDashboardLoaderDelegate;
@class JMDashboard;

typedef NS_ENUM(NSInteger, JMDashboardLoaderErrorType) {
    JMDashboardLoaderErrorTypeUndefined,
    JMDashboardLoaderErrorTypeEmtpyReport,
    JMDashboardLoaderErrorTypeAuthentification
};

typedef NS_ENUM(NSInteger, JMHyperlinkType) {
    JMHyperlinkTypeLocalPage,
    JMHyperlinkTypeLocalAnchor,
    JMHyperlinkTypeRemotePage,
    JMHyperlinkTypeRemoteAnchor,
    JMHyperlinkTypeReference,
    JMHyperlinkTypeReportExecution,
    JMHyperlinkTypeAdHocExecution
};

@protocol JMDashboardLoader <NSObject>
@property (nonatomic, strong) id<JMJavascriptNativeBridgeProtocol>bridge;
@property (nonatomic, weak) id<JMDashboardLoaderDelegate> delegate;

- (instancetype)initWithDashboard:(JMDashboard *)dashboard;
+ (instancetype)loaderWithDashboard:(JMDashboard *)dashboard;

- (void)loadDashboardWithCompletion:(void(^)(BOOL success, NSError *error))completion;
- (void)reloadDashboardWithCompletion:(void(^)(BOOL success, NSError *error))completion;
- (void)reset;
- (void)minimizeDashlet;
@end


@protocol JMDashboardLoaderDelegate <NSObject>
- (void)dashboardLoader:(id<JMDashboardLoader>)loader didStartMaximazeDashletWithTitle:(NSString *)title;
- (void)dashboardLoader:(id<JMDashboardLoader>)loader didReceiveHyperlinkWithType:(JMHyperlinkType)hyperlinkType
         resourceLookup:(JSResourceLookup *)resourceLookup
             parameters:(NSArray *)parameters;
- (void)dashboardLoaderDidReceiveAuthRequest:(id<JMDashboardLoader>)loader;
@end