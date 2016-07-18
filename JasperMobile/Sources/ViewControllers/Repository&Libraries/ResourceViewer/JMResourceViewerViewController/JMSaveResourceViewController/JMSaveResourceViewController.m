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


#import "JMSaveResourceViewController.h"
#import "JMSavedResources+Helpers.h"
#import "JMCancelRequestPopup.h"
#import "JMSaveResourceNameCell.h"
#import "JMSaveResourceFormatCell.h"

#import "JMExportManager.h"

NSString * const kJMSaveResourceViewControllerSegue = @"SaveResourceViewController";
NSString * const kJMSaveResourceNameCellIdentifier = @"ResourceNameCell";
NSString * const kJMSaveResourceFormatCellIdentifier = @"FormatSelectionCell";

@interface JMSaveResourceViewController () < UITextFieldDelegate, JMSaveResourceNameCellDelegate>

@end


@implementation JMSaveResourceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedFormat = [self.availableFormats firstObject];
        
    self.view.backgroundColor = [[JMThemesManager sharedManager] viewBackgroundColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self.tableView setRowHeight:([JMUtils isCompactWidth] || [JMUtils isCompactHeight]) ? 44.f : 50.f];

    self.saveResourceButton.backgroundColor = [[JMThemesManager sharedManager] saveReportSaveReportButtonBackgroundColor];
    [self.saveResourceButton setTitleColor:[[JMThemesManager sharedManager] saveReportSaveReportButtonTextColor]
                                forState:UIControlStateNormal];
    [self.saveResourceButton setTitle:JMCustomLocalizedString(@"dialog_button_save", nil)
                           forState:UIControlStateNormal];

    [self setupSections];
}

- (JMResourceType)resourceType
{
    @throw [NSException exceptionWithName:@"Method implementation is missing" reason:[NSString stringWithFormat:@"You need to implement \"%@\" method in \"%@\" class", NSStringFromSelector(_cmd), NSStringFromClass(self.class)] userInfo:nil];
}

#pragma mark - Setups
- (NSArray *)availableFormats
{
    @throw [NSException exceptionWithName:@"Method implementation is missing" reason:[NSString stringWithFormat:@"You need to implement \"%@\" method in \"%@\" class", NSStringFromSelector(_cmd), NSStringFromClass(self.class)] userInfo:nil];
}

- (void)setupSections
{
    if (!self.sections) {
        self.sections = [@[
                           [JMSaveResourceSection sectionWithType:JMSaveResourceSectionTypeName
                                                          title:JMCustomLocalizedString(@"resource_viewer_save_name", nil)],
                           [JMSaveResourceSection sectionWithType:JMSaveResourceSectionTypeFormat
                                                          title:JMCustomLocalizedString(@"resource_viewer_save_format", nil)],
                           ]mutableCopy];
    }
}

- (void)setErrorString:(NSString *)errorString
{
    if (![_errorString isEqualToString:errorString]) {
        _errorString = errorString;
        [self reloadSectionForType:JMSaveResourceSectionTypeName];
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JMSaveResourceSection *currentSection = self.sections[section];
    switch (currentSection.sectionType) {
        case JMSaveResourceSectionTypeName:
            return 1;
        case JMSaveResourceSectionTypeFormat:
            return self.availableFormats.count;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    JMSaveResourceSection *currentSection = self.sections[section];
    return currentSection.title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && self.errorString) {
        CGFloat maxWidth = self.tableView.frame.size.width - 40;
        CGSize maximumLabelSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
        CGRect textRect = [self.errorString boundingRectWithSize:maximumLabelSize
                                                         options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                      attributes:@{NSFontAttributeName:[[JMThemesManager sharedManager] tableViewCellErrorFont]}
                                                         context:nil];
        return tableView.rowHeight + ceil(textRect.size.height);
    }
    return tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    JMSaveResourceSection *currentSection = self.sections[indexPath.section];
    switch (currentSection.sectionType) {
        case JMSaveResourceSectionTypeName: {
            JMSaveResourceNameCell *resourceNameCell = [tableView dequeueReusableCellWithIdentifier:kJMSaveResourceNameCellIdentifier
                                                                                   forIndexPath:indexPath];
            resourceNameCell.textField.text = self.resourceName;
            resourceNameCell.errorLabel.text = self.errorString;
            resourceNameCell.cellDelegate = self;
            return resourceNameCell;
        }
        case JMSaveResourceSectionTypeFormat: {
            JMSaveResourceFormatCell *formatCell = [tableView dequeueReusableCellWithIdentifier:kJMSaveResourceFormatCellIdentifier
                                                                                 forIndexPath:indexPath];
            NSString *currentFormat = self.availableFormats[indexPath.row];
            formatCell.titleLabel.text = currentFormat;
            formatCell.accessoryType = [self.selectedFormat isEqualToString:currentFormat] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            return formatCell;
        }
        default: {
            return nil;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JMSaveResourceSection *currentSection = self.sections[indexPath.section];
    if (currentSection.sectionType == JMSaveResourceSectionTypeFormat) {
        NSString *reportFormat = self.availableFormats[indexPath.row];
        if (![reportFormat isEqualToString:self.selectedFormat]) {
            self.selectedFormat = reportFormat;
            NSIndexSet *sections = [NSIndexSet indexSetWithIndex:indexPath.section];
            [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

#pragma mark - JMSaveResourceNameCellDelegate
- (void)nameCell:(JMSaveResourceNameCell *)cell didChangeResourceName:(NSString *)resourceName
{
    self.resourceName = resourceName;
}

#pragma mark - Actions
- (IBAction)saveButtonTapped:(id)sender
{
    [self runSaveAction];
}

#pragma mark - Private
- (void)runSaveAction
{
    [self.view endEditing:YES];
    NSString *errorMessageString = nil;
    BOOL isValidresourceName = [JMUtils validateResourceName:self.resourceName errorMessage:&errorMessageString];
    self.errorString = errorMessageString;

    if (!self.errorString && isValidresourceName) {
        __weak typeof(self) weakSelf = self;
        [self verifyExportDataWithCompletion:^(BOOL success) {
            __strong typeof(self) strongSelf = weakSelf;
            if (success) {
                JMSavedResources *savedResource = [JMSavedResources savedResourceWithResourceName:strongSelf.resourceName format:strongSelf.selectedFormat resourceType:strongSelf.resourceType];
                JMExportResource *exportResource = [JMExportManager exportResourceWithName:strongSelf.resourceName format:strongSelf.selectedFormat];

                if (savedResource) {
                    strongSelf.errorString = JMCustomLocalizedString(@"resource_viewer_save_name_errmsg_notunique", nil);
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_error"
                                                                                                      message:@"resource_viewer_save_name_errmsg_notunique_rewrite"
                                                                                            cancelButtonTitle:@"dialog_button_cancel"
                                                                                      cancelCompletionHandler:nil];
                    __weak typeof(self) weakSelf = strongSelf;
                    [alertController addActionWithLocalizedTitle:@"dialog_button_ok" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                        __strong typeof(self) strongSelf = weakSelf;
                        [savedResource removeResource];
                        strongSelf.errorString = nil;
                        
                        [strongSelf saveResource];
                    }];
                    [strongSelf presentViewController:alertController animated:YES completion:nil];
                } else  if (exportResource) {
                    self.errorString = JMCustomLocalizedString(@"resource_viewer_save_name_errmsg_notunique", nil);
                    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_error"
                                                                                                      message:@"resource_viewer_save_name_errmsg_notunique_rewrite"
                                                                                            cancelButtonTitle:@"dialog_button_cancel"
                                                                                      cancelCompletionHandler:nil];
                    __weak typeof(self) weakSelf = self;
                    [alertController addActionWithLocalizedTitle:@"dialog_button_ok" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                        __strong typeof(self) strongSelf = weakSelf;
                        [[JMExportManager sharedInstance] cancelTaskForResource:exportResource];
                        strongSelf.errorString = nil;
                        
                        [strongSelf saveResource];
                    }];
                    [self presentViewController:alertController animated:YES completion:nil];
                } else {
                    [strongSelf saveResource];;
                }
            }
        }];
    }
}

- (void)verifyExportDataWithCompletion:(void(^)(BOOL success))completion
{
    if (completion) {
        completion(YES);
    }
}

- (void) saveResource
{
    if (self.errorString) { // Clear error messages
        self.errorString = nil;
        [self.tableView reloadData];
    }

    // Animation
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self.delegate resourceDidSavedSuccessfully];
    }];
    [self.navigationController popViewControllerAnimated:YES];
    [CATransaction commit];
}

- (JMSaveResourceSection *)sectionForType:(JMSaveResourceSectionType)sectionType
{
    for (JMSaveResourceSection *section in self.sections) {
        if (section.sectionType == sectionType) {
            return section;
        }
    }
    return nil;
}

- (void) reloadSectionForType:(JMSaveResourceSectionType)sectionType
{
    JMSaveResourceSection *section = [self sectionForType:sectionType];
    NSInteger rangeSectionIndex = [self.sections indexOfObject:section];
    NSIndexSet *sectionsForUpdate = [NSIndexSet indexSetWithIndex:rangeSectionIndex];
    [self.tableView reloadSections:sectionsForUpdate withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
