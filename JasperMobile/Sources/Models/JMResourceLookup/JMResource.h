/*
 * TIBCO JasperMobile for iOS
 * Copyright © 2005-2016 TIBCO Software, Inc. All rights reserved.
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

/**
 @author Aleksandr Dakhno odahno@tibco.com
 @since 2.5
 */

typedef NS_ENUM(NSInteger, JMResourceType) {
    JMResourceTypeUnknown,
    JMResourceTypeFile,
    JMResourceTypeFolder,
    JMResourceTypeSavedReport,
    JMResourceTypeSavedDashboard,
    JMResourceTypeReport,
    JMResourceTypeTempExportedReport,
    JMResourceTypeTempExportedDashboard,
    JMResourceTypeDashboard,
    JMResourceTypeLegacyDashboard,
    JMResourceTypeSchedule
};

@interface JMResource : NSObject
@property (nonatomic, strong, nonnull) JSResourceLookup *resourceLookup;
@property (nonatomic, assign) JMResourceType type;
- (instancetype __nullable)initWithResourceLookup:(JSResourceLookup *__nonnull)resourceLookup;
+ (instancetype __nullable)resourceWithResourceLookup:(JSResourceLookup *__nonnull)resourceLookup;
- (id __nullable)modelOfResource;
- (NSString *__nullable)localizedResourceType;
- (NSString *__nullable)resourceViewerVCIdentifier;
- (NSString *__nullable)infoVCIdentifier;

+ (JMResourceType)typeForResourceLookupType:(nonnull NSString *)resourceLookupType;

@end