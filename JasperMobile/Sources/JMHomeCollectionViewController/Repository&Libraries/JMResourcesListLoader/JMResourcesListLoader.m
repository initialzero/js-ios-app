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


#import "JMResourcesListLoader.h"
#import "JMRequestDelegate.h"

@interface JMResourcesListLoader ()

@property (nonatomic, assign) BOOL needUpdateData;
@property (nonatomic, assign) BOOL isLoadingNow;

@end


@implementation JMResourcesListLoader
objection_requires(@"resourceClient", @"constants")

@synthesize resources = _resources;
@synthesize resourceLookup = _resourceLookup;
@synthesize resourceClient = _resourceClient;
@synthesize totalCount = _totalCount;
@synthesize offset = _offset;
@synthesize isLoadingNow = _isLoadingNow;
@synthesize needUpdateData = _needUpdateData;

#pragma mark - NSObject

- (id)init
{
    self = [super init];
    if (self) {
        [[JSObjection defaultInjector] injectDependencies:self];
        self.isLoadingNow = NO;
        self.searchQuery = nil;
        self.resources = [NSMutableArray array];
        [self setNeedsUpdate];
    }
    return self;
}

- (void)setNeedsUpdate
{
    self.needUpdateData = YES;
}

- (void)updateIfNeeded
{
    if (self.needUpdateData && !self.isLoadingNow) {
        // Reset state
        self.totalCount = 0;
        self.offset = 0;
        
        [self.resources removeAllObjects];
        [self.delegate resourceListDidStartLoading:self];
        
        self.isLoadingNow = YES;
        [self loadNextPage];
    }
}

#pragma mark - JMPagination

- (void)loadNextPage
{
    self.needUpdateData = NO;
    JMRequestDelegate *delegate = [JMRequestDelegate requestDelegateForFinishBlock:@weakselfnotnil(^(JSOperationResult *result)) {
        if (!self.totalCount) {
            self.totalCount = [[result.allHeaderFields objectForKey:@"Total-Count"] integerValue];
        }
        [self.resources addObjectsFromArray:result.objects];
        self.offset += kJMResourceLimit;
        
        self.isLoadingNow = NO;
        [self.delegate resourceListDidLoaded:self withError:nil];
        
    } @weakselfend
    errorBlock:@weakselfnotnil(^(JSOperationResult *result)) {
        self.isLoadingNow = NO;
        [self.delegate resourceListDidLoaded:self withError:result.error];
    } @weakselfend];
    
    [self.resourceClient resourceLookups:self.resourceLookup.uri query:self.searchQuery types:self.resourcesTypesParameterForQuery
                                  sortBy:self.sortByParameterForQuery recursive:self.loadRecursively offset:self.offset limit:kJMResourceLimit delegate:delegate];
}

- (BOOL)hasNextPage
{
    return self.offset < self.totalCount;
}

- (void)searchWithQuery:(NSString *)query
{
    if (![self.searchQuery isEqualToString:query]) {
        self.searchQuery = query;
        [self setNeedsUpdate];
        [self updateIfNeeded];
    }
}

- (void)clearSearchResults
{
    if (self.searchQuery) {
        self.searchQuery = nil;
        [self setNeedsUpdate];
        [self updateIfNeeded];
    }
}

- (NSString *)sortByParameterForQuery
{
    switch (self.sortBy) {
        case JMResourcesListLoaderSortBy_Name:
            return @"label";
        case JMResourcesListLoaderSortBy_Date:
            return @"creationDate";
    }
}

- (NSArray *)resourcesTypesParameterForQuery{
    NSMutableArray *typesArray = [NSMutableArray array];
    switch (self.resourcesType) {
        case JMResourcesListLoaderObjectType_RepositoryAll:
            [typesArray addObject:self.constants.WS_TYPE_FOLDER];
        case JMResourcesListLoaderObjectType_LibraryAll:
            [typesArray addObject:self.constants.WS_TYPE_REPORT_UNIT];
            [typesArray addObject:self.constants.WS_TYPE_DASHBOARD];
            break;
        case JMResourcesListLoaderObjectType_Reports:
            [typesArray addObject:self.constants.WS_TYPE_REPORT_UNIT];
            break;
        case JMResourcesListLoaderObjectType_Dashboards:
            [typesArray addObject:self.constants.WS_TYPE_DASHBOARD];
            break;
        case JMResourcesListLoaderObjectType_Folders:
            [typesArray addObject:self.constants.WS_TYPE_FOLDER];
            break;
    }
    return typesArray;
}

@end
