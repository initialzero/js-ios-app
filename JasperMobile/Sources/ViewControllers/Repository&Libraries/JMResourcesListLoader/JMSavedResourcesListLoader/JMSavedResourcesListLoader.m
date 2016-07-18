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


#import "JMSavedResourcesListLoader.h"
#import "JMServerProfile+Helpers.h"
#import "JMSavedResources+Helpers.h"
#import "JMFavorites+Helpers.h"
#import "JMExportManager.h"
#import "JMResourceLoaderOption.h"

@implementation JMSavedResourcesListLoader

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsUpdate) name:kJMSavedResourcesDidChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadNextPage {
    NSError *error;
    NSArray *fetchedObjects = [[JMCoreDataManager sharedInstance].managedObjectContext executeFetchRequest:[self fetchRequest]
                                                                                                     error:&error];
    if (error) {
        [self finishLoadingWithError:error];
    } else {
        NSMutableArray *commonResourcesArray = [NSMutableArray array];
        for(JMSavedResources *savedResource in fetchedObjects) {
            [commonResourcesArray addObject:[savedResource wrapperFromSavedResources]];
        }
        
        NSArray *exportedResources = [[[JMExportManager sharedInstance] exportedResources] filteredArrayUsingPredicate:[self predicate]];
        if (exportedResources.count) {
            [commonResourcesArray addObjectsFromArray:exportedResources];
            NSSortDescriptor *sortDescriptor = [self sortDescriptorForResources];
            if (sortDescriptor) {
                commonResourcesArray = [[commonResourcesArray sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
            }
        }
        [self addResourcesWithResources:commonResourcesArray];

        _needUpdateData = NO;

        [self finishLoadingWithError:nil];
    }
}

- (NSArray <JMResourceLoaderOption *>*)listItemsWithOption:(JMResourcesListLoaderOptionType)optionType
{
    switch (optionType) {
        case JMResourcesListLoaderOptionType_Sort:
            return [super listItemsWithOption:optionType];
        case JMResourcesListLoaderOptionType_Filter: {
            NSMutableArray *filterOptions = [NSMutableArray array];
            
            NSMutableSet *formatsSet = [NSMutableSet setWithArray:[JMUtils supportedFormatsForReportSaving]];
            [formatsSet addObjectsFromArray:[JMUtils supportedFormatsForDashboardSaving]];
            NSArray *formatsArray = formatsSet.allObjects;
            JMResourceLoaderOption *filterByAllOption = [JMResourceLoaderOption optionWithTitle:JMCustomLocalizedString(@"resources_filterby_type_all", nil)
                                                                                          value:formatsArray];
            [filterOptions addObject:filterByAllOption];

            for (NSString *format in formatsArray) {
                JMResourceLoaderOption *filterByOption = [JMResourceLoaderOption optionWithTitle:[format uppercaseString]
                                                                                           value:@[format]];
                [filterOptions addObject:filterByOption];
            }
            return filterOptions;
        }
    }
}

#pragma mark - Utils
- (NSFetchRequest *)fetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:kJMSavedResources inManagedObjectContext:[JMCoreDataManager sharedInstance].managedObjectContext];
    
    NSSortDescriptor *sortDescriptor = [self sortDescriptor];
    if (sortDescriptor) {
        [fetchRequest setSortDescriptors:@[sortDescriptor]];
    }

    [fetchRequest setEntity:entity];
    NSMutableArray *predicates = [NSMutableArray arrayWithObject:[[JMSessionManager sharedManager] predicateForCurrentServerProfile]];
    [predicates addObject:[self predicate]];
    fetchRequest.predicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];
    return fetchRequest;
}

- (NSPredicate *)predicate
{
    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"format IN %@", [self parameterForQueryWithOptionType:JMResourcesListLoaderOptionType_Filter]]];
    if (self.searchQuery && self.searchQuery.length) {
        NSMutableArray *queryPredicates = [NSMutableArray array];
        [queryPredicates addObject:[NSPredicate predicateWithFormat:@"label LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", self.searchQuery]]];
        [queryPredicates addObject:[NSPredicate predicateWithFormat:@"resourceDescription LIKE[cd] %@", [NSString stringWithFormat:@"*%@*", self.searchQuery]]];
        [predicates addObject:[[NSCompoundPredicate alloc] initWithType:NSOrPredicateType subpredicates:queryPredicates]];
    }
    return [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:predicates];
}

- (NSSortDescriptor *)sortDescriptor
{
    if ([self parameterForQueryWithOptionType:JMResourcesListLoaderOptionType_Sort]) {
        BOOL ascending = self.sortBySelectedIndex == 0;
        return [[NSSortDescriptor alloc] initWithKey:[self parameterForQueryWithOptionType:JMResourcesListLoaderOptionType_Sort] ascending:ascending];
    }
    return nil;
}

- (NSSortDescriptor *)sortDescriptorForResources
{
    NSString *sortKey = [self parameterForQueryWithOptionType:JMResourcesListLoaderOptionType_Sort];
    if (sortKey) {
        BOOL ascending = self.sortBySelectedIndex == 0;
        sortKey = [NSString stringWithFormat:@"resourceLookup.%@", sortKey];
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey
                                                                         ascending:ascending];
        return sortDescriptor;
    }
    return nil;
}

@end
