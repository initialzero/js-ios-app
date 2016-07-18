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
//  JMDashboardViewerVC.m
//  TIBCO JasperMobile
//

#import "JMDashboardViewerVC.h"
#import "JMDashboardViewerConfigurator.h"
#import "JMDashboardLoader.h"
#import "JMReportViewerVC.h"
#import "JMDashboard.h"
#import "JMWebViewManager.h"
#import "JMExternalWindowDashboardControlsVC.h"
#import "JMDashboardParameter.h"
#import "JMInputControlsViewController.h"
#import "JMDashboardInputControlsVC.h"
#import "JSRESTBase+JSRESTDashboard.h"
#import "JSDashboardComponent.h"
#import "JMWebEnvironment.h"

#import "UIView+Additions.h"
#import "JMResource.h"
#import "JMAnalyticsManager.h"
#import "JMJavascriptNativeBridge.h"

#import "JMSaveDashboardViewController.h"
#import "ALToastView.h"

NSString * const kJMDashboardViewerPrimaryWebEnvironmentIdentifier = @"kJMDashboardViewerPrimaryWebEnvironmentIdentifier";

@interface JMDashboardViewerVC() <JMDashboardLoaderDelegate, JMExternalWindowDashboardControlsVCDelegate, JMSaveResourceViewControllerDelegate>
@property (nonatomic, copy) NSArray *rightButtonItems;
@property (nonatomic, strong) UIBarButtonItem *leftButtonItem;

@property (nonatomic, strong, readwrite) JMDashboard *dashboard;
@property (nonatomic, strong) JMDashboardViewerConfigurator *configurator;
@property (nonatomic) JMExternalWindowDashboardControlsVC *controlsViewController;
@property (nonatomic, weak) JMWebEnvironment *webEnvironment;
@property (nonatomic, weak) UIBarButtonItem *currentBackButton;
@end


@implementation JMDashboardViewerVC

#pragma mark - UIViewController LifeCycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self configViewport];
}

#pragma mark - Rotation
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];

    if (![self isContentOnTV] && [self.dashboardLoader respondsToSelector:@selector(updateViewportScaleFactorWithValue:)]) {
        CGFloat initialScaleViewport = 0.75;
        BOOL isCompactWidth = newCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
        if (isCompactWidth) {
            initialScaleViewport = 0.25;
        }
        [self.dashboardLoader updateViewportScaleFactorWithValue:initialScaleViewport];
    }
}

#pragma mark - Print
- (void)printResource
{
    [super printResource];
    [self printItem:[self.resourceView renderedImage] withName:self.dashboard.resourceLookup.label completion:nil];
}

#pragma mark - Custom Accessors

- (JMDashboard *)dashboard
{
    if (!_dashboard) {
        _dashboard = [self.resource modelOfResource];
    }
    return _dashboard;
}

- (UIView *)resourceView
{
    return self.webEnvironment.webView;
}

- (void)setupSubviews
{
    // setup subviews after getting dashboard info
}

- (void)setupWebEnvironment
{
    self.webEnvironment = [self primaryWebEnvironment];
    self.configurator = [JMDashboardViewerConfigurator configuratorWithDashboard:self.dashboard
                                                                  webEnvironment:self.webEnvironment];

    [self.configurator updateReportLoaderDelegateWithObject:self];

    [super setupSubviews];
}

- (JMWebEnvironment *)primaryWebEnvironment
{
    JMWebEnvironment *webEnvironment = [[JMWebViewManager sharedInstance] webEnvironmentForId:kJMDashboardViewerPrimaryWebEnvironmentIdentifier]              ;
    return webEnvironment;
}

- (id<JMDashboardLoader>)dashboardLoader
{
    return [self.configurator dashboardLoader];
}

#pragma mark - Setups
- (void)configViewport
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.webEnvironment resetZoom];
    });
}

- (void)setupLeftBarButtonItems
{
    if ([self isDashletShown]) {
        if (!self.navigationItem.leftBarButtonItem) {
            self.navigationItem.leftBarButtonItem = [self backButtonWithTitle:self.title
                                                                       target:self
                                                                       action:@selector(minimizeDashlet)];
        }
    } else {
        [super setupLeftBarButtonItems];
    }
}

- (void)setupRightBarButtonItems
{
    if (![self isDashletShown]) {
        [super setupRightBarButtonItems];
        self.rightButtonItems = self.navigationItem.rightBarButtonItems;
    }
}

- (void)resetSubViews
{
    [self.dashboardLoader destroy];
    [self.webEnvironment resetZoom];
    [self.webEnvironment.webView removeFromSuperview];

    self.webEnvironment = nil;
}


- (void)cancelResourceViewingAndExit:(BOOL)exit
{
    if ([self isContentOnTV]) {
        [self switchFromTV];
        [super cancelResourceViewingAndExit:exit];
    } else {
        [super cancelResourceViewingAndExit:exit];
    }
}

#pragma mark - Actions
- (void)minimizeDashlet
{
    [self.webEnvironment resetZoom];

    if ([self isContentOnTV]) {
        [self.controlsViewController markComponentAsMinimized:self.dashboard.maximizedComponent];
    }

    [self.dashboardLoader minimizeDashlet];
    self.navigationItem.leftBarButtonItem = self.leftButtonItem;
    self.navigationItem.rightBarButtonItems = self.rightButtonItems;
    self.navigationItem.title = self.resource.resourceLookup.label;
    self.leftButtonItem = nil;

}

- (void)reloadDashboard
{
    [self startShowLoaderWithMessage:JMCustomLocalizedString(@"resources_loading_msg", nil)
                               cancelBlock:^(void) {
                                   [self.dashboardLoader cancel];
                               }];
    __weak typeof(self)weakSelf = self;
    [self.dashboardLoader reloadDashboardWithCompletion:^(BOOL success, NSError *error) {
        __weak typeof(self)strongSelf = weakSelf;
        [strongSelf stopShowLoader];

        if (!success) {
            if (error.code == JMJavascriptNativeBridgeErrorAuthError) {
                __weak typeof(self)weakSelf = strongSelf;
                [strongSelf handleAuthErrorWithCompletion:^(void) {
                    __weak typeof(self)strongSelf = weakSelf;
                    [strongSelf startShowDashboard];
                }];
            } else if (error.code == JMJavascriptNativeBridgeErrorTypeUnexpected) {
                JMLog(@"reload dashboard");
                JMLog(@"error: %@", error.localizedDescription);
            } else {
                JMLog(@"error of refreshing dashboard: %@", error);
                [JMUtils presentAlertControllerWithError:error
                                              completion:^{
                                                  [strongSelf cancelResourceViewingAndExit:YES];
                                              }];
            }
        }
    }];
}

- (void)reloadDashlet
{
    if ([self.dashboardLoader respondsToSelector:@selector(reloadMaximizedDashletWithCompletion:)]) {

        [self startShowLoaderWithMessage:JMCustomLocalizedString(@"resources_loading_msg", nil)
                             cancelBlock:^(void) {
                                 [self.dashboardLoader cancel];
                             }];

        __weak typeof(self)weakSelf = self;
        [self.dashboardLoader reloadMaximizedDashletWithCompletion:^(BOOL success, NSError *error){
            __weak typeof(self)strongSelf = weakSelf;
            [strongSelf stopShowLoader];
            if (!success) {
                if (error.code == JMJavascriptNativeBridgeErrorAuthError) {
                    __weak typeof(self)weakSelf = strongSelf;
                    [strongSelf handleAuthErrorWithCompletion:^(void) {
                        __weak typeof(self)strongSelf = weakSelf;
                        [strongSelf startShowDashboard];
                    }];
                } else if (error.code == JMJavascriptNativeBridgeErrorTypeUnexpected) {
                    JMLog(@"reload dashlet");
                    JMLog(@"error: %@", error.localizedDescription);
                } else {
                    [JMUtils presentAlertControllerWithError:error
                                                  completion:nil];
                }
            }
        }];

    } else {
        [self minimizeDashlet];
        [self reloadDashboard];
    }
}

- (void)backActionInWebView
{
    [self startShowLoaderWithMessage:@"status_loading"];
    __weak typeof(self) weakSelf = self;
    [self.dashboardLoader loadDashboardWithCompletion:^(BOOL success, NSError *error) {
        typeof(self) strongSelf = weakSelf;
        [strongSelf stopShowLoader];
        strongSelf.navigationItem.leftBarButtonItem = strongSelf.currentBackButton;
    }];
}

#pragma mark - Overriden methods
- (void)startResourceViewing
{
    if (self.resource.type != JMResourceTypeLegacyDashboard && [JMUtils isSupportVisualize]) {
        [self startShowLoaderWithMessage:JMCustomLocalizedString(@"resources_loading_msg", nil)
                                   cancelBlock:^(void) {
                                       [self.dashboardLoader cancel];
                                       [super cancelResourceViewingAndExit:YES];
                                   }];

        __weak __typeof(self) weakSelf = self;
        [self fetchDashboardMetaDataWithCompletion:^(NSArray *components, NSArray *inputControls, NSError *error) {
            __typeof(self) strongSelf = weakSelf;
            // Web Environment need valid cookies for working
            // in this point we should have valid cookies
            [strongSelf setupWebEnvironment];
            [strongSelf stopShowLoader];

            if (error) {
                [JMUtils presentAlertControllerWithError:error
                                              completion:^{
                                                  [strongSelf cancelResourceViewingAndExit:YES];
                                              }];
            } else {
                strongSelf.dashboard.components = components;
                strongSelf.dashboard.inputControls = inputControls;
                [strongSelf startShowDashboard];
            }
        }];
    } else {
        [self setupWebEnvironment];
        [self startShowDashboard];
    }
}

- (void)startShowDashboard
{
    [self startShowLoaderWithMessage:JMCustomLocalizedString(@"resources_loading_msg", nil)
                               cancelBlock:^(void) {
                                   [self.dashboardLoader cancel];
                                   [super cancelResourceViewingAndExit:YES];
                               }];

    __weak typeof(self)weakSelf = self;
    [self.dashboardLoader loadDashboardWithCompletion:^(BOOL success, NSError *error) {
        __weak typeof(self)strongSelf = weakSelf;
        [strongSelf stopShowLoader];

        if (success) {
            // Analytics
            NSString *label = ([JMUtils isServerProEdition] && [JMUtils isServerVersionUpOrEqual6]) ? kJMAnalyticsResourceLabelDashboardVisualize : kJMAnalyticsResourceLabelDashboardFlow;
            [[JMAnalyticsManager sharedManager] sendAnalyticsEventWithInfo:@{
                    kJMAnalyticsCategoryKey : kJMAnalyticsEventCategoryResource,
                    kJMAnalyticsActionKey   : kJMAnalyticsEventActionOpen,
                    kJMAnalyticsLabelKey    : label
            }];

            if ([strongSelf isContentOnTV]) {
                strongSelf.controlsViewController.components = strongSelf.dashboard.components;
            }
        } else {
            if (error.code == JMJavascriptNativeBridgeErrorAuthError) {
                __weak typeof(self)weakSelf = strongSelf;
                [strongSelf handleAuthErrorWithCompletion:^(void) {
                    __weak typeof(self)strongSelf = weakSelf;
                    [strongSelf startShowDashboard];
                }];
            } else if (error.code == JMJavascriptNativeBridgeErrorTypeUnexpected) {
                JMLog(@"show dashboard");
                JMLog(@"error: %@", error.localizedDescription);
            } else {
                [JMUtils presentAlertControllerWithError:error
                                              completion:nil];
            }
        }
    }];
}

- (JMMenuActionsViewAction)availableAction
{
    JMMenuActionsViewAction menuActions = [super availableAction] | JMMenuActionsViewAction_Refresh;

    menuActions |= JMMenuActionsViewAction_Save;
    
    if ([self isExternalScreenAvailable]) {
        menuActions |= [self isContentOnTV] ?  JMMenuActionsViewAction_HideExternalDisplay : JMMenuActionsViewAction_ShowExternalDisplay;
    }

    if ([self isInputControlsAvailable]) {
        menuActions |= JMMenuActionsViewAction_EditFilters;
    }
    return menuActions;
}

#pragma mark - JMMenuActionsViewDelegate
- (void)actionsView:(JMMenuActionsView *)view didSelectAction:(JMMenuActionsViewAction)action
{
    [super actionsView:view didSelectAction:action];

    switch (action) {
        case JMMenuActionsViewAction_Save: {
            [self saveDashboard];
            break;
        }
        case JMMenuActionsViewAction_Refresh: {
            [self reloadDashboard];
            break;
        }
        case JMMenuActionsViewAction_ShowExternalDisplay: {
            [self showExternalWindowWithCompletion:^(BOOL success) {
                if (success) {
                    [self addControlsForExternalWindow];
                } else {
                    // TODO: add handling this situation
                    JMLog(@"error of showing on tv");
                }
            }];
            break;
        }
        case JMMenuActionsViewAction_HideExternalDisplay: {
            [self switchFromTV];
            break;
        }
        case JMMenuActionsViewAction_EditFilters: {
            [self showInputControlsVC];
            break;
        }
        default:{break;}
    }
}

#pragma mark - JMSaveResourceViewControllerDelegate
- (void)resourceDidSavedSuccessfully
{
    [ALToastView toastInView:self.navigationController.view
                    withText:JMCustomLocalizedString(@"resource_viewer_save_addedToQueue", nil)];
}

- (void)saveDashboard
{
    JMSaveDashboardViewController *saveDashboardVC = [self.storyboard instantiateViewControllerWithIdentifier:@"JMSaveDashboardViewController"];
    saveDashboardVC.dashboard = self.dashboard;
    saveDashboardVC.delegate = self;
    [self.navigationController pushViewController:saveDashboardVC animated:YES];
}

#pragma mark - JMDashboardLoaderDelegate
- (void)dashboardLoader:(id <JMDashboardLoader>)loader didStartMaximazeDashletWithTitle:(NSString *)title
{
    [self.webEnvironment resetZoom];

    self.navigationItem.rightBarButtonItems = nil;
    if ([self.dashboardLoader respondsToSelector:@selector(reloadMaximizedDashletWithCompletion:)]) {
        UIBarButtonItem *refreshDashlet = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh_action"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(reloadDashlet)];
        self.navigationItem.rightBarButtonItem = refreshDashlet;
    }

    self.leftButtonItem = self.navigationItem.leftBarButtonItem;
    self.navigationItem.leftBarButtonItem = [self backButtonWithTitle:self.title
                                                               target:self
                                                               action:@selector(minimizeDashlet)];
    self.navigationItem.title = title;
}

- (void)dashboardLoader:(id <JMDashboardLoader>)loader didReceiveHyperlinkWithType:(JMHyperlinkType)hyperlinkType
         resource:(JMResource *)resource
             parameters:(NSArray *)parameters
{
    NSLog(@"Parameters = %@", parameters);

    switch (hyperlinkType) {
        case JMHyperlinkTypeLocalPage: {
            break;
        }
        case JMHyperlinkTypeLocalAnchor: {
            break;
        }
        case JMHyperlinkTypeRemotePage: {
            break;
        }
        case JMHyperlinkTypeRemoteAnchor: {
            break;
        }
        case JMHyperlinkTypeReference: {
            NSURL *URL = parameters.firstObject;

            NSURL *serverURL = [NSURL URLWithString:self.restClient.serverProfile.serverUrl];
            if ([URL.host isEqualToString:serverURL.host]) {
                NSURLRequest *request = [NSURLRequest requestWithURL:URL];
                [self.webEnvironment.webView loadRequest:request];

                UIBarButtonItem *backButton = [self backButtonWithTitle:JMCustomLocalizedString(@"back_button_title", nil)
                                                                 target:self
                                                                 action:@selector(backActionInWebView)];
                self.currentBackButton = self.navigationItem.leftBarButtonItem;
                self.navigationItem.leftBarButtonItem = backButton;
            } else {
                // TODO: open in safari view controller
                if (URL && [[UIApplication sharedApplication] canOpenURL:URL]) {
                    [[UIApplication sharedApplication] openURL:URL];
                }
            }
            break;
        }
        case JMHyperlinkTypeReportExecution: {

            JMReportViewerVC *reportViewController = [self.storyboard instantiateViewControllerWithIdentifier:[resource resourceViewerVCIdentifier]];
            reportViewController.resource = resource;
            reportViewController.initialReportParameters = parameters;
            reportViewController.isChildReport = YES;
            [self.navigationController pushViewController:reportViewController animated:YES];

            break;
        }
        case JMHyperlinkTypeAdHocExecution: {
            // This case appears for JRS 6.0 - 6.0.1
            // For JRS > 6.1 - in javascript wrapper will be a visualize handler
            NSURL *URL = parameters.firstObject;
            // TODO: open in safari view controller
            if (URL && [[UIApplication sharedApplication] canOpenURL:URL]) {
                [[UIApplication sharedApplication] openURL:URL];
            }
            break;
        }
    }
}

- (void)dashboardLoaderDidReceiveAuthRequest:(id <JMDashboardLoader>)loader
{
    if ([self isDashletShown]) {
        [self minimizeDashlet];
    }

    if ([self isContentOnTV]) {
        [self switchFromTV];
    }

    if ([JMUtils isSupportVisualize]) {
        [self startResourceViewing];
    } else {
        __weak typeof(self)weakSelf = self;
        [self handleAuthErrorWithCompletion:^{
            __strong typeof(self)strongSelf = weakSelf;
            if ([strongSelf.dashboard respondsToSelector:@selector(updateResourceRequest)]) {
                [strongSelf.dashboard updateResourceRequest];
            }
            [strongSelf startShowDashboard];
        }];
    }
}

#pragma mark - Helpers
- (BOOL)isDashletShown
{
    return self.leftButtonItem != nil;
}

- (void)fetchDashboardMetaDataWithCompletion:(void(^)(NSArray <JSDashboardComponent *> *components, NSArray <JSInputControlDescriptor *> *inputControls, NSError *error))completion
{
    if (!completion) {
        return;
    }

    __weak __typeof(self) weakSelf = self;
    [self.restClient fetchDashboardComponentsWithURI:self.dashboard.resourceURI
                                          completion:^(JSOperationResult *result) {
                                              __typeof(self) strongSelf = weakSelf;

                                              if (result.error) {
                                                  completion(nil, nil, result.error);
                                              } else {
                                                  // Get components
                                                  NSArray <JSDashboardComponent *> *components = result.objects;

                                                  NSMutableArray <JSDashboardParameter *> *parameters = [NSMutableArray array];
                                                  for (JSDashboardComponent *component in components) {
                                                      if ([component.type isEqualToString:@"inputControl"]) {
                                                          NSString *URI = component.ownerResourceURI;
                                                          if ([URI hasPrefix:@"/temp"]) {
                                                              NSString *dashboardFilesURI = [NSString stringWithFormat:@"%@_files", strongSelf.dashboard.resourceURI];
                                                              URI = [URI stringByReplacingOccurrencesOfString:@"/temp" withString:dashboardFilesURI];
                                                          }
                                                          NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"SELF.name == %@", URI];
                                                          JSDashboardParameter *parameter = [[parameters filteredArrayUsingPredicate:filterPredicate] lastObject];
                                                          if (!parameter) {
                                                              parameter = [JSDashboardParameter parameterWithName:URI value:[NSMutableArray array]];
                                                              [parameters addObject:parameter];
                                                          }
                                                          [parameter.value addObject:component.ownerResourceParameterName];
                                                      }
                                                  }

                                                  JMLog(@"inputControlsURLs: %@", parameters);
                                                  // Get input controls
                                                  [strongSelf.restClient inputControlsForDashboardWithParameters:parameters
                                                                                                 completionBlock:^(JSOperationResult * _Nullable result) {
                                                                                                     if (result.error) {
                                                                                                         JMLog(@"error: %@", result.error);
                                                                                                     } else {
                                                                                                         NSArray *inputControls = result.objects;
                                                                                                         // Callback
                                                                                                         if (inputControls.count > 0) {
                                                                                                             NSMutableArray *visibleInputControls = [NSMutableArray array];
                                                                                                             for (JSInputControlDescriptor *inputControl in inputControls) {
                                                                                                                 if (inputControl.visible.boolValue) {
                                                                                                                     [visibleInputControls addObject:inputControl];
                                                                                                                 }
                                                                                                             }
                                                                                                             completion(components, visibleInputControls, nil);
                                                                                                         } else {
                                                                                                             completion(components, @[], nil);
                                                                                                         }
                                                                                                     }
                                                                                                 }];
                                              }
                                          }];
}

- (BOOL)isInputControlsAvailable
{
    return self.dashboard.inputControls.count > 0;
}

- (void)handleAuthErrorWithCompletion:(void(^ __nonnull)(void))completion
{
    if ([self isContentOnTV]) {
        [self switchFromTV];
    }
    
    [self.webEnvironment removeCookies];

    if (self.restClient.keepSession) {
        __weak typeof(self)weakSelf = self;
        [self.restClient verifyIsSessionAuthorizedWithCompletion:^(JSOperationResult *_Nullable result) {
            __weak typeof(self)strongSelf = weakSelf;
            if (!result.error) {
                if ([JMUtils isSystemVersion9]) {
                    [strongSelf.webEnvironment addCookies];
                } else {
                    [[JMWebViewManager sharedInstance] reset];
                    [strongSelf setupWebEnvironment];
                    [strongSelf configViewport];
                }
                completion();
            } else {
                __weak typeof(self)weakSelf = strongSelf;
                [JMUtils showLoginViewAnimated:YES completion:^{
                    __weak typeof(self)strongSelf = weakSelf;
                    [strongSelf cancelResourceViewingAndExit:YES];
                }];
            }
        }];
    } else {
        __weak typeof(self)weakSelf = self;
        [JMUtils showLoginViewAnimated:YES completion:^{
            __weak typeof(self)strongSelf = weakSelf;
            [strongSelf cancelResourceViewingAndExit:YES];
        }];
    }
}

#pragma mark - Work with external screen
- (UIView *)viewToShowOnExternalWindow
{
    UIView *dashboardView = self.webEnvironment.webView;
    dashboardView.translatesAutoresizingMaskIntoConstraints = YES;
    return dashboardView;
}

- (void)addControlsForExternalWindow
{
    self.controlsViewController = [JMExternalWindowDashboardControlsVC new];
    self.controlsViewController.components = self.dashboard.components;
    [self.view addSubview:self.controlsViewController.view];

    self.controlsViewController.delegate = self;

    self.controlsViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[controlsView]-0-|"
                                                                      options:NSLayoutFormatAlignAllLeading
                                                                      metrics:nil
                                                                        views:@{@"controlsView": self.controlsViewController.view}]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[controlsView]-0-|"
                                                                      options:NSLayoutFormatAlignAllLeading
                                                                      metrics:nil
                                                                        views:@{@"controlsView": self.controlsViewController.view}]];


}

- (void)switchFromTV
{
    [super setupSubviews];

    [self.controlsViewController.view removeFromSuperview];
    self.controlsViewController = nil;

    [self hideExternalWindowWithCompletion:^(void) {
        [self configViewport];
        [self.webEnvironment.webView.scrollView setZoomScale:0.1 animated:YES];
    }];
}

#pragma mark - JMExternalWindowDashboardControlsVCDelegate
- (void)externalWindowDashboardControlsVC:(JMExternalWindowDashboardControlsVC *)dashboardControlsVC didAskMaximizeDashlet:(JSDashboardComponent *)component
{
    if ([self.dashboardLoader respondsToSelector:@selector(maximizeDashletForComponent:)]) {
        [self.dashboardLoader maximizeDashletForComponent:component];

        // TODO: move to separate method
        self.navigationItem.rightBarButtonItems = nil;
        if ([self.dashboardLoader respondsToSelector:@selector(reloadMaximizedDashletWithCompletion:)]) {
            UIBarButtonItem *refreshDashlet = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh_action"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(reloadDashlet)];
            self.navigationItem.rightBarButtonItem = refreshDashlet;
        }

        self.leftButtonItem = self.navigationItem.leftBarButtonItem;
        self.navigationItem.leftBarButtonItem = [self backButtonWithTitle:self.title
                                                                   target:self
                                                                   action:@selector(minimizeDashlet)];
        self.navigationItem.title = component.name;
    }
}

- (void)externalWindowDashboardControlsVC:(JMExternalWindowDashboardControlsVC *)dashboardControlsVC didAskMinimizeDashlet:(JSDashboardComponent *)component
{
    if ([self.dashboardLoader respondsToSelector:@selector(minimizeDashletForComponent:)]) {
        [self.dashboardLoader minimizeDashletForComponent:component];

        // TODO: move to separate method
        self.navigationItem.leftBarButtonItem = self.leftButtonItem;
        self.navigationItem.rightBarButtonItems = self.rightButtonItems;
        self.navigationItem.title = self.resource.resourceLookup.label;
        self.leftButtonItem = nil;
    }
}

#pragma mark - Input Controls
- (void)showInputControlsVC
{
    JMDashboardInputControlsVC *inputControlsViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JMDashboardInputControlsVC"];
    inputControlsViewController.dashboard = self.dashboard;

    __weak __typeof(self) weakSelf = self;
    inputControlsViewController.exitBlock = ^(BOOL inputControlsDidChanged) {
        if (inputControlsDidChanged) {
            __typeof(self) strongSelf = weakSelf;
            NSMutableDictionary *parameters = [@{} mutableCopy];
            for (JSInputControlDescriptor *inputControlDescriptor in strongSelf.dashboard.inputControls) {
                NSString *componentID;
                for (JSDashboardComponent *component in strongSelf.dashboard.components) {
                    if ([component.ownerResourceParameterName isEqualToString:inputControlDescriptor.uuid]) {
                        componentID = component.identifier;
                    }
                }
                NSArray *values = [inputControlDescriptor selectedValues];
                if (componentID) {
                    parameters[componentID] = values;                    
                }
            }
            [strongSelf.dashboardLoader applyParameters:parameters];
        }
    };

    [self.navigationController pushViewController:inputControlsViewController animated:YES];

}

@end