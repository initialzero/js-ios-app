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


#import "JMSavedResourceViewerViewController.h"
#import "JMSavedResources+Helpers.h"

@interface JMSavedResourceViewerViewController () <UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) JMSavedResources *savedReports;
@property (nonatomic, strong) NSString *changedReportName;
@property (nonatomic) UIDocumentInteractionController *documentController;

@property (nonatomic, strong) UIButton *unplugButton;
@property (nonatomic, strong) UIButton *upButton;
@property (nonatomic, strong) UIButton *downButton;
@property (nonatomic, assign) CGFloat currentOffset;
@end

@implementation JMSavedResourceViewerViewController
@synthesize changedReportName;

#pragma mark - LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    // unplug button
    CGRect buttonFrame = CGRectMake(0, 0, 200, 50);
    self.unplugButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.unplugButton setTitle:@"Unplug" forState:UIControlStateNormal];
    [self.unplugButton setBackgroundColor:[UIColor lightGrayColor]];
    [self.unplugButton addTarget:self action:@selector(unplugExternalWindow) forControlEvents:UIControlEventTouchUpInside];

    // up button
    UIImage *arrowUPImage = [UIImage imageNamed:@"arrow_up"];
    buttonFrame = CGRectMake(0, 0, arrowUPImage.size.width, arrowUPImage.size.height);
    self.upButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.upButton setImage:arrowUPImage forState:UIControlStateNormal];
    [self.upButton addTarget:self action:@selector(upAction) forControlEvents:UIControlEventTouchUpInside];

    // up button
    UIImage *arrowDownImage = [UIImage imageNamed:@"arrow_down"];
    buttonFrame = CGRectMake(0, 0, arrowDownImage.size.width, arrowDownImage.size.height);
    self.downButton = [[UIButton alloc] initWithFrame:buttonFrame];
    [self.downButton setImage:arrowDownImage forState:UIControlStateNormal];
    [self.downButton addTarget:self action:@selector(downAction) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Actions
- (void)unplugExternalWindow
{
    [self.unplugButton removeFromSuperview];
    [self.upButton removeFromSuperview];
    [self.downButton removeFromSuperview];

    [self.webView.scrollView setContentOffset:CGPointMake(0, self.currentOffset)];
    [self.view addSubview:self.webView];

    [self setupWebViewLayout];
    [self hideExternalWindow];
}

- (void)upAction
{
//    self.currentOffset -= 20;
//    if (self.currentOffset < 0) {
//        self.currentOffset = 0;
//    }
//    [self.webView.scrollView setContentOffset:CGPointMake(0, self.currentOffset)];
}

- (void)downAction
{
//    self.currentOffset += 20;
//    CGFloat maxOffset = self.webView.scrollView.contentSize.height - self.externalWindow.bounds.size.height;
//    if (self.currentOffset > maxOffset) {
//        self.currentOffset = maxOffset;
//    }
//    [self.webView.scrollView setContentOffset:CGPointMake(0, self.currentOffset)];
}

#pragma mark - Handle Memory Warnings
- (void)didReceiveMemoryWarning
{
    [self.webView stopLoading];
    [self.webView loadHTMLString:@"" baseURL:nil];

#warning WHY ONLY FOR SAVED REPORT VIEWER WE HANDLE MEMORY WARNINGS???
    NSString *errorMessage = JMCustomLocalizedString(@"savedreport.viewer.show.resource.error.message", nil);
    NSError *error = [NSError errorWithDomain:@"dialod.title.error" code:NSNotFound userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
    __weak typeof(self) weakSelf = self;
    [JMUtils presentAlertControllerWithError:error completion:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf cancelResourceViewingAndExit:YES];
    }];

    [super didReceiveMemoryWarning];
}

- (void)cancelResourceViewingAndExit:(BOOL)exit
{
    [self.documentController dismissMenuAnimated:YES];
    [super cancelResourceViewingAndExit:exit];
}

- (JMSavedResources *)savedReports
{
    if (!_savedReports) {
        _savedReports = [JMSavedResources savedReportsFromResourceLookup:self.resourceLookup];
    }

    return _savedReports;
}

- (void)startResourceViewing
{
    NSString *fullReportPath = [JMSavedResources absolutePathToSavedReport:self.savedReports];

    if (self.webView.isLoading) {
        [self.webView stopLoading];
    }
    self.isResourceLoaded = NO;

    NSURL *url = [NSURL fileURLWithPath:fullReportPath];
    self.resourceRequest = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:self.resourceRequest];

    // Analytics
    NSString *resourcesType = @"Saved Item (Unknown type)";
    if ([self.savedReports.format isEqualToString:[JSConstants sharedInstance].CONTENT_TYPE_HTML]) {
        resourcesType = @"Saved Item (HTML)";
    } else if ([self.savedReports.format isEqualToString:[JSConstants sharedInstance].CONTENT_TYPE_PDF]) {
        resourcesType = @"Saved Item (PDF)";
    } else if ([self.savedReports.format isEqualToString:[JSConstants sharedInstance].CONTENT_TYPE_XLS]) {
        resourcesType = @"Saved Item (XLS)";
    }
    [JMUtils logEventWithName:@"User opened resource"
                 additionInfo:@{
                         @"Resource's Type" : resourcesType
                 }];
}

- (JMMenuActionsViewAction)availableActionForResource:(JSResourceLookup *)resource
{
    return ([super availableActionForResource:[self resourceLookup]] | JMMenuActionsViewAction_Rename | JMMenuActionsViewAction_Delete | JMMenuActionsViewAction_OpenIn | JMMenuActionsViewAction_ExternalDisplay);
}

#pragma mark - JMMenuActionsViewDelegate
- (void)actionsView:(JMMenuActionsView *)view didSelectAction:(JMMenuActionsViewAction)action
{
    [super actionsView:view didSelectAction:action];
    if (action == JMMenuActionsViewAction_Rename) {
        __weak typeof(self) weakSelf = self;
        UIAlertController *alertController = [UIAlertController alertTextDialogueControllerWithLocalizedTitle:@"savedreport.viewer.modify.title"
                                                                                                      message:nil
                                                                                textFieldConfigurationHandler:^(UITextField * _Nonnull textField) {
                                                                                    __strong typeof(self) strongSelf = weakSelf;
                                                                                    textField.placeholder = JMCustomLocalizedString(@"savedreport.viewer.modify.reportname", nil);
                                                                                    textField.text = [strongSelf.resourceLookup.label copy];
                                                                                } textValidationHandler:^NSString * _Nonnull(NSString * _Nullable text) {
                                                                                    NSString *errorMessage = nil;
                                                                                    __strong typeof(self) strongSelf = weakSelf;
                                                                                    if (strongSelf) {
                                                                                        [JMUtils validateReportName:text errorMessage:&errorMessage];
                                                                                        if (!errorMessage && ![JMSavedResources isAvailableReportName:text format:strongSelf.savedReports.format]) {
                                                                                            errorMessage = JMCustomLocalizedString(@"report.viewer.save.name.errmsg.notunique", nil);
                                                                                        }
                                                                                    }
                                                                                    return errorMessage;
                                                                                } textEditCompletionHandler:^(NSString * _Nullable text) {
                                                                                    __strong typeof(self) strongSelf = weakSelf;
                                                                                    if ([strongSelf.savedReports renameReportTo:text]) {
                                                                                        strongSelf.title = text;
                                                                                        strongSelf.resourceLookup = [strongSelf.savedReports wrapperFromSavedReports];
                                                                                        [strongSelf setupRightBarButtonItems];
                                                                                        [strongSelf startResourceViewing];
                                                                                    }
                                                                                }];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if(action == JMMenuActionsViewAction_Delete) {
        UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod.title.confirmation"
                                                                                          message:@"savedreport.viewer.delete.confirmation.message"
                                                                                cancelButtonTitle:@"dialog.button.cancel"
                                                                          cancelCompletionHandler:nil];
        __weak typeof(self) weakSelf = self;
        [alertController addActionWithLocalizedTitle:@"dialog.button.ok" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
            __strong typeof(self) strongSelf = weakSelf;
            BOOL shouldCloseViewer = YES;
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(resourceViewer:shouldCloseViewerAfterDeletingResource:)]) {
                shouldCloseViewer = [strongSelf.delegate resourceViewer:strongSelf shouldCloseViewerAfterDeletingResource:strongSelf.resourceLookup];
            }
            [strongSelf cancelResourceViewingAndExit:shouldCloseViewer];
            [strongSelf.savedReports removeReport];
            
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(resourceViewer:didDeleteResource:)]) {
                [strongSelf.delegate resourceViewer:strongSelf didDeleteResource:strongSelf.resourceLookup];
            }
        }];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if (action == JMMenuActionsViewAction_OpenIn) {
        self.documentController = [self setupDocumentControllerWithURL:self.resourceRequest.URL
                                                         usingDelegate:self];
        
        BOOL canOpen = [self.documentController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
        if (!canOpen) {
            NSString *errorMessage = JMCustomLocalizedString(@"error.openIn.message", nil);
            NSError *error = [NSError errorWithDomain:@"dialod.title.error" code:NSNotFound userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
            [JMUtils presentAlertControllerWithError:error completion:nil];
        }
    } else if (action == JMMenuActionsViewAction_ExternalDisplay) {
        [self setupUnplugButton];
        [self.view addSubview:self.unplugButton];
        
        [self setupUpButton];
        [self.view addSubview:self.upButton];
        [self setupDownButton];
        [self.view addSubview:self.downButton];
    }
}

#pragma mark - Helpers
- (UIDocumentInteractionController *) setupDocumentControllerWithURL: (NSURL *) fileURL
                                                       usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    return interactionController;
}

- (void)setupUnplugButton
{
    CGRect buttonRect = self.unplugButton.frame;
    buttonRect.origin.x = (CGRectGetWidth(self.view.bounds) - CGRectGetWidth(buttonRect))/ 2.0f;
    buttonRect.origin.y = (CGRectGetHeight(self.view.bounds) - CGRectGetHeight(buttonRect))/ 2.0f;
    self.unplugButton.frame = buttonRect;
}

- (void)setupUpButton
{
    CGRect buttonFrame = self.upButton.frame;
    buttonFrame.origin.x = CGRectGetMaxX(self.unplugButton.frame) + 10;
    buttonFrame.origin.y = CGRectGetMinY(self.unplugButton.frame);
    self.upButton.frame = buttonFrame;
}

- (void)setupDownButton
{
    CGRect buttonFrame = self.downButton.frame;
    buttonFrame.origin.x = CGRectGetMaxX(self.unplugButton.frame) + 10;
    buttonFrame.origin.y = CGRectGetMaxY(self.unplugButton.frame) - CGRectGetHeight(buttonFrame);
    self.downButton.frame = buttonFrame;
}

#pragma mark - Work with external screen
- (UIView *)viewForAddingToExternalWindow
{
    self.webView.translatesAutoresizingMaskIntoConstraints = YES;
    return self.webView;
}

@end
