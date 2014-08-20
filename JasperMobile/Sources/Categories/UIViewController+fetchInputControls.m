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
//  UIViewController+fetchInputControls.m
//  Jaspersoft Corporation
//

NSString * const kJMShowReportOptionsSegue = @"ShowReportOptions";
NSString * const kJMShowReportViewerSegue = @"ShowReportViewer";

#import <Objection-iOS/JSObjection.h>
#import "UIViewController+fetchInputControls.h"
#import "JMCancelRequestPopup.h"
#import "JMInputControlsHolder.h"
#import "JMRequestDelegate.h"
#import "JMReportOptionsUtil.h"
#import "JMConstants.h"

@implementation UIViewController (FetchInputControls)

@dynamic resourceClient;

- (void)fetchInputControlsForReport:(JSResourceLookup *)resourceLookup
{
    __weak typeof(self) weakSelf = self;
    
    JSObjectionInjector *objectionInjector = [JSObjection defaultInjector];
    JSRESTReport *report = [objectionInjector getObject:JSRESTReport.class];
    
    [JMCancelRequestPopup presentInViewController:self message:@"status.loading" restClient:nil cancelBlock:^{
        [report cancelAllRequests];
    }];
    
    JMReportOptionsUtil *reportOptionsUtil = [objectionInjector getObject:JMReportOptionsUtil.class];
    NSArray *reportParameters = [reportOptionsUtil reportOptionsAsParametersForReport:resourceLookup.uri];
    
    JMRequestDelegate *delegate = [JMRequestDelegate requestDelegateForFinishBlock:^(JSOperationResult *result) {
        NSMutableArray *invisibleInputControls = [NSMutableArray array];
        for (JSInputControlDescriptor *inputControl in result.objects) {
            if (!inputControl.visible.boolValue) {
                [invisibleInputControls addObject:inputControl];
            }
        }
        
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        [data setObject:resourceLookup forKey:kJMResourceLookup];
        
        if (result.objects.count - invisibleInputControls.count == 0) {
            [weakSelf performSegueWithIdentifier:kJMShowReportViewerSegue sender:data];
        } else {
            if (invisibleInputControls.count) {
                NSMutableArray *inputControls = [result.objects mutableCopy];
                [inputControls removeObjectsInArray:invisibleInputControls];
                [data setObject:inputControls forKey:kJMInputControls];
            } else {
                [data setObject:result.objects forKey:kJMInputControls];
            }
            
            [weakSelf performSegueWithIdentifier:kJMShowReportOptionsSegue sender:data];
        }
    } viewControllerToDismiss:nil];
    
    [report inputControlsForReport:resourceLookup.uri ids:nil selectedValues:reportParameters delegate:delegate];
}

- (BOOL)isReportSegue:(UIStoryboardSegue *)segue;
{
    NSString *identifier = segue.identifier;
    return [identifier isEqualToString:kJMShowReportViewerSegue] || [identifier isEqualToString:kJMShowReportOptionsSegue];
}

@end
