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
//  JMJavascriptNativeBridge.m
//  TIBCO JasperMobile
//

#import "JMJavascriptNativeBridge.h"

NSString *const kJMJavascriptNativeBridgeCallbackURL = @"jaspermobile.callback";

@interface JMJavascriptNativeBridge() <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, weak, readwrite) WKWebView *webView;
@property (nonatomic, strong) NSMutableDictionary <JMJavascriptRequest *, JMJavascriptRequestCompletion>*requestCompletions;
@property (nonatomic, strong) NSMutableDictionary <JMJavascriptRequest *, JMJavascriptRequestCompletion>*listenerCallbacks ;
@end

@implementation JMJavascriptNativeBridge
@synthesize webView = _webView, delegate = _delegate;

#pragma mark - Custom Initializers
- (instancetype __nullable)initWithWebView:(WKWebView * __nonnull)webView
{
    self = [super init];
    if (self) {
        _requestCompletions = [NSMutableDictionary dictionary];
        _listenerCallbacks = [NSMutableDictionary dictionary];
        _webView = webView;
        _webView.navigationDelegate = self;
        [_webView.configuration.userContentController addScriptMessageHandler:self
                                                                         name:@"JMJavascriptNativeBridge"];
    }
    return self;
}

+ (instancetype __nullable)bridgeWithWebView:(WKWebView * __nonnull)webView
{
    return [[self alloc] initWithWebView:webView];
}

- (void)dealloc
{
    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

#pragma mark - Public API
- (void)startLoadHTMLString:(NSString *)HTMLString
                    baseURL:(NSURL *)baseURL
                 completion:(JMJavascriptRequestCompletion __nullable)completion
{
//    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    JMJavascriptRequest *request = [JMJavascriptRequest new];
    request.command = @"DOMContentLoaded";
    JMJavascriptRequestCompletion heapBlock = [completion copy];
    __weak __typeof(self) weakSelf = self;
    JMJavascriptRequestCompletion completionWithCookies = ^(JMJavascriptResponse *callback, NSError *error) {
        JMLog(@"Callback: DOMContentLoaded");
        __typeof(self) strongSelf = weakSelf;
        // add window.onerror listener
        NSString *listenerId = @"JasperMobile.Events.Window.OnError";
        __weak __typeof(self) weakSelf = strongSelf;
        [self addListenerWithId:listenerId
                       callback:^(JMJavascriptResponse *callback, NSError *error) {
                           __typeof(self) strongSelf = weakSelf;
                           if ([strongSelf.delegate respondsToSelector:@selector(javascriptNativeBridge:didReceiveOnWindowError:)]) {
                               [strongSelf.delegate javascriptNativeBridge:strongSelf
                                                   didReceiveOnWindowError:error];
                           }
                       }];
        if (heapBlock) {
            heapBlock(callback, error);
        }
    };

    self.requestCompletions[request] = [completionWithCookies copy];

    // TODO: replace with safety approach
    if (baseURL) {
        [self.webView stopLoading];
        [self.webView loadHTMLString:HTMLString
                             baseURL:baseURL];
    }
}

- (void)sendJavascriptRequest:(JMJavascriptRequest *__nonnull)request
                   completion:(JMJavascriptRequestCompletion __nullable)completion
{
//    JMLog(@"send request: %@", request);
    if (completion) {
        self.requestCompletions[request] = [completion copy];
    }

    [self.webView evaluateJavaScript:[request fullJavascriptRequestString]
                   completionHandler:^(id result, NSError *error) {
                       JMLog(@"request: %@", request);
                       JMLog(@"error: %@", error);
                       JMLog(@"result: %@", result);
                   }];
}

- (void)addListenerWithId:(NSString *__nonnull)listenerId callback:(JMJavascriptRequestCompletion __nullable)callback
{
    if (callback) {
        JMJavascriptRequest *request = [JMJavascriptRequest new];
        request.command = listenerId;
        self.listenerCallbacks[request] = [callback copy];
    }
}

- (void)removeAllListeners
{
//    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    self.requestCompletions = [NSMutableDictionary dictionary];
    self.listenerCallbacks = [NSMutableDictionary dictionary];
}

#pragma mark - WKWebViewDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([self isLocalFileRequest:navigationAction.request]) {
        // TODO: request from delegate to allow such requests.
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    if ([self isCleaningRequest:navigationAction.request]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    if ([self isLoginRequest:navigationAction.request]) {
        // For dashboard only (without visualize)
        if (![JMUtils isSupportVisualize]) {
            [self handleUnauthRequest];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    if ([self isRequestToRunReport:navigationAction.request]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    if ([self isExternalRequest:navigationAction.request]) {
        BOOL shouldStartLoad = NO;

        if ([self.delegate respondsToSelector:@selector(javascriptNativeBridge:shouldLoadExternalRequest:)]) {
            shouldStartLoad = [self.delegate javascriptNativeBridge:self shouldLoadExternalRequest:navigationAction.request];
        }
        if (shouldStartLoad) {
            decisionHandler(WKNavigationActionPolicyAllow);
        } else {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        return;
    }

    NSLog(@"request from webView: %@", navigationAction.request);
    NSLog(@"request from webView, allHTTPHeaderFields: %@", navigationAction.request.allHTTPHeaderFields);

    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
//    JMLog(@"%@ - %@", self, NSStringFromSelector(_cmd));
    id parameters = message.body;
//    JMLog(@"parameters: %@", parameters);

    // At the moment from the webview we can receive only a dictionary
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        [self handleCallbackWithRequestParams:parameters];
    }
}

#pragma mark - Helpers

- (BOOL)isLoginRequest:(NSURLRequest *)request
{
    BOOL isLoginRequest = NO;
    // Check request to login and handle it
    NSString *loginUrlRegex = [NSString stringWithFormat:@"%@/login.html(.+)?", self.restClient.serverProfile.serverUrl];
    NSPredicate *loginUrlValidator = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", loginUrlRegex];
    NSString *requestUrl = request.URL.absoluteString;
    if ([loginUrlValidator evaluateWithObject:requestUrl]) {
        isLoginRequest = YES;
    }
    return isLoginRequest;
}

- (BOOL)isRequestToRunReport:(NSURLRequest *)request
{
    BOOL isRequestToRunReport = NO;

    NSString *requestURLString = request.URL.absoluteString;
    //  don't let run link run report
    if ([requestURLString rangeOfString:@"_flowId=viewReportFlow&reportUnit"].length || [requestURLString rangeOfString:@"_flowId=viewReportFlow&_report"].length) {
        [[UIApplication sharedApplication] openURL:request.URL];
        isRequestToRunReport = YES;
    }
    return isRequestToRunReport;
}

- (BOOL)isExternalRequest:(NSURLRequest *)request
{
    BOOL isExternalRequest = NO;

    NSString *requestURLString = request.URL.absoluteString;
    NSString *requestHostURLString = request.URL.host;
    NSURL *serverURL = [NSURL URLWithString:self.restClient.serverProfile.serverUrl];
    NSString *serverHostURLString = serverURL.host;
    NSString *callbackHostURLString = kJMJavascriptNativeBridgeCallbackURL;

    BOOL isServerURL = [requestHostURLString isEqualToString:serverHostURLString];
    BOOL isCallbackURL = [requestHostURLString isEqualToString:callbackHostURLString];

    if (requestURLString.length > 0 && !(isServerURL || isCallbackURL)) {
        isExternalRequest = YES;
    }

    return isExternalRequest;
}

- (BOOL)isLocalFileRequest:(NSURLRequest *)request
{
    BOOL isLocalFileRequest = NO;
    if ([request.URL isFileURL]) {
        isLocalFileRequest = YES;
    }
    return isLocalFileRequest;
}

- (BOOL)isCleaningRequest:(NSURLRequest *)request
{
    BOOL isCleaningRequest = NO;
    NSString *requestURLString = request.URL.absoluteString;
    if ([requestURLString isEqualToString:@"about:blank"]) {
        isCleaningRequest = YES;
    }
    return isCleaningRequest;
}

#pragma mark - Callbacks
- (void)handleCallbackWithRequestParams:(NSDictionary*)parameters
{
    if (parameters) {
        JMJavascriptResponse *response = [JMJavascriptResponse new];
        NSString *type = parameters[@"type"];
        if ([type isEqualToString:@"logging"]) {
            response.type = JMJavascriptCallbackTypeLog;
        } else if ([type isEqualToString:@"callback"]) {
            response.type = JMJavascriptCallbackTypeCallback;
        } else if ([type isEqualToString:@"listener"]) {
            response.type = JMJavascriptCallbackTypeListener;
        }
        response.command = parameters[@"command"];
        id params = parameters[@"parameters"];
        // TODO: investigate other cases
        if (![params isKindOfClass:[NSDictionary class]]) {
            params = nil;
        }
        response.parameters = params;
        [self didReceiveResponse:response];
    } else {
        // TODO: add general errors handling
    }
}

- (void)handleUnauthRequest
{
    NSString *unauthorizedListenerId = @"JasperMobile.Dashboard.API.unauthorized";
    for (JMJavascriptRequest *request in self.listenerCallbacks) {
        if ([request.command isEqualToString:unauthorizedListenerId]) {
            JMJavascriptRequestCompletion completion = self.listenerCallbacks[request];
            NSError *error = [self makeErrorFromWebViewError:@{
                    @"code" : @"authentication.error"
            }];
            completion(nil, error);
            break;
        }
    }
}

- (void)didReceiveResponse:(JMJavascriptResponse *)response
{
//    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
//    JMLog(@"%@", response);
    switch(response.type) {
        case JMJavascriptCallbackTypeLog: {
            JMLog(@"Bridge Message: %@", response.parameters[@"message"]);
            break;
        }
        case JMJavascriptCallbackTypeListener: {
            for (JMJavascriptRequest *request in self.listenerCallbacks) {
                if ([request.command isEqualToString:response.command]) {
                    JMJavascriptRequestCompletion completion = self.listenerCallbacks[request];
                    if (response.parameters && response.parameters[@"error"]) {
                        NSDictionary *errorJSON = response.parameters[@"error"];
                        NSError *error = [self makeErrorFromWebViewError:errorJSON];
                        completion(nil, error);
                    } else {
                        completion(response, nil);
                    }
                    break;
                }
            }
            break;
        }
        case JMJavascriptCallbackTypeCallback: {
            JMJavascriptRequest *foundRequest;
            for (JMJavascriptRequest *request in self.requestCompletions) {
                if ([request.command isEqualToString:response.command]) {
                    foundRequest = request;
                    JMJavascriptRequestCompletion completion = self.requestCompletions[request];
                    if (response.parameters && response.parameters[@"error"]) {
                        NSDictionary *errorJSON = response.parameters[@"error"];
                        NSError *error = [self makeErrorFromWebViewError:errorJSON];
                        completion(nil, error);
                    } else {
                        completion(response, nil);
                    }
                    break;
                }
            }
            if (foundRequest) {
                [self.requestCompletions removeObjectForKey:foundRequest];
            }
            break;
        }
    }
}

- (NSError *)makeErrorFromWebViewError:(NSDictionary *)errorJSON
{
    NSString *visualizeErrorDomain = @"Visualize Error Domain";
    NSInteger code = JMJavascriptNativeBridgeErrorTypeOther;

    id errorCode = errorJSON[@"code"];
    if (errorCode && [errorCode isKindOfClass:[NSString class]]) {
        NSString *errorCodeString = errorCode;
        if ([errorCodeString isEqualToString:@"window.onerror"]) {
            code = JMJavascriptNativeBridgeErrorTypeWindow;
        } else if ([errorCodeString isEqualToString:@"unexpected.error"]) {
            code = JMJavascriptNativeBridgeErrorTypeUnexpected;
        } else if ([errorCodeString isEqualToString:@"authentication.error"]) {
            code = JMJavascriptNativeBridgeErrorAuthError;
        }
    }
    // TODO: need add handle integer codes?

    NSString *errorMessage = errorJSON[@"message"];
    NSDictionary *userInfo;
    if (errorMessage) {
        userInfo = @{
                NSLocalizedDescriptionKey: errorMessage
        };
    } else {
        userInfo = @{
                NSLocalizedDescriptionKey: @"Error"
        };
    }
    NSError *error = [NSError errorWithDomain:visualizeErrorDomain
                                         code:code
                                     userInfo:userInfo];
    return error;
}

@end