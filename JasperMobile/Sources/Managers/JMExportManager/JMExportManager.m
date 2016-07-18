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
//  JMExportManager.m
//  TIBCO JasperMobile
//

#import "JMExportManager.h"
#import "JMExportTask.h"
#import "JSReportSaver.h"
#import "JMSaveResourcePagesCell.h"
#import "JMSavedResources+Helpers.h"

@interface JMExportManager()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation JMExportManager

#pragma mark - Life Cycle
+ (instancetype)sharedInstance {
    static JMExportManager *sharedInstance;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
       sharedInstance = [JMExportManager new];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueue = [NSOperationQueue new];
        _operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

#pragma mark - Public API
- (void)addExportTask:(JMExportTask *)task
{
    [self.operationQueue addOperation:task];
}

- (void)cancelAll
{
    [self.operationQueue cancelAllOperations];
}

- (void)cancelTask:(JMExportTask *)task
{
    [task cancel];
}

- (void)cancelTaskForResource:(JMExportResource *)resource;
{
    [self cancelTask:[self taskForResource:resource]];
}

- (NSArray <JMExportResource *> *)exportedResources
{
    NSMutableArray *resources = [NSMutableArray new];
    for (JMExportTask *task in self.operationQueue.operations) {
        if (!task.isFinished) {
            [resources addObject:task.exportResource];
        }
    }
    return resources;
}

- (JMExportTask *)taskForResource:(JMExportResource *)resource
{
    for (JMExportTask *exportTask in self.operationQueue.operations) {
        if (exportTask.exportResource == resource) {
            return exportTask;
        }
    }
    return nil;
}

+ (JMExportResource *)exportResourceWithName:(NSString *)reportName format:(NSString *)reportFormat;
{
    NSPredicate *predicateName = [NSPredicate predicateWithFormat:@"resourceLookup.label == %@", reportName];
    NSPredicate *predicateFormat = [NSPredicate predicateWithFormat:@"format == %@", reportFormat];
    NSPredicate *predicateAll = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:@[predicateName, predicateFormat]];
    
    NSArray *allExportResources = [[[self sharedInstance] exportedResources] filteredArrayUsingPredicate:predicateAll];
    return [allExportResources firstObject];
}
@end