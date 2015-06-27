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


#import "JMCancelRequestPopup.h"
#import "JMRestReport.h"

#import "JMSaveReportViewController.h"

#import "SWRevealViewController.h"
#import "JMBaseCollectionViewController.h"
#import "JMReportOptionsViewController.h"
#import "ALToastView.h"
#import "JSResourceLookup+Helpers.h"
#import "JMReportViewerToolBar.h"
#import "JMBaseReportViewerViewController.h"
#import "JMPrintResourceViewController.h"
#import "JMReportLoader.h"
#import "JMJavascriptNativeBridgeProtocol.h"
#import "JMPrintResourceVC.h"

@interface JMBaseReportViewerViewController () <UIAlertViewDelegate, JMSaveReportViewControllerDelegate>
@property (assign, nonatomic) JMMenuActionsViewAction menuActionsViewAction;
@property (assign, nonatomic) JMMenuActionsViewAction disabledMenuActionsViewAction;
@property (nonatomic, weak) JMReportViewerToolBar *toolbar;
@property (weak, nonatomic) IBOutlet UILabel *emptyReportMessageLabel;
@property (nonatomic, strong, readwrite) JMReport *report;

@end

@implementation JMBaseReportViewerViewController

#pragma mark - Lifecycle
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    self.emptyReportMessageLabel.text = JMCustomLocalizedString(@"report.viewer.emptyreport.title", nil);
    [self addObservers];
    [self setupMenuActions];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateToobarAppearence];

    // start point
    if (!self.report.isReportAlreadyLoaded) {
        [self startLoadReportWithPage:1];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_toolbar removeFromSuperview];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:kJMSaveReportViewControllerSegue]) {
        JMSaveReportViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.report = self.report;
        destinationViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"showPrintVC"]) {
        JMPrintResourceVC *printResourceVC = segue.destinationViewController;
        printResourceVC.report = self.report;
    }
}

#pragma mark - Setups
- (void)updateToobarAppearence
{
    if (self.toolbar && self.report.isMultiPageReport && !self.report.isReportEmpty) {
        self.toolbar.currentPage = self.report.currentPage;
        if (self.navigationController.visibleViewController == self) {
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    } else {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

#pragma mark - Observe Notifications
- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(multipageNotification)
                                                 name:kJMReportIsMutlipageDidChangedNotification
                                               object:self.report];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reportLoaderDidChangeCountOfPages:)
                                                 name:kJMReportCountOfPagesDidChangeNotification
                                               object:self.report];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reportLoaderDidChangeCurrentPage:)
                                                 name:kJMReportCurrentPageDidChangeNotification
                                               object:self.report];
}

- (void)multipageNotification
{
    [self updateToobarAppearence];
}

- (void)reportLoaderDidChangeCountOfPages:(NSNotification *)notification
{
    self.toolbar.countOfPages = self.report.countOfPages;
    [self updateMenuActions];
    [self handleReportLoaderDidChangeCountOfPages];
}

- (void)reportLoaderDidChangeCurrentPage:(NSNotification *)notification
{
    self.toolbar.currentPage = self.report.currentPage;
    [self handleReportLoaderDidChangeCurrentPage];
}

- (void)handleReportLoaderDidChangeCountOfPages
{
    // override in child
}

- (void)handleReportLoaderDidChangeCurrentPage
{
    // override in child
}

#pragma mark - Actions
- (void)cancelResourceViewingAndExit:(BOOL)exit
{
    [self.reportLoader cancelReport];
    if (self.exitBlock) {
        self.exitBlock();
    }
    [super cancelResourceViewingAndExit:exit];
}

- (void)refreshReport
{
    [self resetSubViews];
    [self updateToobarAppearence];
    //
    [self runReportWithPage:1];
}

#pragma mark - Overloaded methods
- (void) startResourceViewing
{
    // empty method because parent call it from viewDidLoad
    // there is issue with "white screen" after loading input controls
    // until current view doesn't appear (on iOS 7)
}

- (void)startLoadReportWithPage:(NSInteger)page
{
    BOOL isReportAlreadyLoaded = self.report.isReportAlreadyLoaded;
    BOOL isInputControlsLoaded = self.report.isInputControlsLoaded;
    BOOL isReportInLoadingProcess = self.reportLoader.isReportInLoadingProcess;

    if (!isInputControlsLoaded) {
        // start load input controls

        [self startShowLoaderWithMessage:@"status.loading.ic" cancelBlock:@weakself(^(void)) {
            [self.restClient cancelAllRequests];
            [self.reportLoader cancelReport];
            [self cancelResourceViewingAndExit:YES];
        }@weakselfend];

        NSString *reportURI = [self.report.reportURI stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self loadInputControlsWithReportURI:reportURI
                                  completion:@weakself(^(NSArray *inputControls, NSError* error)) {
                                      [self stopShowLoader];
                                      if (error) {
                                          [JMUtils showAlertViewWithError:error completion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                              [self cancelResourceViewingAndExit:YES];
                                          }];
                                      } else {
                                          [self.report updateInputControls:inputControls];
                                          if (inputControls && [inputControls count]) {
                                              [self.restClient resourceLookupForURI:reportURI resourceType:@"reportUnit"
                                                                          modelClass:[JSResourceReportUnit class]
                                                                    completionBlock:@weakself(^(JSOperationResult *result)) {
                                                                        if (result.error) {
                                                                            [JMUtils showAlertViewWithError:error completion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                                                                [self cancelResourceViewingAndExit:YES];
                                                                            }];
                                                                        } else {
                                                                            JSResourceReportUnit *reportUnit = [result.objects firstObject];
                                                                            if (reportUnit.alwaysPromptControls) {
                                                                                [self showReportOptionsViewControllerWithBackButton:YES];
                                                                            } else {
                                                                                [self runReportWithPage:page];
                                                                            }
                                                                        }
                                              }@weakselfend];
                                          } else {
                                              [self runReportWithPage:page];
                                          }
                                      }
        }@weakselfend];
    } else if(isInputControlsLoaded && (!isReportAlreadyLoaded && !isReportInLoadingProcess) ) {
        // show report with loaded input controls
        // when we start running a report from another report by tapping on hyperlink
        [self runReportWithPage:page];
    }
}

- (void)printResource
{
    [self webView].hidden = YES;
    [self.navigationController setToolbarHidden:YES animated:YES];
    [[self webView].scrollView setZoomScale:0.1 animated:YES];
    [JMCancelRequestPopup presentWithMessage:@"resource.viewer.print.prepare.title"];

    // Add delay before printing and zoom out webView
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [JMCancelRequestPopup dismiss];
        [self webView].hidden = NO;

//        JMPrintResourceViewController *printController = [[JMUtils mainStoryBoard] instantiateViewControllerWithIdentifier:@"JMPrintResourceViewController"];
//        [printController setReport:self.report withWebView:self.webView];
//        printController.printCompletion = @weakself(^){
//                [self webView].frame = self.view.bounds;
//                [self.view insertSubview:[self webView] belowSubview:self.activityIndicator];
//        }@weakselfend;
//        [self.navigationController pushViewController:printController animated:YES];

        [self performSegueWithIdentifier:@"showPrintVC" sender:nil];
    });
}

- (void)runReportWithPage:(NSInteger)page
{
    // This method should be overrided in inherited classes.
}

#pragma mark - Custom accessors
- (JMReportViewerToolBar *)toolbar
{
    if (!_toolbar) {
        _toolbar = [[[NSBundle mainBundle] loadNibNamed:@"JMReportViewerToolBar" owner:self options:nil] firstObject];
        _toolbar.toolbarDelegate = self;
        _toolbar.currentPage = self.report.currentPage;
        _toolbar.countOfPages = self.report.countOfPages;
        _toolbar.frame = self.navigationController.toolbar.bounds;
        [self.navigationController.toolbar addSubview: _toolbar];
    }
    return _toolbar;
}

-(JMReport *)report
{
    if (!_report) {
        _report = [self.resourceLookup reportModel];
    }
    return _report;
}

#pragma mark - JMMenuActionsViewDelegate
- (void)actionsView:(JMMenuActionsView *)view didSelectAction:(JMMenuActionsViewAction)action
{
    [super actionsView:view didSelectAction:action];
    switch (action) {
        case JMMenuActionsViewAction_Refresh:
            [self refreshReport];
            break;
        case JMMenuActionsViewAction_Edit: {
            [self showReportOptionsViewControllerWithBackButton:NO];
            break;
        }
        case JMMenuActionsViewAction_Save:
            // TODO: change save action
            [self performSegueWithIdentifier:kJMSaveReportViewControllerSegue sender:nil];
            break;
        default:
            break;
    }
}

#pragma mark - JMRefreshable
- (void)refresh
{
    [self refreshReport];
}

#pragma mark - JMSaveReportControllerDelegate
- (void)reportDidSavedSuccessfully
{
    [ALToastView toastInView:self.view
                    withText:JMCustomLocalizedString(@"report.viewer.save.saved", nil)];
}

- (void)updateReportWithNewParameters
{
    // can be overriden in childs
    [self refresh];
}

#pragma mark - Report Options (Input Controls)
- (void)loadInputControlsWithReportURI:(NSString *)reportURI completion:(void (^)(NSArray *inputControls, NSError *error))completion
{
    [self.restClient inputControlsForReport:reportURI
                                        ids:nil
                             selectedValues:nil
                            completionBlock:@weakself(^(JSOperationResult *result)) {

                                if (result.error) {
                                    if (result.error.code == JSSessionExpiredErrorCode) {
                                        if (self.restClient.keepSession && [self.restClient isSessionAuthorized]) {
                                            [self loadInputControlsWithReportURI:reportURI completion:completion];
                                        } else {
                                            [JMUtils showLoginViewAnimated:YES completion:@weakself(^(void)) {
                                                [self cancelResourceViewingAndExit:YES];
                                            } @weakselfend];
                                        }
                                    } else {
                                        if (completion) {
                                            completion(nil, result.error);
                                        }
                                    }
                                } else {

                                    NSMutableArray *invisibleInputControls = [NSMutableArray array];
                                    for (JSInputControlDescriptor *inputControl in result.objects) {
                                        if (!inputControl.visible.boolValue) {
                                            [invisibleInputControls addObject:inputControl];
                                        }
                                    }

                                    if (result.objects.count - invisibleInputControls.count == 0) {
                                        completion(nil, nil);
                                    } else {
                                        NSMutableArray *inputControls = [result.objects mutableCopy];
                                        if (invisibleInputControls.count) {
                                            [inputControls removeObjectsInArray:invisibleInputControls];
                                        }
                                        completion([inputControls copy], nil);
                                    }
                                }

                            }@weakselfend];
}

- (void)showReportOptionsViewControllerWithBackButton:(BOOL)isShowBackButton
{
    JMReportOptionsViewController *reportOptionsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JMReportOptionsViewController"];
    reportOptionsViewController.report = self.report;
    reportOptionsViewController.completionBlock = @weakself(^(void)) {
        [self.report updateInputControls:reportOptionsViewController.inputControls];
        [self updateReportWithNewParameters];
    }@weakselfend;

    if (isShowBackButton) {
        UIBarButtonItem *backItem = [self backBarButtonItemWithTarget:reportOptionsViewController
                                                               action:@selector(backButtonTapped:)];
        reportOptionsViewController.navigationItem.leftBarButtonItem = backItem;
    }

    [self.navigationController pushViewController:reportOptionsViewController animated:YES];
}

#pragma mark - Helpers
- (JMMenuActionsViewAction)availableActionForResource:(JSResourceLookup *)resource
{
    JMMenuActionsViewAction availableAction = ([super availableActionForResource:resource] & ~JMMenuActionsViewAction_Print ) | self.menuActionsViewAction;
    if (self.report.isReportWithInputControls) {
        availableAction |= JMMenuActionsViewAction_Edit;
    }
    return availableAction;
}

- (JMMenuActionsViewAction)disabledActionForResource:(JSResourceLookup *)resource
{
    JMMenuActionsViewAction disabledAction = [super disabledActionForResource:resource] | self.disabledMenuActionsViewAction;
    return disabledAction;
}

- (void)showEmptyReportMessage
{
    self.emptyReportMessageLabel.hidden = NO;
    self.menuActionsViewAction = JMMenuActionsViewAction_None;
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)hideEmptyReportMessage
{
    self.emptyReportMessageLabel.hidden = YES;
    [self setupMenuActions];
}

- (void)setupMenuActions
{
    self.menuActionsViewAction = JMMenuActionsViewAction_Save;
    self.disabledMenuActionsViewAction = JMMenuActionsViewAction_Save;
}

- (void)updateMenuActions
{
    if ([self isReportReady]) {
        self.menuActionsViewAction |= JMMenuActionsViewAction_Refresh | JMMenuActionsViewAction_Print;
        self.disabledMenuActionsViewAction = JMMenuActionsViewAction_None;
    } else {
        self.disabledMenuActionsViewAction = JMMenuActionsViewAction_Save;
    }
}

- (BOOL)isReportReady
{
    BOOL isCountOfPagesExist = self.report.countOfPages != NSNotFound;
    return isCountOfPagesExist;
}

@end
