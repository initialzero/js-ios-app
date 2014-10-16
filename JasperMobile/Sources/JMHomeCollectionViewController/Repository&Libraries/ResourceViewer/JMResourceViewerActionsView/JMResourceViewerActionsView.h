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


//
//  JMResourceViewerActionsView.h
//  Tibco JasperMobile
//

/**
 @author Alexey Gubarev agubarev@jaspersoft.com
 @since 1.9
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, JMResourceViewerAction) {
    JMResourceViewerAction_None = 0,
    JMResourceViewerAction_MakeFavorite = 1 << 0,
    JMResourceViewerAction_MakeUnFavorite = 1 << 1,
    JMResourceViewerAction_Refresh = 1 << 2,
    JMResourceViewerAction_Filter = 1 << 3,
    JMResourceViewerAction_Save = 1 << 4,
    JMResourceViewerAction_Delete = 1 << 5,
    JMResourceViewerAction_Rename = 1 << 6,
    JMResourceViewerAction_Info = 1 << 7
};

static inline JMResourceViewerAction JMResourceViewerActionFirst() { return JMResourceViewerAction_MakeFavorite; }
static inline JMResourceViewerAction JMResourceViewerActionLast() { return JMResourceViewerAction_Info; }

@class JMResourceViewerActionsView;

@protocol JMResourceViewerActionsViewDelegate <NSObject>
@required
- (void) actionsView:(JMResourceViewerActionsView *)view didSelectAction:(JMResourceViewerAction)action;

@end

@interface JMResourceViewerActionsView : UIView
@property (nonatomic, weak) id <JMResourceViewerActionsViewDelegate> delegate;
@property (nonatomic, assign) JMResourceViewerAction availableActions;

@end
