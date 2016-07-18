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
            title = JMCustomLocalizedString(@"schedules_new_job_baseOutputFilename", nil);
            break;
        }
        case JMScheduleVCRowTypeOutputFolderURI: {
            title = JMCustomLocalizedString(@"schedules_new_job_folderURI", nil);
            break;
        }
        case JMScheduleVCRowTypeFormat: {
            title = JMCustomLocalizedString(@"schedules_new_job_outputFormat", nil);
            break;
        }
        case JMScheduleVCRowTypeStartDate: {
            title = JMCustomLocalizedString(@"schedules_new_job_startDate", nil);
            break;
        }
        case JMScheduleVCRowTypeEndDate: {
            title = JMCustomLocalizedString(@"schedules_new_job_endDate", nil);
            break;
        }
        case JMScheduleVCRowTypeTimeZone: {
            title = @"Time Zone";
            break;
        }
        case JMScheduleVCRowTypeStartImmediately: {
            title = JMCustomLocalizedString(@"schedules_new_job_startType", nil);
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
            title = JMCustomLocalizedString(@"schedules_new_job_recurrenceIntervalUnit", nil);
            break;
        }
        case JMScheduleVCRowTypeRunIndefinitely: {
            title = JMCustomLocalizedString(@"schedules_new_job_run_indefinitely", nil);
            break;
        }
        case JMScheduleVCRowTypeNumberOfRuns: {
            title = JMCustomLocalizedString(@"schedules_new_job_occurrenceCount", nil);
            break;
        }
        case JMScheduleVCRowTypeCalendarEveryMonth: {
            title = JMCustomLocalizedString(@"schedules_job_calendar_every_month", nil);
            break;
        }
        case JMScheduleVCRowTypeCalendarSelectedMonths: {
            title = JMCustomLocalizedString(@"schedules_new_job_months", nil);
            break;
        }
        case JMScheduleVCRowTypeCalendarEveryDay: {
            title = JMCustomLocalizedString(@"schedules_job_calendar_every_day", nil);
            break;
        }
        case JMScheduleVCRowTypeCalendarSelectedDays: {
            title = JMCustomLocalizedString(@"schedules_new_job_weekDays", nil);
            break;
        }
        case JMScheduleVCRowTypeCalendarDatesInMonth: {
            title = JMCustomLocalizedString(@"schedules_new_job_monthDays", nil);
            break;
        }
        case JMScheduleVCRowTypeCalendarHours: {
            title = JMCustomLocalizedString(@"schedules_new_job_hours", nil);
            break;
        }
        case JMScheduleVCRowTypeCalendarMinutes: {
            title = JMCustomLocalizedString(@"schedules_new_job_minutes", nil);
            break;
        }
    }
    return title;
}

@end