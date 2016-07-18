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
//  JMSavedResources+Helpers.h
//  TIBCO JasperMobile
//

/**
 @author Alexey Gubarev ogubarie@tibco.com
 @since 1.9
 */

#import "JMSavedResources.h"
#import "JMExportResource.h"

extern NSString * const kJMSavedResources;

@interface JMSavedResources (Helpers)

// Returns saved resource from JMResource
+ (JMSavedResources *)savedResourceFromResource:(JMResource *)resource;

+ (JMSavedResources *)savedResourceWithResourceName:(NSString *)resourceName format:(NSString *)format resourceType:(JMResourceType)resourceType;

// Adds saved resource with path to CoreData
+ (JMSavedResources *)addResource:(JMExportResource *)resource sourcesURL:(NSURL *)sourcesURL;

// Returns YES if resource with name resourceName with format format is absent
+ (BOOL)isAvailableResourceName:(NSString *)resourceName format:(NSString *)format resourceType:(JMResourceType)resourceType;

+ (NSArray *)allSavedItems;

+ (BOOL)migrateSavedItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath;

// Rename saved resource
- (BOOL)renameResourceTo:(NSString *)newName;

// Removes saved resource
- (void)removeResource;

// Returns thumbnail image for saved resource
- (UIImage *)thumbnailImage;

// Returns wrapper from SavedResources. Wrapper is a JMResource
- (JMResource *)wrapperFromSavedResources;

// paths
+ (NSString *)uriForSavedResourceWithName:(NSString *)name format:(NSString *)format resourceType:(JMResourceType)resourceType;

+ (NSString *)pathToFolderForSavedResource:(JMSavedResources *)savedResource;
+ (NSString *)absolutePathToSavedResource:(JMSavedResources *)savedResource;

+ (NSString *)oldPathForSavedResource:(JMSavedResources *)savedResource;
+ (NSString *)newURIForSavedResource:(JMSavedResources *)savedResource;
@end
