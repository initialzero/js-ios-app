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
//  JMExportResource.m
//  TIBCO JasperMobile
//

#import "JMExportResource.h"
#import "JMSavedResources+Helpers.h"

@implementation JMExportResource

- (instancetype)initWithResourceLookup:(JSResourceLookup *)resourceLookup format:(NSString *)format
{
    self = [super initWithResourceLookup:resourceLookup];
    if (self) {
        self.format = format;
        self.resourceLookup.version = @0;
        self.resourceLookup.permissionMask = @(JSPermissionMask_Administration);
        self.resourceLookup.creationDate = [NSDate date];
        self.resourceLookup.updateDate = [NSDate date];
        self.resourceLookup.uri = [JMSavedResources uriForSavedResourceWithName:resourceLookup.label format:format resourceType:self.type];
        self.type = [self exportResourceTypeForResourceType:self.type];
    }
    return self;
}

+ (instancetype)resourceWithResourceLookup:(JSResourceLookup *)resourceLookup format:(NSString *)format
{
    return [[self alloc] initWithResourceLookup:resourceLookup format:format];
}

- (JMResourceType)exportResourceTypeForResourceType:(JMResourceType)resourceType
{
    switch (resourceType) {
        case JMResourceTypeReport:
            return JMResourceTypeTempExportedReport;
        case JMResourceTypeDashboard:
        case JMResourceTypeLegacyDashboard:
            return JMResourceTypeTempExportedDashboard;
        default:
            return JMResourceTypeUnknown;
    }
}

@end
