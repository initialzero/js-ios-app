/*
 * JasperMobile for iOS
 * Copyright (C) 2005 - 2012 Jaspersoft Corporation. All rights reserved.
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
//  JSUIRepositoryViewController.m
//  Jaspersoft Corporation
//

#import "JSUIResourceViewController.h"
#import "JSUIBaseRepositoryViewController.h"
#import "JSUILoadingView.h"
#import "JasperMobileAppDelegate.h"
#import "UIAlertView+LocalizedAlert.h"

@implementation JSUIBaseRepositoryViewController

@synthesize descriptor;
@synthesize resourceClient;
@synthesize resources;

#pragma mark -
#pragma mark View lifecycle

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

+ (void)displayErrorMessage:(JSOperationResult *)result {
    NSString *errorMsg = nil;
    NSString *errorTitle = nil;
    
    if (result.error.code == -1003 && result.statusCode == 0) {
        errorMsg = @"error.unknownhost.dialog.msg";
        errorTitle = @"error.unknownhost.dialog.title";
    } if ((result.error.code == -1012 && result.statusCode == 0) || result.statusCode == 401) {
        errorMsg = @"error.authenication.dialog.msg";
        errorTitle = @"error.authenication.dialog.title";
    } else {
        errorTitle = @"error.general.dialog.msg";
        if (result.statusCode != 0) {
            errorMsg = [NSString stringWithFormat:@"%@.%d", @"error.http", result.statusCode];
        } else {
            errorMsg = [[result error] localizedDescription];
        }
    }

    [[UIAlertView localizedAlert:errorTitle
                         message:errorMsg
                        delegate:nil
               cancelButtonTitle:@"dialog.button.ok"
               otherButtonTitles:nil] show];
}

- (id)init {
    self = [super init];
    resources = nil;
    descriptor = nil;
    resourceClient = nil;
    
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];	
}

- (void)requestFinished:(JSOperationResult *)result {  
	if (result.error != nil) {
        [[self class] displayErrorMessage:result];
    } else {
		resources = [[NSMutableArray alloc] initWithCapacity:0];
        for (JSResourceDescriptor *resourceDescriptor in result.objects) {
            [self.resources addObject:resourceDescriptor];
        }
	}
	
	// Update the table
	[[self tableView] beginUpdates];
	[[self tableView] reloadSections: [NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
	[[self tableView] endUpdates];
	[JSUILoadingView hideLoadingView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    if (!self.descriptor) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@", [self.resourceClient.serverProfile alias]];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[JasperMobileAppDelegate sharedInstance].tabBarController setSelectedIndex:4];
}

- (void)clear {
    if (resources != nil) {
        resources = nil;
        [[self tableView] reloadData];
    }
	descriptor = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![JSRESTBase isNetworkReachable]) {
        [[UIAlertView localizedAlert:@"error.noconnection.dialog.title" 
                             message:@"error.noconnection.dialog.msg" 
                            delegate:self 
                   cancelButtonTitle:@"dialog.button.ok"
                   otherButtonTitles:nil] show];
        return;
    } else {
        [self performSelector:@selector(updateTableContent) withObject:nil afterDelay:0.0];
	}
}

- (void)refreshContent {
    if (resources != nil) {
        resources = nil;
    }
    
    [self updateTableContent];
}

- (void)updateTableContent {
    if ([JSRESTBase isNetworkReachable] && self.resources == nil) {
		NSString *uri = @"/";
		if (self.descriptor != nil) {
			uri =  [self.descriptor uriString];
			self.navigationItem.title = [NSString stringWithFormat:@"%@", [descriptor label]];
		}
		// load this view
        [JSUILoadingView showCancelableLoadingInView:self.view restClient:self.resourceClient delegate:self cancelBlock:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
        
        [self.resourceClient resources:uri delegate:self];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return (CGFloat)0.f;
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {	
	if (self.resources != nil) {
		return [self.resources count];
	}
	
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JSResourceDescriptor *rd = (JSResourceDescriptor *)[resources objectAtIndex: [indexPath indexAtPosition:1]];
    
    UITableViewCell *cell;
    NSString *imageNameAndCellIdentifier = nil;
    
    JSConstants *constants = [JSConstants sharedInstance];
    
    if ([rd.wsType isEqualToString: constants.WS_TYPE_FOLDER]) {
        imageNameAndCellIdentifier = @"ic_type_folder.png";
    } else if ([rd.wsType isEqualToString: constants.WS_TYPE_FOLDER]) {
        imageNameAndCellIdentifier = @"ic_type_image.png";
    } else if ([rd.wsType isEqualToString: constants.WS_TYPE_REPORT_UNIT]) {
        imageNameAndCellIdentifier = @"ic_type_report.png";
    } else if ([rd.wsType isEqualToString: constants.WS_TYPE_DASHBOARD]) {
        imageNameAndCellIdentifier = @"ic_type_dashboard.png";
    } else if([rd.wsType isEqualToString: constants.WS_TYPE_CSS] || 
              [rd.wsType isEqualToString: constants.WS_TYPE_XML]) {
        imageNameAndCellIdentifier = @"ic_type_text.png";
    } else {
        imageNameAndCellIdentifier = @"ic_type_unknown.png";
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:imageNameAndCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:imageNameAndCellIdentifier];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.image = [UIImage imageNamed:imageNameAndCellIdentifier];
        cell.textLabel.textColor = [UIColor colorWithRed:46.0/255.0 green:109.0/255.0 blue:159.0/255.0  alpha:1];
        cell.detailTextLabel.textColor = [UIColor orangeColor];
    }
    
	// Configure the cell.    
    cell.textLabel.text = rd.label;
	cell.detailTextLabel.text = rd.uriString;
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.userInteractionEnabled = true;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.descriptor = [resources objectAtIndex: [indexPath indexAtPosition:1]];
    if (self.descriptor)
	{
		JSUIResourceViewController *rvc = [[JSUIResourceViewController alloc] initWithStyle:UITableViewStyleGrouped];
        rvc.resourceClient = self.resourceClient;
        rvc.descriptor = self.descriptor;
		[self.navigationController pushViewController: rvc animated: YES];
	}
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

@end
