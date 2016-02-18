//
//  JMServerProfilesUITests.m
//  TIBCO JasperMobile
//
//  Created by Aleksandr Dakhno on 2/14/16.
//  Copyright © 2016 TIBCO JasperMobile. All rights reserved.
//

#import "JMBaseUITestCase.h"

@interface JMServerProfilesUITests : JMBaseUITestCase

@end

@implementation JMServerProfilesUITests

- (void)setUp {
    [super setUp];
    
    XCUIElement *loginPageView = self.application.otherElements[@"JMLoginPageAccessibilityId"];
    if (loginPageView.exists) {
        [self loginWithTestProfile];
    } else {
        [self logout];
        [self loginWithTestProfile];
    }
}

- (void)testThatListOfServerProfilesVisible
{
    
}

- (void)tearDown {
    [self logout];
    
    [super tearDown];
}

@end
