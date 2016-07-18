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


#import "JMSavedResources+Helpers.h"
#import "JMServerProfile+Helpers.h"
#import "JMFavorites+Helpers.h"
#import "JMSessionManager.h"
#import "JSResourceLookup.h"

NSString * const kJMSavedResources = @"SavedResources";
NSString * const kJMSavedResourcesDefaultOrganization = @"organization_1";


@implementation JMSavedResources (Helpers)

+ (JMSavedResources *)savedResourceFromResource:(JMResource *)resource
{
    NSFetchRequest *fetchRequest = [self savedResourcesFetchRequestWithValuesAndFields:resource.resourceLookup.uri, @"uri", nil];
    NSArray *result = [[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    return [result lastObject];
}

+ (JMSavedResources *)savedResourceWithResourceName:(NSString *)resourceName format:(NSString *)format resourceType:(JMResourceType)resourceType;
{
    NSString *wsType = [self wsTypeWithResourceType:resourceType];
    NSFetchRequest *fetchRequest = [self savedResourcesFetchRequestWithValuesAndFields:resourceName, @"label", format, @"format", wsType, @"wsType", nil];
    NSArray <JMSavedResources*> *savedResources = [[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    return [savedResources firstObject];
}

+ (JMSavedResources *)addResource:(JMExportResource *)resource sourcesURL:(NSURL *)sourcesURL
{
    NSString *wsType =  [self wsTypeWithResourceType:resource.type];
    NSFetchRequest *fetchRequest = [self savedResourcesFetchRequestWithValuesAndFields:resource.resourceLookup.label, @"label", resource.format, @"format", wsType, @"wsType", nil];
    JMSavedResources *savedResource = [[[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];

    if (!savedResource) {
        JMServerProfile *activeServerProfile = [JMServerProfile serverProfileForJSProfile:self.restClient.serverProfile];
        savedResource = [NSEntityDescription insertNewObjectForEntityForName:kJMSavedResources inManagedObjectContext:[JMCoreDataManager sharedInstance].managedObjectContext];
        savedResource.label = resource.resourceLookup.label;
        savedResource.uri = [self uriForSavedResourceWithName:resource.resourceLookup.label format:resource.format resourceType:resource.type];
        savedResource.resourceDescription = resource.resourceLookup.resourceDescription;
        savedResource.format = resource.format;
        savedResource.username = self.restClient.serverProfile.username;
        savedResource.wsType = wsType;
        savedResource.version = resource.resourceLookup.version;
        [activeServerProfile addSavedResourcesObject:savedResource];
    }
    savedResource.creationDate = [NSDate date];
    savedResource.updateDate = [NSDate date];
    
    NSError *error = [self moveResourceContentFromPath:[sourcesURL path] toPath:[JMSavedResources pathToFolderForSavedResource:savedResource] resourceType:resource.type];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        [[JMCoreDataManager sharedInstance] resetPersistentStore];
        return nil;
    } else {
        [[JMCoreDataManager sharedInstance] save:nil];
        return savedResource;
    }
}

- (void)removeResource
{
    [JMFavorites removeFromFavorites:[self wrapperFromSavedResources]];

    NSString *pathToResource = [JMSavedResources pathToFolderForSavedResource:self];
    [[NSFileManager defaultManager] removeItemAtPath:pathToResource error:nil];
    [self.managedObjectContext deleteObject:self];
    [self.managedObjectContext save:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJMSavedResourcesDidChangedNotification object:nil];
}

- (UIImage *)thumbnailImage
{
    NSString *resourceDirectoryPath = [JMSavedResources pathToFolderForSavedResource:self];
    NSString *thumbnailImagePath = [resourceDirectoryPath stringByAppendingPathComponent:kJMThumbnailImageFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailImagePath]) {
        NSData *imageData = [NSData dataWithContentsOfFile:thumbnailImagePath];
        if (imageData) {
            return [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
        }
    }
    return nil;
}

+ (BOOL)isAvailableResourceName:(NSString *)resourceName format:(NSString *)format resourceType:(JMResourceType)resourceType;
{
    return (![self savedResourceWithResourceName:resourceName format:format resourceType:resourceType]);
}

+ (NSArray *)allSavedItems
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kJMSavedResources];
    NSArray *savedItems = [[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    return savedItems;
}

+ (BOOL)migrateSavedItemFromPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    NSString *currentFolderPath = [fromPath stringByDeletingLastPathComponent];
    NSString *newFolderPath = [toPath stringByDeletingLastPathComponent];

    BOOL isFileExists = [self isExistItemAtPath:toPath];

    if (isFileExists) {
        NSString *newFileName = toPath.stringByDeletingPathExtension;
        NSString *newFileFormat = toPath.pathExtension;
        BOOL isEntryInDBExists = [JMSavedResources isAvailableResourceName:newFileName format:newFileFormat resourceType:JMResourceTypeSavedReport];
        if (isEntryInDBExists) {
            return NO;
        } else {
            [self removeResourceAtPath:toPath];
        }
    } else {
        [self createFolderAtPath:newFolderPath];
    }

    NSError *error;

    NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentFolderPath error:&error];

    for (NSString *item in items) {
        NSString *newItem = item;
        if ([newItem isEqualToString:[currentFolderPath lastPathComponent]] || [newItem.stringByDeletingPathExtension isEqualToString:kJMReportFilename]) {
            newItem = [newFolderPath lastPathComponent];
        }
        NSString *itemFromPath = [currentFolderPath stringByAppendingPathComponent:item];
        NSString *itemToPath = [newFolderPath stringByAppendingPathComponent:newItem];
        [[NSFileManager defaultManager] moveItemAtPath:itemFromPath toPath:itemToPath error:&error];
    }

    [self removeResourceAtPath:currentFolderPath];

    return !(error);
}

- (BOOL)renameResourceTo:(NSString *)newName
{
    NSString *currentPath = [JMSavedResources absolutePathToSavedResource:self];
    NSString *newPath = [JMSavedResources renamedAbsolutePathToSavedResource:self newName:newName];
    
    NSString *currentFolderPath = [currentPath stringByDeletingLastPathComponent];
    NSString *newFolderPath = [newPath stringByDeletingLastPathComponent];
    
    JMResourceType resourceType = [JMResource typeForResourceLookupType:self.wsType];
    
    BOOL isFileExists = [JMSavedResources isExistItemAtPath:newPath];
    
    if (isFileExists) {
        BOOL isEntryInDBExists = [JMSavedResources isAvailableResourceName:newName format:self.format resourceType:resourceType];
        if (isEntryInDBExists) {
            return NO;
        } else {
            [JMSavedResources removeResourceAtPath:newPath];
        }
    }
    
    // Move folder and it content
    NSError *moveContentError = [JMSavedResources moveResourceContentFromPath:currentFolderPath toPath:newFolderPath resourceType:[JMResource typeForResourceLookupType:self.wsType]];
    
    if (!moveContentError) {
        // Rename resource file
        NSString *temporaryResourceName = [newFolderPath stringByAppendingPathComponent:[currentPath lastPathComponent]];
        [[NSFileManager defaultManager] moveItemAtPath:temporaryResourceName toPath:newPath error:&moveContentError];
        if (!moveContentError) {
            JMFavorites *favorites = [JMFavorites favoritesFromResourceLookup:[self wrapperFromSavedResources]];
            if (favorites) {
                favorites.label = newName;
                favorites.uri = [JMSavedResources uriForSavedResourceWithName:newName format:self.format resourceType:resourceType];
                [self.managedObjectContext save:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kJMFavoritesDidChangedNotification object:nil];
            }
            
            self.label = newName;
            self.uri = [JMSavedResources uriForSavedResourceWithName:newName format:self.format resourceType:resourceType];
            self.updateDate = [NSDate date];
            [self.managedObjectContext save:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kJMSavedResourcesDidChangedNotification object:nil];
            return YES;
        }
    }
    return NO;
}

- (JMResource *)wrapperFromSavedResources
{
    JSResourceLookup *resourceLookup = [JSResourceLookup new];
    resourceLookup.uri = self.uri;
    resourceLookup.label = self.label;
    resourceLookup.resourceType = self.wsType;
    resourceLookup.creationDate = self.creationDate;
    resourceLookup.updateDate = self.updateDate;
    resourceLookup.resourceDescription = self.resourceDescription;
    resourceLookup.version = self.version;
    return [JMResource resourceWithResourceLookup:resourceLookup];
}

#pragma mark - Public API for Paths
+ (NSString *)pathToFolderForSavedResource:(JMSavedResources *)savedResource
{
    // Documents/PathComponent/resourceTypeFolder/resourceName.format/resourceName.format
    NSString *pathToReport = [self absolutePathToSavedResource:savedResource];
    // Documents/PathComponent/resourceTypeFolder/resourceName.format
    NSString *absolutePath = [pathToReport stringByDeletingLastPathComponent];
    return absolutePath;
}

+ (NSString *)absolutePathToSavedResource:(JMSavedResources *)savedResource
{
    // Documents/
    NSString *pathToDocumentsFolder = [JMUtils applicationDocumentsDirectory];
    // PathComponent/resourceTypeFolder/resourceName.format/resourceName.format
    NSString *uri = savedResource.uri;
    // Documents/PathComponent/resourceTypeFolder/resourceName.format/
    NSString *absolutePath = [pathToDocumentsFolder stringByAppendingPathComponent:uri];
    return absolutePath;
}

+ (NSString *)renamedAbsolutePathToSavedResource:(JMSavedResources *)savedResource newName:(NSString *)newName
{
    JMResourceType resourceType = [JMResource typeForResourceLookupType:savedResource.wsType];
    // Documents/
    NSString *pathToDocumentsFolder = [JMUtils applicationDocumentsDirectory];
    // PathComponent/resourceTypeFolder/resourceName.format/resourceName.format
    NSString *uri = [self uriForSavedResourceWithName:newName format:savedResource.format resourceType:resourceType];
    // Documents/PathComponent/resourceTypeFolder/resourceName.format/
    NSString *absolutePath = [pathToDocumentsFolder stringByAppendingPathComponent:uri];
    return absolutePath;
}

#pragma mark - Private API fo Paths
+ (NSString *)pathComponent
{
    NSString *userName = self.restClient.serverProfile.username;
    NSString *organization = self.restClient.serverProfile.organization;
    if (!organization) {
        organization = kJMSavedResourcesDefaultOrganization;
    }
    NSString *serverURL = self.restClient.serverProfile.serverUrl;
    NSString *alias = self.restClient.serverProfile.alias;

    NSString *uniqueString = [self createUniqueStringWithUserName:userName
                                                     organization:organization
                                                         severURL:serverURL
                                                            alias:alias];
    return uniqueString;
}

+ (NSString *)createUniqueStringWithUserName:(NSString *)userName
                                organization:(NSString *)organization
                                    severURL:(NSString *)serverURL
                                       alias:(NSString *)alias
{
    NSString *combinedString = [NSString stringWithFormat:@"%@+%@+%@+%@", userName, organization, serverURL, alias];
    NSData *combinedStringData = [combinedString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *result = [combinedStringData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    result = [result uppercaseString];
    return result;
}

+ (NSString *)uriForSavedResourceWithName:(NSString *)resourceName format:(NSString *)format resourceType:(JMResourceType)resourceType
{
    NSAssert(resourceName != nil || format != nil, @"There aren't name and format of saved report");

    // resourceName.format
    NSString *savedResourceName = [resourceName stringByAppendingPathExtension:format];
    // resourceName.format/resourceName.format
    NSString *relativePath = [savedResourceName stringByAppendingPathComponent:savedResourceName];
    // reourceTypeFolder
    NSString *resourceTypeFolder = [self folderForResourceType:resourceType];
    // resourceTypeFolder/resourceName.format/resourceName.format
    relativePath = [resourceTypeFolder stringByAppendingPathComponent:relativePath];
    // PathComponent
    NSString *pathComponent = [self pathComponent];
    // PathComponent/resourceTypeFolder/resourceName.format/resourceName.format
    relativePath = [pathComponent stringByAppendingPathComponent:relativePath];

    return [NSString stringWithFormat:@"/%@", relativePath];
}

#pragma mark - Private

+ (NSFetchRequest *)savedResourcesFetchRequestWithValuesAndFields:(id)firstValue, ... NS_REQUIRES_NIL_TERMINATION
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kJMSavedResources];
    NSMutableArray *predicates = [@[[[JMSessionManager sharedManager] predicateForCurrentServerProfile]] mutableCopy];

    va_list args;
    va_start(args, firstValue);
    for (NSString *value = firstValue; value != nil; value = va_arg(args, NSString*)) {
        NSString *queryFormat = [NSString stringWithFormat:@"%@ LIKE[cd] ", va_arg(args,NSString*)];
        [predicates addObject:[NSPredicate predicateWithFormat:[queryFormat stringByAppendingString:@"%@"], value]];
    }
    va_end(args);

    fetchRequest.predicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];
    return fetchRequest;
}

+ (NSString *)folderForResourceType:(JMResourceType)resourceType
{
    switch (resourceType) {
        case JMResourceTypeReport:
        case JMResourceTypeTempExportedReport:
        case JMResourceTypeSavedReport:
            return kJMReportsDirectory;
        case JMResourceTypeDashboard:
        case JMResourceTypeLegacyDashboard:
        case JMResourceTypeTempExportedDashboard:
        case JMResourceTypeSavedDashboard:
            return kJMDashboardsDirectory;
        default:
            return nil;
    }
}

+ (NSString *)wsTypeWithResourceType:(JMResourceType)resourceType
{
    switch (resourceType) {
        case JMResourceTypeReport:
        case JMResourceTypeTempExportedReport:
            return kJMSavedReportUnit;
        case JMResourceTypeDashboard:
        case JMResourceTypeLegacyDashboard:
        case JMResourceTypeTempExportedDashboard:
            return kJMSavedDashboard;
        default:
            return nil;
    }
}

#pragma mark - File handlers
+ (NSError *)moveResourceContentFromPath:(NSString *)fromPath toPath:(NSString *)toPath resourceType:(JMResourceType)resourceType
{
    NSError *error = [self copyResourceContentFromPath:fromPath toPath:toPath resourceType:resourceType];
    if (error) {
        if ([self isExistItemAtPath:toPath]) {
            error = [self removeResourceAtPath:toPath];
        }
    } else {
        error = [self removeResourceAtPath:fromPath];
    }
    return error;
}

+ (NSError *)copyResourceContentFromPath:(NSString *)fromPath toPath:(NSString *)toPath resourceType:(JMResourceType)resourceType
{
    NSError *error;
    if ([self isExistsFolderAtPath:toPath]) {
        error = [self removeResourceAtPath:toPath];
    }
    
    if (!error) {
        // Check existing or create new resource folder
        NSString *pathToDocumentsFolder = [JMUtils applicationDocumentsDirectory];
        NSString *relativeReportsPath = [[self pathComponent] stringByAppendingPathComponent:[self folderForResourceType:resourceType]];
        NSString *reportsFolder = [pathToDocumentsFolder stringByAppendingPathComponent:relativeReportsPath];
        
        if (![self isExistsFolderAtPath:reportsFolder]) {
            error = [self createFolderAtPath:reportsFolder];
        }
        
        // Copy content
        if (!error) {
            [[NSFileManager defaultManager] copyItemAtPath:fromPath toPath:toPath error:&error];
        }
    }
    return error;
}

+ (NSError *)removeResourceAtPath:(NSString *)path
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    return error;
}

+ (NSError *)createFolderAtPath:(NSString *)path
{
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    return error;
}

+ (BOOL)isExistItemAtPath:(NSString *)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+ (BOOL)isExistsFolderAtPath:(NSString *)folderPath
{
    BOOL isDirectory;
    return ([[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDirectory] && isDirectory);
}

#pragma mark - Updater
+ (NSString *)oldPathForSavedResource:(JMSavedResources *)savedResource
{
    NSString *oldPath = @"";
    NSString *documentFolderPath = [JMUtils applicationDocumentsDirectory];
    NSString *uri = savedResource.uri;
    NSString *oldReportsFolder = [documentFolderPath stringByAppendingPathComponent:savedResource.serverProfile.alias];
    BOOL isExistFolder = [self isExistsFolderAtPath:oldReportsFolder];
    if (isExistFolder) {
        oldPath = oldReportsFolder;
    } else {
        oldPath = documentFolderPath;
    }
    oldPath = [oldPath stringByAppendingPathComponent:uri];

    return oldPath;
}

+ (NSString *)newURIForSavedResource:(JMSavedResources *)savedResource
{
    NSString *uri = savedResource.uri;
    NSString *newUri = [uri stringByDeletingLastPathComponent];
    NSString *newName = [newUri lastPathComponent];
    newUri = [newUri stringByAppendingPathComponent:newName];

    NSString *userName = savedResource.username;
    NSString *organization = savedResource.serverProfile.organization;
    if (!organization) {
        organization = kJMDemoServerOrganization;
    }
    NSString *serverURL = savedResource.serverProfile.serverUrl;
    NSString *alias = savedResource.serverProfile.alias;

    NSString *pathComponent = [JMSavedResources createUniqueStringWithUserName:userName
                                                                  organization:organization
                                                                      severURL:serverURL
                                                                         alias:alias];
    newUri = [pathComponent stringByAppendingPathComponent:newUri];

    return newUri;
}

@end
