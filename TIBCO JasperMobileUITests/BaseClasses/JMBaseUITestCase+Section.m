//
// Created by Aleksandr Dakhno on 9/20/16.
// Copyright (c) 2016 TIBCO JasperMobile. All rights reserved.
//

#import "JMBaseUITestCase+Section.h"
#import "JMBaseUITestCase+Helpers.h"
#import "JMBaseUITestCase+ActionsMenu.h"


@implementation JMBaseUITestCase (Section)

#pragma mark - View Types
- (void)switchViewFromListToGridInSectionWithTitle:(NSString *)sectionTitle
{
    XCUIElement *navBar = [self waitNavigationBarWithLabel:sectionTitle
                                                   timeout:kUITestsBaseTimeout];
    XCUIElement *gridButton = [self waitButtonWithAccessibilityId:@"grid button"
                                                    parentElement:navBar
                                                          timeout:kUITestsBaseTimeout];
    [gridButton tap];
}

- (void)switchViewFromGridToListInSectionWithTitle:(NSString *)sectionTitle
{
    XCUIElement *navBar = [self waitNavigationBarWithLabel:sectionTitle
                                                   timeout:kUITestsBaseTimeout];
    XCUIElement *listButton = [self waitButtonWithAccessibilityId:@"horizontal list button"
                                                    parentElement:navBar
                                                          timeout:kUITestsBaseTimeout];
    [listButton tap];
}

#pragma mark - Search
- (void)searchResourceWithName:(NSString *)resourceName
  inSectionWithAccessibilityId:(NSString *)sectionAccessibilityId
{
    XCUIElement *searchResourcesSearchField = [self searchFieldFromSectionWithAccessibilityId:sectionAccessibilityId];
    [searchResourcesSearchField tap];

    XCUIElement *clearTextButton = [self findButtonWithTitle:@"Clear text"
                                               parentElement:searchResourcesSearchField];
    if (clearTextButton) {
        [clearTextButton tap];
    }

    [searchResourcesSearchField typeText:resourceName];

    XCUIElement *searchButton = [self waitButtonWithAccessibilityId:@"Search"
                                                            timeout:kUITestsBaseTimeout];
    [searchButton tap];
}

- (void)clearSearchResultInSectionWithAccessibilityId:(NSString *)sectionAccessibilityId
{
    XCUIElement *searchResourcesSearchField = [self searchFieldFromSectionWithAccessibilityId:sectionAccessibilityId];
    [searchResourcesSearchField tap];

    XCUIElement *clearTextButton = [self findButtonWithTitle:@"Clear text"
                                               parentElement:searchResourcesSearchField];
    if (clearTextButton) {
        [clearTextButton tap];
    }

    XCUIElement *cancelButton = [self waitButtonWithAccessibilityId:@"Cancel"
                                                            timeout:kUITestsBaseTimeout];
    [cancelButton tap];
}

- (XCUIElement *)searchFieldFromSectionWithAccessibilityId:(NSString *)accessibilityId
{
    XCUIElement *section = [self waitElementWithAccessibilityId:accessibilityId
                                                        timeout:kUITestsBaseTimeout];
    XCUIElement *searchField = section.searchFields[@"Search resources"];
    [self waitElementReady:searchField
                   timeout:kUITestsBaseTimeout];
    return searchField;
}

#pragma mark - Cells

- (void)givenThatCollectionViewContainsListOfCells
{
    NSInteger countOfListCells = [self countOfListCells];
    if (countOfListCells > 0) {
        return;
    } else {
        // TODO: use section specific
        [self switchViewFromListToGridInSectionWithTitle:@"Library"];
    }
}

- (NSInteger)countOfGridCells
{
    return [self countCellsWithAccessibilityId:@"JMCollectionViewGridCellAccessibilityId"];
}

- (NSInteger)countOfListCells
{
    return [self countCellsWithAccessibilityId:@"JMCollectionViewListCellAccessibilityId"];
}

- (void)verifyThatCollectionViewContainsListOfCells
{
    // Shold be 'list' cells
    NSInteger countOfListCells = [self countOfListCells];
    XCTAssertTrue(countOfListCells > 0, @"Should be 'List' presentation");

    // Should not be 'grid' cells
    NSInteger countOfGridCells = [self countOfGridCells];
    XCTAssertTrue(countOfGridCells == 0, @"Should be 'Grid' presentation");
}

- (void)verifyThatCollectionViewContainsGridOfCells
{
    // Should be 'grid' cells
    NSInteger countOfGridCells = [self countOfGridCells];
    XCTAssertTrue(countOfGridCells > 0, @"Should be 'Grid' presentation");

    // Shold not be 'list' cells
    NSInteger countOfListCells = [self countOfListCells];
    XCTAssertTrue(countOfListCells == 0, @"Should be 'List' presentation");
}

- (void)verifyThatCollectionViewContainsCells
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.hittable == true"];
    NSInteger filtredResultCount = [[self.application.cells allElementsBoundByIndex] filteredArrayUsingPredicate:predicate].count;
    XCTAssertTrue(filtredResultCount > 0, @"Should be some cells");
}

- (void)verifyThatCollectionViewNotContainsCells
{
    // TODO: implement
}

#pragma mark - Helpers - Menu Sort By

- (void)openSortMenuInSectionWithTitle:(NSString *)sectionTitle
{
    BOOL isShareButtonExists = [self isShareButtonExists];
    if (isShareButtonExists) {
        [self openMenuActions];
        [self tryOpenSortMenuFromMenuActions];
    } else {
        [self tryOpenSortMenuFromNavBarWithTitle:sectionTitle];
    }
}

- (void)tryOpenSortMenuFromMenuActions
{
    XCUIElement *menuActionsElement = [self.application.tables elementBoundByIndex:0];
    XCUIElement *sortActionElement = menuActionsElement.staticTexts[@"Sort by"];
    if (sortActionElement.exists) {
        [sortActionElement tap];

        // Wait until sort view appears
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.tables.count == 1"];
        [self expectationForPredicate:predicate
                  evaluatedWithObject:self.application
                              handler:nil];
        [self waitForExpectationsWithTimeout:5 handler:nil];

    } else {
        XCTFail(@"Sort Action isn't visible");
    }
}

- (void)tryOpenSortMenuFromNavBarWithTitle:(NSString *)navBarTitle
{
    XCUIElement *navBar = self.application.navigationBars[navBarTitle];
    if (navBar.exists) {
        XCUIElement *sortButton = navBar.buttons[@"sort action"];
        if (sortButton.exists) {
            [sortButton tap];
        } else {
            XCTFail(@"Sort Button isn't visible");
        }
    } else {
        XCTFail(@"Navigation bar isn't visible");
    }
}

- (void)selectSortBy:(NSString *)sortTypeString inSectionWithTitle:(NSString *)sectionTitle
{
    [self openSortMenuInSectionWithTitle:sectionTitle];
    XCUIElement *sortOptionsViewElement = [self.application.tables elementBoundByIndex:0];
    if (sortOptionsViewElement.exists) {
        XCUIElement *sortOptionElement = sortOptionsViewElement.staticTexts[sortTypeString];
        if (sortOptionElement.exists) {
            [sortOptionElement tap];
        } else {
            XCTFail(@"'%@' Sort Option isn't visible", sortTypeString);
        }
    } else {
        XCTFail(@"Sort Options View isn't visible");
    }
}

#pragma mark - Menu Filter by

- (void)openFilterMenuInSectionWithTitle:(NSString *)sectionTitle
{
    BOOL isShareButtonExists = [self isShareButtonExists];
    if (isShareButtonExists) {
        [self openMenuActions];
        [self tryOpenFilterMenuFromMenuActions];
    } else {
        [self tryOpenFilterMenuFromNavBarWithTitle:sectionTitle];
    }
}

- (void)tryOpenFilterMenuFromMenuActions
{
    XCUIElement *menuActionsElement = [self.application.tables elementBoundByIndex:0];
    XCUIElement *filterActionElement = menuActionsElement.staticTexts[@"Filter by"];
    if (filterActionElement.exists) {
        [filterActionElement tap];

        // Wait until sort view appears
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.tables.count == 1"];
        [self expectationForPredicate:predicate
                  evaluatedWithObject:self.application
                              handler:nil];
        [self waitForExpectationsWithTimeout:5 handler:nil];

    } else {
        XCTFail(@"Sort Action isn't visible");
    }
}

- (void)tryOpenFilterMenuFromNavBarWithTitle:(NSString *)navBarTitle
{
    XCUIElement *navBar = self.application.navigationBars[navBarTitle];
    if (navBar.exists) {
        XCUIElement *filterButton = navBar.buttons[@"filter action"];
        if (filterButton.exists) {
            [filterButton tap];
        } else {
            XCTFail(@"Filter Button isn't visible");
        }
    } else {
        XCTFail(@"Navigation bar isn't visible");
    }
}

- (void)selectFilterBy:(NSString *)filterTypeString
    inSectionWithTitle:(NSString *)sectionTitle
{
    [self openFilterMenuInSectionWithTitle:sectionTitle];

    XCUIElement *filterOptionsViewElement = [self.application.tables elementBoundByIndex:0];
    if (filterOptionsViewElement.exists) {
        XCUIElement *filterOptionElement = filterOptionsViewElement.staticTexts[filterTypeString];
        if (filterOptionElement.exists) {
            [filterOptionElement tap];
        } else {
            XCTFail(@"'%@' Filter Option isn't visible", filterTypeString);
        }
    } else {
        XCTFail(@"Filter Options View isn't visible");
    }
}

#pragma mark - CollectionView

- (XCUIElement *)collectionViewElementFromSectionWithAccessibilityId:(NSString *)accessibilityId
{
    XCUIElement *section = [self waitElementWithAccessibilityId:accessibilityId
                                                        timeout:kUITestsBaseTimeout];
    return section;
}

@end