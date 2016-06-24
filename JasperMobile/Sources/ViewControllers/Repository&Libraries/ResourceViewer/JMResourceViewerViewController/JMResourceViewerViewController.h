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
//  JMResourceViewerViewController.h
//  TIBCO JasperMobile
//

/**
 @author Alexey Gubarev ogubarie@tibco.com
 @since 1.9
 */

#import "JMBaseResourceViewerVC.h"
@class JMWebEnvironment;

extern NSString * const kJMResourceViewerWebEnvironmentIdentifier;

@interface JMResourceViewerViewController : JMBaseResourceViewerVC <WKNavigationDelegate>
@property (nonatomic, strong) JMWebEnvironment *webEnvironment;
- (UIView *)contentView;
- (JMWebEnvironment *)currentWebEnvironment;
- (void)printResource __attribute__((objc_requires_super));
- (void)printItem:(id)printingItem withName:(NSString *)itemName completion:(void (^)(BOOL completed, NSError *error))completion;
- (void)handleLowMemory __attribute__((objc_requires_super));
@end
