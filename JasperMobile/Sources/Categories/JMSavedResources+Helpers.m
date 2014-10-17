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


#import "JMSavedResources+Helpers.h"
#import "JMServerProfile+Helpers.h"

NSString * const kJMSavedResources = @"SavedResources";


@implementation JMSavedResources (Helpers)

+ (JMSavedResources *)savedReportsFromResourceLookup:(JSResourceLookup *)resource
{
    NSFetchRequest *fetchRequest = [self savedReportsFetchRequestField:@"uri" value:resource.uri];
    return [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];
}

+ (void)addReport:(JSResourceLookup *)resource withName:(NSString *)name format:(NSString *)format
{
    JMServerProfile *activeServerProfile = [JMServerProfile activeServerProfile];
    JMSavedResources *savedReport = [NSEntityDescription insertNewObjectForEntityForName:kJMSavedResources inManagedObjectContext:self.managedObjectContext];
    savedReport.label = name;
    savedReport.uri = [self uriForSavedReportWithName:name format:format];
    savedReport.wsType = resource.resourceType;
    savedReport.creationDate = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle];
    savedReport.resourceDescription = resource.resourceDescription;
    savedReport.username = activeServerProfile.username;
    savedReport.organization = activeServerProfile.organization;
    savedReport.format = format;
    [activeServerProfile addSavedResourcesObject:savedReport];
    
    [self.managedObjectContext save:nil];
}

+ (void)removeReport:(JSResourceLookup *)resource
{
    JMSavedResources *savedReport = [self savedReportsFromResourceLookup:resource];
    NSString *pathToReport = [self pathToDirectoryForSavedReportWithName:savedReport.label format:savedReport.format];

    [[NSFileManager defaultManager] removeItemAtPath:pathToReport error:nil];
    [self.managedObjectContext deleteObject:savedReport];
    [self.managedObjectContext save:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJMSavedResourcesDidChangedNotification object:nil];
}

+ (BOOL)isAvailableReportName:(NSString *)reportName
{
    NSFetchRequest *fetchRequest = [self savedReportsFetchRequestField:@"label" value:reportName];
    return ([self.managedObjectContext countForFetchRequest:fetchRequest error:nil] == 0);
}

- (void)renameReportTo:(NSString *)newName
{
    NSString *currentPath = [JMSavedResources pathToDirectoryForSavedReportWithName:self.label format:self.format];
    NSString *newPath = [JMSavedResources pathToDirectoryForSavedReportWithName:newName format:self.format];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtPath:currentPath toPath:newPath error:&error];
    if (!error) {
        self.label = newName;
        [self.managedObjectContext save:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kJMSavedResourcesDidChangedNotification object:nil];
    }
}

- (JSResourceLookup *)wrapperFromSavedReports
{
    JSResourceLookup *resource = [[JSResourceLookup alloc] init];
    resource.uri = self.uri;
    resource.label = self.label;
    resource.resourceType = self.wsType;
    resource.creationDate = self.creationDate;
    resource.resourceDescription = self.resourceDescription;
    return resource;
}

+ (NSString *)uriForSavedReportWithName:(NSString *)name format:(NSString *)format
{
    NSString *uri = [[self pathToDirectoryForSavedReportWithName:name format:format] stringByAppendingPathComponent:[kJMReportFilename stringByAppendingPathExtension:format]];
    return [NSString stringWithFormat:@"/%@",uri];
}

+ (NSString *)pathToDirectoryForSavedReportWithName:(NSString *)name format:(NSString *)format
{
    return [kJMReportsDirectory stringByAppendingPathComponent:[name stringByAppendingPathExtension:format]];
}

#pragma mark - Private

+ (NSManagedObjectContext *)managedObjectContext
{
    return [JMUtils managedObjectContext];
}

+ (NSFetchRequest *)savedReportsFetchRequestField:(NSString *)fieldName value:(NSString *)value
{
    JMServerProfile *activeServerProfile = [JMServerProfile activeServerProfile];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:kJMSavedResources];
    
    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"serverProfile == %@", activeServerProfile]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"username == %@", activeServerProfile.username]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"organization == %@", activeServerProfile.organization]];
    NSString *queryFormat = [NSString stringWithFormat:@"%@ LIKE[cd] ", fieldName];
    [predicates addObject:[NSPredicate predicateWithFormat:[queryFormat stringByAppendingString:@"%@"], value]];
    
    fetchRequest.predicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];

    return fetchRequest;
}

@end