//
//  UIColor+RGBComponent.h
//  JasperMobile
//
//  Created by Vlad Zavadskii on 5/8/14.
//  Copyright (c) 2014 com.jaspersoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (RGBComponent)

/**
 Returns an rgb color component as normalized value required by colorWithRed:green:blue:alpha: method
 */
+ (CGFloat)rgbComponent:(CGFloat)color;

@end
