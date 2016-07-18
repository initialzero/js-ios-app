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
//  JMResource.h
//  TIBCO JasperMobile
//

#import "JMResource.h"
#import "JMReport.h"
#import "JMDashboard.h"
#import "JMVisualizeDashboard.h"


@implementation JMResource


#pragma mark - Initializers
- (instancetype __nullable)initWithResourceLookup:(JSResourceLookup *__nonnull)resourceLookup
{
    self = [super init];
    if (self) {
        _resourceLookup = [resourceLookup copy];
        _type = [[self class] typeForResourceLookupType:resourceLookup.resourceType];
    }
    return self;
}

+ (instancetype __nullable)resourceWithResourceLookup:(JSResourceLookup *__nonnull)resourceLookup
{
    return [[self alloc] initWithResourceLookup:resourceLookup];
}

#pragma mark - Public API

- (id)modelOfResource
{
    id model;
    switch (self.type) {
        case JMResourceTypeUnknown: {break;}
        case JMResourceTypeFile: {break;}
        case JMResourceTypeFolder: {break;}
        case JMResourceTypeSavedReport: {break;}
        case JMResourceTypeSavedDashboard: {break;}
        case JMResourceTypeReport: {
            model = [JMReport reportWithResourceLookup:self.resourceLookup];
            break;
        }
        case JMResourceTypeTempExportedReport: {break;}
        case JMResourceTypeTempExportedDashboard: {break;}
        case JMResourceTypeDashboard: {
            if ([JMUtils isSupportVisualize]) {
                model = [JMVisualizeDashboard dashboardWithResourceLookup:self.resourceLookup];
            } else {
                model = [JMDashboard dashboardWithResourceLookup:self.resourceLookup];
            }
            break;
        }
        case JMResourceTypeLegacyDashboard: {
            model = [JMDashboard dashboardWithResourceLookup:self.resourceLookup];
            break;
        }
        case JMResourceTypeSchedule: {break;}
    }
    return model;
}

- (NSString *)localizedResourceType
{
    NSString *localizedResourceType;
    switch (self.type) {
        case JMResourceTypeUnknown: {
            localizedResourceType = @"unknown resource";
            break;
        }
        case JMResourceTypeFile: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_saved_reportUnit", nil);
            break;
        }
        case JMResourceTypeFolder: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_folder", nil);
            break;
        }
        case JMResourceTypeSavedReport: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_saved_reportUnit", nil);
            break;
        }
        case JMResourceTypeSavedDashboard: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_saved_reportUnit", nil);
            break;
        }
        case JMResourceTypeReport: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_reportUnit", nil);
            break;
        }
        case JMResourceTypeTempExportedReport: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_saved_reportUnit", nil);
            break;
        }
        case JMResourceTypeTempExportedDashboard: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_saved_reportUnit", nil);
            break;
        }
        case JMResourceTypeDashboard: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_dashboard", nil);
            break;
        }
        case JMResourceTypeLegacyDashboard: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_dashboard_legacy", nil);
            break;
        }
        case JMResourceTypeSchedule: {
            localizedResourceType = JMCustomLocalizedString(@"resources_type_schedule", nil);
            break;
        }
    }
    return localizedResourceType;
}

- (NSString *)resourceViewerVCIdentifier
{
    NSString *vcIdentifier;
    switch (self.type) {
        case JMResourceTypeUnknown: {break;}
        case JMResourceTypeFile: {
            vcIdentifier = @"JMSavedResourceViewerViewController";
            break;
        }
        case JMResourceTypeFolder: {break;}
        case JMResourceTypeSavedReport:
        case JMResourceTypeSavedDashboard:{
            vcIdentifier = @"JMSavedResourceViewerViewController";
            break;
        }
        case JMResourceTypeReport: {
            vcIdentifier = @"JMReportViewerVC";
            break;
        }
        case JMResourceTypeTempExportedReport: {break;}
        case JMResourceTypeTempExportedDashboard: {break;}
        case JMResourceTypeDashboard: {
            vcIdentifier = @"JMDashboardViewerVC";
            break;
        }
        case JMResourceTypeLegacyDashboard: {
            vcIdentifier = @"JMDashboardViewerVC";
            break;
        }
        case JMResourceTypeSchedule: {
            vcIdentifier = @"JMScheduleVC";
            break;
        }
    }
    return vcIdentifier;
}

- (NSString *)infoVCIdentifier
{
    NSString *vcIdentifier = @"JMResourceInfoViewController";
    switch (self.type) {
        case JMResourceTypeUnknown: {break;}
        case JMResourceTypeFile: {
            vcIdentifier = @"JMRepositoryResourceInfoViewController";
            break;
        }
        case JMResourceTypeFolder: {
            vcIdentifier = @"JMRepositoryResourceInfoViewController";
            break;
        }
        case JMResourceTypeSavedReport:
        case JMResourceTypeSavedDashboard:{
            vcIdentifier = @"JMSavedItemsInfoViewController";
            break;
        }
        case JMResourceTypeReport: {
            vcIdentifier = @"JMReportInfoViewController";
            break;
        }
        case JMResourceTypeTempExportedReport: {break;}
        case JMResourceTypeTempExportedDashboard: {break;}
        case JMResourceTypeDashboard: {
            vcIdentifier = @"JMDashboardInfoViewController";
            break;
        }
        case JMResourceTypeLegacyDashboard: {
            vcIdentifier = @"JMDashboardInfoViewController";
            break;
        }
        case JMResourceTypeSchedule: {
            vcIdentifier = @"JMScheduleInfoViewController";
            break;
        }
    }
    return vcIdentifier;
}

#pragma mark - Helpers
+ (JMResourceType)typeForResourceLookupType:(NSString *)resourceLookupType
{
    if ([resourceLookupType isEqualToString:kJS_WS_TYPE_FOLDER]) {
        return JMResourceTypeFolder;
    } else if([resourceLookupType isEqualToString:kJS_WS_TYPE_REPORT_UNIT]) {
        return JMResourceTypeReport;
    } else if([resourceLookupType isEqualToString:kJMSavedReportUnit]) {
        return JMResourceTypeSavedReport;
    } else if([resourceLookupType isEqualToString:kJMTempExportedReportUnit]) {
        return JMResourceTypeTempExportedReport;
    } else if([resourceLookupType isEqualToString:kJMSavedDashboard]) {
        return JMResourceTypeSavedDashboard;
    } else if([resourceLookupType isEqualToString:kJMTempExportedDashboard]) {
        return JMResourceTypeTempExportedDashboard;
    } else if([resourceLookupType isEqualToString:kJS_WS_TYPE_DASHBOARD]) {
        return JMResourceTypeDashboard;
    } else if([resourceLookupType isEqualToString:kJS_WS_TYPE_DASHBOARD_LEGACY]) {
        return JMResourceTypeLegacyDashboard;
    } else if([resourceLookupType isEqualToString:kJS_WS_TYPE_FILE]) {
        return JMResourceTypeFile;
    } else if([resourceLookupType isEqualToString:kJMScheduleUnit]) {
        return JMResourceTypeSchedule;
    }
    return JMResourceTypeUnknown;
}

@end