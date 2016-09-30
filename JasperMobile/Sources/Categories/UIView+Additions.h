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
//  UIView+Additions.h
//  TIBCO JasperMobile
//

/**
 @author Alexey Gubarev ogubarie@tibco.com
 @author Oleksandr Dahno odahno@tibco.com
 @since 1.9
 */

#import <UIKit/UIKit.h>

@interface UIView (Additions)

- (UIColor *) colorOfPoint:(CGPoint)point;

- (UIImage *)renderedImageForView:(UIView *)view;
- (UIImage *)renderedImage;

- (void)updateFrameWithOrigin:(CGPoint)newOrigin size:(CGSize)newSize;
- (void)updateOriginWithOrigin:(CGPoint)newOrigin;
- (void)updateOriginXWithValue:(CGFloat)newOriginX;
- (void)updateOriginYWithValue:(CGFloat)newOriginY;
- (void)updateHeightWithValue:(CGFloat)newHeight;

// Autolayout
// Make subview fill its parent view
- (void)fillWithView:(UIView *)view;

@end
