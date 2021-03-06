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


#import "JMServerOptionCell.h"

@interface JMServerOptionCell ()
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;
@end

@implementation JMServerOptionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.titleLabel.font = [[JMThemesManager sharedManager] tableViewCellTitleFont];
    self.titleLabel.textColor = [[JMThemesManager sharedManager] tableViewCellTitleTextColor];
    
    self.errorLabel.font = [[JMThemesManager sharedManager] tableViewCellErrorFont];
    self.errorLabel.textColor = [[JMThemesManager sharedManager] tableViewCellErrorColor];
}

- (void)setServerOption:(JMServerOption *)serverOption
{
    _serverOption = serverOption;
    
    self.titleLabel.text = serverOption.titleString;
    [self updateDisplayingOfErrorMessage];
}

- (void) updateDisplayingOfErrorMessage
{
    self.errorLabel.text = self.serverOption.errorString;
    [UIView beginAnimations:nil context:nil];
    self.errorLabel.alpha = (self.serverOption.errorString.length == 0) ? 0 : 1;
    [UIView commitAnimations];
    [self.delegate reloadTableViewCell:self];
}


@end