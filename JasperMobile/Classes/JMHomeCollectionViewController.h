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
//  JMHomeCollectionViewController.h
//  Jaspersoft Corporation
//

#import <UIKit/UIKit.h>

/**
 @author Vlad Zavadskii vzavadskii@jaspersoft.com
 @since 2.0
 */

@protocol JMHomeCollectionViewControllerDelegate;

@interface JMHomeCollectionViewController : UICollectionViewController

@property (nonatomic, weak) id <JMHomeCollectionViewControllerDelegate> delegate;

@end

typedef NS_ENUM(NSInteger, JMMenuItem) {
    JMMenuItemHomeView = -1, // State when "Home View" is presented on the screen as Detail view controller while Master is hidden
    JMMenuItemLibrary = 0,
    JMMenuItemSavedReports = 1,
    JMMenuItemSettings,
    JMMenuItemRepository,
    JMMenuItemFavorites,
    JMMenuItemServerProfiles,
};

@protocol JMHomeCollectionViewControllerDelegate <NSObject>
@required
@property (nonatomic, assign) JMMenuItem selectedItem;

@end
