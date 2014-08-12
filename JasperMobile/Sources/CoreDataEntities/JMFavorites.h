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
//  JMFavorites.h
//  Jaspersoft Corporation
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class JMServerProfile;

/**
 @author Vlad Zavadskii vzavadskii@jaspersoft.com
 @since 1.6
 */
@interface JMFavorites : NSManagedObject

@property (nonatomic, strong) NSString * organization;
@property (nonatomic, strong) NSString * username;
@property (nonatomic, strong) NSString * label;
@property (nonatomic, strong) NSString * uri;
@property (nonatomic, strong) NSString * wsType;
@property (nonatomic, strong) JMServerProfile *serverProfile;

@end
