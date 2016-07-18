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
//  JMSaveResourcePagesCell.m
//  TIBCO JasperMobile
//

#import "JMSaveResourcePagesCell.h"

@interface JMSaveResourcePagesCell()
@property (nonatomic, weak) IBOutlet UISwitch *pagesTypeSwitch;
@end

@implementation JMSaveResourcePagesCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.titleLabel.font = [[JMThemesManager sharedManager] tableViewCellTitleFont];
    self.titleLabel.textColor = [[JMThemesManager sharedManager] tableViewCellTitleTextColor];
    self.titleLabel.text = JMCustomLocalizedString(@"resource_viewer_save_pages_all", nil);
    self.pagesTypeSwitch.onTintColor = [[JMThemesManager sharedManager] saveReportSaveReportButtonBackgroundColor];
}

#pragma mark - Private API
-(void)setPagesType:(JMSaveResourcePagesType)pagesType{
    _pagesType = pagesType;
    self.pagesTypeSwitch.on = (pagesType == JMSaveResourcePagesType_All);
}

#pragma mark - Actions
- (IBAction)switchValueChanged:(id)sender
{
    self.pagesType = self.pagesTypeSwitch.on ? JMSaveResourcePagesType_All : JMSaveResourcePagesType_Range;
    [self.cellDelegate pagesCell:self didChangedPagesType:self.pagesType];
}
@end
