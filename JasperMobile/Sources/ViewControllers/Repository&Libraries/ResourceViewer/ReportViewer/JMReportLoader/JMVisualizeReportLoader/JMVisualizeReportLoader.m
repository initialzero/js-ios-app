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
//  JMVisualizeReportLoader.h
//  TIBCO JasperMobile
//

#import "JMBaseReportViewerViewController.h"
#import "JMVisualizeReportLoader.h"
#import "JMVisualizeReport.h"
#import "JMJavascriptNativeBridge.h"
#import "JMJavascriptRequest.h"
#import "JMVisualizeManager.h"
#import "JMJavascriptCallback.h"

typedef NS_ENUM(NSInteger, JMReportViewerAlertViewType) {
    JMReportViewerAlertViewTypeEmptyReport,
    JMReportViewerAlertViewTypeErrorLoad
};

@interface JMVisualizeReportLoader() <JMJavascriptNativeBridgeDelegate>
@property (nonatomic, weak) JMVisualizeReport *report;
@property (nonatomic, assign, readwrite) BOOL isReportInLoadingProcess;

@property (nonatomic, copy) void(^reportLoadCompletion)(BOOL success, NSError *error);
@property (nonatomic, copy) NSString *exportFormat;
@property (nonatomic, strong) JMVisualizeManager *visualizeManager;
@end

@implementation JMVisualizeReportLoader
@synthesize bridge = _bridge, delegate = _delegate;

#pragma mark - Lifecycle
- (instancetype)initWithReport:(JMVisualizeReport *)report
{
    self = [super init];
    if (self) {
        _report = report;
        _visualizeManager = [JMVisualizeManager new];
    }
    return self;
}

+ (instancetype)loaderWithReport:(JMVisualizeReport *)report
{
    return [[self alloc] initWithReport:report];
}

#pragma mark - Custom accessors
-(void)setReportLoadCompletion:(void (^)(BOOL, NSError *))reportLoadCompletion
{
    if (_reportLoadCompletion != reportLoadCompletion) {
        _reportLoadCompletion = [reportLoadCompletion copy];
    }
}

- (void)setBridge:(JMJavascriptNativeBridge *)bridge
{
    _bridge = bridge;
    _bridge.delegate = self;
}

#pragma mark - Public API
- (void)runReportWithPage:(NSInteger)page completion:(void(^)(BOOL success, NSError *error))completionBlock
{
    self.isReportInLoadingProcess = YES;
    [self.report updateLoadingStatusWithValue:NO];
    [self.report updateCountOfPages:NSNotFound];

    if ([[JMVisualizeWebViewManager sharedInstance] isWebViewEmpty:self.bridge.webView]) {
        self.reportLoadCompletion = completionBlock;
        [self.report updateCurrentPage:page];
        [self.report updateCountOfPages:NSNotFound];

        [self startLoadHTMLWithCompletion:@weakself(^(BOOL success, NSError *error)) {
            if (success) {
                [self.bridge startLoadHTMLString:self.report.HTMLString
                                         baseURL:[NSURL URLWithString:self.report.baseURLString]];
            } else {
                NSLog(@"Error loading HTML%@", error.localizedDescription);
            }
        }@weakselfend];
    } else {
        [self fetchPageNumber:page withCompletion:completionBlock];
    }
}

- (void)fetchPageNumber:(NSInteger)pageNumber withCompletion:(void(^)(BOOL success, NSError *error))completionBlock
{
    self.reportLoadCompletion = completionBlock;
    [self.report updateCurrentPage:pageNumber];

    if (!self.report.isReportAlreadyLoaded) {
        NSString *parametersAsString = [self createParametersAsString];
        JMJavascriptRequest *request = [JMJavascriptRequest new];
        request.command = @"MobileReport.run(%@);";
        request.parametersAsString = [NSString stringWithFormat:@"{'uri': '%@', 'params': %@, 'pages' : '%@'}", self.report.reportURI, parametersAsString, @(pageNumber)];
        [self.bridge sendRequest:request];
    } else {
        JMJavascriptRequest *request = [JMJavascriptRequest new];
        request.command = @"MobileReport.selectPage(%@);";
        request.parametersAsString = @(pageNumber).stringValue;
        [self.bridge sendRequest:request];
    }
}

- (void) cancelReport
{
    // TODO: need cancel?
}

- (void)applyReportParametersWithCompletion:(void(^)(BOOL success, NSError *error))completion
{
    if ([[JMVisualizeWebViewManager sharedInstance] isWebViewEmpty:self.bridge.webView]) {
        self.isReportInLoadingProcess = YES;
        [self.report updateLoadingStatusWithValue:NO];

        self.reportLoadCompletion = completion;
        [self.report updateCurrentPage:1];

        [self startLoadHTMLWithCompletion:@weakself(^(BOOL success, NSError *error)) {
                if (success) {
                    [self.bridge startLoadHTMLString:self.report.HTMLString
                                             baseURL:[NSURL URLWithString:self.report.baseURLString]];
                } else {
                    NSLog(@"Error loading HTML%@", error.localizedDescription);
                }
            }@weakselfend];
    } else if (!self.report.isReportAlreadyLoaded) {
        self.isReportInLoadingProcess = YES;
        [self.report updateLoadingStatusWithValue:NO];
        [self.report updateCountOfPages:NSNotFound];

        [self fetchPageNumber:1 withCompletion:completion];
    } else {
        self.reportLoadCompletion = completion;
        [self.report updateCurrentPage:1];
        [self.report updateCountOfPages:NSNotFound];

        JMJavascriptRequest *request = [JMJavascriptRequest new];
        request.command = @"MobileReport.applyReportParams(%@);";
        request.parametersAsString = [self createParametersAsString];
        [self.bridge sendRequest:request];
    }
}

- (void)refreshReportWithCompletion:(void(^)(BOOL success, NSError *error))completion
{
    self.reportLoadCompletion = completion;
    [self.report updateCurrentPage:1];
    [self.report updateCountOfPages:NSNotFound];

    JMJavascriptRequest *request = [JMJavascriptRequest new];
    request.command = @"MobileReport.refresh(%@);";
    request.parametersAsString = @"";
    [self.bridge sendRequest:request];
}

- (void)exportReportWithFormat:(NSString *)exportFormat
{
    self.exportFormat = exportFormat;

    JMJavascriptRequest *request = [JMJavascriptRequest new];
    request.command = @"MobileReport.exportReport(%@);";
    request.parametersAsString = exportFormat;
    [self.bridge sendRequest:request];
}

- (void)destroyReport
{
    JMJavascriptRequest *request = [JMJavascriptRequest new];
    request.command = @"MobileReport.destroy(%@);";
    request.parametersAsString = @"";
    [self.bridge sendRequest:request];

    [self.report updateLoadingStatusWithValue:NO];
}

- (void)authenticate
{
    JMJavascriptRequest *request = [JMJavascriptRequest new];
    request.command = @"MobileReport.authorize(%@);";
    request.parametersAsString = [NSString stringWithFormat:@"{'username': '%@', 'password': '%@', 'organization': '%@'}", self.restClient.serverProfile.username, self.restClient.serverProfile.password, self.restClient.serverProfile.organization];
    [self.bridge sendRequest:request];
}

#pragma mark - Private
- (void)startLoadHTMLWithCompletion:(void(^)(BOOL success, NSError *error))completion
{
    NSLog(@"visuzalise.js did start load");
    [self.visualizeManager loadVisualizeJSWithCompletion:@weakself(^(BOOL success, NSError *error)){
        if (success) {
            NSLog(@"visuzalise.js did end load");
            NSString *baseURLString = self.restClient.serverProfile.serverUrl;
            [self.report updateHTMLString:[self.visualizeManager htmlString] baseURLSring:baseURLString];

            if (completion) {
                completion(YES, nil);
            }
        } else {
            // TODO: handle this error
            NSLog(@"Error loading visualize.js");
            // TODO: add error code
            NSError *error = [NSError errorWithDomain:kJMReportLoaderErrorDomain
                                                 code:0
                                             userInfo:nil];
            if (completion) {
                completion(NO, error);
            }
        }
    }@weakselfend];
}

#pragma mark - JMJavascriptNativeBridgeDelegate
- (void)javascriptNativeBridge:(JMJavascriptNativeBridge *)bridge didReceiveCallback:(JMJavascriptCallback *)callback
{
    NSLog(@"response parameters: %@", callback.parameters);
    if ([callback.type isEqualToString:@"DOMContentLoaded"]) {
        [self handleDOMContentLoaded];
    } else if ([callback.type isEqualToString:@"runReport"]) {
        [self handleRunReportWithParameters:callback.parameters];
    } else if ([callback.type isEqualToString:@"handleReferenceClick"]) {
        [self handleReferenceClickWithParameters:callback.parameters];
    } else if ([callback.type isEqualToString:@"reportDidObtaineMultipageState"]) {
        [self handleEventObtaineMultipageStateWithParameters:callback.parameters];
    } else if ([callback.type isEqualToString:@"reportRunDidCompleted"]) {
        [self handleEventReportRunDidCompletedWithParameters:callback.parameters];
    } else if([callback.type isEqualToString:@"reportDidEndRenderSuccessful"]) {
        [self handleReportEndRenderSuccessfull];
    } else if([callback.type isEqualToString:@"reportDidEndRenderFailured"]) {
        [self handleReportEndRenderFailedWithParameters:callback.parameters];
    } else if ([callback.type isEqualToString:@"exportPath"]) {
        [self handleExportParameters:callback.parameters];
    } else if ([callback.type isEqualToString:@"reportDidDidEndRefreshSuccessful"]) {
        [self handleRefreshDidEndSuccessful];
    } else if ([callback.type isEqualToString:@"reportDidEndRefreshFailured"]) {
        [self handleRefreshDidEndFailedWithParameters:callback.parameters];
    }
}

#pragma mark - Helpers
- (NSString *)createParametersAsString
{
    NSMutableString *parametersAsString = [@"{" mutableCopy];
    for (JSReportParameter *parameter in self.report.reportParameters) {
        NSArray *values = parameter.value;
        NSString *stringValues = @"";
        for (NSString *value in values) {
            stringValues = [stringValues stringByAppendingFormat:@"\"%@\",", value];
        }
        [parametersAsString appendFormat:@"\"%@\":[%@],", parameter.name, stringValues];
    }
    [parametersAsString appendString:@"}"];
    return [parametersAsString copy];
}

- (NSError *)createErrorWithType:(JMReportLoaderErrorType)errorType errorMessage:(NSString *)errorMessage
{
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorMessage ?: JMCustomLocalizedString(@"report.viewer.visualize.render.error", nil) };
    NSError *error = [NSError errorWithDomain:kJMReportLoaderErrorDomain
                                         code:errorType
                                     userInfo:userInfo];
    return error;
}

#pragma mark - DOM listeners
- (void)handleDOMContentLoaded
{
    [self authenticate];
    [self fetchPageNumber:self.report.currentPage withCompletion:self.reportLoadCompletion];
}

#pragma mark - Run report
- (void)handleReportEndRenderSuccessfull
{
    NSLog(@"report rendering end");

    [self.report updateLoadingStatusWithValue:YES];

    if (self.reportLoadCompletion) {
        self.reportLoadCompletion(YES, nil);
    }
}

- (void)handleReportEndRenderFailedWithParameters:(NSDictionary *)parameters
{
    if (self.reportLoadCompletion) {
        NSString *errorString = parameters[@"error"];
        errorString = [errorString stringByRemovingPercentEncoding];
        JMReportLoaderErrorType errorType = JMReportLoaderErrorTypeUndefined;
        if (errorString && [errorString rangeOfString:@"authentication.error"].length) {
            errorType = JMReportLoaderErrorTypeAuthentification;
        }
        self.reportLoadCompletion(NO, [self createErrorWithType:errorType errorMessage:errorString]);
    }
}

- (void)handleEventReportRunDidCompletedWithParameters:(NSDictionary *)parameters
{
    NSInteger countOfPages = ((NSNumber *)parameters[@"pages"]).integerValue;
    [self.report updateCountOfPages:countOfPages];
}

#pragma mark - Multipage
- (void)handleEventObtaineMultipageStateWithParameters:(NSDictionary *)parameters
{
    BOOL isMultiPage =((NSNumber *)parameters[@"isMultiPage"]).boolValue;
    [self.report updateIsMultiPageReport:isMultiPage];
}

#pragma mark - Handle refresh
- (void)handleRefreshDidEndSuccessful
{
    [self.report updateLoadingStatusWithValue:YES];

    if (self.reportLoadCompletion) {
        self.reportLoadCompletion(YES, nil);
    }
}

- (void)handleRefreshDidEndFailedWithParameters:(NSDictionary *)parameters
{
    if (self.reportLoadCompletion) {
        // TODO: add error
        self.reportLoadCompletion(NO, nil);
    }
}

#pragma mark - Export report
- (void)handleExportParameters:(NSDictionary *)parameters
{
    NSString *outputResourcesPath = parameters[@"link"];
    if (outputResourcesPath) {
        if ([self.delegate respondsToSelector:@selector(reportLoader:didReceiveOutputResourcePath:fullReportName:)]) {
            NSString *fullReportName = [NSString stringWithFormat:@"%@.%@", self.report.resourceLookup.label, self.exportFormat];
            [self.delegate reportLoader:self didReceiveOutputResourcePath:outputResourcesPath fullReportName:fullReportName];
        }
    }
}

#pragma mark - Hyperlinks handlers
- (void)handleReferenceClickWithParameters:(NSDictionary *)parameters
{
    NSString *locationString = parameters[@"location"];
    if (locationString) {
        NSURL *locationURL = [NSURL URLWithString:locationString];
        if ([self.delegate respondsToSelector:@selector(reportLoader:didReceiveOnClickEventForReference:)]) {
            [self.delegate reportLoader:self didReceiveOnClickEventForReference:locationURL];
        }
    }
}

- (void)handleRunReportWithParameters:(NSDictionary *)parameters
{
    NSString *params = parameters[@"params"];
    if (!params) {
        return;
    }
    NSData *jsonData = [params dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

    NSString *reportPath;
    if (json) {
        reportPath = json[@"_report"];

        if (reportPath) {
            [self.restClient resourceLookupForURI:reportPath resourceType:[JSConstants sharedInstance].WS_TYPE_REPORT_UNIT completionBlock:^(JSOperationResult *result) {
                NSError *error = result.error;
                if (error) {
                    NSLog(@"error: %@", error.localizedDescription);

                    NSString *errorString = error.localizedDescription;
                    JMReportLoaderErrorType errorType = JMReportLoaderErrorTypeUndefined;
                    if (errorString && [errorString rangeOfString:@"unauthorized"].length) {
                        errorType = JMReportLoaderErrorTypeAuthentification;
                    }
                    self.reportLoadCompletion(NO, [self createErrorWithType:errorType errorMessage:errorString]);
                } else {
                    NSLog(@"objects: %@", result.objects);
                    JSResourceLookup *resourceLookup = [result.objects firstObject];
                    if (resourceLookup) {
                        NSMutableArray *reportParameters = [NSMutableArray array];
                        for (NSString *key in json.allKeys) {
                            if (![key isEqualToString:@"_report"]) {
                                JSReportParameter *reportParameter = [[JSReportParameter alloc] initWithName:key
                                                                                                       value:@[json[key]]];
                                [reportParameters addObject:reportParameter];
                            }
                        }

                        if ([self.delegate respondsToSelector:@selector(reportLoader:didReceiveOnClickEventForResourceLookup:withParameters:)]) {
                            [self.delegate reportLoader:self didReceiveOnClickEventForResourceLookup:resourceLookup withParameters:[reportParameters copy]];
                        }
                    }
                }
            }];
        }

    } else {
        NSLog(@"parse json with error: %@", jsonError.localizedDescription);
    }
}

@end