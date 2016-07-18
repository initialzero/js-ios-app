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


#import "JMResourceCollectionViewCell.h"
#import "JMSavedResources+Helpers.h"
#import "JMServerProfile+Helpers.h"
#import "UIImageView+AFNetworking.h"
#import "UIImage+Additions.h"
#import "JMExportResource.h"
#import "JMResource.h"
#import "JMAnalyticsManager.h"

NSString * kJMHorizontalResourceCell = @"JMHorizontalResourceCollectionViewCell";
NSString * kJMGridResourceCell = @"JMGridResourceCollectionViewCell";


@interface JMResourceCollectionViewCell()
@property (nonatomic, weak) IBOutlet UIImageView *resourceImage;
@property (nonatomic, weak) IBOutlet UILabel *resourceName;
@property (nonatomic, weak) IBOutlet UILabel *resourceDescription;
@property (nonatomic, weak) IBOutlet UIButton *infoButton;
@property (nonatomic, readwrite) UIImage *thumbnailImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@end

@implementation JMResourceCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.resourceName.adjustsFontSizeToFitWidth = YES;
    self.resourceName.minimumScaleFactor = [JMUtils isCompactWidth] ? 0.7 : 0.5;
    
    self.resourceName.font = [[JMThemesManager sharedManager] collectionResourceNameFont];
    self.resourceName.textColor = [[JMThemesManager sharedManager] resourceViewResourceCellTitleTextColor];
    
    self.resourceDescription.font = [[JMThemesManager sharedManager] collectionResourceDescriptionFont];
    self.resourceDescription.textColor = [[JMThemesManager sharedManager] resourceViewResourceCellDetailsTextColor];
    self.infoButton.tintColor = [[JMThemesManager sharedManager] resourceViewResourceInfoButtonTintColor];

    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)setResource:(JMResource *)resource
{
    _resource = resource;
    self.resourceName.text = resource.resourceLookup.label;
    self.resourceDescription.text = resource.resourceLookup.resourceDescription;
    self.thumbnailImage = nil;
    [self updateResourceImage];
    
    // Add file extension for saved & temp exported items
    if (self.resource.type == JMResourceTypeSavedReport || self.resource.type == JMResourceTypeSavedDashboard) {
        JMSavedResources *savedReport = [JMSavedResources savedResourceFromResource:self.resource];
        self.resourceName.text = [resource.resourceLookup.label stringByAppendingPathExtension:savedReport.format];
    } else if (self.resource.type == JMResourceTypeTempExportedReport || self.resource.type == JMResourceTypeTempExportedDashboard) {
        JMExportResource *exportResource = (JMExportResource *)resource;
        self.resourceName.text = [exportResource.resourceLookup.label stringByAppendingPathExtension:exportResource.format];
    }
}

- (IBAction)infoButtonDidTapped:(id)sender
{
    [self.delegate infoButtonDidTappedOnCell:self];
}

- (void)updateResourceImage
{
    self.contentView.alpha = 1;
    UIImage *resourceImage;
    if (self.resource.type == JMResourceTypeReport || self.resource.type == JMResourceTypeSchedule) {
        resourceImage = [UIImage imageNamed:@"res_type_report"];
        if ([JMUtils isServerVersionUpOrEqual6]) { // Thumbnails supported on server
            NSMutableURLRequest *imageRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self.restClient generateThumbnailImageUrl:self.resource.resourceLookup.uri]]];
            [imageRequest setValue:@"image/jpeg" forHTTPHeaderField:@"Accept"];
            __weak typeof(self)weakSelf = self;
            [self.resourceImage setImageWithURLRequest:imageRequest
                                      placeholderImage:resourceImage
                                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                   __strong typeof(self)strongSelf = weakSelf;
                                                   if (image) {
                                                       strongSelf.thumbnailImage = image;
                                                       [strongSelf updateResourceImage:self.thumbnailImage thumbnails:YES];
                                                       [[JMAnalyticsManager sharedManager] sendThumbnailEventIfNeed];
                                                   }
                                               }
                                               failure:nil];
        }
    } else if (self.resource.type == JMResourceTypeSavedReport || self.resource.type == JMResourceTypeSavedDashboard) {
        JMLog(@"saved items");
//        JMSavedResources *savedReport = [JMSavedResources savedResourceFromResourceLookup:self.resourceLookup];
//        self.thumbnailImage = [savedReport thumbnailImage];
//        resourceImage = [UIImage imageNamed:[NSString stringWithFormat:@"res_type_%@", savedReport.format]];

        // We temporary disabled showing thumbnails of saved items
        resourceImage = [UIImage imageNamed:@"res_type_report"];
        JMSavedResources *savedReport = [JMSavedResources savedResourceFromResource:self.resource];
        if (savedReport) {
            if ([savedReport.format isEqualToString:kJS_CONTENT_TYPE_HTML]) {
                resourceImage = [UIImage imageNamed:@"res_type_file_html"];
            } else if ([savedReport.format isEqualToString:kJS_CONTENT_TYPE_PDF]) {
                resourceImage = [UIImage imageNamed:@"res_type_file_pdf"];
            } else if ([savedReport.format isEqualToString:kJS_CONTENT_TYPE_XLS]) {
                resourceImage = [UIImage imageNamed:@"res_type_file_xls"];
            } else if ([savedReport.format isEqualToString:kJS_CONTENT_TYPE_IMG]) {
                resourceImage = [UIImage imageNamed:@"res_type_file_img"];
            }
        }
    } else if (self.resource.type == JMResourceTypeTempExportedReport || self.resource.type == JMResourceTypeTempExportedDashboard) {
        resourceImage = [UIImage imageNamed:@"res_type_report"];
        JMExportResource *exportResource = (JMExportResource *)self.resource;
        if ([exportResource.format isEqualToString:kJS_CONTENT_TYPE_HTML]) {
            resourceImage = [UIImage imageNamed:@"res_type_file_html"];
        } else if ([exportResource.format isEqualToString:kJS_CONTENT_TYPE_PDF]) {
            resourceImage = [UIImage imageNamed:@"res_type_file_pdf"];
        } else if ([exportResource.format isEqualToString:kJS_CONTENT_TYPE_XLS]) {
            resourceImage = [UIImage imageNamed:@"res_type_file_xls"];
        } else if ([exportResource.format isEqualToString:kJS_CONTENT_TYPE_IMG]) {
            resourceImage = [UIImage imageNamed:@"res_type_file_img"];
        }
        self.contentView.alpha = 0.5;
    } else if (self.resource.type == JMResourceTypeDashboard || self.resource.type == JMResourceTypeLegacyDashboard) {
        resourceImage = [UIImage imageNamed:@"res_type_dashboard"];
    } else if (self.resource.type == JMResourceTypeFolder) {
        resourceImage = [UIImage imageNamed:@"res_type_folder"];
    } else if(self.resource.type == JMResourceTypeFile) {
        resourceImage = [UIImage imageNamed:@"res_type_file"];

        __typeof(self) weakSelf = self;
        [self.restClient contentResourceWithResourceLookup:self.resource.resourceLookup
                                                completion:^(JSContentResource *resource, NSError *error) {
                                                    __typeof(self) strongSelf = weakSelf;
                                                    if (resource) {
                                                        NSString *imageName = @"res_type_file";
                                                        if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_HTML]) {
                                                            imageName = @"res_type_file_html";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_PDF]) {
                                                            imageName = @"res_type_file_pdf";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_IMG]) {
                                                            imageName = @"res_type_file_img";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_RTF]) {
                                                            imageName = @"res_type_file_rtf";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_CSV]) {
                                                            imageName = @"res_type_file_csv";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_ODT]) {
                                                            imageName = @"res_type_file_odt";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_ODS]) {
                                                            imageName = @"res_type_file_ods";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_JSON]) {
                                                            imageName = @"res_type_file_json";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_XLS] || [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_XLSX]) {
                                                            imageName = @"res_type_file_xls";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_PPT] || [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_PPTX]) {
                                                            imageName = @"res_type_file_pptx";
                                                        } else if ([resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_DOC] || [resource.fileFormat isEqualToString:kJS_CONTENT_TYPE_DOCX]) {
                                                            imageName = @"res_type_file_doc";
                                                        }
                                                        UIImage *image = [UIImage imageNamed:imageName];
                                                        [strongSelf updateResourceImage:image thumbnails:NO];
                                                    }
                                                }];
    }
    
    if (resourceImage || _thumbnailImage) {
        [self updateResourceImage:_thumbnailImage ?: resourceImage thumbnails:_thumbnailImage != nil];
    }
}

- (void)updateResourceImage:(UIImage *)image thumbnails:(BOOL)thumbnails
{
    UIImage *resourceImage = thumbnails ? [image cropedImageForRect:self.resourceImage.bounds] : image;
    BOOL shouldFitImage = thumbnails;
    if (!shouldFitImage) {
        shouldFitImage = ((resourceImage.size.height > self.resourceImage.frame.size.height) || (resourceImage.size.width > self.resourceImage.frame.size.width));
    }
    self.resourceImage.contentMode = shouldFitImage ? UIViewContentModeScaleAspectFit : UIViewContentModeCenter;
    if (self.resource.type == JMResourceTypeLegacyDashboard) {
        self.resourceImage.backgroundColor = [UIColor grayColor];
    } else {
        self.resourceImage.backgroundColor = thumbnails ? [UIColor clearColor] : [[JMThemesManager sharedManager] resourceViewResourceCellPreviewBackgroundColor];
    }
    self.resourceImage.image = resourceImage;
    [self layoutIfNeeded];
    self.imageWidthConstraint.constant = [JMUtils isCompactWidth] ? 100: 115;
    [self setNeedsUpdateConstraints];
}

@end
