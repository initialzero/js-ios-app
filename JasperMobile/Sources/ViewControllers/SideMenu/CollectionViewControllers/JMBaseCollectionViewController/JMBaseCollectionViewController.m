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
//  JMBaseCollectionViewController.h
//  TIBCO JasperMobile
//


#import "JMBaseCollectionViewController.h"
#import "SWRevealViewController.h"
#import "JMLoadingCollectionViewCell.h"
#import "JMResourceCollectionViewCell.h"
#import "JMPopupView.h"
#import "PopoverView.h"
#import "JMListOptionsPopupView.h"
#import "JMCancelRequestPopup.h"
#import "JMAboutViewController.h"
#import "JMRepositoryCollectionViewController.h"
#import "JMReportViewerVC.h"
#import "JMResourceInfoViewController.h"
#import "UIViewController+Additions.h"
#import "JMExportManager.h"
#import "JMResource.h"
#import "JMSchedule.h"
#import "JMWebViewManager.h"

CGFloat const kJMBaseCollectionViewGridWidth = 310;

CGFloat const kJMBaseCollectionViewCompactGridWidth = 150;

NSString * const kJMShowFolderContetnSegue = @"ShowFolderContetnSegue";

NSString * const kJMRepresentationTypeDidChangeNotification = @"JMRepresentationTypeDidChangeNotification";

@interface JMBaseCollectionViewController() <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
                                            UISearchBarDelegate, JMPopupViewDelegate, JMResourceCollectionViewCellDelegate,
                                            PopoverViewDelegate, JMMenuActionsViewDelegate, JMResourcesListLoaderDelegate>
@property (nonatomic, strong) PopoverView *popoverView;
@property (nonatomic, assign) BOOL isScrollToTop;
@end

@implementation JMBaseCollectionViewController
@synthesize representationType = _representationType;


#pragma mark - LifeCycle
-(void)awakeFromNib {
    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    baseCollectionView.contentView.translatesAutoresizingMaskIntoConstraints = NO;

    id topGuide = self.topLayoutGuide;
    [baseCollectionView addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:|-0-[contentView]-0-|"
                                options:NSLayoutFormatAlignAllLeading
                                metrics:nil
                                  views:@{@"contentView": baseCollectionView.contentView}]];
    [baseCollectionView addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[topGuide]-0-[contentView]-0-|"
                                options:0
                                metrics:nil
                                  views:@{@"contentView": baseCollectionView.contentView, @"topGuide" : topGuide}]];
}

- (void)dealloc
{
    [self removeObservers];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    [baseCollectionView setupWithNoResultText:[self noResultText]];
    baseCollectionView.collectionView.delegate = self;
    baseCollectionView.collectionView.dataSource = self;

    [baseCollectionView.refreshControl addTarget:self
                                          action:@selector(refershControlAction:)
                                forControlEvents:UIControlEventValueChanged];

    baseCollectionView.searchBar.delegate = self;

    [self addObservers];

    self.shouldShowButtonForChangingViewPresentation = YES;
    self.shouldShowRightNavigationItems = YES;
    self.isScrollToTop = NO;

    [self makeSearchBarVisible:[self needShowSearchBar]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.screenName = NSStringFromClass(self.class);
    [self addKeyboardObservers];

    self.needLayoutUI = YES;

    if (self.needReloadData) {
        [self updateStrong];
    }
    [self.resourceListLoader updateIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self removeKeyboardObservers];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self isMenuShown]) {
        [self closeMenu];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.needReloadData = YES;
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self showNavigationItemsForTraitCollection:newCollection];
}

#pragma mark - Setup
- (BOOL)needShowSearchBar
{
    return YES;
}

- (void)makeSearchBarVisible:(BOOL)visible
{
    JMBaseCollectionView *baseCollectionView = [self collectionView];
    baseCollectionView.searchBarPlaceholderTopConstraint.constant = visible ? 0 : (- CGRectGetHeight(baseCollectionView.searchBarPlaceholder.frame));
}

- (JMBaseCollectionView *)collectionView
{
    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    return baseCollectionView;
}

#pragma mark - Custom accessors
- (void)setNeedReloadData:(BOOL)needReloadData
{
    _needReloadData = needReloadData;
    [self updateIfNeeded];
}

- (void)setNeedLayoutUI:(BOOL)needLayoutUI
{
    _needLayoutUI = needLayoutUI;
    _needReloadData = needLayoutUI;
    
    [self updateIfNeeded];
}

- (JMResourcesRepresentationType)representationType
{
    if (![[NSUserDefaults standardUserDefaults] objectForKey:[self representationTypeKey]]) {
        _representationType = JMResourcesRepresentationTypeFirst();
    } else {
        _representationType = [[NSUserDefaults standardUserDefaults] integerForKey:[self representationTypeKey]];
    }
    return _representationType;
}

- (void)setRepresentationType:(JMResourcesRepresentationType)representationType
{
    if (_representationType != representationType) {
        _representationType = representationType;
        [[NSUserDefaults standardUserDefaults] setInteger:representationType forKey:[self representationTypeKey]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:kJMRepresentationTypeDidChangeNotification object:nil];
    }
}

- (NSString *)representationTypeKey
{
    if (!_representationTypeKey) {
        _representationTypeKey = [self defaultRepresentationTypeKey];
    }
    return _representationTypeKey;
}

- (JMResourcesListLoader *)resourceListLoader
{
    if (!_resourceListLoader) {
        _resourceListLoader = [[self resourceLoaderClass] new];
        _resourceListLoader.delegate = self;
        _resourceListLoader.filterBySelectedIndex = [self defaultFilterByIndex];
        _resourceListLoader.sortBySelectedIndex = [self defaultSortByIndex];
    }
    return _resourceListLoader;
}

- (NSInteger)defaultFilterByIndex
{
    // Could be overriden in children
    return 0;
}

- (NSInteger)defaultSortByIndex
{
    // Could be overriden in children
    return 0;
}

#pragma mark - Actions
- (void)sortByButtonTapped:(id)sender
{
    JMListOptionsPopupView *sortPopup = [[JMListOptionsPopupView alloc] initWithDelegate:self
                                                                                    type:JMPopupViewType_ContentViewOnly
                                                                                 options:[self.resourceListLoader listItemsWithOption:JMResourcesListLoaderOptionType_Sort]];
    sortPopup.titleString = JMCustomLocalizedString(@"resources_sortby_title", nil);
    sortPopup.selectedIndex = self.resourceListLoader.sortBySelectedIndex;
    sortPopup.optionType = JMResourcesListLoaderOptionType_Sort;
    [sortPopup show];
}

- (void)filterByButtonTapped:(id)sender
{
    JMListOptionsPopupView *filterPopup = [[JMListOptionsPopupView alloc] initWithDelegate:self
                                                                                      type:JMPopupViewType_ContentViewOnly
                                                                                   options:[self.resourceListLoader listItemsWithOption:JMResourcesListLoaderOptionType_Filter]];
    filterPopup.titleString = JMCustomLocalizedString(@"resources_filterby_title", nil);
    filterPopup.selectedIndex = self.resourceListLoader.filterBySelectedIndex;
    filterPopup.optionType = JMResourcesListLoaderOptionType_Filter;
    [filterPopup show];
}

- (void)refershControlAction:(id)sender
{
    [self.resourceListLoader setNeedsUpdate];
    [self.resourceListLoader updateIfNeeded];
}

- (void)actionButtonClicked:(id) sender
{
    JMMenuActionsView *actionsView = [JMMenuActionsView new];
    actionsView.delegate = self;
    actionsView.availableActions = [self availableAction];
    CGPoint point = CGPointMake(CGRectGetWidth(self.view.frame), -10);
    
    self.popoverView = [PopoverView showPopoverAtPoint:point
                                                inView:self.view
                                             withTitle:nil
                                       withContentView:actionsView
                                              delegate:self];
}

- (void)representationTypeButtonTapped:(id)sender
{
    self.representationType = [self nextRepresentationTypeForType:self.representationType];
    [self replaceRightNavigationItem:sender withItem:[self resourceRepresentationItem]];
}

#pragma mark - Private API
- (void)updateIfNeeded
{
    if ([self isVisible]) {
        [self updateStrong];
    }
}

- (void) updateStrong
{
    if (self.needReloadData) {
        JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
        [baseCollectionView.collectionView reloadData];
        
        if (self.isScrollToTop) {
            self.isScrollToTop = NO;
            NSIndexPath *firstItemIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            if ([baseCollectionView.collectionView cellForItemAtIndexPath:firstItemIndexPath]) {
                [baseCollectionView.collectionView scrollToItemAtIndexPath:firstItemIndexPath
                                                          atScrollPosition:UICollectionViewScrollPositionBottom
                                                                  animated:NO];
            }
        }
        
        _needReloadData = NO;
    }
    
    if (self.needLayoutUI) {
        [self.popoverView dismiss:YES];
        [self showNavigationItemsForTraitCollection:self.traitCollection];
        _needLayoutUI = NO;
    }
}

- (Class)resourceLoaderClass
{
    return [JMResourcesListLoader class];
}

#pragma mark - Overloaded methods
- (JMMenuActionsViewAction)availableAction
{
    JMMenuActionsViewAction availableAction = JMMenuActionsViewAction_Sort;
    NSArray *filterItems = [self.resourceListLoader listItemsWithOption:JMResourcesListLoaderOptionType_Filter];
    if ([filterItems count] > 1) {
        availableAction |= JMMenuActionsViewAction_Filter;
    }
    return  availableAction;
}

- (NSString *)defaultRepresentationTypeKey
{
    return @"RepresentationTypeKey";
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    return [self.resourceListLoader resourceCount];
}

- (JMResource *)loadedResourceForIndexPath:(NSIndexPath *)indexPath
{
    return [self.resourceListLoader resourceAtIndex:indexPath.row];
}

- (NSString *)noResultText
{
    NSString *noResultText = JMCustomLocalizedString(@"resources_noresults_msg", nil);
    return noResultText;
}

#pragma mark - Observers
- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(representationTypeDidChange)
                                                 name:kJMRepresentationTypeDidChangeNotification
                                               object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)representationTypeDidChange
{
    self.needReloadData = YES;
}

#pragma mark - Keyboard Observers
- (void)addKeyboardObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];

}

- (void)removeKeyboardObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
}

- (void)keyboardDidHide
{
    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    if (!baseCollectionView.searchBar.text.length) {
        [self.resourceListLoader clearSearchResults];
    }
}

#pragma mark - Setup Navigation Items
- (void) showNavigationItemsForTraitCollection:(UITraitCollection *)traitCollection
{
    if (traitCollection) {
        if (self.shouldShowRightNavigationItems) {
            NSMutableArray *navBarItems = [NSMutableArray array];
            JMMenuActionsViewAction availableAction = [self availableAction];
            if (availableAction & JMMenuActionsViewAction_Filter) {
                UIBarButtonItem *filterItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"filter_action"]
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(filterByButtonTapped:)];
                [navBarItems addObject:filterItem];
            }
            if (availableAction & JMMenuActionsViewAction_Sort) {
                UIBarButtonItem *sortItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"sort_action"]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(sortByButtonTapped:)];
                [navBarItems addObject:sortItem];
            }

            UIUserInterfaceSizeClass horizontalSizeClass = traitCollection.horizontalSizeClass;
            if (horizontalSizeClass == UIUserInterfaceSizeClassUnspecified && [JMUtils isIphone] && UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                horizontalSizeClass = UIUserInterfaceSizeClassCompact;
            }

            BOOL shouldConcateItems = (navBarItems.count > 1) && (horizontalSizeClass == UIUserInterfaceSizeClassCompact) &&
                                                                 (traitCollection.verticalSizeClass != UIUserInterfaceSizeClassCompact);

            if (shouldConcateItems) {
                navBarItems = [@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(actionButtonClicked:)]] mutableCopy];
            }
            if (self.shouldShowButtonForChangingViewPresentation) {
                [navBarItems addObject:[self resourceRepresentationItem]];
            }
            self.navigationItem.rightBarButtonItems = navBarItems;
        }
    } else {
        self.needLayoutUI = YES;
    }
}

#pragma mark - Menu Utils
- (BOOL)isMenuShown
{
    return (self.revealViewController.frontViewPosition == FrontViewPositionRight);
}

- (void)closeMenu
{
    [self.revealViewController setFrontViewPosition:FrontViewPositionLeft];
}

#pragma mark - Utils

- (UIBarButtonItem *)resourceRepresentationItem
{
    NSString *imageName = ([self nextRepresentationTypeForType:self.representationType] == JMResourcesRepresentationType_Grid) ? @"grid_button" : @"horizontal_list_button";
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(representationTypeButtonTapped:)];
}

- (JMResourcesRepresentationType)nextRepresentationTypeForType:(JMResourcesRepresentationType)currentType
{
    // last type - grid
    // first type - list
    JMResourcesRepresentationType nextType = (currentType == JMResourcesRepresentationTypeLast()) ? JMResourcesRepresentationTypeFirst() : currentType + 1;
    return nextType;
}

- (void)didSelectResourceAtIndexPath:(NSIndexPath *)indexPath
{
    JMResource *resource = [self loadedResourceForIndexPath:indexPath];
    __block id nextVC = nil;

    if (resource.type == JMResourceTypeFolder) {
        // TODO: replace identifier with constant
        JMRepositoryCollectionViewController *repositoryViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"JMRepositoryCollectionViewController"];
        repositoryViewController.resourceListLoader.resource = resource;
        repositoryViewController.navigationItem.leftBarButtonItem = nil;
        repositoryViewController.navigationItem.title = resource.resourceLookup.label;
        repositoryViewController.representationTypeKey = self.representationTypeKey;
        repositoryViewController.representationType = self.representationType;
        nextVC = repositoryViewController;
    } else if (resource.type == JMResourceTypeSchedule) {
        [self actionForResource:resource];
        return;
    } else if (resource.type == JMResourceTypeTempExportedReport) {
        // TODO: add canceling task
//        [[JMExportManager sharedInstance] cancelAll];
//        JMResourceCollectionViewCell *cell = (JMResourceCollectionViewCell *) [((JMBaseCollectionView *) self.view).collectionView cellForItemAtIndexPath:indexPath];
//        JMSavedResources *savedReport = [JMSavedResources savedResourceFromResourceLookup:cell.resourceLookup];
//        [[JMExportManager sharedInstance] cancelTaskForSavedResource:savedReport];
    } else {
        void (^configureNextVCBlock)(void) = ^{
            NSString *resourceViewerVCIdentifier = [resource resourceViewerVCIdentifier];
            if (resourceViewerVCIdentifier) {
                nextVC = [self.storyboard instantiateViewControllerWithIdentifier:resourceViewerVCIdentifier];
                if ([nextVC respondsToSelector:@selector(setResource:)]) {
                    [nextVC setResource:resource];
                }
                // Customizing report viewer view controller
                if (resource.type == JMResourceTypeReport) {
                    JMResourceCollectionViewCell *cell = (JMResourceCollectionViewCell *) [((JMBaseCollectionView *)self.view).collectionView cellForItemAtIndexPath:indexPath];
                    JMReport *report = (JMReport *)[nextVC report];
                    report.thumbnailImage = cell.thumbnailImage;
                }
            }
        };
        
        if (resource.type == JMResourceTypeLegacyDashboard || (resource.type == JMResourceTypeDashboard && ![JMUtils isServerVersionUpOrEqual6])) {
            [JMUtils showNetworkActivityIndicator];
            [JMCancelRequestPopup presentWithMessage:@"status_loading"
                                         cancelBlock:nil];
            [self.restClient verifyIsSessionAuthorizedWithCompletion:^(JSOperationResult *_Nullable result) {
                [JMCancelRequestPopup dismiss];
                [JMUtils hideNetworkActivityIndicator];
                
                if (!result.error) {
                    [[JMWebViewManager sharedInstance] reset];
                    configureNextVCBlock();
                    if (nextVC) {
                        [self.navigationController pushViewController:nextVC animated:YES];
                    }
                } else {
                    [JMUtils showLoginViewAnimated:YES completion:nil];
                }
            }];
            
        } else {
            configureNextVCBlock();
        }
    }

    if (nextVC) {
        [self.navigationController pushViewController:nextVC animated:YES];
    }
}

- (void)actionForResource:(JMResource *)resource
{
    // override in children
}

- (void) replaceRightNavigationItem:(UIBarButtonItem *)oldItem withItem:(UIBarButtonItem *)newItem
{
    NSMutableArray *rightItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    NSInteger index = [rightItems indexOfObject:oldItem];
    rightItems[index] = newItem;
    self.navigationItem.rightBarButtonItems = rightItems;
}

- (void)showResourceInfoViewControllerWithResourceLookup:(JMResource *)resource
{
    JMResourceInfoViewController *vc = (JMResourceInfoViewController *) [NSClassFromString([resource infoVCIdentifier]) new];
    vc.resource = resource;
    __weak __typeof(self) weakSelf = self;
    vc.exitBlock = ^(){
        __typeof(self) strongSelf = weakSelf;
        [strongSelf.resourceListLoader setNeedsUpdate];
        [strongSelf.resourceListLoader updateIfNeeded];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (UIDocumentInteractionController *) setupDocumentControllerWithURL: (NSURL *) fileURL
                                                       usingDelegate: (id <UIDocumentInteractionControllerDelegate>) interactionDelegate {
    UIDocumentInteractionController *interactionController = [UIDocumentInteractionController interactionControllerWithURL: fileURL];
    interactionController.delegate = interactionDelegate;
    return interactionController;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = [self numberOfItemsInSection:section];
    if ([self.resourceListLoader hasNextPage]) count++;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    if (indexPath.item == [self.resourceListLoader resourceCount]) {
        [self.resourceListLoader loadNextPage];
        return [collectionView dequeueReusableCellWithReuseIdentifier:[baseCollectionView loadingCellForRepresentationType:self.representationType] forIndexPath:indexPath];
    }
    
    JMResourceCollectionViewCell *cell = (JMResourceCollectionViewCell *) [collectionView dequeueReusableCellWithReuseIdentifier:[baseCollectionView resourceCellForRepresentationType:self.representationType]
                                                                                                                    forIndexPath:indexPath];
    cell.resource = [self loadedResourceForIndexPath:indexPath];
    cell.delegate = self;
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isMenuShown]) {
        [self closeMenu];
    }
    if (self.actionBlock) {
        JMResource *resource = [self loadedResourceForIndexPath:indexPath];
        self.actionBlock(resource);
    } else {
        [self didSelectResourceAtIndexPath:indexPath];
    }
}


#pragma mark - UICollectionViewFlowLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewFlowLayout *flowLayout = (id)collectionView.collectionViewLayout;
    
    CGFloat itemHeight = 80.f;
    CGFloat itemWidth = collectionView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right;
    
    if (self.representationType == JMResourcesRepresentationType_Grid) {
        NSInteger countOfCellsInRow = 0;
        CGFloat minItemWidth = [JMUtils isIphone] ? kJMBaseCollectionViewCompactGridWidth : kJMBaseCollectionViewGridWidth;
        itemWidth = minItemWidth;
        while (((countOfCellsInRow + 1) * itemWidth + countOfCellsInRow * flowLayout.minimumInteritemSpacing) <= (collectionView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right)) {
            countOfCellsInRow ++;
        }
        
        CGFloat (^getItemWidth)(NSInteger) = ^CGFloat (NSInteger countOfCellsInRow){
            return floorf((collectionView.frame.size.width - flowLayout.sectionInset.left * (countOfCellsInRow + 1)) / countOfCellsInRow);
        };

        itemWidth = getItemWidth(countOfCellsInRow);
        if (itemWidth >= 1.5 * minItemWidth) {
            itemWidth = getItemWidth(++countOfCellsInRow);
        }
        
        itemHeight = [JMUtils isIphone] ? itemWidth : ceil(0.8*itemWidth);
    }
    
    return CGSizeMake(itemWidth, itemHeight);
}

#pragma mark - JMResourceCollectionViewCellDelegate
- (void)infoButtonDidTappedOnCell:(JMResourceCollectionViewCell *)cell
{
    if ([self isMenuShown]) {
        [self closeMenu];
    }
    [self showResourceInfoViewControllerWithResourceLookup:cell.resource];
}


#pragma mark - JMMenuActionsViewDelegate
- (void)actionsView:(JMMenuActionsView *)view didSelectAction:(JMMenuActionsViewAction)action
{
    switch (action) {
        case JMMenuActionsViewAction_Filter:
            [self filterByButtonTapped:nil];
            break;
        case JMMenuActionsViewAction_Sort:
            [self sortByButtonTapped:nil];
            break;
        default:
            break;
    }
    [self.popoverView performSelector:@selector(dismiss) withObject:nil afterDelay:0.2f];
}

#pragma mark - UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self.resourceListLoader searchWithQuery:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    searchBar.text = nil;
    [self.resourceListLoader clearSearchResults];
}

#pragma mark - JMPopupDelegate
- (void)popupViewWillShow:(JMPopupView *)popup
{
    [self.view endEditing:YES];
}

- (void)popupViewValueDidChanged:(JMListOptionsPopupView *)popup
{
    switch (popup.optionType) {
        case JMResourcesListLoaderOptionType_Filter: {
            NSUInteger selectedIndex = [popup selectedIndex];
            if (selectedIndex != self.resourceListLoader.filterBySelectedIndex) {
                self.resourceListLoader.filterBySelectedIndex = selectedIndex;
                self.isScrollToTop = YES;
            }
            break;
        }
        case JMResourcesListLoaderOptionType_Sort: {
            NSUInteger selectedIndex = [popup selectedIndex];
            if (selectedIndex != self.resourceListLoader.sortBySelectedIndex) {
                self.resourceListLoader.sortBySelectedIndex = selectedIndex;
                self.isScrollToTop = YES;
            }
            break;
        }
    }
}

#pragma mark - PopoverViewDelegate Methods
- (void)popoverViewDidDismiss:(PopoverView *)popoverView
{
    self.popoverView = nil;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGPoint point = CGPointMake(self.view.frame.size.width, -10);
    [self.popoverView animateRotationToNewPoint:point
                                         inView:self.view
                                   withDuration:duration];
}

#pragma mark - JMResourcesListLoaderDelegate
- (void)resourceListLoaderDidStartLoad:(JMResourcesListLoader *)listLoader
{
    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    [baseCollectionView showLoadingView];
}

- (void)resourceListLoaderDidEndLoad:(JMResourcesListLoader *)listLoader withResources:(NSArray *)resources
{
    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    [baseCollectionView hideLoadingView];
    self.needReloadData = YES;
}

- (void)resourceListLoaderDidFailed:(JMResourcesListLoader *)listLoader withError:(NSError *)error
{
    JMBaseCollectionView *baseCollectionView = (JMBaseCollectionView *)self.view;
    [baseCollectionView hideLoadingView];
    
    [JMUtils presentAlertControllerWithError:error completion:nil];
}

@end
