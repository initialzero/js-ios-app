/*
 * JasperMobile for iOS
 * Copyright (C) 2011 - 2014 Jaspersoft Corporation. All rights reserved.
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
//  JMInputControlFactory.h
//  Jaspersoft Corporation
//

#import <Foundation/Foundation.h>
#import "JMInputControlCell.h"
#import "JMInputControlsHolder.h"
#import "JMReportOptionsTableViewController.h"
#import <jaspersoft-sdk/JaspersoftSDK.h>

/**
 @author Vlad Zavadskii vzavadskii@jaspersoft.com
 @since 1.6
 */
@interface JMInputControlFactory : NSObject

@property (nonatomic, weak) UIViewController <JMInputControlsHolder> *viewController;
@property (nonatomic, weak) UITableView *tableView;

/**
 Initialize a new factory
 
 @param viewController A view controller which conforms to JMInputControlsHolder protocol. Needed to update IC cascades
 @param tableView A tableView used to get prototype cells
 @return An initialized factory
 */
- (id)initWithViewController:(UIViewController <JMInputControlsHolder> *)viewController andTableView:(UITableView *)tableView;

/**
 Creates the input control cell
 
 @param inputControl An IC descriptor (REST v2)
 @return The IC cell of a certain type
 */
- (JMInputControlCell *)inputControlWithInputControlDescriptor:(JSInputControlDescriptor *)inputControl;

@end
