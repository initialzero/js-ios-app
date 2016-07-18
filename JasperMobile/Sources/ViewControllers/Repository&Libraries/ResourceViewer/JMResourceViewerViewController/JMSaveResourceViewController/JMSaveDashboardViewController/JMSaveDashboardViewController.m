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
//  JMSaveDashboardViewController.m
//  TIBCO JasperMobile
//

#import "JMSaveDashboardViewController.h"
#import "JMDashboardExportTask.h"
#import "JMExportManager.h"


@implementation JMSaveDashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [JMCustomLocalizedString(@"resource_viewer_save_title", nil) capitalizedString];
    self.resourceName = self.dashboard.resourceLookup.label;
}

- (JMResourceType)resourceType
{
    return [JMResource typeForResourceLookupType:self.dashboard.resourceLookup.resourceType];
}


-(NSArray *)availableFormats
{
    return [JMUtils supportedFormatsForDashboardSaving];
}

- (void) saveResource
{
    JMDashboardExportTask *task = [[JMDashboardExportTask alloc] initWithDashboard:self.dashboard name:self.resourceName format:self.selectedFormat];
    [[JMExportManager sharedInstance] addExportTask:task];
    
    [super saveResource];
}

@end
