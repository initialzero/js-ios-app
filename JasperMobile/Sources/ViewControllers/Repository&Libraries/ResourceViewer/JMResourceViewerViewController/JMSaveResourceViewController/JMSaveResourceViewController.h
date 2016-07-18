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
//  JMSaveResourceViewController.h
//  TIBCO JasperMobile
//

/**
 @author Alexey Gubarev ogubarie@tibco.com
 @since 2.6
 */

#import <UIKit/UIKit.h>
#import "JMEditabledViewController.h"
#import "JMSaveResourceSection.h"
#import "JMResource.h"

@protocol JMSaveResourceViewControllerDelegate <NSObject>

@required
- (void)resourceDidSavedSuccessfully;

@end

@interface JMSaveResourceViewController : JMEditabledViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <JMSaveResourceViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *saveResourceButton;

@property (nonatomic, strong) NSArray *availableFormats;
@property (nonatomic, strong) NSString *selectedFormat;

@property (nonatomic, strong) NSString *resourceName;
@property (nonatomic, strong) NSString *errorString;
@property (nonatomic, assign) JMResourceType resourceType;

@property (nonatomic, strong) NSMutableArray *sections;

- (void)setupSections NS_REQUIRES_SUPER;

- (void) saveResource NS_REQUIRES_SUPER;

- (void)verifyExportDataWithCompletion:(void(^)(BOOL success))completion;

- (JMSaveResourceSection *)sectionForType:(JMSaveResourceSectionType)sectionType;

- (void) reloadSectionForType:(JMSaveResourceSectionType)sectionType;

@end
