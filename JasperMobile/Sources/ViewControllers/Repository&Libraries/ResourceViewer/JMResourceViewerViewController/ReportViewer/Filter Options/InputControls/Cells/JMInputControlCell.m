/*
 * TIBCO JasperMobile for iOS
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

//
//  JMInputControlCell.m
//  TIBCO JasperMobile
//

#import "JMInputControlCell.h"

@interface JMInputControlCell()
@property (nonatomic, weak) IBOutlet UIView  *valuePlaceHolderView;
@end

@implementation JMInputControlCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.titleLabel.font = [JMThemesManager tableViewCellTitleFont];
    self.titleLabel.textColor = [UIColor darkGrayColor];
    self.errorLabel.font = [JMThemesManager tableViewCellDetailErrorFont];
    self.errorLabel.textColor = [UIColor redColor];
}

- (void) updateDisplayingOfErrorMessage
{
    NSString *errorString = [self.inputControlDescriptor errorString];
    self.errorLabel.text = errorString;
    [self.delegate reloadTableViewCell:self];
}

- (void)setInputControlDescriptor:(JSInputControlDescriptor *)inputControlDescriptor
{
    _inputControlDescriptor = inputControlDescriptor;
    [self setEnabledCell:(!inputControlDescriptor.readOnly.boolValue)];
    if (inputControlDescriptor.mandatory.boolValue) {
        self.titleLabel.text = [NSString stringWithFormat:@"* %@",inputControlDescriptor.label];
    } else {
        self.titleLabel.text = inputControlDescriptor.label;
    }
    [self updateDisplayingOfErrorMessage];
}

- (void)setEnabledCell:(BOOL)enabled
{
    if (enabled) {
        self.titleLabel.textColor = [UIColor darkGrayColor];
    } else {
        self.titleLabel.textColor = [UIColor lightGrayColor];
    }
}

- (BOOL)isValidData
{
    [self updateDisplayingOfErrorMessage];
    return ![self.inputControlDescriptor errorString];
}

@end
