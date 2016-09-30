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
//  NSObject+Additions.m
//  TIBCO JasperMobile
//

#import "NSObject+Additions.h"
#import "JMLocalization.h"

@implementation NSObject(Additions)

- (JSRESTBase *)restClient
{
    return [JMSessionManager sharedManager].restClient;
}

- (void)setAccessibility:(BOOL)accessibility withTextKey:(NSString *)key identifier:(NSString *)accessibilityIdentifier
{
    [JMLocalization localizeStringForKey:key completion:^(NSString *localizedString, NSString *languageString) {
        self.isAccessibilityElement = accessibility;
        self.accessibilityLabel = localizedString;
        self.accessibilityLanguage = languageString;
        if ([self conformsToProtocol:@protocol(UIAccessibilityIdentification)]) {
            id identificationObject = self;
            [identificationObject setAccessibilityIdentifier:accessibilityIdentifier];
        }
    }];
}
@end
