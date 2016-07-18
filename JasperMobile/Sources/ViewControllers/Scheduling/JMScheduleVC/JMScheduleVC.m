/*
 * TIBCO JasperMobile for iOS
 * Copyright © 2005-2016 TIBCO Software, Inc. All rights reserved.
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
//  JMScheduleVC.m
//  TIBCO JasperMobile
//

#import "JMScheduleVC.h"
#import "JMScheduleManager.h"
#import "JMScheduleCell.h"
#import "JMScheduleBoolenCell.h"
#import "JMScheduleVCSection.h"
#import "JMScheduleVCRow.h"
#import "JMMultiSelectedItemsVC.h"
#import "JMSelectedItem.h"
#import "JMCancelRequestPopup.h"
#import "ALToastView.h"
#import "JMResource.h"

@interface JMScheduleVC () <UITableViewDataSource, UITableViewDelegate, JMScheduleCellDelegate, JMScheduleBoolenCellDelegate>
@property (nonatomic, strong, readwrite) JSScheduleMetadata *scheduleMetadata;
@property (assign, nonatomic) BOOL isNewScheduleMetadata;

@property (strong, nonatomic) UIDatePicker *datePickerForStartDate;
@property (strong, nonatomic) UIDatePicker *datePickerForEndDate;
@property (nonatomic, strong) NSArray <JMScheduleVCSection *> *sections;
@property (weak, nonatomic) IBOutlet UIButton *createJobButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UITableViewCell *tappedCell;
@property (strong, nonatomic) JSScheduleTrigger *originTrigger;
@end

@implementation JMScheduleVC

#pragma mark - Custom Accessors
- (UIDatePicker *)datePickerForStartDate
{
    if (!_datePickerForStartDate) {
        _datePickerForStartDate = [UIDatePicker new];

        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:[self currentTrigger].timezone];
        _datePickerForStartDate.timeZone = timeZone;

        JSScheduleTrigger *trigger = [self currentTrigger];
        if (!trigger.startDate || [trigger.startDate isKindOfClass:[NSNull class]]) {
            _datePickerForStartDate.date = [NSDate date];
        } else {
            _datePickerForStartDate.date = trigger.startDate;
        }
        [_datePickerForStartDate addTarget:self
                       action:@selector(updateDate:)
             forControlEvents:UIControlEventValueChanged];
    }
    return _datePickerForStartDate;
}

- (UIDatePicker *)datePickerForEndDate
{
    if (!_datePickerForEndDate) {
        _datePickerForEndDate = [UIDatePicker new];

        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:[self currentTrigger].timezone];
        _datePickerForEndDate.timeZone = timeZone;

        JSScheduleTrigger *trigger = [self currentTrigger];
        if (!trigger.endDate || [trigger.endDate isKindOfClass:[NSNull class]]) {
            _datePickerForEndDate.date = [NSDate date];
        } else {
            _datePickerForEndDate.date = trigger.endDate;
        }
        [_datePickerForEndDate addTarget:self
                        action:@selector(updateDate:)
              forControlEvents:UIControlEventValueChanged];
    }
    return _datePickerForEndDate;
}

#pragma mark - UIViewController LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Schedule";
    self.view.backgroundColor = [[JMThemesManager sharedManager] viewBackgroundColor];

    [self createSections];

    [self.createJobButton setTitle:@"Apply"
                          forState:UIControlStateNormal];

    // TODO: need make this copy?
    self.originTrigger = self.scheduleMetadata.trigger;
}

#pragma mark - Actions
- (void)updateDate:(UIDatePicker *)sender
{
    NSDate *newDate = sender.date;
    [self updateCurrentDateCellWithDate:newDate];
}

- (void)setStartDate:(UIBarButtonItem *)sender
{
    NSDate *newDate = self.datePickerForStartDate.date;
    JSScheduleTrigger *trigger = [self currentTrigger];
    trigger.startDate = newDate;

    [[self startDateCell].valueTextField resignFirstResponder];
}

- (void)setEndDate:(UIBarButtonItem *)sender
{
    NSDate *newDate = self.datePickerForEndDate.date;
    JSScheduleTrigger *trigger = [self currentTrigger];
    trigger.endDate = newDate;

    if (trigger.type == JSScheduleTriggerTypeSimple) {
        JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
        simpleTrigger.occurrenceCount = @-1;
    }

    [[self endDateCell].valueTextField resignFirstResponder];

    [self setupEndPolicySection];
    NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeScheduleEnd];
    [self.tableView reloadSections:sectionIndecies
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)cancelEditStartDate:(UIBarButtonItem *)sender
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    [self updateCurrentDateCellWithDate:trigger.startDate];

    [[self startDateCell].valueTextField resignFirstResponder];
}

- (void)cancelEditEndDate:(UIBarButtonItem *)sender
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    [self updateCurrentDateCellWithDate:trigger.endDate];

    [[self endDateCell].valueTextField resignFirstResponder];
}

- (void)setRecurrenceCount:(UIBarButtonItem *)sender
{
    JMScheduleCell *cell = [self recurrenceCountCell];
    NSAssert(cell != nil, @"number of runs cell is nil");

    [cell.valueTextField resignFirstResponder];
}

- (void)setOccurrenceCount:(UIBarButtonItem *)sender
{
    JMScheduleCell *cell = [self numberOfRunsCell];
    NSAssert(cell != nil, @"occurrence count cell is nil");

    [cell.valueTextField resignFirstResponder];
}

- (void)setCalendarHours:(UIBarButtonItem *)sender
{
    JMScheduleCell *cell = [self calendarHoursCell];
    NSAssert(cell != nil, @"celendar hours cell is nil");

    [cell.valueTextField resignFirstResponder];
}

- (void)setCalendarMinutes:(UIBarButtonItem *)sender
{
    JMScheduleCell *cell = [self calendarMinutesCell];
    NSAssert(cell != nil, @"celendar minutes cell is nil");

    [cell.valueTextField resignFirstResponder];
}

- (void)updateCurrentDateCellWithDate:(NSDate *)date
{
    NSAssert(self.tappedCell != nil, @"date cell is nil");
    JMScheduleCell *scheduleCell = (JMScheduleCell *) self.tappedCell;
    scheduleCell.valueTextField.text = [self dateStringFromDate:date];
}

- (IBAction)selectFormat:(id)sender
{
    NSArray *availableFormats = @[
            kJS_CONTENT_TYPE_HTML,
            kJS_CONTENT_TYPE_PDF,
            kJS_CONTENT_TYPE_XLS
    ];

    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:JMCustomLocalizedString(@"schedules_new_job_outputFormat", nil)
                                                                                      message:nil
                                                                            cancelButtonTitle:@"dialog_button_cancel"
                                                                      cancelCompletionHandler:nil];

    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeOutputOptions];
    JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeFormat];
    NSInteger rowFormatCell = [section.rows indexOfObject:row];
    NSIndexPath *formatCellIndexPath = [NSIndexPath indexPathForRow:rowFormatCell
                                                          inSection:JMNewScheduleVCSectionTypeOutputOptions];
    JMScheduleCell *formatCell = [self.tableView cellForRowAtIndexPath:formatCellIndexPath];

    NSAssert(formatCell != nil, @"Cell is nil");

    for (NSString *format in availableFormats) {
        [alertController addActionWithLocalizedTitle:format style:UIAlertActionStyleDefault
                                             handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                                                 self.scheduleMetadata.outputFormats = @[format.uppercaseString];
                                                 formatCell.valueTextField.text = self.scheduleMetadata.outputFormats.firstObject;
                                             }];
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)selectRepeatInterval
{
    NSArray *intervals = @[
            @(JSScheduleSimpleTriggerRecurrenceIntervalTypeMinute),
            @(JSScheduleSimpleTriggerRecurrenceIntervalTypeHour),
            @(JSScheduleSimpleTriggerRecurrenceIntervalTypeDay),
            @(JSScheduleSimpleTriggerRecurrenceIntervalTypeWeek)
    ];

    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:JMCustomLocalizedString(@"schedules_new_job_recurrenceIntervalUnit", nil)
                                                                                      message:nil
                                                                            cancelButtonTitle:@"dialog_button_cancel"
                                                                      cancelCompletionHandler:nil];

    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeRecurrence];
    JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeRepeatTimeInterval];
    NSInteger cellIndex = [section.rows indexOfObject:row];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellIndex
                                                    inSection:JMNewScheduleVCSectionTypeRecurrence];
    JMScheduleCell *cell = [self.tableView cellForRowAtIndexPath:cellIndexPath];

    NSAssert(cell != nil, @"Repeat Interval Cell is nil");

    JSScheduleTrigger *trigger = [self currentTrigger];
    NSAssert(trigger.type == JSScheduleTriggerTypeSimple, @"Should be simple trigger");

    JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *)trigger;
    for (NSNumber *interval in intervals) {
        JSScheduleSimpleTriggerRecurrenceIntervalType intervalType = (JSScheduleSimpleTriggerRecurrenceIntervalType) interval.integerValue;
        NSString *title = [self stringValueForRecurrenceType:intervalType];
        [alertController addActionWithLocalizedTitle:title
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                                                 simpleTrigger.recurrenceIntervalUnit = intervalType;
                                                 cell.valueTextField.text = title;
                                             }];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)selectTrigger
{
    NSArray *triggerTypes = @[
            @(JSScheduleTriggerTypeNone),
            @(JSScheduleTriggerTypeSimple),
            @(JSScheduleTriggerTypeCalendar),
    ];

    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:JMCustomLocalizedString(@"schedules_new_job_repeat_type_alert_title", nil)
                                                                                      message:nil
                                                                            cancelButtonTitle:@"dialog_button_cancel"
                                                                      cancelCompletionHandler:nil];

    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeRecurrence];
    JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeRepeatType];
    NSInteger cellIndex = [section.rows indexOfObject:row];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellIndex
                                                    inSection:JMNewScheduleVCSectionTypeRecurrence];
    JMScheduleCell *cell = [self.tableView cellForRowAtIndexPath:cellIndexPath];
    NSAssert(cell != nil, @"Recurrence Type Cell is nil");

    for (NSNumber *triggerTypeValue in triggerTypes) {
        JSScheduleTriggerType triggerType = (JSScheduleTriggerType) triggerTypeValue.integerValue;
        NSString *title = [self stringValueForTriggerType:triggerType];
        [alertController addActionWithLocalizedTitle:title
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                                                 cell.valueTextField.text = title;

                                                 // assigning a trigger
                                                 self.scheduleMetadata.trigger = [self triggerForType:triggerType];
                                                 // updating representation of the trigger
                                                 [self setupStartPolicySection];
                                                 [self setupRecurrenceSection];
                                                 [self setupEndPolicySection];

                                                 NSMutableIndexSet *sectionIndecies = [NSMutableIndexSet indexSet];
                                                 [sectionIndecies addIndex:JMNewScheduleVCSectionTypeScheduleStart];
                                                 [sectionIndecies addIndex:JMNewScheduleVCSectionTypeRecurrence];
                                                 [sectionIndecies addIndex:JMNewScheduleVCSectionTypeScheduleEnd];
                                                 [self.tableView reloadSections:sectionIndecies
                                                               withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)selectMonths
{
    JMMultiSelectedItemsVC *multiValuesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"JMMultiSelectedItemsVC"];
    multiValuesVC.title = @"Select months";

    JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) [self currentTrigger];
    NSAssert(calendarTrigger.type == JSScheduleTriggerTypeCalendar, @"should be calendar trigger");

    NSMutableArray *availableItems = [NSMutableArray new];
    for (NSInteger i = 1; i <=12; i++) {
        NSNumber *month = @(i);
        BOOL isSelected = NO;
        if ([calendarTrigger.months containsObject:month]) {
            isSelected = YES;
        }
        JMSelectedItem *item = [JMSelectedItem itemWithTitle:[self stringValueForMonth:month]
                                                       value:month
                                                    selected:isSelected];
        [availableItems addObject:item];
    }

    multiValuesVC.availableItems = availableItems;
    multiValuesVC.exitBlock = ^(NSArray *selectedItems) {
        NSMutableArray *selectedMonths = [NSMutableArray new];
        for (JMSelectedItem *item in selectedItems) {
            if (item.selected) {
                [selectedMonths addObject:item.value];
            }
        }
        [selectedMonths sortUsingComparator:^NSComparisonResult(NSNumber *item1, NSNumber *item2) {
            return [item1 compare:item2];
        }];
        calendarTrigger.months = selectedMonths;
        NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeRecurrence];
        [self.tableView reloadSections:sectionIndecies
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    [self.navigationController pushViewController:multiValuesVC animated:YES];
}

- (void)selectDays
{
    JMMultiSelectedItemsVC *multiValuesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"JMMultiSelectedItemsVC"];
    multiValuesVC.title = @"Select days";

    JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) [self currentTrigger];
    NSAssert(calendarTrigger.type == JSScheduleTriggerTypeCalendar, @"should be calendar trigger");

    NSMutableArray *availableItems = [NSMutableArray new];
    for (NSInteger i = 1; i <=7; i++) {
        NSNumber *day = @(i);
        BOOL isSelected = NO;
        if ([calendarTrigger.weekDays containsObject:day]) {
            isSelected = YES;
        }
        JMSelectedItem *item = [JMSelectedItem itemWithTitle:[self stringValueForDay:day]
                                                       value:day
                                                    selected:isSelected];
        [availableItems addObject:item];
    }

    multiValuesVC.availableItems = availableItems;
    multiValuesVC.exitBlock = ^(NSArray *selectedItems) {
        NSMutableArray *selectedDays = [NSMutableArray new];
        for (JMSelectedItem *item in selectedItems) {
            if (item.selected) {
                [selectedDays addObject:item.value];
            }
        }
        [selectedDays sortUsingComparator:^NSComparisonResult(NSNumber *item1, NSNumber *item2) {
            return [item1 compare:item2];
        }];
        calendarTrigger.weekDays = selectedDays;
        NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeRecurrence];
        [self.tableView reloadSections:sectionIndecies
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    [self.navigationController pushViewController:multiValuesVC animated:YES];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    JMScheduleVCSection *section = self.sections[indexPath.section];
    JMScheduleVCRow *row = section.rows[indexPath.row];
    if (row.type == JMScheduleVCRowTypeFormat) {
        [self selectFormat:nil];
    } else if (row.type == JMScheduleVCRowTypeRepeatTimeInterval) {
        [self selectRepeatInterval];
    } else if (row.type == JMScheduleVCRowTypeRepeatType) {
        [self selectTrigger];
    } else if (row.type == JMScheduleVCRowTypeCalendarSelectedMonths) {
        [self selectMonths];
    } else if (row.type == JMScheduleVCRowTypeCalendarSelectedDays) {
        [self selectDays];
    } else {
        id cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[JMScheduleCell class]]) {
            JMScheduleCell *scheduleCell = cell;
            [scheduleCell.valueTextField becomeFirstResponder];
        }
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [[JMThemesManager sharedManager] tableViewCellTitleFont].lineHeight + 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = 60;
    JMScheduleVCSection *scheduleVCSection = self.sections[indexPath.section];
    JMScheduleVCRow *row = scheduleVCSection.rows[indexPath.row];
    if (row.errorMessage.length > 0) {
        cellHeight += 35;
    }
    return cellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *titleLabel = [UILabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [[JMThemesManager sharedManager] tableViewCellTitleFont];
    titleLabel.textColor = [[JMThemesManager sharedManager] reportOptionsTitleLabelTextColor];
    titleLabel.backgroundColor = [UIColor clearColor];

    JMScheduleVCSection *scheduleVCSection = self.sections[section];
    NSString *sectionTitle = scheduleVCSection.title;

    titleLabel.text = [sectionTitle uppercaseString];
    [titleLabel sizeToFit];

    UIView *headerView = [UIView new];
    [headerView addSubview:titleLabel];
    [headerView addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:headerView
                                                           attribute:NSLayoutAttributeBottom
                                                          multiplier:1.0
                                                            constant: -8.0]];
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    JMScheduleVCSection *scheduleVCSection = self.sections[section];
    NSArray *rows = scheduleVCSection.rows;

    return rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JMScheduleVCSection *section = self.sections[indexPath.section];
    JMScheduleVCRow *row = section.rows[indexPath.row];
    UITableViewCell *cell;

    switch(row.type) {
        case JMScheduleVCRowTypeLabel: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeDescription: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeOutputFileURI: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeOutputFolderURI: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeFormat: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.userInteractionEnabled = NO;
            break;
        }
        case JMScheduleVCRowTypeStartDate: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.inputView = self.datePickerForStartDate;
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForCellWithDoneAction:@selector(setStartDate:)
                                                                                   cancelAction:@selector(cancelEditStartDate:)];
            break;
        }
        case JMScheduleVCRowTypeEndDate: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.inputView = self.datePickerForEndDate;
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForCellWithDoneAction:@selector(setEndDate:)
                                                                                   cancelAction:@selector(cancelEditEndDate:)];
            break;
        }
        case JMScheduleVCRowTypeTimeZone: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.userInteractionEnabled = NO;
            break;
        }
        case JMScheduleVCRowTypeStartImmediately: {
            cell = [self scheduleBooleanCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeRepeatType: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.userInteractionEnabled = NO;
            break;
        }
        case JMScheduleVCRowTypeRepeatCount: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForCellWithAction:@selector(setRecurrenceCount:)];
            break;
        }
        case JMScheduleVCRowTypeRepeatTimeInterval: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.userInteractionEnabled = NO;
            break;
        }
        case JMScheduleVCRowTypeRunIndefinitely: {
            cell = [self scheduleBooleanCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeNumberOfRuns: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForCellWithAction:@selector(setOccurrenceCount:)];
            break;
        }
        case JMScheduleVCRowTypeCalendarEveryMonth: {
            cell = [self scheduleBooleanCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeCalendarSelectedMonths: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.userInteractionEnabled = NO;
            break;
        }
        case JMScheduleVCRowTypeCalendarEveryDay: {
            cell = [self scheduleBooleanCellForIndexPath:indexPath row:row];
            break;
        }
        case JMScheduleVCRowTypeCalendarSelectedDays: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.userInteractionEnabled = NO;
            break;
        }
        case JMScheduleVCRowTypeCalendarHours: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForCellWithAction:@selector(setCalendarHours:)];
            break;
        }
        case JMScheduleVCRowTypeCalendarMinutes: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForCellWithAction:@selector(setCalendarMinutes:)];
            break;
        }
        case JMScheduleVCRowTypeCalendarDatesInMonth:
            // TODO: implement in next release.
            break;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

#pragma mark - Save
- (IBAction)makeAction:(UIButton *)sender
{
    [self.view endEditing:YES];

    [JMCancelRequestPopup presentWithMessage:@"status_validation"];
    BOOL isJobValid = [self validateJob];
    [self.tableView reloadData];
    [JMCancelRequestPopup dismiss];

    if (isJobValid) {
        __weak typeof(self) weakSelf = self;
        [JMCancelRequestPopup presentWithMessage:@"status_validation" cancelBlock:^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf.restClient cancelAllRequests];
        }];
        
        JMScheduleCompletion completion = ^(JSScheduleMetadata *newScheduleMetadata, NSError *error) {
            [JMCancelRequestPopup dismiss];
            __strong typeof(self) strongSelf = weakSelf;
            if (newScheduleMetadata) {
                if (strongSelf.exitBlock) {
                    strongSelf.exitBlock(newScheduleMetadata);
                }
                
                [strongSelf.navigationController popViewControllerAnimated:YES];
                NSString *toastMessageKey = self.isNewScheduleMetadata ? @"schedules_created_success" : @"schedules_updated_success";
                [ALToastView toastInView:self.navigationController.view
                                withText:JMCustomLocalizedString(toastMessageKey, nil)];
            } else {
                [JMUtils presentAlertControllerWithError:error completion:nil];
            }
        };
        
        if (self.isNewScheduleMetadata) {
            [[JMScheduleManager sharedManager] createScheduleWithData:self.scheduleMetadata
                                                           completion:completion];
        } else {
            [[JMScheduleManager sharedManager] updateSchedule:self.scheduleMetadata
                                                   completion:completion];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark - JMNewScheduleCellDelegate
- (void)scheduleCellDidStartChangeValue:(JMScheduleCell *)cell
{
    self.tappedCell = cell;
}

- (void)scheduleCellDidEndChangeValue:(JMScheduleCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    JMScheduleVCSection *section = self.sections[indexPath.section];
    JMScheduleVCRow *row = section.rows[indexPath.row];
    row.errorMessage = nil;

    JSScheduleTrigger *trigger = [self currentTrigger];

    NSString *trimmedValue = [cell.valueTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    if (row.type == JMScheduleVCRowTypeLabel) {
        self.scheduleMetadata.label = trimmedValue;
    } else if (row.type == JMScheduleVCRowTypeDescription) {
        self.scheduleMetadata.scheduleDescription = trimmedValue;
    } else if (row.type == JMScheduleVCRowTypeOutputFileURI) {
        self.scheduleMetadata.baseOutputFilename = trimmedValue;
    } else if (row.type == JMScheduleVCRowTypeOutputFolderURI) {
        self.scheduleMetadata.folderURI = trimmedValue;
    } else if (row.type == JMScheduleVCRowTypeRepeatCount) {
        NSAssert([trigger class] == [JSScheduleSimpleTrigger class], @"Should be simple trigger");
        if ([self isStringContainsOnlyDigits:trimmedValue]) {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *)trigger;
            simpleTrigger.recurrenceInterval = @(trimmedValue.integerValue);
            row.errorMessage = nil;
        } else {
            // show error message in cell
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_repeat_count_invalid_characters", nil);
        }
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (row.type == JMScheduleVCRowTypeNumberOfRuns) {
        NSAssert(trigger.type == JSScheduleTriggerTypeSimple, @"Should be simple trigger");
        if ([self isStringContainsOnlyDigits:trimmedValue]) {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            simpleTrigger.occurrenceCount = @(trimmedValue.integerValue);
            simpleTrigger.endDate = nil;
            row.errorMessage = nil;
        } else {
            // show error message in cell
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_repeat_count_invalid_characters", nil);
        }
        NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeScheduleEnd];
        [self.tableView reloadSections:sectionIndecies
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (row.type == JMScheduleVCRowTypeCalendarHours) {
        NSAssert(trigger.type == JSScheduleTriggerTypeCalendar, @"Should be simple trigger");
        JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *)trigger;

        NSString *stringWithoutSpaces = [trimmedValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        calendarTrigger.hours = stringWithoutSpaces;
    } else if (row.type == JMScheduleVCRowTypeCalendarMinutes) {
        NSAssert(trigger.type == JSScheduleTriggerTypeCalendar, @"Should be simple trigger");

        NSString *stringWithoutSpaces = [trimmedValue stringByReplacingOccurrencesOfString:@" " withString:@""];
        JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *)trigger;
        calendarTrigger.minutes = stringWithoutSpaces;
    }
    self.tappedCell = nil;
}

#pragma mark - JMNewScheduleBoolenCellDelegate
- (void)scheduleBoolenCell:(JMScheduleBoolenCell *)cell didChangeValue:(BOOL)newValue
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    JMScheduleVCSection *section = self.sections[indexPath.section];

    JSScheduleTrigger *trigger = [self currentTrigger];
    if (section.type == JMNewScheduleVCSectionTypeScheduleStart) {
        if (newValue) {
            trigger.startType = JSScheduleTriggerStartTypeImmediately;
            trigger.startDate = nil;

            // Update Rows
            [section hideRowWithType:JMScheduleVCRowTypeStartDate];
        } else {
            trigger.startType = JSScheduleTriggerStartTypeAtDate;
            trigger.startDate = [NSDate date];

            // Update Rows
            [section showRowWithType:JMScheduleVCRowTypeStartDate];
        }

        NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeScheduleStart];
        [self.tableView reloadSections:sectionIndecies withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (section.type == JMNewScheduleVCSectionTypeScheduleEnd) {
        NSAssert([trigger isKindOfClass:[JSScheduleSimpleTrigger class]], @"Should be simple trigger");
        JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
        if (newValue) {
            simpleTrigger.type = JSScheduleTriggerTypeNone;
            simpleTrigger.occurrenceCount = @-1;
            simpleTrigger.endDate = nil;

            // Update Rows
            [section hideRowWithType:JMScheduleVCRowTypeEndDate];
            [section hideRowWithType:JMScheduleVCRowTypeNumberOfRuns];
        } else {
            simpleTrigger.type = JSScheduleTriggerTypeSimple;
            simpleTrigger.occurrenceCount = @-1;
            simpleTrigger.endDate = [NSDate date];

            // Update Rows
            [section showRowWithType:JMScheduleVCRowTypeEndDate];
            [section showRowWithType:JMScheduleVCRowTypeNumberOfRuns];
        }

        NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeScheduleEnd];
        [self.tableView reloadSections:sectionIndecies withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (section.type == JMNewScheduleVCSectionTypeRecurrence) {
        JMScheduleVCRow *row = [self rowForCell:cell];
        NSAssert(row != nil, @"schedule row is nil");
        if (row.type == JMScheduleVCRowTypeCalendarEveryMonth) {
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            NSAssert(calendarTrigger.type == JSScheduleTriggerTypeCalendar, @"should be calendar trigger");
            if (newValue) {
                calendarTrigger.months = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12];

                [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedMonths];
            } else {
                calendarTrigger.months = @[@1]; // TODO: which should be default value

                [section showRowWithType:JMScheduleVCRowTypeCalendarSelectedMonths];
            }
        } else if(row.type == JMScheduleVCRowTypeCalendarEveryDay) {
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            NSAssert(calendarTrigger.type == JSScheduleTriggerTypeCalendar, @"should be calendar trigger");
            if (newValue) {
                calendarTrigger.daysType = JSScheduleCalendarTriggerDaysTypeAll;

                [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedDays];
            } else {
                calendarTrigger.daysType = JSScheduleCalendarTriggerDaysTypeWeek;

                [section showRowWithType:JMScheduleVCRowTypeCalendarSelectedDays];
            }
        }

        NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeRecurrence];
        [self.tableView reloadSections:sectionIndecies withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Setup
- (void)createNewScheduleMetadataWithResourceLookup:(nonnull JMResource *)resource
{
    self.scheduleMetadata = [[JMScheduleManager sharedManager] createNewScheduleMetadataWithResourceLookup:resource];
    self.isNewScheduleMetadata = YES;
}

- (void)updateScheduleMetadata:(nonnull JSScheduleMetadata *)metaData
{
    self.scheduleMetadata = metaData;
    self.isNewScheduleMetadata = NO;
}

- (void)createSections
{
    self.sections = @[
            [self mainSection],
            [self outupOptionsSection],
            [self schedleStartSection],
            [self recurrenceSection],
            [self schedleEndSection],
    ];

    [self setupStartPolicySection];
    [self setupRecurrenceSection];
    [self setupEndPolicySection];
}

#pragma mark - Setup Sections

- (JMScheduleVCSection *)mainSection
{
    JMScheduleVCSection *mainSection = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeMain
                                                                              rows:@[
                                                                                      [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeLabel],
                                                                                      [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeDescription],
                                                                              ]];
    return mainSection;
}

- (JMScheduleVCSection *)outupOptionsSection
{
    JMScheduleVCSection *outputOptionsSection = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeOutputOptions
                                                                                       rows:@[
                                                                                               [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeOutputFileURI],
                                                                                               [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeOutputFolderURI],
                                                                                               [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeFormat],
                                                                                       ]];
    return outputOptionsSection;
}

- (JMScheduleVCSection *)schedleStartSection
{
    JMScheduleVCSection *scheduleSection = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeScheduleStart
                                                                                  rows:@[
                                                                                          [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeStartImmediately],
                                                                                          [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeStartDate hidden:YES],
                                                                                          //[JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeTimeZone],
                                                                                  ]];
    return scheduleSection;
}

- (JMScheduleVCSection *)recurrenceSection
{
    // TODO: add all needed fields
    JMScheduleVCSection *recurrenceSection;
    recurrenceSection = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeRecurrence
                                                               rows:@[
                                                                       // simple trigger
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeRepeatType],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeRepeatCount hidden:YES],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeRepeatTimeInterval hidden:YES],
                                                                       // calendar trigger
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeCalendarEveryMonth hidden:YES],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeCalendarSelectedMonths hidden:YES],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeCalendarEveryDay hidden:YES],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeCalendarSelectedDays hidden:YES],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeCalendarHours hidden:YES],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeCalendarMinutes hidden:YES],
                                                               ]];
    return recurrenceSection;
}

- (JMScheduleVCSection *)schedleEndSection
{
    JMScheduleVCSection *section = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeScheduleEnd
                                                                          rows:@[
                                                                                  [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeRunIndefinitely hidden:YES],
                                                                                  [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeNumberOfRuns hidden:YES],
                                                                                  [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeEndDate hidden:YES],
                                                                          ]];
    return section;
}

- (JMScheduleVCSection *)holidaysSection
{
    JMScheduleVCSection *section = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeHolidays
                                                                          rows:@[]];;
    return section;
}

#pragma mark - Setup of sections
- (void)setupStartPolicySection
{
    JSScheduleTrigger *trigger = [self currentTrigger];

    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeScheduleStart];
    BOOL isStartImmediately = trigger.startType == JSScheduleTriggerStartTypeImmediately;
    if (isStartImmediately) {
        [section hideRowWithType:JMScheduleVCRowTypeStartDate];
    } else {
        [section showRowWithType:JMScheduleVCRowTypeStartDate];
    }
}

- (void)setupRecurrenceSection
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeRecurrence];
    switch(trigger.type) {
        case JSScheduleTriggerTypeNone: {
            // disable simple trigger
            [section hideRowWithType:JMScheduleVCRowTypeRepeatCount];
            [section hideRowWithType:JMScheduleVCRowTypeRepeatTimeInterval];
            // disable calendar trigger
            [section hideRowWithType:JMScheduleVCRowTypeCalendarEveryMonth];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedMonths];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarEveryDay];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedDays];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarHours];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarMinutes];
            break;
        }
        case JSScheduleTriggerTypeSimple: {
            // enable simple trigger
            [section showRowWithType:JMScheduleVCRowTypeRepeatCount];
            [section showRowWithType:JMScheduleVCRowTypeRepeatTimeInterval];
            // disable calendar trigger
            [section hideRowWithType:JMScheduleVCRowTypeCalendarEveryMonth];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedMonths];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarEveryDay];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedDays];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarHours];
            [section hideRowWithType:JMScheduleVCRowTypeCalendarMinutes];
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            // disable simple trigger
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            [section hideRowWithType:JMScheduleVCRowTypeRepeatCount];
            [section hideRowWithType:JMScheduleVCRowTypeRepeatTimeInterval];

            // enable calendar trigger
            // months
            [section showRowWithType:JMScheduleVCRowTypeCalendarEveryMonth];
            if (calendarTrigger.months.count < 12) {
                [section showRowWithType:JMScheduleVCRowTypeCalendarSelectedMonths];
            } else {
                [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedMonths];
            }

            // days
            [section showRowWithType:JMScheduleVCRowTypeCalendarEveryDay];
            if (calendarTrigger.daysType == JSScheduleCalendarTriggerDaysTypeAll) {
                [section hideRowWithType:JMScheduleVCRowTypeCalendarSelectedDays];
            } else {
                [section showRowWithType:JMScheduleVCRowTypeCalendarSelectedDays];
            }

            // hours and minutes
            [section showRowWithType:JMScheduleVCRowTypeCalendarHours];
            [section showRowWithType:JMScheduleVCRowTypeCalendarMinutes];
            break;
        }
    }
}

- (void)setupEndPolicySection
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeScheduleEnd];
    switch(trigger.type) {
        case JSScheduleTriggerTypeNone: {
            [section hideRowWithType:JMScheduleVCRowTypeRunIndefinitely];
            [section hideRowWithType:JMScheduleVCRowTypeNumberOfRuns];
            [section hideRowWithType:JMScheduleVCRowTypeEndDate];
            break;
        }
        case JSScheduleTriggerTypeSimple: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            [section showRowWithType:JMScheduleVCRowTypeRunIndefinitely];
            NSInteger occurenceCount = simpleTrigger.occurrenceCount.integerValue;
            if (occurenceCount == -1 && !simpleTrigger.endDate) {
                [section hideRowWithType:JMScheduleVCRowTypeNumberOfRuns];
                [section hideRowWithType:JMScheduleVCRowTypeEndDate];
            } else {
                [section showRowWithType:JMScheduleVCRowTypeNumberOfRuns];
                [section showRowWithType:JMScheduleVCRowTypeEndDate];
            }
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            [section hideRowWithType:JMScheduleVCRowTypeRunIndefinitely];
            [section hideRowWithType:JMScheduleVCRowTypeNumberOfRuns];
            [section showRowWithType:JMScheduleVCRowTypeEndDate];
            break;
        }
    }
}

#pragma mark - Helpers

- (NSString *)dateStringFromDate:(NSDate *)date
{
    NSString *dateString;
    if (!date) {
        dateString = @"";
    } else {
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:[self currentTrigger].timezone];
        NSDateFormatter *formatter = [[JSDateFormatterFactory sharedFactory] formatterWithPattern:@"yyyy-MM-dd HH:mm" timeZone:timeZone];
        dateString = [formatter stringFromDate:date];
    }
    return dateString;
}

- (UIToolbar *)toolbarForCellWithAction:(SEL)action
{
    return [self toolbarForCellWithDoneAction:action cancelAction:NULL];
}

- (UIToolbar *)toolbarForCellWithDoneAction:(SEL)doneAction cancelAction:(SEL)cancelAction
{
    UIToolbar *toolbar = [UIToolbar new];
    [toolbar sizeToFit];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:doneAction];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    if (cancelAction != NULL) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                     target:self
                                                                                     action:cancelAction];
        [toolbar setItems:@[cancelButton, flexibleSpace, doneButton] animated:YES];
    } else {
        [toolbar setItems:@[flexibleSpace, doneButton] animated:YES];
    }
    return toolbar;
}

- (NSString *)stringValueForRecurrenceType:(JSScheduleSimpleTriggerRecurrenceIntervalType)recurrenceType
{
    NSString *stringValue;

    switch(recurrenceType) {
        case JSScheduleSimpleTriggerRecurrenceIntervalTypeNone: {
            stringValue = @"None";
            break;
        }
        case JSScheduleSimpleTriggerRecurrenceIntervalTypeMinute: {
            stringValue = @"Minutes";
            break;
        }
        case JSScheduleSimpleTriggerRecurrenceIntervalTypeHour: {
            stringValue = @"Hours";
            break;
        }
        case JSScheduleSimpleTriggerRecurrenceIntervalTypeDay: {
            stringValue = @"Days";
            break;
        }
        case JSScheduleSimpleTriggerRecurrenceIntervalTypeWeek: {
            stringValue = @"Weeks";
            break;
        }
    }

    return stringValue;
}

- (NSString *)stringValueForTriggerType:(JSScheduleTriggerType)repeatType
{
    NSString *stringValue;

    switch(repeatType) {
        case JSScheduleTriggerTypeNone: {
            stringValue = @"None";
            break;
        }
        case JSScheduleTriggerTypeSimple: {
            stringValue = @"Simple";
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            stringValue = @"Calendar";
            break;
        }
    }

    return stringValue;
}

#pragma mark - Validation
- (BOOL)validateJob
{
    BOOL isValidLabel = [self validateLabel];
    BOOL isValidOutputFileName = [self validateOutputFileName];
    BOOL isValidOutputFolderURI = [self validateOutputFolderURI];
    BOOL isValidRepeatCount = [self validateRepeatCount];
    BOOL isValidNumberOfRuns = [self validateNumberOfRuns];
    BOOL isValidStartDate = [self validateStartDate];
    BOOL isValidEndDate = [self validateEndDate];
    BOOL isValidCalendarHours = [self validateHoursForCalendarTrigger];
    BOOL isValidCalendarMinutes = [self validateMinutesForCalendarTrigger];
    BOOL isValidCalendarDays = [self validateWeekdaysForCalendarTrigger];
    BOOL isValidCalendarMonths = [self validateMonthsForCalendarTrigger];

    return (isValidLabel
            && isValidOutputFileName && isValidOutputFolderURI
            && isValidRepeatCount && isValidNumberOfRuns
            && isValidStartDate && isValidEndDate
            && isValidCalendarHours && isValidCalendarMinutes
            && isValidCalendarDays && isValidCalendarMonths);
}

- (BOOL)validateLabel
{
    BOOL isValid = YES;
    if (!self.scheduleMetadata.label.length) {
        isValid = NO;
        JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeMain];
        JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeLabel];
        row.errorMessage = JMCustomLocalizedString(@"schedules_error_empty_label", nil);
    }
    if (self.scheduleMetadata.label.length > 100) {
        isValid = NO;
        JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeMain];
        JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeLabel];
        row.errorMessage = JMCustomLocalizedString(@"schedules_error_length", nil);
    }
    return isValid;
}

- (BOOL)validateOutputFileName
{
    BOOL isValid = YES;
    if (!self.scheduleMetadata.baseOutputFilename.length) {
        isValid = NO;
        JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeOutputOptions];
        JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeOutputFileURI];
        row.errorMessage = JMCustomLocalizedString(@"schedules_error_empty_filename", nil);
    } else {
        NSArray *parts = [self.scheduleMetadata.baseOutputFilename componentsSeparatedByString:@" "];
        if (parts.count > 1) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeOutputOptions];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeOutputFileURI];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_empty_filename_invalid_characters", nil);
        }
        if (self.scheduleMetadata.baseOutputFilename.length > 100) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeOutputOptions];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeOutputFileURI];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_length", nil);
        }
    }
    return isValid;
}

- (BOOL)validateOutputFolderURI
{
    BOOL isValid = YES;
    if (!self.scheduleMetadata.folderURI.length) {
        isValid = NO;
        JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeOutputOptions];
        JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeOutputFolderURI];
        row.errorMessage = JMCustomLocalizedString(@"schedules_error_empty_output_folder", nil);
    }
    return isValid;
}

- (BOOL)validateRepeatCount
{
    BOOL isValid = YES;
    id trigger = [self currentTrigger];
    if ([trigger isKindOfClass:[JSScheduleSimpleTrigger class]]) {
        JSScheduleSimpleTrigger *simpleTrigger = trigger;
        if (simpleTrigger.recurrenceInterval && simpleTrigger.recurrenceInterval.integerValue == 0) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeRecurrence];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeRepeatCount];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_repeat_count_empty", nil);
        }
    }
    return isValid;
}

- (BOOL)validateNumberOfRuns
{
    BOOL isValid = YES;
    id trigger = [self currentTrigger];
    if ([trigger isKindOfClass:[JSScheduleSimpleTrigger class]]) {
        JSScheduleSimpleTrigger *simpleTrigger = trigger;
        if (simpleTrigger.occurrenceCount && simpleTrigger.occurrenceCount.integerValue == 0) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeScheduleEnd];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeNumberOfRuns];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_occurrence_count_empty", nil);
        }
    }
    return isValid;
}

- (BOOL)validateStartDate
{
    BOOL isValid = YES;

    NSDate *currentDate = [NSDate date];
    NSDate *startDate = [self currentTrigger].startDate;
    if (startDate && [startDate compare:currentDate] == NSOrderedAscending) {
        isValid = NO;
        JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeScheduleStart];
        JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeStartDate];
        row.errorMessage = JMCustomLocalizedString(@"schedules_error_date_past", nil);
    }

    return isValid;
}

- (BOOL)validateEndDate
{
    BOOL isValid = YES;

    NSDate *currentDate = [NSDate date];
    NSDate *endDate = [self currentTrigger].endDate;
    if (endDate && [endDate compare:currentDate] == NSOrderedAscending) {
        isValid = NO;
        JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeScheduleEnd];
        JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeEndDate];
        row.errorMessage = JMCustomLocalizedString(@"schedules_error_date_past", nil);
    }

    return isValid;
}

- (BOOL)validateHoursForCalendarTrigger
{
    BOOL isValid = YES;

    id trigger = [self currentTrigger];
    if ([trigger isKindOfClass:[JSScheduleCalendarTrigger class]]) {
        JSScheduleCalendarTrigger *calendarTrigger = trigger;
        // TODO: verify ranges (example 0 or '1-17' )
        if (!calendarTrigger.hours || calendarTrigger.hours.length == 0 || calendarTrigger.hours.integerValue < 0 || calendarTrigger.hours.integerValue > 23) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeRecurrence];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeCalendarHours];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_wrong_hours", nil);
        }
    }

    return isValid;
}

- (BOOL)validateMinutesForCalendarTrigger
{
    BOOL isValid = YES;

    id trigger = [self currentTrigger];
    if ([trigger isKindOfClass:[JSScheduleCalendarTrigger class]]) {
        JSScheduleCalendarTrigger *calendarTrigger = trigger;
        // TODO: verify ranges (example '0' or '0, 15, 30, 45')
        if (!calendarTrigger.minutes || calendarTrigger.minutes.length == 0 || calendarTrigger.minutes.integerValue < 0 || calendarTrigger.minutes.integerValue > 59) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeRecurrence];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeCalendarMinutes];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_wrong_minutes", nil);
        }
    }

    return isValid;
}

- (BOOL)validateWeekdaysForCalendarTrigger
{
    BOOL isValid = YES;
    id trigger = [self currentTrigger];
    if ([trigger isKindOfClass:[JSScheduleCalendarTrigger class]]) {
        JSScheduleCalendarTrigger *calendarTrigger = trigger;
        if (calendarTrigger.daysType == JSScheduleCalendarTriggerDaysTypeWeek && calendarTrigger.weekDays.count == 0) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeRecurrence];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeCalendarSelectedDays];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_empty_weekdays", nil);
        }
    }
    return isValid;
}

- (BOOL)validateMonthsForCalendarTrigger
{
    BOOL isValid = YES;
    id trigger = [self currentTrigger];
    if ([trigger isKindOfClass:[JSScheduleCalendarTrigger class]]) {
        JSScheduleCalendarTrigger *calendarTrigger = trigger;
        if (calendarTrigger.months.count == 0) {
            isValid = NO;
            JMScheduleVCSection *section = [self sectionWithType:JMNewScheduleVCSectionTypeRecurrence];
            JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeCalendarSelectedMonths];
            row.errorMessage = JMCustomLocalizedString(@"schedules_error_empty_months", nil);
        }
    }
    return isValid;
}

- (BOOL)isStringContainsOnlyDigits:(NSString *)string
{
    BOOL isOnlyDigits = YES;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]*$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];

    NSArray *matches = [regex matchesInString:string
                                      options:NSMatchingReportCompletion
                                        range:NSMakeRange(0, string.length)];
    if (!matches.count) {
        isOnlyDigits = NO;
    }
    return isOnlyDigits;
}

#pragma mark - Cell Helpers

- (JMScheduleCell *)startDateCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeScheduleStart
                                        andRow:JMScheduleVCRowTypeStartDate];
    return cell;
}

- (JMScheduleCell *)endDateCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeScheduleEnd
                                        andRow:JMScheduleVCRowTypeEndDate];
    return cell;
}

- (JMScheduleCell *)recurrenceCountCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeRecurrence
                                        andRow:JMScheduleVCRowTypeRepeatCount];
    return cell;
}

- (JMScheduleCell *)calendarHoursCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeRecurrence
                                        andRow:JMScheduleVCRowTypeCalendarHours];
    return cell;
}

- (JMScheduleCell *)calendarMinutesCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeRecurrence
                                        andRow:JMScheduleVCRowTypeCalendarMinutes];
    return cell;
}

- (JMScheduleCell *)numberOfRunsCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeScheduleEnd
                                        andRow:JMScheduleVCRowTypeNumberOfRuns];
    return cell;
}

- (JMScheduleCell *)cellInSection:(JMScheduleVCSectionType)sectionType andRow:(JMScheduleVCRowType)rowType
{
    JMScheduleVCSection *searchSection = [self sectionWithType:sectionType];
    JMScheduleVCRow *row = [searchSection rowWithType:rowType];
    NSInteger cellIndex = [searchSection.rows indexOfObject:row];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellIndex
                                                    inSection:sectionType];
    JMScheduleCell *cell = [self.tableView cellForRowAtIndexPath:cellIndexPath];
    return cell;
}

- (JMScheduleVCSection *)sectionWithType:(JMScheduleVCSectionType)sectionType
{
    JMScheduleVCSection *searchSection;
    for (JMScheduleVCSection *section in self.sections) {
        if (section.type == sectionType) {
            searchSection = section;
            break;
        }
    }
    return searchSection;
}

- (JMScheduleVCRow *)rowForCell:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    JMScheduleVCSection *section = self.sections[indexPath.section];
    JMScheduleVCRow *row = section.rows[indexPath.row];
    return row;
}

- (JMScheduleCell *)scheduleCellForIndexPath:(NSIndexPath *)indexPath row:(JMScheduleVCRow *)row
{
    JMScheduleCell *scheduleCell = [self.tableView dequeueReusableCellWithIdentifier:@"JMScheduleCell" forIndexPath:indexPath];
    scheduleCell.titleLabel.text = row.title;
    scheduleCell.valueTextField.text = [self propertyValueForRowType:row.type];
    scheduleCell.valueTextField.inputView = nil;
    scheduleCell.valueTextField.inputAccessoryView = nil;
    scheduleCell.valueTextField.keyboardType = UIKeyboardTypeDefault;
    scheduleCell.valueTextField.userInteractionEnabled = YES;
    scheduleCell.delegate = self;

    [scheduleCell showErrorMessage:row.errorMessage];

    return scheduleCell;
}

- (JMScheduleBoolenCell *)scheduleBooleanCellForIndexPath:(NSIndexPath *)indexPath row:(JMScheduleVCRow *)row
{
    JMScheduleBoolenCell *scheduleCell = [self.tableView dequeueReusableCellWithIdentifier:@"JMScheduleBoolenCell" forIndexPath:indexPath];
    scheduleCell.titleLabel.text = row.title;
    scheduleCell.uiSwitch.on = [self booleanValueForRowType:row.type];
    scheduleCell.delegate = self;
    return scheduleCell;
}

- (NSString *)propertyValueForRowType:(JMScheduleVCRowType)type
{
    NSString *propertyValue;

    JSScheduleTrigger *trigger = [self currentTrigger];

    if (type == JMScheduleVCRowTypeLabel) {
        propertyValue = self.scheduleMetadata.label;
    } else if (type == JMScheduleVCRowTypeDescription) {
        propertyValue = self.scheduleMetadata.scheduleDescription;
    } else if (type == JMScheduleVCRowTypeOutputFileURI) {
        propertyValue = self.scheduleMetadata.baseOutputFilename;
    }  else if (type == JMScheduleVCRowTypeOutputFolderURI) {
        propertyValue = self.scheduleMetadata.folderURI;
    } else if (type == JMScheduleVCRowTypeFormat) {
        // TODO: extend for using several formats
        propertyValue = self.scheduleMetadata.outputFormats.firstObject;
    } else if (type == JMScheduleVCRowTypeStartDate) {
        propertyValue = [self dateStringFromDate:trigger.startDate];
    } else if (type == JMScheduleVCRowTypeEndDate) {
        propertyValue = [self dateStringFromDate:trigger.endDate];
    } else if (type == JMScheduleVCRowTypeTimeZone) {
        propertyValue = trigger.timezone;
    }

    switch (trigger.type) {
        case JSScheduleTriggerTypeNone: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            if (type == JMScheduleVCRowTypeRepeatType) {
                propertyValue = [self stringValueForTriggerType:JSScheduleTriggerTypeNone];
            } else if (type == JMScheduleVCRowTypeRepeatCount) {
                propertyValue = simpleTrigger.recurrenceInterval.stringValue;
            } else if (type == JMScheduleVCRowTypeRepeatTimeInterval) {
                propertyValue = [self stringValueForRecurrenceType:simpleTrigger.recurrenceIntervalUnit];
            }
            break;
        }
        case JSScheduleTriggerTypeSimple: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            if (type == JMScheduleVCRowTypeRepeatType) {
                propertyValue = [self stringValueForTriggerType:JSScheduleTriggerTypeSimple];
            } else if (type == JMScheduleVCRowTypeRepeatCount) {
                propertyValue = simpleTrigger.recurrenceInterval.stringValue;
            } else if (type == JMScheduleVCRowTypeRepeatTimeInterval) {
                propertyValue = [self stringValueForRecurrenceType:simpleTrigger.recurrenceIntervalUnit];
            } else if (type == JMScheduleVCRowTypeEndDate) {
                [self dateStringFromDate:simpleTrigger.endDate];
            } else if (type == JMScheduleVCRowTypeNumberOfRuns) {
                propertyValue = (simpleTrigger.occurrenceCount.integerValue == -1) ? @"" : simpleTrigger.occurrenceCount.stringValue;
            }
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            if (type == JMScheduleVCRowTypeRepeatType) {
                propertyValue = [self stringValueForTriggerType:JSScheduleTriggerTypeCalendar];
            } else if (type == JMScheduleVCRowTypeCalendarHours) {
                propertyValue = [calendarTrigger.hours stringByReplacingOccurrencesOfString:@"," withString:@", "];
            } else if (type == JMScheduleVCRowTypeCalendarMinutes) {
                propertyValue = [calendarTrigger.minutes stringByReplacingOccurrencesOfString:@"," withString:@", "];
            } else if (type == JMScheduleVCRowTypeCalendarSelectedDays) {
                NSString *weekDays = @"";
                for (NSNumber *weekDayNumber in calendarTrigger.weekDays) {
                    weekDays = [weekDays stringByAppendingFormat:@"%@", [self stringValueForDay:weekDayNumber]];
                    BOOL isLastDay = ([calendarTrigger.weekDays indexOfObject:weekDayNumber] == calendarTrigger.weekDays.count - 1);
                    if (!isLastDay) {
                        weekDays = [weekDays stringByAppendingString:@", "];
                    }
                }
                propertyValue = weekDays;
            } else if (type == JMScheduleVCRowTypeCalendarSelectedMonths) {
                NSString *months = @"";
                for (NSNumber *monthNumber in calendarTrigger.months) {
                    months = [months stringByAppendingFormat:@"%@", [self stringValueForMonth:monthNumber]];
                    BOOL isLastMonth = ([calendarTrigger.months indexOfObject:monthNumber] == calendarTrigger.months.count - 1);
                    if (!isLastMonth) {
                        months = [months stringByAppendingString:@", "];
                    }
                }
                propertyValue = months;
            }
            break;
        }
    }
    return propertyValue;
}

- (BOOL)booleanValueForRowType:(JMScheduleVCRowType)type
{
    BOOL boolenValue = NO;
    JSScheduleTrigger *trigger = [self currentTrigger];
    switch (trigger.type) {
        case JSScheduleTriggerTypeNone:
        case JSScheduleTriggerTypeSimple: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            if (type == JMScheduleVCRowTypeStartImmediately) {
                boolenValue = simpleTrigger.startType == JSScheduleTriggerStartTypeImmediately;
            } else if (type == JMScheduleVCRowTypeRunIndefinitely) {
                NSInteger occurrenceCount = simpleTrigger.occurrenceCount.integerValue;
                boolenValue = (occurrenceCount == -1) && !trigger.endDate;
            }
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            if (type == JMScheduleVCRowTypeStartImmediately) {
                boolenValue = calendarTrigger.startType == JSScheduleTriggerStartTypeImmediately;
            } else if (type == JMScheduleVCRowTypeCalendarEveryMonth) {
                boolenValue = calendarTrigger.months.count == 12;
            } else if (type == JMScheduleVCRowTypeCalendarEveryDay) {
                boolenValue = calendarTrigger.daysType == JSScheduleCalendarTriggerDaysTypeAll;
            }
            break;
        }
    }
    return boolenValue;
}

#pragma mark - Trigger
- (JSScheduleTrigger *)currentTrigger
{
    JSScheduleTrigger *trigger = self.scheduleMetadata.trigger;
    return trigger;
}

- (JSScheduleTrigger *)triggerForType:(JSScheduleTriggerType)type
{
    JSScheduleTrigger *trigger;
    // TODO:
    // in editing mode, we need save origin trigger
    // when an user changing trigger type:
    //   if new trigger - take default
    //   if existing trigger - take origin without changes
    switch(type) {
        case JSScheduleTriggerTypeNone: {
            trigger = self.originTrigger.type == type ? self.originTrigger : [[JMScheduleManager sharedManager] defaultNoneTrigger];
            break;
        }
        case JSScheduleTriggerTypeSimple: {
            trigger = self.originTrigger.type == type ? self.originTrigger : [[JMScheduleManager sharedManager] defaultSimpleTrigger];
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            trigger = self.originTrigger.type == type ? self.originTrigger : [[JMScheduleManager sharedManager] defaultCalendarTrigger];
            break;
        }
    }
    return trigger;
}

#pragma mark - Days And Months
- (NSString *)stringValueForDay:(NSNumber *)day
{
    NSString *stringValue;
    switch(day.integerValue) {
        case 1: {
            stringValue = @"Sun";
            break;
        }
        case 2: {
            stringValue = @"Mon";
            break;
        }
        case 3: {
            stringValue = @"Tue";
            break;
        }
        case 4: {
            stringValue = @"Wed";
            break;
        }
        case 5: {
            stringValue = @"Thu";
            break;
        }
        case 6: {
            stringValue = @"Fri";
            break;
        }
        case 7: {
            stringValue = @"Sat";
            break;
        }
        default:
            NSCAssert(NO, @"wrong day: %@", day);
    }
    return stringValue;
}

- (NSString *)stringValueForMonth:(NSNumber *)month
{
    NSString *stringValue;
    switch(month.integerValue) {
        case 1: {
            stringValue = @"Jan";
            break;
        }
        case 2: {
            stringValue = @"Feb";
            break;
        }
        case 3: {
            stringValue = @"Mar";
            break;
        }
        case 4: {
            stringValue = @"Apr";
            break;
        }
        case 5: {
            stringValue = @"May";
            break;
        }
        case 6: {
            stringValue = @"Jun";
            break;
        }
        case 7: {
            stringValue = @"Jul";
            break;
        }
        case 8: {
            stringValue = @"Aug";
            break;
        }
        case 9: {
            stringValue = @"Sep";
            break;
        }
        case 10: {
            stringValue = @"Oct";
            break;
        }
        case 11: {
            stringValue = @"Nov";
            break;
        }
        case 12: {
            stringValue = @"Dec";
            break;
        }
        default:
            NSCAssert(NO, @"wrong month: %@", month);
    }
    return stringValue;
}

@end