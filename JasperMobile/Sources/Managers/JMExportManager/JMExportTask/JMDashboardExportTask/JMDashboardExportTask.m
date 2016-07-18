//
//  JMDashboardExportTask.m
//  TIBCO JasperMobile
//
//  Created by Alexey Gubarev on 7/13/16.
//  Copyright © 2016 TIBCO JasperMobile. All rights reserved.
//

#import "JMDashboardExportTask.h"
#import "JMSavedResources+Helpers.h"
#import "JSDashboardSaver.h"

@interface JMDashboardExportTask ()
@property (nonatomic, strong) JSDashboardSaver *dashboardSaver;
@property (nonatomic, assign) BOOL localExecuting;
@property (nonatomic, assign) BOOL localFinished;

@end

@implementation JMDashboardExportTask
- (instancetype)initWithDashboard:(JSDashboard *)dashboard name:(NSString *)name format:(NSString *)format
{
    JMExportResource *resource = [JMExportResource resourceWithResourceLookup:dashboard.resourceLookup format:format];
    resource.resourceLookup.label = name;
    self = [super initWithResource:resource];
    if(self) {
        _dashboardSaver = [[JSDashboardSaver alloc] initWithDashboard:dashboard restClient:self.restClient];
    }
    return self;
}

- (void)dealloc
{
    [self.dashboardSaver cancel];
}

#pragma mark - Overrides
- (void)start
{
    if (![NSThread isMainThread]) {
#warning HERE NEED ADD SUPPORT OTHER THREAD
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if(self.localFinished || [self isCancelled]) {
        [self completeOperation];
    } else {
        [self willChangeValueForKey:@"isExecuting"];
        [self main];
        self.localExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)main
{
    __weak typeof(self) weakSelf = self;
    [self.dashboardSaver saveDashboardWithName:self.exportResource.resourceLookup.label
                                        format:self.exportResource.format
                                    completion:^(NSURL * _Nullable savedDashboardFolderURL, NSError * _Nullable error) {
                                        __strong typeof(self) strongSelf = weakSelf;
                                        if (error) {
                                            if (error.code == JSSessionExpiredErrorCode) {
                                                [JMUtils showLoginViewAnimated:YES completion:nil];
                                            } else {
                                                [JMUtils presentAlertControllerWithError:error completion:nil];
                                            }
                                        } else {
                                            [JMSavedResources addResource:strongSelf.exportResource sourcesURL:savedDashboardFolderURL];
                                        }
                                        [strongSelf completeOperation];
                                    }];
}

- (void)completeOperation {
    if(self.dashboardSaver) {
        [self.dashboardSaver cancel];
        self.dashboardSaver = nil;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.localExecuting = NO;
    self.localFinished  = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
    
    if ([self isCancelled]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJMExportedResourceDidCancelNotification object:self.exportResource userInfo:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJMExportedResourceDidLoadNotification object:self.exportResource userInfo:nil];
        
        UILocalNotification* notification = [UILocalNotification new];
        notification.fireDate = [NSDate date];
        notification.alertBody = self.exportResource.resourceLookup.label;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return self.localExecuting;
}

- (BOOL)isFinished
{
    return self.localFinished;
}

- (void)cancel
{
    [super cancel];
    [self completeOperation];
}

@end
