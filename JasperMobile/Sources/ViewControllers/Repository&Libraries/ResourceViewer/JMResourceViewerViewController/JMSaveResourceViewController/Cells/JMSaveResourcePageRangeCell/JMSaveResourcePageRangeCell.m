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
//  JMSaveResourcePageRangeCell.h
//  TIBCO JasperMobile
//

/**
@since 1.9.1
*/

#import "JMSaveResourcePageRangeCell.h"
#import "JMTextField.h"

@interface JMSaveResourcePageRangeCell() <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet JMTextField *textField;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign) NSRange availableRange;
@end

@implementation JMSaveResourcePageRangeCell

#pragma mark - Lifecycle

- (void)awakeFromNib
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.titleLabel.font = [[JMThemesManager sharedManager] tableViewCellTitleFont];
    self.titleLabel.textColor = [[JMThemesManager sharedManager] tableViewCellTitleTextColor];
    
    UIPickerView *pickerView = [UIPickerView new];
    
    self.textField.inputView = pickerView;
    self.textField.inputAccessoryView = [self pickerToolbar];
    
    self.pickerView = pickerView;
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = NO;
    self.activityIndicator.color = [UIColor darkGrayColor];
    
    [self.textField addSubview:self.activityIndicator];
    
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.textField addConstraint:[NSLayoutConstraint constraintWithItem:self.textField
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.activityIndicator
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0]];
    
    [self.textField addConstraint:[NSLayoutConstraint constraintWithItem:self.textField
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.activityIndicator
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0]];
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    self.textField.enabled = editable;
}

#pragma mark - Custom Setters
- (void)setCurrentPage:(NSInteger)currentPage
{
    if (currentPage != NSNotFound) {
        _currentPage = currentPage;
        self.textField.text = @(currentPage).stringValue;
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
    } else {
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
    }
}

#pragma mark - Private API
- (BOOL)configurePickerView
{
    self.availableRange = [self.cellDelegate availableRangeForPageRangeCell:self];
    if (self.availableRange.location != NSNotFound) {
        [self.pickerView selectRow:(self.currentPage - self.availableRange.location)
                       inComponent:0
                          animated:YES];
        [self.pickerView reloadAllComponents];
        return YES;
    }
    return NO;
}

#pragma mark - Picker
- (UIToolbar *)pickerToolbar
{
    UIToolbar *pickerToolbar = [[UIToolbar alloc] init];
    [pickerToolbar sizeToFit];

    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [pickerToolbar setItems:@[flexibleSpace, cancel, done]];

    return pickerToolbar;
}

- (void)done:(id)sender
{
    if ([self.cellDelegate respondsToSelector:@selector(pageRangeCell:didSelectPage:)]) {
        [self.cellDelegate pageRangeCell:self didSelectPage:[self.pickerView selectedRowInComponent:0] + self.availableRange.location];
    }
    [self hidePicker];
}

- (void)cancel:(id)sender
{
    [self hidePicker];
}

- (void)hidePicker
{
    [self.textField resignFirstResponder];
}

#pragma mark - UIPickeViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.availableRange.length;
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [NSString stringWithFormat:@"%@", @(self.availableRange.location + row)];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return [self configurePickerView];
}

@end
