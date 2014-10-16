/*
 * Tibco JasperMobile for iOS
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
//  JMSavedResources+Helpers.h
//  Tibco JasperMobile
//

/**
 @author Alexey Gubarev agubarev@jaspersoft.com
 @since 1.9
 */

#import "JMSavedResources.h"

extern NSString * const kJMSavedResources;

@interface JMSavedResources (Helpers)

// Returns saved report from JSResourceLookup
+ (JMSavedResources *)savedReportsFromResourceLookup:(JSResourceLookup *)resource;

// Adds saved resource with path to CoreData
+ (void)addReport:(JSResourceLookup *)resource withName:(NSString *)name format:(NSString *)format;

// Removes saved resource
+ (void)removeReport:(JSResourceLookup *)resource;

// Returns YES if report with name reportName is absent
+ (BOOL)isAvailableReportName:(NSString *)reportName;

// Rename saved resource
- (void)renameReportTo:(NSString *)newName;

// Returns wrapper from SavedReports. Wrapper is a JSResourceLookup
- (JSResourceLookup *)wrapperFromSavedReports;

+ (NSString *)uriForSavedReportWithName:(NSString *)name format:(NSString *)format;

+ (NSString *)pathToDirectoryForSavedReportWithName:(NSString *)name format:(NSString *)format;

@end
