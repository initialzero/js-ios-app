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

#import "JMReportViewer.h"
#import "JMRequestDelegate.h"
#import "JMReportClientHolder.h"
#import "JMCancelRequestPopup.h"
#import "UIViewController+fetchInputControls.h"
#import "UIAlertView+LocalizedAlert.h"

typedef NS_ENUM(NSInteger, JMReportViewerOutputResourceType) {
    JMReportViewerOutputResourceType_None = 0,
    JMReportViewerOutputResourceType_LoadingNow,
    JMReportViewerOutputResourceType_NotFinal,
    JMReportViewerOutputResourceType_Final,
    JMReportViewerOutputResourceType_AlreadyLoaded = JMReportViewerOutputResourceType_NotFinal | JMReportViewerOutputResourceType_Final
};

#define kJMReportViewerStatusCheckingInterval       1.f

NSString * const kJMRestStatusReady = @"ready";

@interface JMReportViewer() <UIAlertViewDelegate, JMReportClientHolder, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSString *requestId;
@property (nonatomic, assign) BOOL reportExequtingStatusIsReady;

@property (nonatomic, strong) NSMutableDictionary *exportIdsDictionary;
@property (nonatomic, assign) JMReportViewerOutputResourceType outputResourceType;

@property (nonatomic, strong) NSTimer *statusCheckingTimer;

@property (nonatomic, strong) NSUndoManager *icUndoManager;

@property (nonatomic, readwrite) NSInteger countOfPages;
@property (nonatomic, readwrite) BOOL multiPageReport;

@end

@implementation JMReportViewer
objection_requires(@"resourceClient", @"reportClient")

@synthesize reportClient    = _reportClient;
@synthesize resourceClient = _resourceClient;
@synthesize resourceLookup = _resourceLookup;

#pragma mark - Initialization

- (instancetype)initWithResourceLookup:(JSResourceLookup *)resource
{
    self = [super init];
    if (self) {
        [[JSObjection defaultInjector] injectDependencies:self];
        self.icUndoManager = [NSUndoManager new];
        [self resetReportViewer];
        self.resourceLookup = resource;
    }
    return self;
}

#pragma mark - 
#pragma mark - Properties
- (void)setCurrentPage:(NSInteger)currentPage
{
    if (currentPage != _currentPage) {
        _currentPage = currentPage;
        [self runExportExecutionForPage:_currentPage];
        [self.delegate reportViewerDidChangedPagination:self];
    }
}

- (void)setCountOfPages:(NSInteger)countOfPages
{
    if (countOfPages != _countOfPages) {
        _countOfPages = countOfPages;
        if (self.currentPage > _countOfPages) {
            self.currentPage = _countOfPages;
        }
        _multiPageReport = (self.countOfPages > 1) && (self.countOfPages != kJMCountOfPagesUnknown);
        [self.delegate reportViewerDidChangedPagination:self];
        if ([self reportIsEmpty]) {
            UIAlertView *alertView = [UIAlertView localizedAlertWithTitle:@"detail.report.viewer.emptyreport.title" message:nil delegate:nil cancelButtonTitle:@"dialog.button.ok" otherButtonTitles: nil];
            if ([self.icUndoManager canUndo]) {
                alertView.delegate = self;
                alertView.message = JMCustomLocalizedString(@"detail.report.viewer.emptyreport.message", nil);
                [alertView addButtonWithTitle:JMCustomLocalizedString(@"dialog.button.cancel", nil)];
            }
            [alertView show];
        }
    }
}

- (void)setMultiPageReport:(BOOL)multiPageReport
{
    if (_multiPageReport != multiPageReport) {
        _multiPageReport = multiPageReport;
        [self.delegate reportViewerDidChangedPagination:self];
    }
}

- (void)setInputControls:(NSMutableArray *)inputControls
{
    if (self.inputControls != inputControls) {
        if (self.inputControls) {
            [[self.icUndoManager prepareWithInvocationTarget:self] setInputControls:self.inputControls];
            [self.icUndoManager setActionName:@"ResetChanges"];
        }
        _inputControls = inputControls;
    }
}

- (void) resetReportViewer
{
    self.outputResourceType = JMReportViewerOutputResourceType_None;
    self.exportIdsDictionary = [NSMutableDictionary dictionary];
    self.reportExequtingStatusIsReady = NO;
    self.requestId = nil;
    self.countOfPages = kJMCountOfPagesUnknown;
    self.currentPage = 1;
}

- (void) runReportExecution
{
    if (self.outputResourceType & JMReportViewerOutputResourceType_AlreadyLoaded) {
        [JMCancelRequestPopup presentInViewController:self.delegate message:@"status.loading" restClient:self.resourceClient cancelBlock:nil];
    }
    
    [self resetReportViewer];
    
    JMRequestDelegate *requestDelegate = [JMRequestDelegate requestDelegateForFinishBlock:@weakself(^(JSOperationResult *result)) {
        JSReportExecutionResponse *reportExecution = [result.objects objectAtIndex:0];
        self.requestId = reportExecution.requestId;
        self.reportExequtingStatusIsReady = [reportExecution.status.status isEqualToString:kJMRestStatusReady];
        if (self.reportExequtingStatusIsReady) {
            self.countOfPages = [reportExecution.totalPages integerValue];
        } else {
            [self startStatusChecking];
        }
        if (![self reportIsEmpty]) {
            [self runExportExecutionForPage:self.currentPage];
//            [self runExportExecutionForPage:self.currentPage + 1];
        }
    } @weakselfend
    errorBlock:nil
    viewControllerToDismiss:(!self.requestId) ? self.delegate : nil];
    
    NSMutableArray *parameters = [NSMutableArray array];
    for (JSInputControlDescriptor *inputControlDescriptor in self.inputControls) {
        [parameters addObject:[[JSReportParameter alloc] initWithName:inputControlDescriptor.uuid value:inputControlDescriptor.selectedValues]];
    }
    
    [self.reportClient runReportExecution:self.resourceLookup.uri async:YES outputFormat:[JSConstants sharedInstance].CONTENT_TYPE_HTML
                              interactive:YES freshData:YES saveDataSnapshot:NO ignorePagination:NO transformerKey:nil
                                    pages:nil attachmentsPrefix:nil parameters:parameters delegate:requestDelegate];
}

- (void) runExportExecutionForPage:(NSInteger)page
{
    if (self.requestId) {
        if (![self.exportIdsDictionary objectForKey:@(page)]) {
            [JMCancelRequestPopup presentInViewController:self.delegate message:@"status.loading" restClient:self.resourceClient cancelBlock:nil];

            JMRequestDelegate *requestDelegate = [JMRequestDelegate requestDelegateForFinishBlock:@weakself(^(JSOperationResult *result)) {
                JSExportExecutionResponse *export = [result.objects objectAtIndex:0];
                [self.exportIdsDictionary setObject:export.uuid forKey:@(page)];
                [self loadOutputResourcesForPage:page displayImmediatelly:page == self.currentPage];
            } @weakselfend
            errorBlock:nil
            viewControllerToDismiss:nil];
            
            NSString *pagesString = [NSString stringWithFormat:@"%zd", page];
            NSString *attachemntPreffix = [JSConstants sharedInstance].REST_EXPORT_EXECUTION_ATTACHMENTS_PREFIX_URI;

            // Fix for JRS version smaller 5.6.0
            if (self.reportClient.serverInfo.versionAsFloat < [JSConstants sharedInstance].SERVER_VERSION_CODE_EMERALD_5_6_0) {
                attachemntPreffix = nil;
            }
            [self.reportClient runExportExecution:self.requestId outputFormat:[JSConstants sharedInstance].CONTENT_TYPE_HTML pages:pagesString allowInlineScripts:NO attachmentsPrefix:attachemntPreffix delegate:requestDelegate];
        } else {
            [self loadOutputResourcesForPage:page displayImmediatelly:page == self.currentPage];
        }
    }
}

- (void) loadOutputResourcesForPage:(NSInteger)page displayImmediatelly:(BOOL)display
{
    NSString *exportID = [self.exportIdsDictionary objectForKey:@(page)];
    if (display) {
        self.outputResourceType = JMReportViewerOutputResourceType_LoadingNow;
    }

    // Fix for JRS version smaller 5.6.0
    NSString *fullExportID = exportID;
    if (self.reportClient.serverInfo.versionAsFloat < [JSConstants sharedInstance].SERVER_VERSION_CODE_EMERALD_5_6_0) {
        fullExportID = [NSString stringWithFormat:@"%@;pages=%zd", exportID, self.currentPage];
    }
    
    JMRequestDelegate *requestDelegate = [JMRequestDelegate requestDelegateForFinishBlock:@weakself(^(JSOperationResult *result)) {
        if ([result.MIMEType isEqualToString:[JSConstants sharedInstance].REST_SDK_MIMETYPE_USED]) {
            JSErrorDescriptor *error = [result.objects objectAtIndex:0];
            if (!display) {
                [UIAlertView localizedAlertWithTitle:nil message:error.message delegate:nil cancelButtonTitle:@"dialog.button.ok" otherButtonTitles: nil];
            } else {
#warning NEED TEST OTHER ERRORS!!!!!
                if ([error.errorCode isEqualToString:@"illegal.parameter.value.error"]) {
                    self.countOfPages = page - 1;
                }
            }
        } else {
            if (display) {
                NSString *finalityStatus = [result.allHeaderFields objectForKey:@"output-final"];
                if (finalityStatus) {
                    self.outputResourceType = [finalityStatus boolValue] ? JMReportViewerOutputResourceType_Final : JMReportViewerOutputResourceType_NotFinal;
                } else {
                    self.outputResourceType = JMReportViewerOutputResourceType_Final;
                }
                self.outputResourceType = (finalityStatus && [finalityStatus boolValue]) ? JMReportViewerOutputResourceType_Final : JMReportViewerOutputResourceType_NotFinal;
                [self.delegate reportViewer:self loadHTMLString:result.bodyAsString baseURL:self.reportClient.serverProfile.serverUrl];
            }
            if (page > 1) {
                self.multiPageReport = YES;
            }
        }
    } @weakselfend
    errorBlock:nil
    viewControllerToDismiss: nil];
    
    [self.reportClient loadReportOutput:self.requestId exportOutput:fullExportID loadForSaving:NO path:nil delegate:requestDelegate];
    
//    NSString *reportUrl = [self.reportClient generateReportOutputUrl:self.requestId exportOutput:fullExportID];
//    [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:reportUrl]] delegate:self];
}

- (void)startStatusChecking
{
    [self checkStatus];
    self.statusCheckingTimer = [NSTimer scheduledTimerWithTimeInterval:kJMReportViewerStatusCheckingInterval target:self selector:@selector(checkStatus) userInfo:nil repeats:YES];
}

- (void)cancelStatusChecking
{
    [self.statusCheckingTimer invalidate];
    if (self.outputResourceType == JMReportViewerOutputResourceType_NotFinal && self.outputResourceType != JMReportViewerOutputResourceType_LoadingNow) {
        [self runExportExecutionForPage:self.currentPage];
    }
    
    JMRequestDelegate *requestDelegate = [JMRequestDelegate requestDelegateForFinishBlock:@weakself(^(JSOperationResult *result)) {
        JSReportExecutionResponse *reportDetails = [result.objects objectAtIndex:0];
        self.countOfPages = [reportDetails.totalPages integerValue];
    } @weakselfend
    errorBlock:nil
    viewControllerToDismiss: nil];
    
    [self.reportClient getReportExecutionMetadata:self.requestId delegate:requestDelegate];
}

- (void) checkStatus
{
    if (!self.reportExequtingStatusIsReady) {
        JMRequestDelegate *requestDelegate = [JMRequestDelegate requestDelegateForFinishBlock:@weakself(^(JSOperationResult *result)) {
            JSExecutionStatus *status = [result.objects objectAtIndex:0];
            self.reportExequtingStatusIsReady = [status.status isEqualToString:kJMRestStatusReady];
            if (self.reportExequtingStatusIsReady) {
                [self cancelStatusChecking];
            }
        } @weakselfend
        errorBlock:nil
        viewControllerToDismiss: nil];
        [self.reportClient getReportExecutionStatus:self.requestId delegate:requestDelegate];
    } else {
        [self cancelStatusChecking];
    }
}

- (void) cancelReport
{
    [self.statusCheckingTimer invalidate];
}

- (BOOL)reportIsEmpty
{
    return (self.reportExequtingStatusIsReady && self.countOfPages == 0);
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex == buttonIndex) {
        [self.delegate performSegueWithIdentifier:kJMShowReportOptionsSegue sender:nil];
    }
    [self.icUndoManager undo];
    [self.icUndoManager removeAllActionsWithTarget:self];
}

@end
