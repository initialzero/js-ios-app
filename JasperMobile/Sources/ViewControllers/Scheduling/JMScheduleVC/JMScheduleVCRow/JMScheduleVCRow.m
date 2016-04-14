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
//  JMScheduleVCRow.m
//  TIBCO JasperMobile
//

#import "JMScheduleVCRow.h"


@implementation JMScheduleVCRow

- (instancetype)initWithRowType:(JMScheduleVCRowType)type hidden:(BOOL)hidden
{
    self = [super init];
    if (self) {
        _type = type;
        _title = [self titleForRowType:type];
        _hidden = hidden;
    }
    return self;
}

- (instancetype)initWithRowType:(JMScheduleVCRowType)type
{
    return [self initWithRowType:type hidden:NO];
}

+ (instancetype)rowWithRowType:(JMScheduleVCRowType)type
{
    return [[self alloc] initWithRowType:type];
}

+ (instancetype)rowWithRowType:(JMScheduleVCRowType)type hidden:(BOOL)hidden
{
    return [[self alloc] initWithRowType:type hidden:hidden];
}

#pragma mark - Helpers
- (NSString *)titleForRowType:(JMScheduleVCRowType)type
{
    NSString *title;
    switch(type) {
        case JMScheduleVCRowTypeLabel: {
            title = JMCustomLocalizedString(@"schedules_new_job_label", nil);
            break;
        }
        case JMScheduleVCRowTypeDescription: {
            title =JMCustomLocalizedString(@"schedules_new_job_description", nil);
            break;
        }
        case JMScheduleVCRowTypeOutputFileURI: {
            title = JMCustomLocalizedString(@"schedules_new_job_output_file_name", nil);
            break;
        }
        case JMScheduleVCRowTypeOutputFolderURI: {
            title = JMCustomLocalizedString(@"schedules_new_job_output_file_path", nil);
            break;
        }
        case JMScheduleVCRowTypeFormat: {
            title = JMCustomLocalizedString(@"schedules_new_job_format", nil);
            break;
        }
        case JMScheduleVCRowTypeStartDate: {
            title = JMCustomLocalizedString(@"schedules_new_job_start_date", nil);
            break;
        }
        case JMScheduleVCRowTypeEndDate: {
            title = JMCustomLocalizedString(@"schedules_new_job_end_date", nil);
            break;
        }
        case JMScheduleVCRowTypeTimeZone: {
            title = @"Time Zone";
            break;
        }
        case JMScheduleVCRowTypeStartImmediately: {
            title = JMCustomLocalizedString(@"schedules_new_job_start_immediately", nil);
            break;
        }
        case JMScheduleVCRowTypeRepeatType: {
            title = JMCustomLocalizedString(@"schedules_new_job_repeat_type", nil);
            break;
        }
        case JMScheduleVCRowTypeRepeatCount: {
            title = JMCustomLocalizedString(@"schedules_new_job_repeat_count", nil);
            break;
        }
        case JMScheduleVCRowTypeRepeatTimeInterval: {
            title = JMCustomLocalizedString(@"schedules_new_job_repeat_interval", nil);
            break;
        }
    }
    return title;
}

@end