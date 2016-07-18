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
//  JMDashboardViewerConfigurator.h
//  TIBCO JasperMobile
//

#import "JMDashboardViewerConfigurator.h"
#import "JMDashboardLoader.h"
#import "JMBaseDashboardLoader.h"
#import "JMVisDashboardLoader.h"
#import "JMWebViewManager.h"
#import "JMVisualizeManager.h"
#import "JMDashboard.h"
#import "JMWebEnvironment.h"
#import "JMResource.h"

@interface JMDashboardViewerConfigurator()
@property (nonatomic, weak) JMDashboard *dashboard;
@end

@implementation JMDashboardViewerConfigurator

- (void)dealloc
{
    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

#pragma mark - Initializers
- (instancetype)initWithDashboard:(JMDashboard *)dashboard webEnvironment:(JMWebEnvironment *)webEnvironment
{
    self = [super init];
    if (self) {
        _dashboard = dashboard;
        if ([JMUtils isSupportVisualize] && [JMResource typeForResourceLookupType:self.dashboard.resourceLookup.resourceType] == JMResourceTypeDashboard) {
            _dashboardLoader = [JMVisDashboardLoader loaderWithDashboard:self.dashboard
                                                          webEnvironment:webEnvironment];
            ((JMVisDashboardLoader *)_dashboardLoader).visualizeManager.viewportScaleFactor = self.viewportScaleFactor;
        } else {
            _dashboardLoader = [JMBaseDashboardLoader loaderWithDashboard:self.dashboard
                                                           webEnvironment:webEnvironment];
        }
    }
    return self;
}

+ (instancetype)configuratorWithDashboard:(JMDashboard *)dashboard webEnvironment:(JMWebEnvironment *)webEnvironment
{
    return [[self alloc] initWithDashboard:dashboard webEnvironment:webEnvironment];
}

#pragma mark - Public API
- (void)updateReportLoaderDelegateWithObject:(id <JMDashboardLoaderDelegate>)delegate
{
    [self dashboardLoader].delegate = delegate;
}

@end