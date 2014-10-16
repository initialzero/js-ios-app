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
//  JMCancelRequestPopup.h
//  Tibco JasperMobile
//

#import <UIKit/UIKit.h>
#import <jaspersoft-sdk/JaspersoftSDK.h>

typedef void(^JMCancelRequestBlock)(void);

/**
 @author Vlad Zavadskii vzavadskii@jaspersoft.com
 @since 1.6
 */
@interface JMCancelRequestPopup : UIViewController

/**
 Presents cancel request popup in view controller
 
 @param viewController A view controller inside which popup will be shown
 @param message A message of a progress dialog
 @param restClient A rest client to cancel all requests
 @param cancelBlock A cancelBlock to execute
 */
+ (void)presentInViewController:(UIViewController *)viewController message:(NSString *)message restClient:(JSRESTBase *)client cancelBlock:(JMCancelRequestBlock)cancelBlock;

/**
 Provides a global offset for all popups that will be displayed

 @param offset A popup offset

 **Default**: CGPointZero (same as CGPointMake(0,0) )
*/
+ (void)offset:(CGPoint)offset;

/**
 Dismisses last presented popup
 */
+ (void)dismiss;


/**
 Return YES if CancelRequestPopup is presented
 */
+ (BOOL)isVisiblePopup;

@end

