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

#import "JMDashboard.h"

#import "JMDashboardInputControlsVC.h"
#import "JMSingleSelectTableViewController.h"
#import "JMCancelRequestPopup.h"
#import "JSRESTBase+JSRESTDashboard.h"


@interface JMDashboardInputControlsVC () <UITableViewDelegate, UITableViewDataSource, JMInputControlCellDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *applyButton;
@property (nonatomic, copy) NSArray <JSInputControlDescriptor *> *chagedInputControls;
@property (nonatomic, copy) NSArray <JSInputControlDescriptor *> *currentInputControls;
@end

@implementation JMDashboardInputControlsVC

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = JMCustomLocalizedString(@"report_viewer_options_title", nil);
    self.view.backgroundColor = [[JMThemesManager sharedManager] viewBackgroundColor];

    // Remove extra separators
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    // setup "Run Report" button
    self.applyButton.backgroundColor = [[JMThemesManager sharedManager] reportOptionsRunReportButtonBackgroundColor];
    [self.applyButton setTitleColor:[[JMThemesManager sharedManager] reportOptionsRunReportButtonTextColor]
                           forState:UIControlStateNormal];
    [self.applyButton setTitle:JMCustomLocalizedString(@"dialog_button_applyUpdate", nil)
                      forState:UIControlStateNormal];

    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;

    self.chagedInputControls = [NSMutableArray array];
    self.currentInputControls = [[NSArray alloc] initWithArray:self.dashboard.inputControls copyItems:YES];

    [self setupNavigationItems];
}

#pragma mark - Actions
- (IBAction)applyButtonDidTap:(id)sender
{
    [self applyAction];
}

- (void)backButtonTapped:(id)sender
{
    self.dashboard.inputControls = self.currentInputControls;
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private API
- (BOOL) validateInputControls
{
    for (JSInputControlDescriptor *descriptor in self.dashboard.inputControls) {
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
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 0;
    if ([self.dashboard.inputControls count]) {
        numberOfSections++;
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

    titleLabel.text = [sectionTitle uppercaseString];
    [titleLabel sizeToFit];

    UIView *headerView = [UIView new];
    [headerView addSubview:titleLabel];
    [headerView addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:headerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant: -8.0]];

    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dashboard.inputControls.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    JSInputControlDescriptor *inputControlDescriptor = self.dashboard.inputControls[indexPath.row];
    JMInputControlCell *icCell = (JMInputControlCell *)cell;
    [icCell setInputControlDescriptor:inputControlDescriptor];

    cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));

    [cell setNeedsLayout];
    [cell layoutIfNeeded];

    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    height += 1;

    return (height > 44) ? height : 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    JSInputControlDescriptor *inputControlDescriptor = self.dashboard.inputControls[indexPath.row];
    JMInputControlCell *icCell = (JMInputControlCell *)cell;
    [icCell setInputControlDescriptor:inputControlDescriptor];
    icCell.delegate = self;

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
    if (![self.chagedInputControls containsObject:cell.inputControlDescriptor]) {
        NSMutableArray *changedInputControls = [self.chagedInputControls mutableCopy];
        [changedInputControls addObject:cell.inputControlDescriptor];
        self.chagedInputControls = changedInputControls;
    }

    [self.tableView reloadData];
}

#pragma mark - Private

- (NSString *)cellIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    JSInputControlDescriptor *inputControlDescriptor = self.dashboard.inputControls[indexPath.row];
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

- (void)updatedInputControlsValuesWithCompletion:(void(^)(BOOL dataIsValid))completion
{
    [JMCancelRequestPopup presentWithMessage:@"status_loading"
                                 cancelBlock:^(void) {
                                     [self.restClient cancelAllRequests];
                                     [self backButtonTapped:nil];
                                 }];

    NSMutableArray *parametersArray = [NSMutableArray array];
    for (JSInputControlDescriptor *inputControlDescriptor in self.chagedInputControls) {

        JSDashboardParameter *dashboardParameter = [[JSDashboardParameter alloc] initWithName:inputControlDescriptor.uuid
                                                                               value:inputControlDescriptor.selectedValues];

        NSString *URI = [inputControlDescriptor.uri stringByReplacingOccurrencesOfString:@"repo:" withString:@""];
        
        JSParameter *parameter = [JSParameter parameterWithName:URI value:@[dashboardParameter]];
        [parametersArray addObject:parameter];
    }
    
    [self.restClient updatedInputControlValuesForDashboardWithParameters:parametersArray completionBlock:^(JSOperationResult * _Nullable result) {
        [JMCancelRequestPopup dismiss];
        if (result.error) {
            if (result.error.code == JSSessionExpiredErrorCode) {
                [JMUtils showLoginViewAnimated:YES completion:nil];
            } else {
                [JMUtils presentAlertControllerWithError:result.error completion:nil];
            }
        } else {
            for (JSInputControlState *state in result.objects) {
                for (JSInputControlDescriptor *inputControl in self.chagedInputControls) {
                    if ([state.uuid isEqualToString:inputControl.uuid]) {
                        inputControl.state = state;
                        break;
                    }
                }
            }
        }
        [self.tableView reloadData];
        if (completion) {
            completion([self validateInputControls]);
        }
    }];
}

#pragma mark - Helpers
- (void)applyAction
{
    if ([self validateInputControls]) { // Local validation
        [self updatedInputControlsValuesWithCompletion:^(BOOL dataIsValid) { // Server validation
            if (dataIsValid) {
                if (self.exitBlock) {
                    self.exitBlock([self.chagedInputControls count] > 0);
                }
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    } else {
        [self.tableView reloadData];
    }
}

- (void)setupNavigationItems
{
    UIBarButtonItem *backItem = [self backButtonWithTitle:nil
                                                   target:self
                                                   action:@selector(backButtonTapped:)];
    self.navigationItem.leftBarButtonItem = backItem;
}

@end