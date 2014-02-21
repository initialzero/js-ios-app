/*
 * JasperMobile for iOS
 * Copyright (C) 2011 - 2014 Jaspersoft Corporation. All rights reserved.
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
//  JMRotationBase.m
//  Jaspersoft Corporation
//

#import "JMRotatable.h"
#import <Objection-iOS/Objection.h>

@implementation JMRotationBase

#pragma mark - Rotation base implementation

+ (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [[self rotation] preferredInterfaceOrientationForPresentation];
}

+ (NSUInteger)supportedInterfaceOrientations
{
    return [[self rotation] supportedInterfaceOrientations];
}

+ (BOOL)shouldAutorotate
{
    return [[self rotation] shouldAutorotate];
}

+ (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [[self rotation] shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - Private

+ (id <JMRotatable>)rotation
{
    return [[JSObjection defaultInjector] getObject:@protocol(JMRotatable)];
}

@end
