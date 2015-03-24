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
//  JMVisualizeClient.h
//  TIBCO JasperMobile
//

#import "JMVisualizeClient.h"

@interface JMVisualizeClient()
@property (assign, nonatomic) BOOL isActive;
@end


@implementation JMVisualizeClient

@synthesize resourceLookup = _resourceLookup;

#pragma mark - Initialize
- (instancetype)init {
    self = [super init];
    if (self) {
        _isActive = NO;
    }
    return self;
}

#pragma mark - Public API
- (void)setup {
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"visualize_test" ofType:@"html"];
    NSError *error;
    NSString *html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:&error];

    if (html) {
        NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/", self.restClient.serverProfile.serverUrl]];
        NSURL *visualizePathURL = [NSURL URLWithString:@"client/visualize.js" relativeToURL:baseURL];

        html = [html stringByReplacingOccurrencesOfString:@"VISUALIZE_PATH" withString:visualizePathURL.absoluteString]; // relative server base url
        [self.webView loadHTMLString:html baseURL:baseURL];
    } else {
        NSLog(@"error loading html: %@", error.localizedDescription);
    }
}

- (void)runDashboard {
    if (!self.isActive) {
        self.isActive = YES;
        NSLog(@"call dashboard api");
        // set credentials
        NSString *credentials = @"JasperMobile.auth.setCredentials(\"NAME\", \"PASSWORD\");";
        credentials = [credentials stringByReplacingOccurrencesOfString:@"NAME" withString:self.restClient.serverProfile.username];
        credentials = [credentials stringByReplacingOccurrencesOfString:@"PASSWORD" withString:self.restClient.serverProfile.username];
        [self.webView stringByEvaluatingJavaScriptFromString:credentials];

        // run dashboard
        NSString *runDashboardCall = @"JasperMobile.dashboard.run(\"REPORT_PATH\");";
        runDashboardCall = [runDashboardCall stringByReplacingOccurrencesOfString:@"REPORT_PATH" withString:self.resourceLookup.uri];
        [self.webView stringByEvaluatingJavaScriptFromString:runDashboardCall];
    }
}

- (BOOL)isCallbackRequest:(NSURLRequest *)request {
    NSString *requestURLString = request.URL.absoluteString;
    NSRange range = [requestURLString rangeOfString:@"http://jaspermobile.callback/"];
    if (range.length) {
        NSRange callbackRange = NSMakeRange(range.length, requestURLString.length - range.length);
        NSString *callback = [requestURLString substringWithRange:callbackRange];
        NSArray *callbackItems = [callback componentsSeparatedByString:@"&"];

        NSString *commandItem = callbackItems[0];
        NSRange commandRange = [callback rangeOfString:@"command:"];
        NSString *command = [commandItem substringWithRange:NSMakeRange(commandRange.length, commandItem.length - commandRange.length)];

        if ([command isEqualToString:@"didEndLoading"]) {
            if ([self.delegate respondsToSelector:@selector(visualizeClientDidEndLoading)]) {
                [self.delegate visualizeClientDidEndLoading];
            }
        } else if ([command isEqualToString:@"maximize"]) {
            NSString *titleItem = callbackItems[1];
            NSRange titleRange = [titleItem rangeOfString:@"title:"];

            NSString *title = [titleItem substringWithRange:NSMakeRange(titleRange.length, titleItem.length - titleRange.length)];

            if ([self.delegate respondsToSelector:@selector(visualizeClientDidMaximizeDashletWithTitle:)]) {
                [self.delegate visualizeClientDidMaximizeDashletWithTitle:[title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
        }
        return YES;
    }
    return NO;
}

- (void)minimizeDashlet {
    NSString *minimizeDashletCall = @"JasperMobile.htmlHandler.minimizeDashlet()";
    [self.webView stringByEvaluatingJavaScriptFromString:minimizeDashletCall];
}

#pragma mark - Private API


@end