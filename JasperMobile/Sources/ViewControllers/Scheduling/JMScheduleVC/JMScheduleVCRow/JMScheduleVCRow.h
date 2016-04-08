/*
 * TIBCO JasperMobile for iOS
 * Copyright © 2005-2016 TIBCO Software, Inc. All rights reserved.
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
//  JMScheduleVCRow.h
//  TIBCO JasperMobile
//


/**
@author Aleksandr Dakhno odahno@tibco.com
@since 2.5
*/

typedef NS_ENUM(NSInteger, JMScheduleVCRowType) {
    JMScheduleVCRowTypeLabel,
    JMScheduleVCRowTypeDescription,
    JMScheduleVCRowTypeOutputFileURI,
    JMScheduleVCRowTypeOutputFolderURI,
    JMScheduleVCRowTypeFormat,
    JMScheduleVCRowTypeStartDate,
    JMScheduleVCRowTypeEndDate,
    JMScheduleVCRowTypeTimeZone,
    JMScheduleVCRowTypeStartImmediately,
    JMScheduleVCRowTypeRepeatType,
    JMScheduleVCRowTypeRepeatCount,
    JMScheduleVCRowTypeRepeatTimeInterval
};

@interface JMScheduleVCRow : NSObject
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, assign, readonly) JMScheduleVCRowType type;
@property (nonatomic, assign, getter=isHidden) BOOL hidden;
- (instancetype)initWithRowType:(JMScheduleVCRowType)type;
- (instancetype)initWithRowType:(JMScheduleVCRowType)type hidden:(BOOL)hidden;
+ (instancetype)rowWithRowType:(JMScheduleVCRowType)type;
+ (instancetype)rowWithRowType:(JMScheduleVCRowType)type hidden:(BOOL)hidden;
@end