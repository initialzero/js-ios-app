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
//  JMNewJobVC.m
//  TIBCO JasperMobile
//

#import "JMNewJobVC.h"
#import "JMSchedulingManager.h"
#import "JMScheduleJob.h"
#import "JMNewJobCell.h"

NSString *const kJMJobLabel = @"kJMJobLabel";
NSString *const kJMJobOutputFileURI = @"kJMJobOutputFileURI";
NSString *const kJMJobFormat = @"kJMJobFormat";
NSString *const kJMJobStartDate = @"kJMJobStartDate";

@interface JMNewJobVC() <UITableViewDataSource, UITableViewDelegate, JMNewJobCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property (weak, nonatomic) IBOutlet UITextField *jobNameTextField;
//@property (weak, nonatomic) IBOutlet UITextField *fileNameTextField;
//@property (weak, nonatomic) IBOutlet UITextField *dateTextField;
//@property (weak, nonatomic) IBOutlet UIButton *formatButton;
//@property (nonatomic) NSString *format;
@property (nonatomic, strong) JMScheduleJob *job;
@property (nonatomic, strong) NSArray *jobRepresentationProperties;
@end

@implementation JMNewJobVC

#pragma mark - Object LifeCycle
//- (void)awakeFromNib
//{
//    [super awakeFromNib];
//
//}

#pragma mark - UIViewController LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"New Job";
    self.view.backgroundColor = [[JMThemesManager sharedManager] viewBackgroundColor];

    // textfields
//    self.jobNameTextField.text = self.resourceLookup.label;

    // date text field
    UIDatePicker *datePicker = [[UIDatePicker alloc]init];
    [datePicker setDate:[NSDate date]];
    [datePicker addTarget:self
                   action:@selector(updateDate:)
         forControlEvents:UIControlEventValueChanged];
//    self.dateTextField.inputView = datePicker;

//    UIToolbar *toolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, -40, 320, 40)];
//    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(setDate:)];
//    [toolbar setItems:@[doneButton] animated:YES];
//    self.dateTextField.inputAccessoryView = toolbar;

//    self.dateTextField.text = [self dateStringFromDate:[NSDate date]];

    // format button
//    self.format = @"PDF";
//    [self.formatButton setTitle:self.format forState:UIControlStateNormal];

    [self createJobRepresentation];
    self.job = [JMScheduleJob jobWithReportURI:self.resourceLookup.uri
                                         label:self.resourceLookup.label
                                outputFilename:nil
                                        format:nil
                                     startDate:nil];

}

#pragma mark - Actions
- (void)updateDate:(UIDatePicker *)sender
{
    JMLog(@"new date: %@", sender.date);
    self.job.startDate = sender.date;

    // find text field for date
    NSInteger rowDateCell = [self.jobRepresentationProperties indexOfObject:kJMJobStartDate];
    NSIndexPath *dateCellIndexPath = [NSIndexPath indexPathForRow:rowDateCell inSection:0];
    JMNewJobCell *dateCell = [self.tableView cellForRowAtIndexPath:dateCellIndexPath];

    // set new value
    dateCell.valueTextField.text = [self dateStringFromDate:self.job.startDate];
}

- (void)setDate:(UIButton *)sender
{
    // find text field for date
    NSInteger rowDateCell = [self.jobRepresentationProperties indexOfObject:kJMJobStartDate];
    NSIndexPath *dateCellIndexPath = [NSIndexPath indexPathForRow:rowDateCell inSection:0];
    JMNewJobCell *dateCell = [self.tableView cellForRowAtIndexPath:dateCellIndexPath];

    // set new value
    dateCell.valueTextField.text = [self dateStringFromDate:self.job.startDate];
    [dateCell.valueTextField resignFirstResponder];
}

- (IBAction)selectFormat:(id)sender
{
    JMLog(@"select format");

    NSArray *availableFormats = @[@"HTML", @"PDF", @"XLS"];

    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"Output Format"
                                                                                      message:nil
                                                                            cancelButtonTitle:@"dialog.button.cancel"
                                                                      cancelCompletionHandler:nil];

    NSInteger rowFormatCell = [self.jobRepresentationProperties indexOfObject:kJMJobFormat];
    NSIndexPath *formatCellIndexPath = [NSIndexPath indexPathForRow:rowFormatCell inSection:0];
    JMNewJobCell *formatCell = [self.tableView cellForRowAtIndexPath:formatCellIndexPath];

    for (NSString *format in availableFormats) {
        [alertController addActionWithLocalizedTitle:format style:UIAlertActionStyleDefault
                                             handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                                                 formatCell.valueTextField.text = format;
                                                 self.job.outputFormat = format;
                                             }];
    }

    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSString *jobProperty = self.jobRepresentationProperties[indexPath.row];
    if ([jobProperty isEqualToString:kJMJobLabel]) {

    } else if ([jobProperty isEqualToString:kJMJobOutputFileURI]) {

    } else if ([jobProperty isEqualToString:kJMJobFormat]) {
        [self selectFormat:nil];
    } else if ([jobProperty isEqualToString:kJMJobStartDate]) {

    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.jobRepresentationProperties.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JMNewJobCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JMNewJobCell" forIndexPath:indexPath];

    NSString *jobProperty = self.jobRepresentationProperties[indexPath.row];

    NSString *propertyTitle;
    NSString *propertyValue;
    if ([jobProperty isEqualToString:kJMJobLabel]) {
        propertyTitle = @"Job Label";
        propertyValue = self.job.label;
    } else if ([jobProperty isEqualToString:kJMJobOutputFileURI]) {
        propertyTitle = @"Output File Name";
        propertyValue = self.job.baseOutputFilename;
    } else if ([jobProperty isEqualToString:kJMJobFormat]) {
        propertyTitle = @"Format";
        propertyValue = self.job.outputFormat;
        cell.valueTextField.userInteractionEnabled = NO;
    } else if ([jobProperty isEqualToString:kJMJobStartDate]) {
        propertyTitle = @"Start Date";
        propertyValue = [self dateStringFromDate:self.job.startDate];
        [self setupToolbarForTextField:cell.valueTextField];
    }

    cell.titleLabel.text = propertyTitle;
    cell.valueTextField.text = propertyValue;

    cell.delegate = self;

    return cell;
}

#pragma mark - Save
- (IBAction)saveJob:(id)sender
{
    [self createJobWithCompletion:^(NSError *error) {
        if (error) {
            [JMUtils presentAlertControllerWithError:error completion:nil];
        } else {
            if (self.exitBlock) {
                self.exitBlock();
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

#pragma mark - JMNewJobCellDelegate
- (void)jobCell:(JMNewJobCell *)cell didChangeValue:(NSString *)newValue
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSString *jobProperty = self.jobRepresentationProperties[indexPath.row];
    if ([jobProperty isEqualToString:kJMJobLabel]) {
        self.job.label = newValue;
    } else if ([jobProperty isEqualToString:kJMJobOutputFileURI]) {
        self.job.baseOutputFilename = newValue;
    } else if ([jobProperty isEqualToString:kJMJobFormat]) {

    } else if ([jobProperty isEqualToString:kJMJobStartDate]) {

    }
}

#pragma mark - Helpers
- (void)createJobWithCompletion:(void(^)(NSError *error))completion
{
    if (!completion) {
        return;
    }

    JMSchedulingManager *jobsManager = [JMSchedulingManager new];
    [jobsManager createJobWithData:[self.job jobAsData] completion:^(NSDictionary *job, NSError *error) {
        completion(error);
    }];
}

- (void)createJobRepresentation
{
    self.jobRepresentationProperties = @[
            kJMJobLabel,
            kJMJobOutputFileURI,
            kJMJobFormat,
            kJMJobStartDate
    ];
}

- (NSString *)dateStringFromDate:(NSDate *)date
{
    NSDateFormatter* outputFormatter = [[NSDateFormatter alloc]init];
    [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];

    // Increase to 1 min for test purposes
    // TODO: remove this
    NSTimeInterval timeInterval = [date timeIntervalSince1970];
    timeInterval += 60;
    date = [NSDate dateWithTimeIntervalSince1970:timeInterval];

    NSString *dateString = [outputFormatter stringFromDate:date];
    return dateString;
}

- (void)setupToolbarForTextField:(UITextField *)textField
{
    UIDatePicker *datePicker = [[UIDatePicker alloc]init];
    [datePicker setDate:[NSDate date]];
    [datePicker addTarget:self
                   action:@selector(updateDate:)
         forControlEvents:UIControlEventValueChanged];
    textField.inputView = datePicker;


    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar sizeToFit];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(setDate:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:nil];
    [toolbar setItems:@[flexibleSpace, doneButton] animated:YES];
    textField.inputAccessoryView = toolbar;
}

@end