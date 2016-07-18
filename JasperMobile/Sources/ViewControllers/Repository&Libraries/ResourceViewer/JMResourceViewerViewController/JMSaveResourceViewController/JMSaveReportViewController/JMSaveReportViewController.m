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


#import "JMSaveReportViewController.h"
#import "JMCancelRequestPopup.h"
#import "JMSaveResourcePagesCell.h"
#import "JMSaveResourcePageRangeCell.h"
#import "JMReport.h"
#import "JSReportSaver.h"
#import "JMExportManager.h"
#import "JMReportExportTask.h"


NSString * const kJMSaveResourcePagesCellIdentifier = @"PagesCell";
NSString * const kJMSaveResourcePageRangeCellIdentifier = @"PageRangeCell";

@interface JMSaveReportViewController () <JMSaveResourcePageRangeCellDelegate, JMSaveResourcePagesCellDelegate>

@property (nonatomic, assign) JMSaveResourcePagesType pagesType;
@property (nonatomic, strong) JSReportPagesRange *pagesRange;

@end


@implementation JMSaveReportViewController

#pragma mark - Lifecycle
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [JMCustomLocalizedString(@"resource_viewer_save_title", nil) capitalizedString];
    self.resourceName = self.report.resourceLookup.label;

    self.pagesType = JMSaveResourcePagesType_All;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportLoaderDidChangeCountOfPages:) name:kJSReportCountOfPagesDidChangeNotification object:self.report];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupSections) name:kJSReportIsMutlipageDidChangedNotification object:self.report];
}

- (JMResourceType)resourceType
{
    return [JMResource typeForResourceLookupType:self.report.resourceLookup.resourceType];
}

-(NSArray *)availableFormats
{
    return [JMUtils supportedFormatsForReportSaving];
}

#pragma mark - Setups
- (void)setupSections
{
    if (!self.sections) {
        [super setupSections];
    }
    
    if (self.report.isMultiPageReport) {
        if (![self sectionForType:JMSaveResourceSectionTypePageRange]) {
            [self.sections addObject: [JMSaveResourceSection sectionWithType:JMSaveResourceSectionTypePageRange
                                                                     title:JMCustomLocalizedString(@"resource_viewer_save_pages", nil)]];
        }
    } else {
        if ([self sectionForType:JMSaveResourceSectionTypePageRange]) {
            [self.sections removeObject:[self sectionForType:JMSaveResourceSectionTypePageRange]];
        }
    }
}

- (JSReportPagesRange *)pagesRange
{
    if (!_pagesRange) {
        _pagesRange = [JSReportPagesRange rangeWithStartPage:1 endPage:self.report.countOfPages];
    }
    return _pagesRange;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JMSaveResourceSection *currentSection = self.sections[section];
    if (currentSection.sectionType == JMSaveResourceSectionTypePageRange) {
        return (self.pagesType == JMSaveResourcePagesType_All) ? 1 : 3;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    JMSaveResourceSection *currentSection = self.sections[indexPath.section];
    if (currentSection.sectionType == JMSaveResourceSectionTypePageRange) {
            if (indexPath.row == 0) {
                JMSaveResourcePagesCell *pagesCell = [tableView dequeueReusableCellWithIdentifier:kJMSaveResourcePagesCellIdentifier
                                                                                           forIndexPath:indexPath];
                pagesCell.cellDelegate = self;
                pagesCell.pagesType = self.pagesType;
                return pagesCell;
            } else {
                JMSaveResourcePageRangeCell *pageRangeCell = [tableView dequeueReusableCellWithIdentifier:kJMSaveResourcePageRangeCellIdentifier
                                                                                           forIndexPath:indexPath];
                pageRangeCell.cellDelegate = self;
                
                if (indexPath.row == 1) {
                    pageRangeCell.titleLabel.text = JMCustomLocalizedString(@"resource_viewer_save_pages_range_fromPage", nil);
                    pageRangeCell.currentPage = self.pagesRange.startPage;
                } else if (indexPath.row == 2) {
                    pageRangeCell.titleLabel.text = JMCustomLocalizedString(@"resource_viewer_save_pages_range_toPage", nil);
                    pageRangeCell.currentPage = self.pagesRange.endPage;
                }
                return pageRangeCell;
            }
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

#pragma mark - JMSaveResourcePageRangeCellDelegate
- (NSRange)availableRangeForPageRangeCell:(JMSaveResourcePageRangeCell *)cell
{
    if (self.report.countOfPages != NSNotFound) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        if (indexPath.row == 1) {
            return NSMakeRange(1, self.pagesRange.endPage);
        } else {
            return NSMakeRange(self.pagesRange.startPage, self.report.countOfPages - self.pagesRange.startPage + 1);
        }
    }
    return NSMakeRange(NSNotFound, 0);
}

- (void)pageRangeCell:(JMSaveResourcePageRangeCell *)cell didSelectPage:(NSInteger)page
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath.row == 1) {
        self.pagesRange.startPage = page;
    } else if (indexPath.row == 2) {
        self.pagesRange.endPage = page;
    }
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - JMSaveResourcePagesCellDelegate
- (void)pagesCell:(JMSaveResourcePagesCell *)pagesCell didChangedPagesType:(JMSaveResourcePagesType)pagesType
{
    self.pagesType = pagesType;
    [self reloadSectionForType:JMSaveResourceSectionTypePageRange];
}

- (void)verifyRangePagesWithCompletion:(void(^)(BOOL success))completion
{
    BOOL isNotPDF = ![self.selectedFormat isEqualToString:kJS_CONTENT_TYPE_PDF];
    if (isNotPDF) {
        if ((self.pagesRange.endPage - self.pagesRange.startPage) + 1 > kJMSaveReportMaxRangePages ) {
            NSString *errorMessage = [NSString stringWithFormat:JMCustomLocalizedString(@"resource_viewer_save_name_errmsg_tooBigRange", nil), @(kJMSaveReportMaxRangePages), [self.selectedFormat uppercaseString]];
            
            UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_error"
                                                                                              message:errorMessage
                                                                                    cancelButtonTitle:@"dialog_button_cancel"
                                                                              cancelCompletionHandler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                                                                                  if (completion) {
                                                                                      completion(NO);
                                                                                  }
                                                                              }];
            __weak typeof(self) weakSelf = self;
            [alertController addActionWithLocalizedTitle:@"dialog_button_ok" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.selectedFormat = kJS_CONTENT_TYPE_PDF;
                // update format section
                JMSaveResourceSection *formatSection = [strongSelf sectionForType:JMSaveResourceSectionTypeFormat];
                NSInteger formatSectionIndex = [strongSelf.sections indexOfObject:formatSection];
                NSIndexSet *sectionsForUpdate = [NSIndexSet indexSetWithIndex:formatSectionIndex];
                [strongSelf.tableView reloadSections:sectionsForUpdate withRowAnimation:UITableViewRowAnimationAutomatic];
                if (completion) {
                    completion(YES);
                }
            }];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            if (completion) {
                completion(YES);
            }
        }
    } else {
        if (completion) {
            completion(YES);
        }
    }
}

- (void) saveResource
{
    JMReportExportTask *task = [[JMReportExportTask alloc] initWithReport:self.report
                                                                     name:self.resourceName
                                                                   format:self.selectedFormat
                                                                    pages:self.pagesRange];
    [[JMExportManager sharedInstance] addExportTask:task];
    
    [super saveResource];
}

- (void) reportLoaderDidChangeCountOfPages:(NSNotification *) notification
{
    self.pagesRange.endPage = self.report.countOfPages;
    [self.tableView reloadData];
}

- (void)reportLoaderDidChangeMultipage:(NSNotification *)notification
{
    [self setupSections];
    [self.tableView reloadData];
}

@end
