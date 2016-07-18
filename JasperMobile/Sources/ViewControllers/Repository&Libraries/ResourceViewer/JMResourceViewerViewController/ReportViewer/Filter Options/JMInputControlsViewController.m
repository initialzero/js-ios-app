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


#import "JMInputControlsViewController.h"
#import "JMSingleSelectTableViewController.h"

#import "JMCancelRequestPopup.h"
#import "JMReportOptionsCell.h"
#import "JMInputControlCell.h"
#import "JMReportOptionsViewController.h"
#import "JSReportOption.h"

@interface JMInputControlsViewController () <UITableViewDelegate, UITableViewDataSource, JMInputControlCellDelegate, JMReportOptionsViewControllerDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *runReportButton;

@property (nonatomic, strong) JSReportOption *currentReportOption;
@property (nonatomic, strong) NSArray *currentInputControls;

@property (nonatomic, strong) JSResourceLookup *parentFolderLookup;

@end

@implementation JMInputControlsViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = JMCustomLocalizedString(@"report_viewer_options_title", nil);
    self.view.backgroundColor = [[JMThemesManager sharedManager] viewBackgroundColor];
    
    // Remove extra separators
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // setup "Run Report" button
    self.runReportButton.backgroundColor = [[JMThemesManager sharedManager] reportOptionsRunReportButtonBackgroundColor];
    [self.runReportButton setTitleColor:[[JMThemesManager sharedManager] reportOptionsRunReportButtonTextColor]
                               forState:UIControlStateNormal];
    [self.runReportButton setTitle:JMCustomLocalizedString(@"dialog_button_run_report", nil)
                          forState:UIControlStateNormal];

    [self setupReportOptions];
    if (![JMUtils isServerProEdition]) {
        self.navigationItem.rightBarButtonItem = nil;
    }

    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
}

#pragma mark - Actions
- (IBAction)runReportAction:(id)sender
{
    [self runReport];
}

- (void)backButtonTapped:(id)sender
{
    if (self.completionBlock) {
        self.completionBlock(nil);
    }
}

- (void)createReportOptionTapped:(id)sender
{
    if ([self validateInputControls]) { // Local validation
        __weak typeof(self) weakSelf = self;
        [self checkParentFolderPermissionWithCompletion:^(BOOL reportOptionsEditingAvailable) {
            __strong typeof(self) strongSelf = weakSelf;
            if (reportOptionsEditingAvailable) {
                __weak typeof(self) weakSelf = strongSelf;
                [strongSelf updatedInputControlsValuesWithCompletion:^(BOOL dataIsValid) { // Server validation
                    __strong typeof(self) strongSelf = weakSelf;
                    if (dataIsValid) {
                        __weak typeof(self) weakSelf = strongSelf;
                        UIAlertController *alertController = [UIAlertController alertTextDialogueControllerWithLocalizedTitle:@"report_viewer_report_options_new_option_title"
                                                                                                                      message:nil
                                                                                                textFieldConfigurationHandler:nil
                                                                                                        textValidationHandler:^NSString * _Nonnull(NSString * _Nullable text) {
                                                                                                            NSString *errorMessage = nil;
                                                                                                            __strong typeof(self) strongSelf = weakSelf;
                                                                                                            if (strongSelf) {
                                                                                                                [JMUtils validateResourceName:text errorMessage:&errorMessage];
                                                                                                                if (!errorMessage && ![strongSelf isUniqueNewReportOptionName:text]) {
                                                                                                                    errorMessage = JMCustomLocalizedString(@"report_viewer_report_options_new_option_title_alreadyexist", nil);
                                                                                                                }
                                                                                                            }
                                                                                                            return errorMessage;
                                                                                                        } textEditCompletionHandler:^(NSString * _Nullable text) {
                                                                                                            __strong typeof(self) strongSelf = weakSelf;
                                                                                                            [strongSelf createNewReportOptionWithName:text];
                                                                                                        }];
                        [strongSelf presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            } else {
                NSString *errorMessage = JMCustomLocalizedString(@"report_viewer_report_options_create_permission_error", nil);
                NSError *error = [NSError errorWithDomain:@"dialod_title_error" code:0 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
                [JMUtils presentAlertControllerWithError:error completion:nil];
            }
        }];
    } else {
        [self.tableView reloadData];
    }
}

- (void)deleteReportOptionTapped:(id)sender
{
    __weak typeof(self) weakSelf = self;
    [self checkParentFolderPermissionWithCompletion:^(BOOL reportOptionsEditingAvailable) {
        __strong typeof(self) strongSelf = weakSelf;
        if (reportOptionsEditingAvailable) {
                NSString *confirmationMessage = [NSString stringWithFormat:JMCustomLocalizedString(@"report_viewer_report_options_remove_confirmation_message", nil), strongSelf.currentReportOption.label];
                UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_confirmation"
                                                                                                  message:confirmationMessage
                                                                                        cancelButtonTitle:@"dialog_button_cancel"
                                                                                  cancelCompletionHandler:nil];
                __weak typeof(self) weakSelf = strongSelf;
                [alertController addActionWithLocalizedTitle:@"dialog_button_ok" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                    __strong typeof(self) strongSelf = weakSelf;
                    if (strongSelf) {
                        [JMCancelRequestPopup presentWithMessage:@"status_loading" cancelBlock:nil];
                        [self.restClient deleteReportOption:strongSelf.currentReportOption withReportURI:strongSelf.report.reportURI completion:^(JSOperationResult * _Nullable result) {
                            [JMCancelRequestPopup dismiss];
                            if (result.error) {
                                if (result.error.code == JSSessionExpiredErrorCode) {
                                    [JMUtils showLoginViewAnimated:YES completion:nil];
                                } else {
                                    [JMUtils presentAlertControllerWithError:result.error completion:nil];
                                }
                            } else {
                                [strongSelf.report removeReportOption:strongSelf.currentReportOption];
                                strongSelf.currentReportOption = [strongSelf.report.reportOptions firstObject];
                            }
                        }];
                    }
                }];
                [strongSelf presentViewController:alertController animated:YES completion:nil];
            } else {
                NSString *errorMessage = JMCustomLocalizedString(@"report_viewer_report_options_remove_permission_error", nil);
                NSError *error = [NSError errorWithDomain:@"dialod_title_error" code:NSNotFound userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
                [JMUtils presentAlertControllerWithError:error completion:nil];
            }
        }];
}

#pragma mark - Private API
- (void)runReport
{
    [self.view endEditing:YES];
    BOOL isNoneReportOption = [self isNoneReportOption:self.currentReportOption];

    if (isNoneReportOption) { // NONE OPTION
        BOOL isReportParametersChanged = [self isReportParametersChanged];
        if (isReportParametersChanged) {
            if ([self validateInputControls]) { // Local validation
                [self updatedInputControlsValuesWithCompletion:^(BOOL dataIsValid) { // Server validation
                    if (dataIsValid) {
                        if (self.completionBlock) {
                            self.completionBlock(self.currentReportOption);
                        }
                    } else {
                        [self.tableView reloadData];
                    }
                }];
            } else {
                [self.tableView reloadData];
            }
        } else {
            if (self.completionBlock) {
                self.completionBlock(nil);
            }
        }
    } else { // SOME REPORT OPTION
        BOOL isReportOptionChanged = [self isReportOptionChanged];
        if (isReportOptionChanged) {
            if (self.completionBlock) {
                self.completionBlock(self.currentReportOption);
            }
        } else {
            if (self.completionBlock) {
                self.completionBlock(nil);
            }
        }
    }
}

- (BOOL)isNoneReportOption:(JSReportOption *)reportOption
{
    // TODO: consider other properties
    return reportOption.uri == nil;
}

- (BOOL)isReportOptionChanged
{
    return (![self.report.activeReportOption isEqual: self.currentReportOption]);
}

- (BOOL)isReportParametersChanged
{
    // TODO: add implementation
    return YES;

//    for (JSInputControlDescriptor *inputControl in self.report.activeReportOption.inputControls) {
//        for (JSInputControlDescriptor *internalInputControl in self.currentInputControls) {
//            if ([inputControl.uuid isEqualToString:internalInputControl.uuid]) {
//                NSSet *inputControlSelectedValues = [NSSet setWithArray:[inputControl selectedValues]];
//                NSSet *internalInputControlSelectedValues = [NSSet setWithArray:[internalInputControl selectedValues]];
//                if (![inputControlSelectedValues isEqualToSet:internalInputControlSelectedValues]) {
//                    return YES;
//                }
//                break;
//            }
//        }
//    }
//    return NO;
}

- (BOOL) validateInputControls
{
    for (JSInputControlDescriptor *descriptor in self.currentInputControls) {
        if ([[descriptor errorString] length]) {
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id destinationViewController = segue.destinationViewController;
    if ([destinationViewController respondsToSelector:@selector(setCell:)]) {
        [destinationViewController setCell:sender];
    }

    if ([destinationViewController isKindOfClass:[JMReportOptionsViewController class]]) {
        JMReportOptionsViewController *reportOptionsVC = (JMReportOptionsViewController *)destinationViewController;
        reportOptionsVC.listOfValues = self.report.reportOptions;
        reportOptionsVC.delegate = self;
        reportOptionsVC.selectedReportOption = self.currentReportOption;
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 0;
    if ([self isMultyReportOptions]) {
        numberOfSections ++;
    }
    if ([self.currentInputControls count]) {
        numberOfSections ++;
    }
    return numberOfSections;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [[JMThemesManager sharedManager] tableViewCellTitleFont].lineHeight + 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *titleLabel = [UILabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [[JMThemesManager sharedManager] tableViewCellTitleFont];
    titleLabel.textColor = [[JMThemesManager sharedManager] reportOptionsTitleLabelTextColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    NSString *sectionTitle = JMCustomLocalizedString(@"report_viewer_options_title", nil);
    if ([self isMultyReportOptions] && section == 0) {
        sectionTitle = JMCustomLocalizedString(@"report_viewer_report_options_title", nil);
    }
    titleLabel.text = [sectionTitle uppercaseString];
    [titleLabel sizeToFit];
    
    UIView *headerView = [UIView new];
    [headerView addSubview:titleLabel];
    [headerView addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant: -8.0]];
    
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isMultyReportOptions] && section == 0) {
        return 1;
    }
    return self.currentInputControls.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];
 
    // This solution was taken form http://stackoverflow.com/a/18746930/2523825
    
    // Use the dictionary of offscreen cells to get a cell for the reuse identifier, creating a cell and storing
    // it in the dictionary if one hasn't already been added for the reuse identifier.
    // WARNING: Don't call the table view's dequeueReusableCellWithIdentifier: method here because this will result
    // in a memory leak as the cell is created but never returned from the tableView:cellForRowAtIndexPath: method!
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    // Configure the cell for this indexPath
    if ([self isMultyReportOptions] && indexPath.section == 0) {
        JMReportOptionsCell *roCell = (JMReportOptionsCell *)cell;
        roCell.titleLabel.text = self.currentReportOption.label;
    } else {
        JSInputControlDescriptor *inputControlDescriptor = self.currentInputControls[indexPath.row];
        JMInputControlCell *icCell = (JMInputControlCell *)cell;
        [icCell setInputControlDescriptor:inputControlDescriptor];
    }
    
    // The cell's width must be set to the same size it will end up at once it is in the table view.
    // This is important so that we'll get the correct height for different table view widths, since our cell's
    // height depends on its width due to the multi-line UILabel word wrapping. Don't need to do this above in
    // -[tableView:cellForRowAtIndexPath:] because it happens automatically when the cell is used in the table view.
    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
    // NOTE: if you are displaying a section index (e.g. alphabet along the right side of the table view), or
    // if you are using a grouped table view style where cells have insets to the edges of the table view,
    // you'll need to adjust the cell.bounds.size.width to be smaller than the full width of the table view we just
    // set it to above. See http://stackoverflow.com/questions/3647242 for discussion on the section index width.
    
    // Do the layout pass on the cell, which will calculate the frames for all the views based on the constraints
    // (Note that the preferredMaxLayoutWidth is set on multi-line UILabels inside the -[layoutSubviews] method
    // in the UITableViewCell subclass
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    // Get the actual height required for the cell
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    // Add an extra point to the height to account for the cell separator, which is added between the bottom
    // of the cell's contentView and the bottom of the table view cell.
    height += 1;
    
    return (height > 44) ? height : 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Configure the cell for this indexPath
    if ([self isMultyReportOptions] && indexPath.section == 0) {
        JMReportOptionsCell *roCell = (JMReportOptionsCell *)cell;
        roCell.titleLabel.text = self.currentReportOption.label;
    } else {
        JSInputControlDescriptor *inputControlDescriptor = self.currentInputControls[indexPath.row];
        JMInputControlCell *icCell = (JMInputControlCell *)cell;
        [icCell setInputControlDescriptor:inputControlDescriptor];
        icCell.delegate = self;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - JMInputControlCellDelegate
- (void)reloadTableViewCell:(JMInputControlCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)updatedInputControlsValuesWithDescriptor:(JSInputControlDescriptor *)descriptor
{
    if (descriptor.slaveDependencies.count) {
        [JMCancelRequestPopup presentWithMessage:@"status_loading"
                                     cancelBlock:^(void) {
                                         [self.restClient cancelAllRequests];
                                         [self.navigationController popViewControllerAnimated:YES];
                                     }];

        [self updatedInputControlsValuesWithCompletion:^(BOOL dataIsValid) {
            [JMCancelRequestPopup dismiss];
        }];
    }
}

- (void)inputControlCellDidChangedValue:(JMInputControlCell *)cell
{
    if ([self.report.reportOptions indexOfObject:self.currentReportOption] != NSNotFound ||
        self.report.activeReportOption == self.currentReportOption) {
        _currentReportOption = [JSReportOption defaultReportOption];
        _currentReportOption.inputControls = self.currentInputControls;

        [self updateRightBurButtonItem];
        [self.tableView reloadData];
    }
}

#pragma mark - JMReportOptionsViewControllerDelegate
- (void)reportOptionsViewController:(JMReportOptionsViewController *)controller didSelectOption:(JSReportOption *)option
{
    if (self.currentReportOption != option) {
        JSReportOption *oldActiveReportOption = self.currentReportOption;
        self.currentReportOption = option;
        
        if (![self.currentInputControls count]) {
            [JMCancelRequestPopup presentWithMessage:@"status_loading" cancelBlock:nil];
            
            __weak typeof(self)weakSelf = self;
            [self.restClient inputControlsForReport:self.currentReportOption.uri
                                     selectedValues:nil
                                    completionBlock:^(JSOperationResult *result) {
                                        __strong typeof(self) strongSelf = weakSelf;
                                        [JMCancelRequestPopup dismiss];
                                        if (result.error) {
                                            if (result.error.code == JSSessionExpiredErrorCode) {
                                                [JMUtils showLoginViewAnimated:YES completion:nil];
                                            } else {
                                                __weak typeof(self) weakSelf = strongSelf;
                                                [JMUtils presentAlertControllerWithError:result.error completion:^{
                                                    __strong typeof(self) strongSelf = weakSelf;
                                                    strongSelf.currentReportOption = oldActiveReportOption;
                                                }];
                                            }
                                        } else {
                                            NSMutableArray *visibleInputControls = [NSMutableArray array];
                                            for (JSInputControlDescriptor *inputControl in result.objects) {
                                                if (inputControl.visible.boolValue) {
                                                    [visibleInputControls addObject:inputControl];
                                                }
                                            }
                                            strongSelf.currentReportOption.inputControls = visibleInputControls;
                                            strongSelf.currentInputControls = [[NSArray alloc] initWithArray:visibleInputControls copyItems:YES];
                                            [strongSelf.tableView reloadData];
                                        }
                                    }];
        }
    }
}

#pragma mark - Private

- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    if ([self isMultyReportOptions] && indexPath.section == 0) {
        return @"ReportOptionsCell";
    }
    JSInputControlDescriptor *inputControlDescriptor = self.currentInputControls[indexPath.row];
    NSDictionary *inputControlDescriptorTypes = @{
                                                  @(kJS_ICD_TYPE_BOOL)                     : @"BooleanCell",
                                                  @(kJS_ICD_TYPE_SINGLE_VALUE_TEXT)        : @"TextEditCell",
                                                  @(kJS_ICD_TYPE_SINGLE_VALUE_NUMBER)      : @"NumberCell",
                                                  @(kJS_ICD_TYPE_SINGLE_VALUE_DATE)        : @"DateCell",
                                                  @(kJS_ICD_TYPE_SINGLE_VALUE_TIME)        : @"TimeCell",
                                                  @(kJS_ICD_TYPE_SINGLE_VALUE_DATETIME)    : @"DateTimeCell",
                                                  @(kJS_ICD_TYPE_SINGLE_SELECT)            : @"SingleSelectCell",
                                                  @(kJS_ICD_TYPE_SINGLE_SELECT_RADIO)      : @"SingleSelectCell",
                                                  @(kJS_ICD_TYPE_MULTI_SELECT)             : @"MultiSelectCell",
                                                  @(kJS_ICD_TYPE_MULTI_SELECT_CHECKBOX)    : @"MultiSelectCell",
                                                  };

    return inputControlDescriptorTypes[@(inputControlDescriptor.type)];
}

- (BOOL)isMultyReportOptions
{
    return [self.report.reportOptions count] > 1;
}

- (void)setupReportOptions
{
    self.currentReportOption = self.report.activeReportOption;
    if (![self isMultyReportOptions]) {
        [JMCancelRequestPopup presentWithMessage:@"status_loading" cancelBlock:nil];
        
        __weak typeof(self) weakSelf = self;
        [self.restClient reportOptionsForReportURI:self.report.reportURI completion:^(JSOperationResult * _Nullable result) {
            [JMCancelRequestPopup dismiss];
            if (result.error) {
                if (result.error.code == JSSessionExpiredErrorCode) {
                    [JMUtils showLoginViewAnimated:YES completion:nil];
                }
            } else {
                __strong typeof(self) strongSelf = weakSelf;
                NSMutableArray *reportOptions = [NSMutableArray array];
                for (id reportOption in result.objects) {
                    if ([reportOption isKindOfClass:[JSReportOption class]] && [reportOption identifier]) {
                        [reportOptions addObject:reportOption];
                    }
                }
                [strongSelf.report addReportOptions:reportOptions];
                [strongSelf.tableView reloadData];
            }
        }];
    }
}

- (void)setCurrentReportOption:(JSReportOption *)currentReportOption
{
    if (_currentReportOption != currentReportOption) {
        _currentReportOption = currentReportOption;
        _currentInputControls = [[NSArray alloc] initWithArray:currentReportOption.inputControls copyItems:YES];
        [self updateRightBurButtonItem];
        [self.tableView reloadData];
    }
}

- (void)updatedInputControlsValuesWithCompletion:(void(^)(BOOL dataIsValid))completion
{
    NSMutableArray *selectedValues = [NSMutableArray array];
    NSMutableArray *allInputControls = [NSMutableArray array];
    // Get values from Input Controls
    for (JSInputControlDescriptor *descriptor in self.currentInputControls) {
        [selectedValues addObject:[[JSReportParameter alloc] initWithName:descriptor.uuid
                                                                    value:descriptor.selectedValues]];
        [allInputControls addObject:descriptor.uuid];
    }
    
    [JMCancelRequestPopup presentWithMessage:@"status_loading"
                                 cancelBlock:^(void) {
                                     [self.restClient cancelAllRequests];
                                     if (self.completionBlock) {
                                         self.completionBlock(nil);
                                     }
                                 }];
    NSString *resourceURI = self.currentReportOption.uri;
    if (![resourceURI length]) {
        resourceURI = self.report.resourceLookup.uri;
    }
    
    [self.restClient updatedInputControlsValues:resourceURI
                                            ids:allInputControls
                                 selectedValues:selectedValues
                                completionBlock:^(JSOperationResult *result) {
                                    [JMCancelRequestPopup dismiss];

                                    if (result.error) {
                                        if (result.error.code == JSSessionExpiredErrorCode) {
                                            [JMUtils showLoginViewAnimated:YES completion:nil];
                                        } else {
                                            [JMUtils presentAlertControllerWithError:result.error completion:nil];
                                        }
                                    } else {
                                        for (JSInputControlState *state in result.objects) {
                                            for (JSInputControlDescriptor *inputControl in self.currentInputControls) {
                                                if ([state.uuid isEqualToString:inputControl.uuid]) {
                                                    inputControl.state = state;
                                                    break;
                                                }
                                            }
                                        }
                                        [self.tableView reloadData];
                                        if (completion) {
                                            completion([self validateInputControls]);
                                        }
                                    }
                                }];
}

- (BOOL)isReportOptionsEditingAvailable
{
    NSInteger permissionMask = self.parentFolderLookup.permissionMask.integerValue;
    return (permissionMask & JSPermissionMask_Administration || permissionMask & JSPermissionMask_Write);
}

- (void)checkParentFolderPermissionWithCompletion:(void(^)(BOOL reportOptionsEditingAvailable))completion
{
    if (self.parentFolderLookup) {
        if (completion) {
            completion([self isReportOptionsEditingAvailable]);
        }
    } else {
        [JMCancelRequestPopup presentWithMessage:@"status_loading"
                                     cancelBlock:^(void) {
                                         [self.restClient cancelAllRequests];
                                     }];

        NSString *resourceFolderURI = [self.report.resourceLookup.uri stringByDeletingLastPathComponent];
        [self.restClient resourceLookupForURI:resourceFolderURI resourceType:kJS_WS_TYPE_FOLDER
                                   modelClass:[JSResourceLookup class]
                              completionBlock:^(JSOperationResult *result) {
                                  [JMCancelRequestPopup dismiss];
                                  
                                  if (result.error) {
                                      if (result.error.code == JSSessionExpiredErrorCode) {
                                          [JMUtils showLoginViewAnimated:YES completion:nil];
                                      } else {
                                          [JMUtils presentAlertControllerWithError:result.error completion:nil];
                                      }
                                  } else {
                                      self.parentFolderLookup = [result.objects firstObject];
                                      if (completion) {
                                          completion([self isReportOptionsEditingAvailable]);
                                      }
                                  }
                              }];
    }
}

- (void)updateRightBurButtonItem
{
    if ([JMUtils isServerProEdition]) {
        if ([self currentReportOptionIsExisted]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete_item"] style:UIBarButtonItemStyleDone target:self action:@selector(deleteReportOptionTapped:)];
        } else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save_item"] style:UIBarButtonItemStyleDone target:self action:@selector(createReportOptionTapped:)];
        }
    }
}

- (void)createNewReportOptionWithName:(NSString *)name
{
    NSArray *reportParameters = [JSUtils reportParametersFromInputControls:self.currentInputControls];

    [JMCancelRequestPopup presentWithMessage:@"status_loading" cancelBlock:nil];
    NSString *newReportOptionName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    __weak typeof(self) weakSelf = self;
    [self.restClient createReportOptionWithReportURI:self.report.resourceLookup.uri optionLabel:newReportOptionName reportParameters:reportParameters completion:^(JSOperationResult * _Nullable result) {
        [JMCancelRequestPopup dismiss];
        if (result.error) {
            if (result.error.code == JSSessionExpiredErrorCode) {
                [JMUtils showLoginViewAnimated:YES completion:nil];
            } else {
                [JMUtils presentAlertControllerWithError:result.error completion:nil];
            }
        } else {
            JSReportOption *reportOption = [result.objects objectAtIndex:0];
            if (reportOption) {
                __strong typeof(self)strongSelf = weakSelf;
                reportOption.inputControls = strongSelf.currentInputControls;
                if (![strongSelf isUniqueNewReportOptionName:reportOption.label]) {
                    for (JSReportOption *existedReportOption in strongSelf.report.reportOptions) {
                        if ([reportOption.label isEqualToString:existedReportOption.label]) {
                            [strongSelf.report removeReportOption:existedReportOption];
                            break;
                        }
                    }
                }
                [strongSelf.report addReportOptions:@[reportOption]];
                strongSelf.currentReportOption= reportOption;
            }
        }
    }];
}

- (BOOL)isUniqueNewReportOptionName:(NSString *)name
{
    for (JSReportOption *reportOption in self.report.reportOptions) {
        if ([name isEqualToString:reportOption.label]) {
            return NO;
        }
    }
    return YES;
}

- (BOOL) currentReportOptionIsExisted
{
    NSInteger indexOfCurrentOption = [self.report.reportOptions indexOfObject:self.currentReportOption];
    return (indexOfCurrentOption != NSNotFound && indexOfCurrentOption != 0);

}
@end
