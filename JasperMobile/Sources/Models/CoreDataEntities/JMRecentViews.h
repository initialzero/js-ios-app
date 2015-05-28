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
//  JMRecentViews.h
//  TIBCO JasperMobile
//

/**
 @author Alexey Gubarev ogubarie@tibco.com
 @since 2.1
 */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class JMServerProfile;

@interface JMRecentViews : NSManagedObject

@property (nonatomic, retain) NSDate * creationDate;
@property (nonatomic, retain) NSNumber * countOfViews;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSDate * lastViewDate;
@property (nonatomic, retain) NSString * resourceDescription;
@property (nonatomic, retain) NSString * uri;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * wsType;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) JMServerProfile *serverProfile;

@end
