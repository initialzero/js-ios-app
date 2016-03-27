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
//  JMScheduleManager.m
//  TIBCO JasperMobile
//

#import "JMScheduleManager.h"
#import "JMResource.h"

@implementation JMScheduleManager

#pragma mark - Life Cycle
+ (instancetype)sharedManager
{
    static JMScheduleManager *sharedManager;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^() {
        sharedManager = [JMScheduleManager new];
    });
    return sharedManager;
}

#pragma mark - Public API
- (void)loadScheduleMetadataForScheduleWithId:(NSInteger)scheduleId completion:(JMScheduleCompletion __nonnull)completion
{
    if (!completion) {
        return;
    }

    [self.restClient fetchScheduleMetadataWithId:scheduleId completion:^(JSOperationResult *result) {
        if (result.error) {
            completion(nil, result.error);
        } else {
            completion(result.objects.firstObject, nil);
        }
    }];
}

- (void)createScheduleWithData:(JSScheduleMetadata *)schedule completion:(JMScheduleCompletion)completion
{
    [self.restClient createScheduleWithData:schedule
                                 completion:^(JSOperationResult *result) {
                                     NSError *error = result.error;
                                     if (error) {
                                         if (error.code == 1007) {
                                             [self handleErrorWithData:result.body completion:completion];
                                         } else {
                                            completion(nil, result.error);
                                        }
                                    } else {
                                        JSScheduleMetadata *scheduledJob = result.objects.firstObject;
                                        completion(scheduledJob, nil);
                                    }
                                }];
}

- (void)updateSchedule:(JSScheduleMetadata *)schedule completion:(JMScheduleCompletion)completion
{
    if (!completion) {
        return;
    }

    [self.restClient updateSchedule:schedule
                         completion:^(JSOperationResult *result) {
                             if (result.error) {
                                 completion(nil, result.error);
                             } else {
                                 completion(result.objects.firstObject, nil);
                             }
                         }];
}

- (void)deleteScheduleWithJobIdentifier:(NSInteger)identifier completion:(void(^)(NSError *))completion
{
    if (!completion) {
        return;
    }

    [self.restClient deleteScheduleWithId:identifier
                               completion:^(JSOperationResult *result) {
                                   if (result.error) {
                                       completion(result.error);
                                   } else {
                                       completion(nil);
                                   }
                               }];
}

#pragma mark - Hanlde Errors
- (void)handleErrorWithData:(NSData *)jsonData completion:(JMScheduleCompletion)completion
{
    NSError *serializeError;
    NSDictionary *bodyJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&serializeError];
    if (bodyJSON) {
        NSArray *errors = bodyJSON[@"error"];
        if (errors.count > 0) {
            NSString *fullMessage = @"";
            for (NSDictionary *errorJSON in errors) {
                id message = errorJSON[@"defaultMessage"];
                NSString *errorMessage = @"";
                NSString *field = errorJSON[@"field"];
                if (message && [message isKindOfClass:[NSString class]]) {
                    errorMessage = [NSString stringWithFormat:@"Message: '%@', field: %@", message, field];
                } else {
                    NSString *errorCode = errorJSON[@"errorCode"];
                    errorMessage = [NSString stringWithFormat:@"Error Code: '%@'", errorCode];
                }
                NSArray *arguments = errorJSON[@"errorArguments"];
                NSString *argumentsString = @"";
                if (arguments) {
                    for (NSString *argument in arguments) {
                        argumentsString = [argumentsString stringByAppendingFormat:@"'%@', ", argument];
                    }
                }
                if (arguments.count) {
                    fullMessage = [fullMessage stringByAppendingFormat:@"%@.\nArguments: %@.\n", errorMessage, argumentsString];
                } else {
                    fullMessage = [fullMessage stringByAppendingFormat:@"%@.\n", errorMessage];
                }
            }
            // TODO: enhance error
            NSError *createScheduledJobError = [[NSError alloc] initWithDomain:@"Error"
                                                                          code:0
                                                                      userInfo:@{NSLocalizedDescriptionKey: fullMessage}];
            completion(nil, createScheduledJobError);
        }
    } else {
        completion(nil, serializeError);
    }
}


#pragma mark - New Schedule Metadata
- (JSScheduleMetadata *)createNewScheduleMetadataWithResourceLookup:(JMResource *)resource
{
    JSScheduleMetadata *scheduleMetadata = [JSScheduleMetadata new];

    NSString *resourceFolder = [resource.resourceLookup.uri stringByDeletingLastPathComponent];
    scheduleMetadata.folderURI = resourceFolder;
    scheduleMetadata.reportUnitURI = resource.resourceLookup.uri;
    scheduleMetadata.label = resource.resourceLookup.label;
    scheduleMetadata.baseOutputFilename = [self filenameFromLabel:resource.resourceLookup.label];
    scheduleMetadata.outputFormats = [self defaultFormats];
    scheduleMetadata.outputTimeZone = [self currentTimeZone];

    JSScheduleSimpleTrigger *simpleTrigger = [self simpleTrigger];
    scheduleMetadata.trigger = @{
            @(JSScheduleTriggerTypeSimple) : simpleTrigger
    };
    return scheduleMetadata;
}

- (JSScheduleSimpleTrigger *)simpleTrigger
{
    JSScheduleSimpleTrigger *simpleTrigger = [JSScheduleSimpleTrigger new];
    simpleTrigger.startType = JSScheduleTriggerStartTypeAtDate;
    simpleTrigger.occurrenceCount = @1;
    simpleTrigger.startDate = [NSDate date];
    simpleTrigger.timezone = [self currentTimeZone];
    simpleTrigger.recurrenceIntervalUnit = JSScheduleSimpleTriggerRecurrenceIntervalTypeNone;
    return simpleTrigger;
}

- (NSString *)currentTimeZone
{
    NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
    NSString *localTimeZoneName = localTimeZone.name;
    return localTimeZoneName;
}

- (NSArray *)defaultFormats
{
    return @[kJS_CONTENT_TYPE_PDF.uppercaseString];
}

- (NSString *)filenameFromLabel:(NSString *)label
{
    NSString *filename = [label stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    return filename;
}

@end