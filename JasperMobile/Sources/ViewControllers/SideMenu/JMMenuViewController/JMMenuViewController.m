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
//  JMMenuViewController.h
//  TIBCO JasperMobile
//

#import "JMMenuViewController.h"
#import "SWRevealViewController.h"
#import "JMMenuItemTableViewCell.h"
#import "JMMainNavigationController.h"
#import "JMLibraryCollectionViewController.h"
#import "JMSavedItemsCollectionViewController.h"
#import "JMFavoritesCollectionViewController.h"
#import "JMSettingsViewController.h"
#import "JMServerProfile.h"
#import "JMServerProfile+Helpers.h"
#import "JMConstants.h"
#import <Crashlytics/Crashlytics.h>

@interface JMMenuViewController() <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (strong, nonatomic) NSArray *menuItems;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;
@end

@implementation JMMenuViewController
+ (NSInteger)defaultItemIndex {
    return JMResourceTypeLibrary;
}

#pragma mark - LifeCycle
-(void)dealloc
{
    JMLog(@"%@ -%@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // version and build
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    self.appVersionLabel.text = [NSString stringWithFormat:@"v. %@ (%@)", version, build];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateServerInfo];

    [self.tableView reloadData];
}

#pragma mark - Utils
- (void)updateServerInfo
{
    NSString *alias = self.restClient.serverProfile.alias;
    NSString *version = self.restClient.serverProfile.serverInfo.version;
    self.serverNameLabel.text = [NSString stringWithFormat:@"%@ (v.%@)", alias, version];
    self.userNameLabel.text = self.restClient.serverProfile.username;
    self.organizationNameLabel.text = self.restClient.serverProfile.organization;
}

- (void)unselectItems
{
    for(JMMenuItem *item in self.menuItems) {
        if (item.selected) {
            item.selected = NO;
        }
    }
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JMMenuItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JMMenuItemTableViewCell"
                                                                    forIndexPath:indexPath];
    cell.menuItem = self.menuItems[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self setSelectedItemIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
    JMMenuItem *menuItem = self.menuItems[indexPath.row];
    cell.selected = menuItem.selected;
}

#pragma mark - Public API
- (void) setSelectedItemIndex:(NSUInteger)itemIndex
{
    if (itemIndex < self.menuItems.count) {
        JMMenuItem *currentSelectedItem = self.selectedItem;
        JMMenuItem *item = [self.menuItems objectAtIndex:itemIndex];
        
        if (item.resourceType != JMResourceTypeLogout) {
            if (!currentSelectedItem || currentSelectedItem != item) {
                [self unselectItems];
                item.selected = YES;
                
                [self.tableView reloadData];
                if([item vcIdentifierForSelectedItem]) {
                    UINavigationController *nvc = [self.storyboard instantiateViewControllerWithIdentifier:[item vcIdentifierForSelectedItem]];
                    self.revealViewController.frontViewController = nvc;
                }
            }
            [self.revealViewController setFrontViewPosition:FrontViewPositionLeft
                                                   animated:YES];
        } else {
            [[JMSessionManager sharedManager] logout];
            [JMUtils showLoginViewAnimated:YES completion:nil];
            self.menuItems = nil;
        }
    }
}

#pragma mark - Properties
- (NSArray *)menuItems
{
    if (!_menuItems) {
        _menuItems = [self createMenuItems];
    }
    return _menuItems;
}

- (JMMenuItem *)selectedItem
{
    for (JMMenuItem *menuItem in self.menuItems) {
        if (menuItem.selected) {
            return menuItem;
        }
    }
    return nil;
}

#pragma mark - Helpers
- (NSArray *)createMenuItems
{
    NSMutableArray *menuItems = [@[
            [JMMenuItem menuItemWithResourceType:JMResourceTypeLibrary],
            [JMMenuItem menuItemWithResourceType:JMResourceTypeRepository],
            [JMMenuItem menuItemWithResourceType:JMResourceTypeSavedItems],
            [JMMenuItem menuItemWithResourceType:JMResourceTypeFavorites],
            [JMMenuItem menuItemWithResourceType:JMResourceTypeSettings],
            [JMMenuItem menuItemWithResourceType:JMResourceTypeLogout]
    ] mutableCopy];

    if ([JMUtils isServerProEdition]) {
        NSUInteger indexOfRepository = [menuItems indexOfObject:[JMMenuItem menuItemWithResourceType:JMResourceTypeRepository]];
        [menuItems insertObject:[JMMenuItem menuItemWithResourceType:JMResourceTypeRecentViews] atIndex:indexOfRepository + 1];
    }

    return [menuItems copy];
}

@end
