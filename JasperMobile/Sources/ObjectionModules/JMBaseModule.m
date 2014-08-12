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
//  JMBaseModule.m
//  Jaspersoft Corporation
//

#import "JMBaseModule.h"
#import "JMFavoritesUtil.h"

@implementation JMBaseModule

- (void)configure
{
    // Set visibility scope
    [self bindClass:[JSProfile class] inScope:JSObjectionScopeSingleton];
    [self bindClass:[JSRESTReport class] inScope:JSObjectionScopeSingleton];
    [self bindClass:[JSRESTResource class] inScope:JSObjectionScopeSingleton];
    [self bindClass:[JSConstants class] inScope:JSObjectionScopeSingleton];
    [self bindClass:[NSManagedObjectContext class] inScope:JSObjectionScopeSingleton];

    JSRESTReport *reportClient = [[JSRESTReport alloc] init];
    JSRESTResource *resourceClient = [[JSRESTResource alloc] init];
    // Set "continue request" as a default request background policy
    reportClient.requestBackgroundPolicy = JSRequestBackgroundPolicyContinue;
    resourceClient.requestBackgroundPolicy = JSRequestBackgroundPolicyContinue;

    [self bind:reportClient toClass:[JSRESTReport class]];
    [self bind:resourceClient toClass:[JSRESTResource class]];
    [self bind:[JSConstants sharedInstance] toClass:[JSConstants class]];
    [self bind:self.managedObjectContext toClass:[NSManagedObjectContext class]];
}

@end
