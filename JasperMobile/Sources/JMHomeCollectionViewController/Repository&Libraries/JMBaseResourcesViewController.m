//
//  JMBaseResourcesViewController.m
//  JasperMobile
//
//  Created by Vlad Zavadskii on 7/4/14.
//  Copyright (c) 2014 com.jaspersoft. All rights reserved.
//

#import "JMBaseResourcesViewController.h"
#import "UIViewController+FetchInputControls.h"
#import "JMConstants.h"
#import "JMDetailReportViewerViewController.h"
#import "JMDetailReportOptionsViewController.h"
#import <Objection-iOS/Objection.h>

NSString * kJMResourceCellIdentifier = @"ResourceCell";
NSString * kJMLoadingCellIdentifier = @"LoadingCell";

@implementation JMBaseResourcesViewController
objection_requires(@"constants")


- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)numberOfResourcesInSection:(NSInteger)section
{
    NSInteger count = self.delegate.resources.count;
    if ([self.delegate hasNextPage]) count++;
    
    return count;
}

- (void)didSelectResource:(JSResourceLookup *)resourceLookup
{
    if ([resourceLookup.resourceType isEqualToString:self.constants.WS_TYPE_REPORT_UNIT]) {
        [self fetchInputControlsForReport:resourceLookup];
    } else {
        NSDictionary *data = @{
                               kJMResourceLookup : resourceLookup
                               };
        [self performSegueWithIdentifier:kJMShowReportViewerSegue sender:data];
    }
}


- (void)didSelectResourceAtIndexPath:(NSIndexPath *)indexPath
{
    JSResourceLookup *resourceLookup = [self.delegate.resources objectAtIndex:indexPath.row];
    [self didSelectResource:resourceLookup];
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[JSObjection defaultInjector] injectDependencies:self];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];

    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kJMShowReportInDetail object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.navigationController popToViewController:strongSelf animated:NO];
            [strongSelf didSelectResource:note.object];
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSInteger row;
    
    if ([self isReportSegue:segue]) {
        JSResourceLookup *resourcesLookup = [sender objectForKey:kJMResourceLookup];
        row = [self.delegate.resources indexOfObject:resourcesLookup];
        
        NSArray *inputControls = [sender objectForKey:kJMInputControls];
        id destinationViewController = segue.destinationViewController;
        [destinationViewController setInputControls:[inputControls mutableCopy]];
        [destinationViewController setResourceLookup:resourcesLookup];
    } else {
        row = [sender row];
    }
    
    NSDictionary *userInfo = @{
                   kJMResources : self.delegate.resources,
                   kJMTotalCount : @(self.delegate.totalCount),
                   kJMOffset : @(self.delegate.offset),
                   kJMSelectedResourceIndex : @(row)
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kJMShowResourcesListInMaster
                                                        object:nil
                                                      userInfo:userInfo];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - JMRefreshable

- (void)refresh
{
    @throw [NSException exceptionWithName:@"Method implementation is missing" reason:@"You need to implement \"refresh\" method in subclasses" userInfo:nil];
}

#pragma mark - JMActionBarProvider

- (id)actionBar
{
    return [self.delegate actionBar];
}

@end