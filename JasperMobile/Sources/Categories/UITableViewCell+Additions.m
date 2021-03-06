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
//  UITableViewCell+Additions.h
//  TIBCO JasperMobile
//

#import "UITableViewCell+Additions.h"
#import "JMUtils.h"

@implementation UITableViewCell (Additions)

- (BOOL)isSeparatorNeeded:(UITableViewStyle)style
{
    return style != UITableViewStyleGrouped;
}

- (UIToolbar *)toolbarForInputAccessoryView
{
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [toolbar setItems:[self inputAccessoryViewToolbarItems]];
    [toolbar sizeToFit];
    if (([JMUtils isCompactWidth] || [JMUtils isCompactHeight])) {
        CGRect toolBarRect = toolbar.frame;
        toolBarRect.size.height = 34;
        toolbar.frame = toolBarRect;
    }
    return toolbar;
}

- (NSArray *)inputAccessoryViewToolbarItems
{
    NSMutableArray *items = [NSMutableArray arrayWithArray:[self leftInputAccessoryViewToolbarItems]];
    [items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    [items addObjectsFromArray:[self rightInputAccessoryViewToolbarItems]];
    return items;
}

- (NSArray *)leftInputAccessoryViewToolbarItems
{
    return [NSArray array];
}

- (NSArray *)rightInputAccessoryViewToolbarItems
{
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
    return @[done];
}

- (void)doneButtonTapped:(id)sender
{
    
}
@end
