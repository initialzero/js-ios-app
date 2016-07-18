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
#import "JMExternalWindowControlsVC.h"
#import "JSReportSaver.h"
#import "JMWebViewManager.h"
#import "JMWebEnvironment.h"
#import "JMResource.h"
#import "JMAnalyticsManager.h"

@interface JMSavedResourceViewerViewController () <UIDocumentInteractionControllerDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) JMSavedResources *savedResources;
@property (nonatomic, strong) NSString *changedReportName;
@property (nonatomic) UIDocumentInteractionController *documentController;
@property (nonatomic) JMExternalWindowControlsVC *controlViewController;
@property (nonatomic, strong) NSURL *savedResourceURL;
@property (nonatomic, weak) UIImageView *imageView;
@end

@implementation JMSavedResourceViewerViewController
@synthesize changedReportName;


#pragma mark - Accessors
- (JMSavedResources *)savedResources
{
    if (!_savedResources) {
        _savedResources = [JMSavedResources savedResourceFromResource:self.resource];
    }

    return _savedResources;
}

- (UIView *)resourceView
{
    UIView *resourceView;
    if (self.imageView) {
        resourceView = self.imageView;
    } else {
        JMWebEnvironment *webEnvironment = [[JMWebViewManager sharedInstance] webEnvironmentForId:kJMResourceViewerWebEnvironmentIdentifier];
        resourceView = webEnvironment.webView;
    }
    return resourceView;
}

#pragma mark - Overrided methods
- (void)cancelResourceViewingAndExit:(BOOL)exit
{
    [self.documentController dismissMenuAnimated:YES];

    if (self.savedResourceURL) {
        [self removeSavedResource];
    }

    [super cancelResourceViewingAndExit:exit];
}


- (void)startResourceViewing
{
    if (self.resource.type == JMResourceTypeFile) {
        [self showRemoteResource];
    } else {
        [self showSavedResource];
    }

    // Analytics
    NSString *label = [kJMAnalyticsResourceLabelSavedResource stringByAppendingFormat:@" (%@)", [self.savedResources.format uppercaseString]];
    [[JMAnalyticsManager sharedManager] sendAnalyticsEventWithInfo:@{
            kJMAnalyticsCategoryKey : kJMAnalyticsEventCategoryResource,
            kJMAnalyticsActionKey   : kJMAnalyticsEventActionOpen,
            kJMAnalyticsLabelKey    : label
    }];
}

- (JMMenuActionsViewAction)availableAction
{
    JMMenuActionsViewAction action = JMMenuActionsViewAction_None;
    if (self.resource.type == JMResourceTypeFile) {
        action = [super availableAction] | JMMenuActionsViewAction_OpenIn;
    } else {
        action = [super availableAction] | JMMenuActionsViewAction_Rename | JMMenuActionsViewAction_Delete | JMMenuActionsViewAction_OpenIn ;
    }

    // TODO: We need come up with another approach to control a resource which is being presented on tv.
//    if ([self isExternalScreenAvailable]) {
//        action |= [self isContentOnTV] ?  JMMenuActionsViewAction_HideExternalDisplay : JMMenuActionsViewAction_ShowExternalDisplay;
//    }
    return action;
}

#pragma mark - JMMenuActionsViewDelegate
- (void)actionsView:(JMMenuActionsView *)view didSelectAction:(JMMenuActionsViewAction)action
{
    [super actionsView:view didSelectAction:action];
    if (action == JMMenuActionsViewAction_Rename) {
        __weak typeof(self) weakSelf = self;
        UIAlertController *alertController = [UIAlertController alertTextDialogueControllerWithLocalizedTitle:@""
                                                                                                      message:nil
                                                                                textFieldConfigurationHandler:^(UITextField * _Nonnull textField) {
                                                                                    __strong typeof(self) strongSelf = weakSelf;
                                                                                    textField.placeholder = JMCustomLocalizedString(@"savedreport_viewer_modify_reportname", nil);
                                                                                    textField.text = [strongSelf.resource.resourceLookup.label copy];
                                                                                } textValidationHandler:^NSString * _Nonnull(NSString * _Nullable text) {
                                                                                    NSString *errorMessage = nil;
                                                                                    __strong typeof(self) strongSelf = weakSelf;
                                                                                    if (strongSelf) {
                                                                                        [JMUtils validateResourceName:text errorMessage:&errorMessage];
                                                                                        if (!errorMessage && ![JMSavedResources isAvailableResourceName:text format:strongSelf.savedResources.format resourceType:[JMResource typeForResourceLookupType:strongSelf.savedResources.wsType]]) {
                                                                                            errorMessage = JMCustomLocalizedString(@"resource_viewer_save_name_errmsg_notunique", nil);
                                                                                        }
                                                                                    }
                                                                                    return errorMessage;
                                                                                } textEditCompletionHandler:^(NSString * _Nullable text) {
                                                                                    __strong typeof(self) strongSelf = weakSelf;
                                                                                    if ([strongSelf.savedResources renameResourceTo:text]) {
                                                                                        strongSelf.title = text;
                                                                                        strongSelf.resource = [strongSelf.savedResources wrapperFromSavedResources];
                                                                                        [strongSelf setupRightBarButtonItems];
                                                                                        [strongSelf startResourceViewing];
                                                                                    }
                                                                                }];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if(action == JMMenuActionsViewAction_Delete) {
        UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_confirmation"
                                                                                          message:@"savedreport_viewer_delete_confirmation_message"
                                                                                cancelButtonTitle:@"dialog_button_cancel"
                                                                          cancelCompletionHandler:nil];
        __weak typeof(self) weakSelf = self;
        [alertController addActionWithLocalizedTitle:@"dialog_button_ok" style:UIAlertActionStyleDefault handler:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action) {
            __strong typeof(self) strongSelf = weakSelf;
            BOOL shouldCloseViewer = YES;
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(resourceViewer:shouldCloseViewerAfterDeletingResource:)]) {
                shouldCloseViewer = [strongSelf.delegate resourceViewer:strongSelf shouldCloseViewerAfterDeletingResource:strongSelf.resource];
            }
            [strongSelf cancelResourceViewingAndExit:shouldCloseViewer];
            [strongSelf.savedResources removeResource];
            
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(resourceViewer:didDeleteResource:)]) {
                [strongSelf.delegate resourceViewer:strongSelf didDeleteResource:strongSelf.resource];
            }
        }];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if (action == JMMenuActionsViewAction_OpenIn) {
        // TODO: Should be reviewed and refactored!!!
        NSURL *url;
        if (self.resource.type == JMResourceTypeFile) {
            url = self.savedResourceURL;
        } else {
            url = [NSURL fileURLWithPath:[JMSavedResources absolutePathToSavedResource:self.savedResources]];
        }
        self.documentController = [self setupDocumentControllerWithURL:url
                                                         usingDelegate:self];
        
        BOOL canOpen = [self.documentController presentOpenInMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
        if (!canOpen) {
            NSString *errorMessage = JMCustomLocalizedString(@"error_openIn_message", nil);
            NSError *error = [NSError errorWithDomain:@"dialod_title_error" code:NSNotFound userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
            [JMUtils presentAlertControllerWithError:error completion:nil];
        }
    }
}

#pragma mark - Helpers
- (UIDocumentInteractionController *) setupDocumentControllerWithURL: (NSURL *) fileURL
                                                       usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    return interactionController;
}

#pragma mark - Viewers
- (void)showSavedResource
{
    NSString *reportDirectory = [JMSavedResources pathToFolderForSavedResource:self.savedResources];
    
    NSString *tempAppDirectory = NSTemporaryDirectory();
    NSString *tempReportDirectory = [tempAppDirectory stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    
    NSError *error = nil;
    if ([[NSFileManager defaultManager] copyItemAtPath:reportDirectory toPath:tempReportDirectory error:&error]) {
        NSString *tempReportPath = [tempReportDirectory stringByAppendingPathComponent:[self.savedResources.label stringByAppendingPathExtension:self.savedResources.format]];
        self.savedResourceURL = [NSURL fileURLWithPath:tempReportPath];
        [self showResourceWithURL:self.savedResourceURL
                   resourceFormat:self.savedResources.format
                          baseURL:nil];
    }
    if (error) {
        [JMUtils presentAlertControllerWithError:error completion:^{
            [self cancelResourceViewingAndExit:YES];
        }];
    }
}

- (void)showRemoteResource
{
    [self startShowLoaderWithMessage:@"status_loading" cancelBlock:^{
        [self cancelResourceViewingAndExit:YES];
    }];

    __typeof(self) weakSelf = self;
    [self.restClient contentResourceWithResourceLookup:self.resource.resourceLookup
                                            completion:^(JSContentResource *resource, NSError *error) {
                                                __typeof(self) strongSelf = weakSelf;
                                                [strongSelf stopShowLoader];
                                                if (error) {
                                                    [strongSelf showErrorWithMessage:error.localizedDescription
                                                                          completion:^{
                                                                              [strongSelf cancelResourceViewingAndExit:YES];
                                                                          }];
                                                } else {
                                                    if ([strongSelf isSupportedResource:resource]) {
                                                        [strongSelf startShowLoaderWithMessage:@"status_loading" cancelBlock:^{
                                                            [strongSelf cancelResourceViewingAndExit:YES];
                                                        }];
                                                        
                                                        NSString *resourcePath = [NSString stringWithFormat:@"%@/rest_v2/resources%@", strongSelf.restClient.serverProfile.serverUrl, resource.uri];
                                                        NSString *tempAppDirectory = NSTemporaryDirectory();
                                                        NSString *tempReportDirectory = [tempAppDirectory stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];                                                        
                                                        NSString *tempReportPath = [tempReportDirectory stringByAppendingPathComponent:resource.label];
                                                        
                                                        __typeof(self) weakSelf = strongSelf;
                                                        [JSReportSaver downloadResourceWithRestClient:self.restClient
                                                                                        fromURLString:resourcePath
                                                                                      destinationPath:tempReportPath
                                                                                           completion:^(NSError *error) {
                                                                                               __typeof(self) strongSelf = weakSelf;
                                                                                               [strongSelf stopShowLoader];
                                                                                               if (error) {
                                                                                                   [strongSelf showErrorWithMessage:error.localizedDescription
                                                                                                                         completion:^{
                                                                                                                             [strongSelf cancelResourceViewingAndExit:YES];
                                                                                                                         }];
                                                                                               } else {
                                                                                                   strongSelf.savedResourceURL = [NSURL fileURLWithPath:tempReportPath];
                                                                                                   
                                                                                                   if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_IMG]) {
                                                                                                       [strongSelf showImageWithURL:strongSelf.savedResourceURL];
                                                                                                   } else {
                                                                                                       NSURL *fileURL = [strongSelf updateFormatForURL:strongSelf.savedResourceURL withFormat:resource.fileFormat];
                                                                                                       [strongSelf moveResourceFromPath:strongSelf.savedResourceURL.path
                                                                                                                                 toPath:fileURL.path];
                                                                                                       strongSelf.savedResourceURL = fileURL;
                                                                                                       NSString *baseURLString = [NSString stringWithFormat:@"%@/fileview/fileview/%@", self.restClient.serverProfile.serverUrl, resource.uri];
                                                                                                       [strongSelf showResourceWithURL:fileURL
                                                                                                                        resourceFormat:resource.fileFormat
                                                                                                                               baseURL:[NSURL URLWithString:baseURLString]];
                                                                                                   }
                                                                                               }
                                                                                           }];
                                                    } else {
                                                        // TODO: add showing with ...
                                                        [strongSelf showErrorWithMessage:JMCustomLocalizedString(@"savedreport_viewer_format_not_supported", nil)
                                                                              completion:^{
                                                                                  [strongSelf cancelResourceViewingAndExit:YES];
                                                                              }];
                                                    }
                                                }
                                            }];
}

- (void)showResourceWithURL:(NSURL *)url
             resourceFormat:(NSString *)resourceFormat
                    baseURL:(NSURL *)baseURL
{
    JMWebEnvironment *webEnvironment = [[JMWebViewManager sharedInstance] webEnvironmentForId:kJMResourceViewerWebEnvironmentIdentifier];
    [webEnvironment loadLocalFileFromURL:url
                              fileFormat:resourceFormat
                                 baseURL:baseURL];
}

- (void)showImageWithURL:(NSURL *)url
{
    [[self resourceView] removeFromSuperview];

    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    UIScrollView *scrollView = [self createScrollViewWithImage:image];
    [self.view addSubview:scrollView];

    [self addConstraintsForScrollView:scrollView];
}

#pragma mark - Helpers
- (void)removeSavedResource
{
    NSString *directoryPath = [self.savedResourceURL.path stringByDeletingLastPathComponent];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:nil];
    }
    _savedResourceURL = nil;
}

- (NSError *)moveResourceFromPath:(NSString *)fromPath toPath:(NSString *)toPath
{
    if ([fromPath isEqualToString:toPath]) {
        return nil;
    }
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:fromPath
                                            toPath:toPath
                                             error:&error];
    return error;
}

- (NSURL *)updateFormatForURL:(NSURL *)fromURL withFormat:(NSString *)newFormat
{
    NSString *fullPathWithoutFormat = [fromURL.path stringByDeletingPathExtension];
    NSString *fullPathWithNewFormat = [fullPathWithoutFormat stringByAppendingPathExtension:newFormat];
    NSURL *URLWithFormat = [NSURL fileURLWithPath:fullPathWithNewFormat];
    JMLog(@"%@", URLWithFormat);
    return URLWithFormat;
}

- (void)showErrorWithMessage:(NSString *)message completion:(void(^)(void))completion
{
    UIAlertController *alertController = [UIAlertController alertControllerWithLocalizedTitle:@"dialod_title_error"
                                                                                      message:message
                                                                            cancelButtonTitle:@"dialog_button_ok"
                                                                      cancelCompletionHandler:^(UIAlertController *controller, UIAlertAction *action) {
                                                                          if (completion) {
                                                                              completion();
                                                                          }
                                                                      }];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)isSupportedResource:(JSContentResource *)resource
{
    BOOL isHTML = [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_HTML];
    BOOL isPDF = [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_PDF];
    BOOL isXLS = [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_XLS];
    BOOL isXLSX = [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_XLSX];
    BOOL isIMG = [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_IMG];
    return isHTML || isPDF || isXLS || isXLSX || isIMG;
}

- (UIScrollView *)createScrollViewWithImage:(UIImage *)image
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    [scrollView addSubview:imageView];
    self.imageView = imageView;

    CGFloat contentViewHeight = CGRectGetHeight(self.imageView.frame);
    CGFloat contentViewWidth = CGRectGetWidth(self.imageView.frame);

    CGFloat containerViewHeight = CGRectGetHeight(scrollView.frame);
    CGFloat containerViewWidth = CGRectGetWidth(scrollView.frame);

    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;

    NSLayoutConstraint *constraint;
    if (contentViewHeight > containerViewHeight || contentViewWidth > containerViewWidth) {
        JMLog(@"big content");
        scrollView.delegate = self;
        scrollView.clipsToBounds = YES;
        scrollView.contentSize = image.size;

        CGFloat minScaleFactor = CGRectGetWidth(self.view.frame)/image.size.width;
        scrollView.minimumZoomScale = minScaleFactor;
        scrollView.maximumZoomScale = 1;

        [scrollView setZoomScale:minScaleFactor animated:YES];

        constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                  attribute:NSLayoutAttributeTrailing
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:scrollView
                                                  attribute:NSLayoutAttributeTrailing
                                                 multiplier:1
                                                   constant:0];
        [scrollView addConstraint:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                  attribute:NSLayoutAttributeLeading
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:scrollView
                                                  attribute:NSLayoutAttributeLeading
                                                 multiplier:1
                                                   constant:0];
        [scrollView addConstraint:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:scrollView
                                                  attribute:NSLayoutAttributeTop
                                                 multiplier:1
                                                   constant:0];
        [scrollView addConstraint:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:scrollView
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1
                                                   constant:0];
        [scrollView addConstraint:constraint];
    } else {
        JMLog(@"small content");
        constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                  attribute:NSLayoutAttributeCenterX
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:scrollView
                                                  attribute:NSLayoutAttributeCenterX
                                                 multiplier:1
                                                   constant:0];
        [scrollView addConstraint:constraint];

        constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                                  attribute:NSLayoutAttributeCenterY
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:scrollView
                                                  attribute:NSLayoutAttributeCenterY
                                                 multiplier:1
                                                   constant:0];
        [scrollView addConstraint:constraint];
    }

    constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                              attribute:NSLayoutAttributeWidth
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                               constant:contentViewWidth];
    [scrollView addConstraint:constraint];

    constraint = [NSLayoutConstraint constraintWithItem:self.imageView
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:nil
                                              attribute:NSLayoutAttributeNotAnAttribute
                                             multiplier:1
                                               constant:contentViewHeight];
    [scrollView addConstraint:constraint];

    return scrollView;
}

- (void)addConstraintsForScrollView:(UIScrollView *)scrollView
{
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[scrollView]-0-|"
                                                                      options:NSLayoutFormatAlignAllLeading
                                                                      metrics:nil
                                                                        views:@{@"scrollView": scrollView}]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[scrollView]-0-|"
                                                                      options:NSLayoutFormatAlignAllLeading
                                                                      metrics:nil
                                                                        views:@{@"scrollView": scrollView}]];
}


#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
