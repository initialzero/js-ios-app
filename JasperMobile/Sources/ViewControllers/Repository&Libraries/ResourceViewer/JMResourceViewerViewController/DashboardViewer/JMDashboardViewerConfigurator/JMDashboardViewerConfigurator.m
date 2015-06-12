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
//  JMDashboardViewerConfigurator.h
//  TIBCO JasperMobile
//

#import "JMDashboardViewerConfigurator.h"
#import "JMDashboardLoader.h"
#import "JMBaseDashboardLoader.h"
#import "JMJavascriptNativeBridge.h"
#import "JMVisDashboardLoader.h"

@interface JMDashboardViewerConfigurator()
@property (nonatomic, weak) JMDashboard *dashboard;
@property (nonatomic, weak) id webView;
@property (nonatomic, strong) id<JMDashboardLoader> dashboardLoader;
@end

@implementation JMDashboardViewerConfigurator

#pragma mark - Initializers
- (instancetype)initWithDashboard:(JMDashboard *)dashboard
{
    self = [super init];
    if (self) {
        _dashboard = dashboard;
    }
    return self;
}

+ (instancetype)configuratorWithDashboard:(JMDashboard *)dashboard {
    return [[self alloc] initWithDashboard:dashboard];
}

#pragma mark - Public API
- (id)webViewWithFrame:(CGRect)frame asSecondary:(BOOL)asSecondary
{
    if (!_webView) {
        _webView = [[JMVisualizeWebViewManager sharedInstance] webViewWithParentFrame:frame asSecondary:asSecondary];
    }
    return _webView;
}

- (id <JMDashboardLoader>)dashboardLoader {
    if (!_dashboardLoader) {
        if ([JMUtils isServerAmber2]) {
            _dashboardLoader = [JMVisDashboardLoader loaderWithDashboard:self.dashboard];
        } else {
            _dashboardLoader = [JMBaseDashboardLoader loaderWithDashboard:self.dashboard];
        }
        JMJavascriptNativeBridge *bridge = [JMJavascriptNativeBridge new];
        _dashboardLoader.bridge = bridge;
        bridge.webView = self.webView;
    }
    return _dashboardLoader;
}


- (void)updateReportLoaderDelegateWithObject:(id <JMDashboardLoaderDelegate>)delegate
{
    [self dashboardLoader].delegate = delegate;
}

@end