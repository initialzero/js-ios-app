/*
 * JasperMobile for iOS
 * Copyright (C) 2011 - 2013 Jaspersoft Corporation. All rights reserved.
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
//  JMMultiSelectTableViewController.m
//  Jaspersoft Corporation
//

#import "JMMultiSelectTableViewController.h"

@interface JMMultiSelectTableViewController()
@property (nonatomic, strong) NSSet *previousSelectedValues;
@end

@implementation JMMultiSelectTableViewController

#pragma mark - UITableViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.previousSelectedValues = [self.selectedValues copy];
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (![self.previousSelectedValues isEqualToSet:self.selectedValues]) {
        [self.cell updateWithParameters:self.selectedValues];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    JMListValue *value = [self.cell.listOfValues objectAtIndex:indexPath.row];
    value.selected = !value.selected;
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self markCell:cell isSelected:value];
}

#pragma mark - Actions

- (IBAction)unsetAllValues:(id)sender
{
    for (JMListValue *value in self.selectedValues) {
        value.selected = NO;
    }

    [self.selectedValues removeAllObjects];
    [self.cell updateWithParameters:nil];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
