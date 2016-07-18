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
//  JMServerProfile+Helpers.m
//  TIBCO JasperMobile
//

#import "JMServerProfile+Helpers.h"
#import "JMConstants.h"
#import <objc/runtime.h>
#import "JMSessionManager.h"
#import "JMSavedResources+Helpers.h"

@implementation JMServerProfile (Helpers)
+ (JMServerProfile *)demoServerProfile
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ServerProfile"];
    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"serverUrl == %@", kJMDemoServerUrl]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"alias == %@", kJMDemoServerAlias]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"organization == %@", kJMDemoServerOrganization]];
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    JMServerProfile *demoServerProfile = [[[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil] firstObject];
    if (!demoServerProfile) {
        demoServerProfile = (JMServerProfile *) [NSEntityDescription insertNewObjectForEntityForName:@"ServerProfile"
                                                                              inManagedObjectContext:[JMCoreDataManager sharedInstance].managedObjectContext];
        demoServerProfile.alias = kJMDemoServerAlias;
        demoServerProfile.organization = kJMDemoServerOrganization;
        demoServerProfile.serverUrl = kJMDemoServerUrl;
        [[JMCoreDataManager sharedInstance] save:nil];
    }
    return demoServerProfile;
}

+ (JMServerProfile *)serverProfileForJSProfile:(JSProfile *)profile
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ServerProfile"];
    
    NSMutableArray *serverUrlPredicates = [NSMutableArray array];
    [serverUrlPredicates addObject:[NSPredicate predicateWithFormat:@"serverUrl == %@", profile.serverUrl]];
    [serverUrlPredicates addObject:[NSPredicate predicateWithFormat:@"serverUrl == %@", [profile.serverUrl stringByAppendingString:@"/"]]];

    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"alias == %@", profile.alias]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"organization == %@", profile.organization]];
    [predicates addObject:[NSCompoundPredicate orPredicateWithSubpredicates:serverUrlPredicates]];
    
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    
    return [[[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];
}

+ (JMServerProfile *) cloneServerProfile:(JMServerProfile *)serverProfile
{
    NSString *entityName = [[serverProfile entity] name];
    
    //create new object in data store
    JMServerProfile *newServerProfile = (JMServerProfile *) [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                                          inManagedObjectContext:[JMCoreDataManager sharedInstance].managedObjectContext];

    NSInteger cloneNumber = 0;
    NSString *serverName = nil;
    do {
        serverName = (cloneNumber++ > 0) ? [serverProfile.alias stringByAppendingFormat:@" %zd", cloneNumber] : serverProfile.alias;
    } while (![newServerProfile isValidNameForServerProfile:serverName]);
    
    newServerProfile.alias          = serverName;
    newServerProfile.askPassword    = serverProfile.askPassword;
    newServerProfile.keepSession    = serverProfile.keepSession;
    newServerProfile.organization   = serverProfile.organization;
    newServerProfile.serverUrl      = serverProfile.serverUrl;
    return newServerProfile;
}

+ (void) deleteServerProfile:(JMServerProfile *)serverProfile
{
    NSArray *savedReports = [serverProfile.savedResources allObjects];
    for (JMSavedResources *savedResource in savedReports) {
        NSString *fullPath = [JMSavedResources absolutePathToSavedResource:savedResource];
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    }
    [serverProfile.managedObjectContext deleteObject:serverProfile];
    [serverProfile.managedObjectContext save:nil];
}

- (BOOL) isValidNameForServerProfile:(NSString *)name
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ServerProfile"];
    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"self != %@", [JMServerProfile demoServerProfile]]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"self != %@", self]];
    [predicates addObject:[NSPredicate predicateWithFormat:@"alias == %@", name]];
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    JMServerProfile *profile = [[[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];
    return !profile;
}

- (BOOL) isActiveServerProfile
{
    JMServerProfile *activeProfile = [JMServerProfile serverProfileForJSProfile:self.restClient.serverProfile];
    return (self == activeProfile);
}

@end
