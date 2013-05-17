/*
 * JasperMobile for iOS
 * Copyright (C) 2005 - 2012 Jaspersoft Corporation. All rights reserved.
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
//  JSUILoadingView.h
//
//  The code of this class derives from code created by Matt Gallagher on 12/04/09.
//  Copyright Matt Gallagher 2009. All rights reserved.
// 
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>
#import <jaspersoft-sdk/JaspersoftSDK.h>

typedef void(^JSUILoadingViewCancelBLock)(void);

/**
 @author Giulio Toffoli giulio@jaspersoft.com
 @author Vlad Zavadskii vzavadskii@jaspersoft.com
 @since 1.0
 */
@interface JSUILoadingView : UIView

+ (void)showCancelableLoadingInView:(UIView *)view restClient:(JSRESTBase *)restClient
                           delegate:(id<JSRequestDelegate>)delegate cancelBlock:(JSUILoadingViewCancelBLock)cancelBlock;
+ (void)showCancelableAllRequestsLoadingInView:(UIView *)view restClient:(JSRESTBase *)restClient
                                   cancelBlock:(JSUILoadingViewCancelBLock)cancelBlock;
+ (void)showLoadingInView:(UIView *)view;
+ (void)hideLoadingView;

- (id)initWithFrame:(CGRect)frame restClient:(JSRESTBase *)restClient delegate:(id<JSRequestDelegate>)delegate cancelAllRequests:(BOOL)cancelAllRequests cancelBlock:(JSUILoadingViewCancelBLock)theCancelBlock;
- (void)showInView:(UIView *)aSuperview;
- (void)removeView;

@end