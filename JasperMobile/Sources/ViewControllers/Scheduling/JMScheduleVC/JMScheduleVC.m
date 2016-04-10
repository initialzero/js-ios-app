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


NSString *const kJMJobLabel              = @"kJMJobLabel";
NSString *const kJMJobDescription        = @"kJMJobDescription";
NSString *const kJMJobOutputFileURI      = @"kJMJobOutputFileURI";
NSString *const kJMJobOutputFolderURI    = @"kJMJobOutputFolderURI";
NSString *const kJMJobFormat             = @"kJMJobFormat";
NSString *const kJMJobStartDate          = @"kJMJobStartDate";
NSString *const kJMJobStartImmediately   = @"kJMJobStartImmediately";
NSString *const kJMJobRepeatType         = @"kJMJobRepeatType";
NSString *const kJMJobRepeatCount        = @"kJMJobRepeatCount";
NSString *const kJMJobRepeatTimeInterval = @"kJMJobRepeatTimeInterval";

@interface JMScheduleVC () <UITableViewDataSource, UITableViewDelegate, JMScheduleCellDelegate, JMScheduleBoolenCellDelegate>
@property (strong, nonatomic) UIDatePicker *datePicker;
@property (nonatomic, strong) NSArray <JMScheduleVCSection *> *sections;
@property (weak, nonatomic) IBOutlet UIButton *createJobButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UITableViewCell *tappedCell;
@property (assign, nonatomic) CGPoint originalTableViewContentOffset;
@end

@implementation JMScheduleVC

#pragma mark - Custom Accessors
- (UIDatePicker *)datePicker
{
    if (!_datePicker) {
        _datePicker = [UIDatePicker new];
        // need set timezone to 0 because of received value
        _datePicker.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

        JSScheduleTrigger *trigger = [self currentTrigger];
        _datePicker.date = trigger.startDate;
        [_datePicker addTarget:self
                       action:@selector(updateDate:)
             forControlEvents:UIControlEventValueChanged];
    }
    return _datePicker;
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

    [self setupLeftBarButtonItems];
    self.originalTableViewContentOffset = CGPointZero;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self addKeyboardObservers];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self removeKeyboardObservers];
}

#pragma mark - Setups
- (void)setupLeftBarButtonItems
{
    UIBarButtonItem *backItem = [self backButtonWithTitle:self.backButtonTitle
                                                   target:self
                                                   action:@selector(backButtonTapped:)];
    self.navigationItem.leftBarButtonItem = backItem;
}

#pragma mark - Actions
- (void)updateDate:(UIDatePicker *)sender
{
    NSDate *newDate = sender.date;
    NSDate *currentDate = [NSDate date];
    if ([newDate compare:currentDate] == NSOrderedAscending) {
        return;
    } else {
        [self updateDateCellWithDate:newDate];
    }
}

- (void)setDate:(UIBarButtonItem *)sender
{
    NSDate *newDate = self.datePicker.date;
    NSDate *currentDate = [NSDate date];
    if ([newDate compare:currentDate] == NSOrderedAscending) {
        UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_error"
                                                                                          message:JMCustomLocalizedString(@"schedules_error_date_past", nil)
                                                                                cancelButtonTitle:@"dialog_button_ok"
                                                                          cancelCompletionHandler:nil];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    JSScheduleTrigger *trigger = [self currentTrigger];
    trigger.startDate = newDate;

    [[self dateCell].valueTextField resignFirstResponder];
}

- (void)cancelEditDate:(UIBarButtonItem *)sender
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    [self updateDateCellWithDate:trigger.startDate];

    [[self dateCell].valueTextField resignFirstResponder];
}

- (void)setRecurrenceCount:(UIBarButtonItem *)sender
{
    JMScheduleCell *cell = [self recurrenceCountCell];
    JSScheduleTrigger *trigger = [self currentTrigger];
    NSAssert(trigger.type == JSScheduleTriggerTypeSimple, @"Should be simple trigger");

    JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *)trigger;
    // TODO: from ipad we can get letters
    NSString *value = cell.valueTextField.text;
    if (value.length == 0 || !value.integerValue) {
        UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_error"
                                                                                          message:JMCustomLocalizedString(@"schedules_error_repeat_count_wrong", nil)
                                                                                cancelButtonTitle:@"dialog_button_ok"
                                                                          cancelCompletionHandler:nil];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    } else {
        simpleTrigger.recurrenceInterval = @(value.integerValue);
        [cell.valueTextField resignFirstResponder];
    }
}

- (void)updateDateCellWithDate:(NSDate *)date
{
    [self dateCell].valueTextField.text = [self dateStringFromDate:date];
}

- (IBAction)selectFormat:(id)sender
{
    NSArray *availableFormats = @[
            kJS_CONTENT_TYPE_HTML,
            kJS_CONTENT_TYPE_PDF,
            kJS_CONTENT_TYPE_XLS
    ];

    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:JMCustomLocalizedString(@"schedules_new_job_output_format", nil)
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

    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:JMCustomLocalizedString(@"schedules_new_job_recurrenceType_alert_title", nil)
                                                                                      message:nil
                                                                            cancelButtonTitle:@"dialog_button_cancel"
                                                                      cancelCompletionHandler:nil];

    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeRecurrence];
    JMScheduleVCRow *row = [section rowWithType:JMScheduleVCRowTypeRepeatTimeInterval];
    NSInteger cellIndex = [section.rows indexOfObject:row];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellIndex
                                                    inSection:JMNewScheduleVCSectionTypeRecurrence];
    JMScheduleCell *cell = [self.tableView cellForRowAtIndexPath:cellIndexPath];

    NSAssert(cell != nil, @"Cell is nil");

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

- (void)selectRepeatType
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
    NSAssert(cell != nil, @"Cell is nil");

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
                                                 [self setupRecurrenceSection];
                                                 NSIndexSet *sectionIndecies = [NSIndexSet indexSetWithIndex:JMNewScheduleVCSectionTypeRecurrence];
                                                 [self.tableView reloadSections:sectionIndecies withRowAnimation:UITableViewRowAnimationAutomatic];
                                             }];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)backButtonTapped:(UIBarButtonItem *)sender
{
    self.exitBlock(nil);
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
    }  else if (row.type == JMScheduleVCRowTypeRepeatType) {
        [self selectRepeatType];
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
            scheduleCell.valueTextField.inputView = self.datePicker;
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForStartDateCell];
            break;
        }
        case JMScheduleVCRowTypeEndDate: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
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
            scheduleCell.valueTextField.inputAccessoryView = [self toolbarForRecurrenceCountCell];
            break;
        }
        case JMScheduleVCRowTypeRepeatTimeInterval: {
            cell = [self scheduleCellForIndexPath:indexPath row:row];
            JMScheduleCell *scheduleCell = (JMScheduleCell *) cell;
            scheduleCell.valueTextField.userInteractionEnabled = NO;
            break;
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

#pragma mark - Save
- (IBAction)makeAction:(UIButton *)sender
{
    [self validateJobWithCompletion:^(BOOL success, NSError *error) {
        if (success) {
            self.exitBlock(self.scheduleMetadata);
        } else {
            [self.tableView reloadData];
            [JMUtils presentAlertControllerWithError:error completion:nil];
        }
    }];
}

#pragma mark - JMNewScheduleCellDelegate
- (void)scheduleCellDidStartChangeValue:(JMScheduleCell *)cell
{
    self.tappedCell = cell;
}

- (void)scheduleCell:(JMScheduleCell *)cell didChangeValue:(NSString *)newValue
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    JMScheduleVCSection *section = self.sections[indexPath.section];
    JMScheduleVCRow *row = section.rows[indexPath.row];

    NSString *trimmedValue = [newValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (row.type == JMScheduleVCRowTypeLabel) {
        self.scheduleMetadata.label = trimmedValue;
    } else if (row.type == JMScheduleVCRowTypeDescription) {
        self.scheduleMetadata.scheduleDescription = trimmedValue;
    } else if (row.type == JMScheduleVCRowTypeOutputFileURI) {
        self.scheduleMetadata.baseOutputFilename = trimmedValue;
    } else if (row.type == JMScheduleVCRowTypeOutputFolderURI) {
        self.scheduleMetadata.folderURI = newValue;
    } else if (row.type == JMScheduleVCRowTypeRepeatCount) {
        JSScheduleTrigger *trigger = [self currentTrigger];
        NSAssert(trigger.type == JSScheduleTriggerTypeSimple, @"Should be simple trigger");

        JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *)trigger;
        // TODO: come up with verifying entered symbols
//            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^?:|0|\\s|[1-9]\\d*$"
//                                                                                   options:NSRegularExpressionCaseInsensitive
//                                                                                     error:nil];
//            NSArray *matches = [regex matchesInString:newValue
//                                              options:NSMatchingReportCompletion
//                                                range:NSMakeRange(0, newValue.length)];
//            if (matches.count) {
//                simpleTrigger.recurrenceInterval = @(newValue.integerValue);
//            } else {
//                UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_error"
//                                                                                              message:JMCustomLocalizedString(@"schedules_error_repeat_count_invalid_characters", nil)
//                                                                                    cancelButtonTitle:@"dialog_button_ok"
//                                                                              cancelCompletionHandler:nil];
//                [self presentViewController:alertController animated:YES completion:nil];
//            }

        simpleTrigger.recurrenceInterval = @(newValue.integerValue);
    }
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
            trigger.startDate = [NSNull null];

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
    }
}

#pragma mark - Setup
- (void)createSections
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    // TODO: trigger denendence

    self.sections = @[
            [self mainSection],
            [self outupOptionsSection],
            [self schedleStartSection],
            [self recurrenceSection],
            //[self schedleEndSection],
    ];
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
    JSScheduleTrigger *trigger = [self currentTrigger];
    BOOL isStartImmediately = trigger.startType == JSScheduleTriggerStartTypeImmediately;

    JMScheduleVCSection *scheduleSection = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeScheduleStart
                                                                                  rows:@[
                                                                                          [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeStartImmediately],
                                                                                          [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeStartDate hidden:isStartImmediately],
                                                                                          [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeTimeZone hidden:isStartImmediately],
                                                                                  ]];
    return scheduleSection;
}

- (JMScheduleVCSection *)recurrenceSection
{
    JSScheduleTrigger *trigger = [self currentTrigger];

    // TODO: add all needed fields
    JMScheduleVCSection *recurrenceSection;
    recurrenceSection = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeRecurrence
                                                               rows:@[
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeRepeatType],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeRepeatCount hidden:YES],
                                                                       [JMScheduleVCRow rowWithRowType:JMScheduleVCRowTypeRepeatTimeInterval hidden:YES],
                                                               ]];
    [self setupRecurrenceSection];
    return recurrenceSection;
}

- (void)setupRecurrenceSection
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    JMScheduleVCSection *section = self.sections[JMNewScheduleVCSectionTypeRecurrence];
    switch(trigger.type) {
        case JSScheduleTriggerTypeNone: {
            [section hideRowWithType:JMScheduleVCRowTypeRepeatCount];
            [section hideRowWithType:JMScheduleVCRowTypeRepeatTimeInterval];
            break;
        }
        case JSScheduleTriggerTypeSimple: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            [section showRowWithType:JMScheduleVCRowTypeRepeatCount];
            [section showRowWithType:JMScheduleVCRowTypeRepeatTimeInterval];
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            [section hideRowWithType:JMScheduleVCRowTypeRepeatCount];
            [section hideRowWithType:JMScheduleVCRowTypeRepeatTimeInterval];
            break;
        }
    }
}

- (JMScheduleVCSection *)schedleEndSection
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    // TODO: trigger denendence

    JMScheduleVCSection *section = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeScheduleEnd
                                                                          rows:@[]];
    return section;
}

- (JMScheduleVCSection *)holidaysSection
{
    JSScheduleTrigger *trigger = [self currentTrigger];
    // TODO: trigger denendence

    JMScheduleVCSection *section = [JMScheduleVCSection sectionWithSectionType:JMNewScheduleVCSectionTypeHolidays
                                                                          rows:@[]];;
    return section;
}

#pragma mark - Keyboard Observers
- (void)addKeyboardObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)removeKeyboardObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGRect keyboardRect = ((NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;

    if (!self.tappedCell) {
        return;
    }
    CGRect cellFrame = self.tappedCell.frame;
    CGFloat cellYPositionInVisibleFrame = CGRectGetMaxY(cellFrame) - self.tableView.contentOffset.y;
    CGFloat visibleFrameHeightWithKeyboard = CGRectGetHeight(self.tableView.frame) - CGRectGetHeight(keyboardRect);
    if (cellYPositionInVisibleFrame > visibleFrameHeightWithKeyboard) {
        CGPoint offset = CGPointMake(0, self.tableView.contentOffset.y + (cellYPositionInVisibleFrame - visibleFrameHeightWithKeyboard));
        [self.tableView setContentOffset:offset animated:YES];
    }
    self.originalTableViewContentOffset = self.tableView.contentOffset;
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    CGFloat diff = ceilf(self.originalTableViewContentOffset.y - self.tableView.contentOffset.y);
    if (abs((int) diff) > 0) {
        [self.tableView setContentOffset:self.originalTableViewContentOffset animated:YES];
        self.tappedCell = nil;
    }
}

#pragma mark - Helpers

- (NSString *)dateStringFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [[JSDateFormatterFactory sharedFactory] formatterWithPattern:@"yyyy-MM-dd HH:mm"];
    NSString *dateString = [formatter stringFromDate:date];
    return dateString;
}

- (UIToolbar *)toolbarForStartDateCell
{
    UIToolbar *toolbar = [UIToolbar new];
    [toolbar sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                              target:self
                                                              action:@selector(setDate:)];
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                              target:self
                                                              action:@selector(cancelEditDate:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    [toolbar setItems:@[cancelButton, flexibleSpace, doneButton] animated:YES];
    return toolbar;
}

- (UIToolbar *)toolbarForRecurrenceCountCell
{
    UIToolbar *toolbar = [UIToolbar new];
    [toolbar sizeToFit];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                  target:self
                                                                  action:@selector(setRecurrenceCount:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    [toolbar setItems:@[flexibleSpace, doneButton] animated:YES];
    return toolbar;
}

- (void)validateJobWithCompletion:(void(^)(BOOL success, NSError *error))completion
{
    if (!completion) {
        return;
    }

    NSString *message;

    if (!self.scheduleMetadata.baseOutputFilename.length) {
        message = JMCustomLocalizedString(@"schedules_error_empty_filename", nil);
    } else if (!self.scheduleMetadata.folderURI.length) {
        message = JMCustomLocalizedString(@"schedules_error_empty_output_folder", nil);
    } else if (!self.scheduleMetadata.label.length) {
        message = JMCustomLocalizedString(@"schedules_error_empty_label", nil);
    } else if (!self.scheduleMetadata.outputFormats.count) {
        message = JMCustomLocalizedString(@"schedules_error_empty_format", nil);
    }

    if (message) {
        NSError *error = [[NSError alloc] initWithDomain:JMCustomLocalizedString(@"schedules_error_domain", nil)
                                                    code:0
                                                userInfo:@{ NSLocalizedDescriptionKey : message }];
        completion(NO, error);
    } else {
        completion(YES, nil);
    }
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

- (JMScheduleCell *)dateCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeScheduleStart
                                           andRow:JMScheduleVCRowTypeStartDate];
    return cell;
}

- (JMScheduleCell *)recurrenceCountCell
{
    JMScheduleCell *cell = [self cellInSection:JMNewScheduleVCSectionTypeRecurrence
                                        andRow:JMScheduleVCRowTypeRepeatCount];
    return cell;
}

- (JMScheduleCell *)cellInSection:(JMScheduleVCSectionType)sectionType andRow:(JMScheduleVCRowType)rowType
{
    JMScheduleVCSection *searchSection;
    for (JMScheduleVCSection *section in self.sections) {
        if (section.type == sectionType) {
            searchSection = section;
            break;
        }
    }
    JMScheduleVCRow *row = [searchSection rowWithType:rowType];
    NSInteger cellIndex = [searchSection.rows indexOfObject:row];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:cellIndex
                                                    inSection:sectionType];
    JMScheduleCell *cell = [self.tableView cellForRowAtIndexPath:cellIndexPath];
    return cell;
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
    } else if (type == JMScheduleVCRowTypeTimeZone) {
        propertyValue = trigger.timezone;
    }

    switch (trigger.type) {
        case JSScheduleTriggerTypeSimple: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            if (type == JMScheduleVCRowTypeRepeatType) {
                propertyValue = [self stringValueForTriggerType:JSScheduleTriggerTypeSimple];
            } else if (type == JMScheduleVCRowTypeRepeatCount) {
                propertyValue = simpleTrigger.recurrenceInterval.stringValue;
            } else if (type == JMScheduleVCRowTypeRepeatTimeInterval) {
                propertyValue = [self stringValueForRecurrenceType:simpleTrigger.recurrenceIntervalUnit];
            }
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            if (type == JMScheduleVCRowTypeRepeatType) {
                propertyValue = [self stringValueForTriggerType:JSScheduleTriggerTypeCalendar];
            }
            break;
        }
        case JSScheduleTriggerTypeNone: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            if (type == JMScheduleVCRowTypeRepeatType) {
                propertyValue = [self stringValueForTriggerType:JSScheduleTriggerTypeNone];
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
        case JSScheduleTriggerTypeSimple: {
            JSScheduleSimpleTrigger *simpleTrigger = (JSScheduleSimpleTrigger *) trigger;
            if (type == JMScheduleVCRowTypeStartImmediately) {
                boolenValue = simpleTrigger.startType == JSScheduleTriggerStartTypeImmediately;
            }
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            JSScheduleCalendarTrigger *calendarTrigger = (JSScheduleCalendarTrigger *) trigger;
            if (type == JMScheduleVCRowTypeStartImmediately) {
                boolenValue = calendarTrigger.startType == JSScheduleTriggerStartTypeImmediately;
            }
            break;
        }
        case JSScheduleTriggerTypeNone: {
            // TODO: implement
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
            trigger = [[JMScheduleManager sharedManager] defaultNoneTrigger];
            break;
        }
        case JSScheduleTriggerTypeSimple: {
            trigger = [[JMScheduleManager sharedManager] defaultSimpleTrigger];
            break;
        }
        case JSScheduleTriggerTypeCalendar: {
            trigger = [[JMScheduleManager sharedManager] defaultCalendarTrigger];
            break;
        }
    }
    return trigger;
}

@end