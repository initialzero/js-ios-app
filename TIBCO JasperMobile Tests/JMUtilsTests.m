//
//  JMUtilsTests.m
//  TIBCO JasperMobile
//
//  Created by Aleksandr Dakhno on 12/4/14.
//  Copyright (c) 2014 TIBCO JasperMobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "JMUtils.h"

@interface JMUtilsTests : XCTestCase

@end

@implementation JMUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatReportNameCannotBeEmpty {
    NSString *reportName = @"";
    NSString *errorMessage;
    BOOL isValid = [JMUtils validateResourceName:reportName errorMessage:&errorMessage];
    XCTAssertFalse(isValid);
}

- (void)testThatReportNameNotContainsWrongSymbols {
    NSString *reportName = @"~!#$%^|`@&*()-+={}[]:;\"'<>,?/|\\";
    NSString *errorMessage;
    BOOL isValid = [JMUtils validateResourceName:reportName errorMessage:&errorMessage];
    XCTAssertFalse(isValid);
}

- (void)testThatReportNameCorrectlyValidateForNotEmptyReportNameAndWithoutWrongSymbolsInReportName {
    NSString *reportName = @"ReportName";
    NSString *errorMessage;
    BOOL isValid = [JMUtils validateResourceName:reportName errorMessage:&errorMessage];
    XCTAssert(isValid);
}



@end
