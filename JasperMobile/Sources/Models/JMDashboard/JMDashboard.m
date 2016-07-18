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
//  JMDashboard.h
//  TIBCO JasperMobile
//

#import "JMDashboard.h"
#import "JMDashboardParameter.h"

@interface JMDashboard()
// setters
@property (nonatomic, strong, readwrite) NSURLRequest *resourceRequest;
@end

@implementation JMDashboard

#pragma mark - LifyCycle
- (instancetype)initWithResourceLookup:(JSResourceLookup *)resource
{
    self = [super initWithResourceLookup:resource];
    if (self) {
        _resourceRequest = [self createResourceRequest];
    }
    return self;
}

#pragma mark - Public API

#pragma mark - Private API

#pragma mark - Helpers
- (NSURLRequest *)createResourceRequest
{
    NSString *dashboardUrl = [NSString stringWithFormat:@"flow.html?_flowId=dashboardRuntimeFlow&viewAsDashboardFrame=true&dashboardResource=%@", self.resourceURI];
    dashboardUrl = [dashboardUrl stringByAppendingString:@"&"];
    dashboardUrl = [[NSURL URLWithString:dashboardUrl relativeToURL:self.restClient.baseURL] absoluteString];
    
    NSMutableURLRequest *dashboardRequest = [self.restClient.requestSerializer requestWithMethod:@"GET" URLString:dashboardUrl parameters:nil error:nil];
    dashboardRequest.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    [dashboardRequest addValue:[self cookiesAsStringFromCookies:self.restClient.cookies]
            forHTTPHeaderField:@"Cookie"];

    return dashboardRequest;
}

- (void)updateResourceRequest
{
    self.resourceRequest = [self createResourceRequest];
}

- (NSString *)cookiesAsStringFromCookies:(NSArray <NSHTTPCookie *>*)cookies
{
    NSString *cookiesAsString = @"";
    for (NSHTTPCookie *cookie in cookies) {
        NSString *name = cookie.name;
        NSString *value = cookie.value;
        cookiesAsString = [cookiesAsString stringByAppendingFormat:@"%@=%@; ", name, value];
    }
    return cookiesAsString;
}

@end
