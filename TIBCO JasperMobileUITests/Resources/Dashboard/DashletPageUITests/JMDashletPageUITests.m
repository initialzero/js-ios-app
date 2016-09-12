//
//  JMDashletPageUITests.m
//  TIBCO JasperMobile
//
//  Created by Aleksandr Dakhno on 2/19/16.
//  Copyright © 2016 TIBCO JasperMobile. All rights reserved.
//

#import "JMDashletPageUITests.h"
#import "JMBaseUITestCase+Dashboard.h"
#import "JMBaseUITestCase+Helpers.h"

static NSString *const kDashletName = @"13. Top Fives Report";

@implementation JMDashletPageUITests

- (void)setUp
{
    [super setUp];
    
    [self openTestDashboardPage];
}

- (void)tearDown
{
    [self closeTestDashlet];
    [self closeTestDashboardPage];
    
    [super tearDown];
}

#pragma mark - Tests

//User should see selected dashlet on the separate screen
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard
//    < Tap on the any dashlet
//    > User should see selected dashlet on the separate screen
- (void)testThatUserCanSeeSelectedDashlet
{
        [self openTestDashletWithHyperlinks];
}

//Back button like title of the dashboard
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard
//    < Open any dashlet
//    < Tap back button
//    > Dashboard View screen should appears
- (void)testThatBackButtonHasCorrectTitle
{
    [self openTestDashletWithHyperlinks];
    [self verifyThatDashletPageHasCorrentBackButton];
}

//Title like name of the dashlet
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard
//    < Open any dashlet
//    > User should see title like name of the dashlet
- (void)testThatPageHasCorrectTitle
{
    [self openTestDashletWithHyperlinks];
    [self verifyThatDashletPageHasCorrectTitle];
}

//Zoom on Dashlet View screen
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard
//    < Open any dashlet
//    < Increase the zoom
//    < Decrease the zoom
//    < Verify that dashlet is not scalled if previous dashlet was scalled
//    < Verify interaction
//    > Dashlet should be bigger
//    > Dashlet should be smaller
//    > Dashlet shouldn't be scalled
//    > Interaction works as expect
- (void)testThatZoomWorkCorrectly
{
    [self openTestDashletWithHyperlinks];
    
    XCUIElement *webView = [self.application.webViews elementBoundByIndex:0];
    [self waitElement:webView
              timeout:kUITestsBaseTimeout];
    [webView pinchWithScale:2
                   velocity:1];
    sleep(kUITestsElementAvailableTimeout);
}

//Hyperlinks
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard with hyperlinks (for instance 1. Supermart Dashboard)
//    < Open dashlet with hyperlinks
//    < Tap on hyperlink
//    > Hyperlink work as expected
- (void)testThatHyperlinksWorkCorrectly
{
    [self openTestDashletWithHyperlinks];
    
    [self openTestHyperlinkPage];
    [self verifyThatReportFromTestHypelinkOnScreen];
    [self closeTestHyperlinkPage];
}

//Input Controls
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard which has reports with IC (for instance 1.Supermart Dashboard)
//    < Open dashlet with IC
//    < Change IC for any report
//    > Report's IC work as expected
// TODO: Old version
- (void)testThatInputControlsWorkCorrectly
{
//    TODO: remove this case, because of 'native input controls change' feature.
}

//Change Chart Type of report
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard with chart reports
//    < Open dashlet with chart
//    < Tap "Chart Types..." button
//    < Select one of chart types
//    < Close "Select Cart Type" window
//    < Tap back button on Dashlet View screen
//    > Chart type of report should be changed. User should see chanched report on Dashboard View screen
- (void)testThatChartTypeCanBeChanged
{
    [self openTestDashletWithChartTypes];
    
    XCUIElement *chartTypeElement = [self waitStaticTextWithAccessibilityId:@"Store Sales"
                                                                    timeout:kUITestsBaseTimeout];
    [chartTypeElement tap];
    sleep(3);
}

//JIVE
//    < Open the Left Panel
//    < Tap on the Library button
//    < Run the dashboard with table or crosstab
//    < Open the dashlet with table or crosstab
//    < Verify JIVE operations
//    < Tap back button on Dashlet View screen
//    > JIVE operations work as expected. User should see saved JIVE operations on Dashboard View screen
- (void)testThatJIVEWorkCorrectly
{
//    XCTFail(@"Not implemented tests");
}

#pragma mark - Helpers

- (void)openTestDashletWithHyperlinks
{
    XCUIElement *customersElement = [self waitStaticTextWithAccessibilityId:@"Customers"
                                                                    timeout:kUITestsBaseTimeout];
    [customersElement tap];
    [self givenLoadingPopupNotVisible];
}

- (void)closeTestDashlet
{
    XCUIElement *backButton = [self waitBackButtonWithAccessibilityId:@"Back"
                                                              timeout:kUITestsBaseTimeout];
    [backButton tap];
    [self givenLoadingPopupNotVisible];
}

- (void)openTestDashletWithChartTypes
{
    XCUIElement *customersElement = [self waitStaticTextWithAccessibilityId:@"Store Cost"
                                                                    timeout:kUITestsBaseTimeout];
    [customersElement tap];
    [self givenLoadingPopupNotVisible];
}

- (void)openTestHyperlinkPage
{
    XCUIElement *hyperlinkElement = [self waitStaticTextWithAccessibilityId:@"Ida Rodriguez"
                                                                    timeout:kUITestsBaseTimeout];
    [hyperlinkElement tap];
    [self givenLoadingPopupNotVisible];
}

- (void)closeTestHyperlinkPage
{
    [self tryBackToPreviousPage];
}

#pragma mark - Verifying

- (void)verifyThatDashletPageHasCorrentBackButton
{
    [self waitBackButtonWithAccessibilityId:@"Back"
                          onNavBarWithLabel:kDashletName
                                    timeout:kUITestsBaseTimeout];
}

- (void)verifyThatDashletPageHasCorrectTitle
{
    [self waitNavigationBarWithLabel:kDashletName
                             timeout:kUITestsBaseTimeout];
}

- (void)verifyThatReportFromTestHypelinkOnScreen
{
    [self waitNavigationBarWithLabel:@"09. Customer Detail Report"
                             timeout:kUITestsBaseTimeout];
}

@end
