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
//  JMSaveResourceSection.h
//  TIBCO JasperMobile
//

/**
 @author Alexey Gubarev ogubarie@tibco.com
 @author Aleksandr Dakhno odahno@tibco.com

 @since 1.9.1
*/

typedef NS_ENUM(NSInteger, JMSaveResourceSectionType) {
    JMSaveResourceSectionTypeName,
    JMSaveResourceSectionTypeFormat,
    JMSaveResourceSectionTypePageRange
};

@interface JMSaveResourceSection : NSObject
@property (nonatomic, assign) JMSaveResourceSectionType sectionType;
@property (nonatomic, copy) NSString *title;
- (instancetype)initWithSectionType:(JMSaveResourceSectionType)sectionType title:(NSString *)title;
+ (JMSaveResourceSection *)sectionWithType:(JMSaveResourceSectionType)sectionType title:(NSString *)title;
@end
