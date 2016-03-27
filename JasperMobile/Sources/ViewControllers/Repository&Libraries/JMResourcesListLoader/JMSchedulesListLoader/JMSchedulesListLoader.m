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
//  JMSchedulesListLoader.h
//  TIBCO JasperMobile
//

#import "JMSchedulesListLoader.h"
#import "JMResource.h"
#import "JMSchedule.h"


@implementation JMSchedulesListLoader

- (void)loadNextPage
{
    __weak typeof(self)weakSelf = self;
    [self.restClient fetchSchedulesForResourceWithURI:self.resource.resourceLookup.uri completion:^(JSOperationResult *result) {
        __strong typeof(self)strongSelf = weakSelf;
        if (result.error) {
            if (result.error.code == JSSessionExpiredErrorCode) {
                [JMUtils showLoginViewAnimated:YES completion:nil];
            } else {
                [strongSelf finishLoadingWithError:result.error];
            }
        } else {
            for (id scheduleLookup in result.objects) {
                if ([scheduleLookup isKindOfClass:[JSScheduleLookup class]]) {
                    JSResourceLookup *resourceLookup = [strongSelf resourceLookupFromScheduleLookup:scheduleLookup];
                    JMSchedule *resource = [JMSchedule scheduleWithResourceLookup:resourceLookup scheduleLookup:scheduleLookup];
                    [strongSelf addResourcesWithResource:resource];
                }
            }
            [strongSelf finishLoadingWithError:nil];
        }
    }];
}

- (JSResourceLookup *)resourceLookupFromScheduleLookup:(JSScheduleLookup *)scheduleLookup
{
    JSResourceLookup *resourceLookup = [JSResourceLookup new];
    resourceLookup.label = scheduleLookup.label;
    resourceLookup.resourceType = kJMScheduleUnit;
    resourceLookup.resourceDescription = scheduleLookup.scheduleDescription;
    resourceLookup.version = @(scheduleLookup.version);
    return resourceLookup;
}

@end