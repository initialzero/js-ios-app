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
//  JMLibraryCollectionViewController.h
//  TIBCO JasperMobile
//

#import "JMLibraryCollectionViewController.h"
#import "SWRevealViewController.h"
#import "JMLibraryListLoader.h"
#import "JMLocalization.h"

NSString *const kJMLibraryCollectionViewFilterByIndexKey = @"kJMLibraryCollectionViewFilterByIndexKey";
NSString *const kJMLibraryCollectionViewSortByIndexKey = @"kJMLibraryCollectionViewSortByIndexKey";

@interface JMLibraryCollectionViewController()
@end

@implementation JMLibraryCollectionViewController

#pragma mark -LifeCycle
-(void)awakeFromNib {
    [super awakeFromNib];
    self.filterByIndex = JMLibraryListLoaderFilterIndexByUndefined;
    self.sortByIndex = JMLibraryListLoaderSortIndexByUndefined;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = JMLocalizedString(@"menuitem_library_label");
}

#pragma mark - Overloaded methods
- (NSString *)defaultRepresentationTypeKey
{
    NSString * keyString = @"RepresentationTypeKey";
    keyString = [@"Library" stringByAppendingString:keyString];
    return keyString;
}

- (Class)resourceLoaderClass
{
    return NSClassFromString(@"JMLibraryListLoader");
}

- (void)updateFilterByIndex:(NSInteger)newIndex
{
    self.filterByIndex = newIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:newIndex
                                               forKey:kJMLibraryCollectionViewFilterByIndexKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)defaultFilterByIndex
{
    if (self.filterByIndex == JMLibraryListLoaderFilterIndexByUndefined) {
        NSInteger filterByIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kJMLibraryCollectionViewFilterByIndexKey];
        self.filterByIndex = filterByIndex;
    }
    return self.filterByIndex;
}

- (void)updateSortByIndex:(NSInteger)newIndex
{
    self.filterByIndex = newIndex;
    [[NSUserDefaults standardUserDefaults] setInteger:newIndex
                                               forKey:kJMLibraryCollectionViewSortByIndexKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)defaultSortByIndex
{
    if (self.sortByIndex == JMLibraryListLoaderSortIndexByUndefined) {
        NSInteger sortByIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kJMLibraryCollectionViewSortByIndexKey];
        self.sortByIndex = sortByIndex;
    }
    return self.sortByIndex;
}

@end
