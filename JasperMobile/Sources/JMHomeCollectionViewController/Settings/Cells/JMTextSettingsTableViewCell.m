/*
 * Tibco JasperMobile for iOS
 * Copyright © 2005-2014 TIBCO Software, Inc. All rights reserved.
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


#import "JMTextSettingsTableViewCell.h"
#import "UITableViewCell+Additions.h"

@interface JMTextSettingsTableViewCell ()
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation JMTextSettingsTableViewCell
- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textField.background = [self.textField.background resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10.0f, 0, 10.0f)];
    self.textField.inputAccessoryView = [self toolbarForInputAccessoryView];
}

-(void)setSettingsItem:(JMSettingsItem *)settingsItem
{
    [super setSettingsItem:settingsItem];
    self.textField.text = settingsItem.valueSettings;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    
    NSMutableString *newString = [NSMutableString stringWithString:textField.text];
    [newString replaceCharactersInRange:range withString:string];
    NSInteger currentValue = [newString integerValue];
    
    return (([string isEqualToString:filtered]) && (NSLocationInRange(currentValue, self.settingsItem.availableRange)));
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    self.settingsItem.valueSettings = textField.text;
}

#pragma mark - Actions

- (void)doneButtonTapped:(id)sender
{
    [self.textField resignFirstResponder];
}

@end
