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


#import "JMResourceViewerViewController.h"
#import "JMWebViewManager.h"
#import "ALToastView.h"
#import "JMMainNavigationController.h"
#import "JMWebEnvironment.h"
#import "UIView+Additions.h"
#import "JMResource.h"
#import "JMShareViewController.h"
#import "JMAnalyticsManager.h"

NSString * const kJMResourceViewerWebEnvironmentIdentifier = @"kJMResourceViewerWebEnvironmentIdentifier";

@interface JMResourceViewerViewController () <UIPrintInteractionControllerDelegate>
@property (nonatomic, strong) UINavigationController *printNavController;
@property (nonatomic, assign) CGSize printSettingsPreferredContentSize;
@property (nonatomic, assign) NSInteger lowMemoryWarningsCount;
@end

@implementation JMResourceViewerViewController

#pragma mark - Handle Memory Warnings
- (void)didReceiveMemoryWarning
{
    // Skip first warning.
    // TODO: Consider replace this approach.
    //
    if (self.lowMemoryWarningsCount++ >= 1) {
        [self handleLowMemory];
    }

    [super didReceiveMemoryWarning];
}


#pragma mark - UIViewController LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.printSettingsPreferredContentSize = CGSizeMake(540, 580);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.lowMemoryWarningsCount = 0;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

//    if (self.webView.loading) {
//        [self stopShowLoadingIndicators];
//        // old dashboards don't load empty page
//        //[self.webView stopLoading];
//    }
}

- (void)viewWillLayoutSubviews
{
    CGRect frame = self.printNavController.view.superview.frame;
    frame.size = self.printSettingsPreferredContentSize;
    self.printNavController.view.superview.frame = frame;

    self.printNavController.preferredContentSize = self.printSettingsPreferredContentSize;

    [super viewWillLayoutSubviews];
}

#pragma mark - Custom Accessors
- (UIView *)resourceView
{
    JMWebEnvironment *webEnvironment = [[JMWebViewManager sharedInstance] webEnvironmentForId:kJMResourceViewerWebEnvironmentIdentifier];
    return webEnvironment.webView;
}

#pragma mark - Setups
- (void)setupSubviews
{
    [self.view addSubview:[self resourceView]];
    [self setupResourceViewLayout];
}

- (void)setupResourceViewLayout
{
    UIView *resourceView = [self resourceView];
    resourceView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[resourceView]-0-|"
                                                                      options:NSLayoutFormatAlignAllLeading
                                                                      metrics:nil
                                                                        views:@{@"resourceView": resourceView}]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[resourceView]-0-|"
                                                                      options:NSLayoutFormatAlignAllLeading
                                                                      metrics:nil
                                                                        views:@{@"resourceView": resourceView}]];
}

- (void)resetSubViews
{
    JMWebEnvironment *webEnvironment = [[JMWebViewManager sharedInstance] webEnvironmentForId:kJMResourceViewerWebEnvironmentIdentifier];
    [webEnvironment clean];
}

- (void)cancelResourceViewingAndExit:(BOOL)exit
{
    [self resetSubViews];
    [self.view endEditing:YES];
//    self.webView.navigationDelegate = nil;

    [super cancelResourceViewingAndExit:exit];
}

#pragma mark - Overriden methods

- (JMMenuActionsViewAction)availableAction
{
    JMMenuActionsViewAction availableActions = [super availableAction];
    availableActions |= JMMenuActionsViewAction_Share;

    BOOL isSaveReport = self.resource.type == JMResourceTypeSavedReport;
    BOOL isFile = self.resource.type == JMResourceTypeFile;
    if ( !(isSaveReport || isFile) ) {
        availableActions |= JMMenuActionsViewAction_Print;
    }
    return availableActions;
}

- (void)actionsView:(JMMenuActionsView *)view didSelectAction:(JMMenuActionsViewAction)action
{
    [super actionsView:view didSelectAction:action];
    if (action == JMMenuActionsViewAction_Print) {
        [self printResource];
    } else if (action == JMMenuActionsViewAction_Share) {
        [self shareResource];
    }
}

#pragma mark - Print API
- (void)printResource
{
    // Analytics
    NSString *label = kJMAnalyticsResourceLabelSavedResource;
    if (self.resource.type == JMResourceTypeReport) {
        label = [JMUtils isSupportVisualize] ? kJMAnalyticsResourceLabelReportVisualize : kJMAnalyticsResourceLabelReportREST;
    } else if (self.resource.type == JMResourceTypeDashboard) {
        label = ([JMUtils isServerProEdition] && [JMUtils isServerVersionUpOrEqual6]) ? kJMAnalyticsResourceLabelDashboardVisualize : kJMAnalyticsResourceLabelDashboardFlow;
    }
    [[JMAnalyticsManager sharedManager] sendAnalyticsEventWithInfo:@{
            kJMAnalyticsCategoryKey : kJMAnalyticsEventCategoryResource,
            kJMAnalyticsActionKey   : kJMAnalyticsEventActionPrint,
            kJMAnalyticsLabelKey    : label
    }];
}

- (void)printItem:(id)printingItem withName:(NSString *)itemName completion:(void(^)(BOOL completed, NSError *error))completion
{
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.jobName = itemName;
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.duplex = UIPrintInfoDuplexLongEdge;

    UIPrintInteractionController *printInteractionController = [UIPrintInteractionController sharedPrintController];
    printInteractionController.printInfo = printInfo;
    printInteractionController.showsPageRange = YES;
    printInteractionController.printingItem = printingItem;

    UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if (completion) {
            completion(completed, error);
        }
        // reassign keyWindow status (there is an issue when using showing a report on tv and printing the report).
        [self.view.window makeKeyWindow];
    };

    if ([JMUtils isIphone]) {
        [printInteractionController presentAnimated:YES completionHandler:completionHandler];
    } else {
        if ([JMUtils isSystemVersion9]) {
            [printInteractionController presentFromBarButtonItem:self.printNavController.navigationItem.rightBarButtonItems.firstObject
                                                        animated:YES
                                               completionHandler:completionHandler];
        } else {
            printInteractionController.delegate = self;
            self.printNavController = [JMMainNavigationController new];
            self.printNavController.modalPresentationStyle = UIModalPresentationFormSheet;
            self.printNavController.preferredContentSize = self.printSettingsPreferredContentSize;
            [printInteractionController presentFromBarButtonItem:self.printNavController.navigationItem.rightBarButtonItems.firstObject
                                                        animated:YES
                                               completionHandler:completionHandler];
        }
    }
}

- (void)shareResource
{
    JMShareViewController *shareViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JMShareViewController"];
    shareViewController.imageForSharing = [self.resourceView renderedImage];
    [self.navigationController pushViewController:shareViewController animated:YES];
}

#pragma mark - UIPrintInteractionControllerDelegate
- (UIViewController *)printInteractionControllerParentViewController:(UIPrintInteractionController *)printInteractionController
{
    return self.printNavController;
}

- (void)printInteractionControllerDidPresentPrinterOptions:(UIPrintInteractionController *)printInteractionController
{
    [self presentViewController:self.printNavController animated:YES completion:nil];
    UIViewController *printSettingsVC = self.printNavController.topViewController;
    printSettingsVC.navigationItem.leftBarButtonItem.tintColor = [[JMThemesManager sharedManager] barItemsColor];
}

- (void)printInteractionControllerWillDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController
{
    [self.printNavController dismissViewControllerAnimated:YES completion:^{
        self.printNavController = nil;
    }];
}

#pragma mark - WebViewDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *serverHost = [NSURL URLWithString:self.restClient.serverProfile.serverUrl].host;
    NSString *requestHost = navigationAction.request.URL.host;
    BOOL isParentHost = [requestHost isEqualToString:serverHost];
    BOOL isLinkClicked = navigationAction.navigationType == UIWebViewNavigationTypeLinkClicked;

    if (!isParentHost && isLinkClicked) {
        if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_attention"
                                                                                              message:@"resource_viewer_open_link"
                                                                                    cancelButtonTitle:@"dialog_button_cancel"
                                                                              cancelCompletionHandler:nil];
            [alertController addActionWithLocalizedTitle:@"dialog_button_ok" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
            }];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            [ALToastView toastInView:webView
                            withText:JMCustomLocalizedString(@"resource_viewer_can_not_open_link", nil)];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}


- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    [self startShowLoadingIndicators];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self stopShowLoadingIndicators];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self stopShowLoadingIndicators];
}

#pragma mark - Helpers
- (void)handleLowMemory
{
    JMLog(@"%@ - %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    [self resetSubViews];

    NSString *errorMessage = JMCustomLocalizedString(@"resource_viewer_memory_warning", nil);
    NSError *error = [NSError errorWithDomain:@"dialod_title_attention" code:NSNotFound userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    __weak typeof(self) weakSelf = self;
    [JMUtils presentAlertControllerWithError:error completion:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf cancelResourceViewingAndExit:YES];
    }];
}

@end
