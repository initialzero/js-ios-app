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
//  ServerSettingsViewController.m
//  Jaspersoft Corporation
//

#import "ServerSettingsViewController.h"
#import "ServersViewController.h"
#import "JasperMobileAppDelegate.h"
#import "UIAlertView+LocalizedAlert.h"
#import "JSLocalization.h"

@implementation ServerSettingsViewController

@synthesize aliasCell;
@synthesize organizationCell;
@synthesize urlCell;
@synthesize usernameCell;
@synthesize passwordCell;
@synthesize currentServerProfile;
@synthesize previousViewController;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	// Add our custom add button as the nav bar's custom right view
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:JSCustomLocalizedString(@"dialog.button.save", nil)
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(saveAction:)];
	self.navigationItem.rightBarButtonItem = addButton;
	keybordIsActive = NO;
}


- (IBAction)saveAction:(id)sender {
	BOOL isNew = NO;
    JasperMobileAppDelegate *app = [JasperMobileAppDelegate sharedInstance];
    
    if (aliasTextField.text == nil || [aliasTextField.text isEqualToString:@""]) {
        [[UIAlertView localizedAlert:@"" message:@"servers.name.errmsg.empty" delegate:nil cancelButtonTitle:@"dialog.button.ok" otherButtonTitles:nil] show];        
        return;
    }
    
    for (ServerProfile *serverProfile in app.servers) {
        if (![serverProfile isEqual:currentServerProfile] && [serverProfile.alias isEqualToString:aliasTextField.text]) {
            [[UIAlertView localizedAlert:@"" message:@"servers.name.errmsg.exists" delegate:nil cancelButtonTitle:@"dialog.button.ok" otherButtonTitles:nil] show];        
            return;
        }
    }
    
    NSURL *url = [NSURL URLWithString:urlTextField.text];    
    if (!url || !url.scheme || !url.host) {
        [[UIAlertView localizedAlert:@"" message:@"servers.url.errmsg" delegate:nil cancelButtonTitle:@"dialog.button.ok" otherButtonTitles:nil] show];
        return;
    }
    
    if (usernameTextField.text == nil || [usernameTextField.text isEqualToString:@""]) {
        [[UIAlertView localizedAlert:@"" message:@"servers.username.errmsg.empty" delegate:nil cancelButtonTitle:@"dialog.button.ok" otherButtonTitles:nil] show];
        return;
    }
    
    for (ServerProfile *serverProfile in app.servers) {
        if (currentServerProfile && [serverProfile isEqual:currentServerProfile]) {
            continue;
        } else if ([serverProfile isEqualToProfileByServerURL:urlTextField.text username:usernameTextField.text 
                                          organization:organizationTextField.text]) {
            [[UIAlertView localizedAlert:@"" message:@"servers.profile.exists" delegate:nil 
                       cancelButtonTitle:@"dialog.button.ok" otherButtonTitles:nil] show];
            return;
        }
    }
    
    // Create the new server
	if (currentServerProfile == nil) {
		isNew = YES;
        currentServerProfile = [NSEntityDescription insertNewObjectForEntityForName:@"ServerProfile" inManagedObjectContext:[app managedObjectContext]];
	}

    currentServerProfile.alias = aliasTextField.text;
    currentServerProfile.serverUrl = urlTextField.text;
    currentServerProfile.organization = organizationTextField.text;
    currentServerProfile.username = usernameTextField.text;
    currentServerProfile.password = passwordTextField.text;
    currentServerProfile.askPassword = [NSNumber numberWithBool:askPasswordSwitch.on];
    [[app managedObjectContext] save:nil];
    [ServerProfile storePasswordInKeychain:currentServerProfile.password profileID:[currentServerProfile profileID]];
	
	[self.navigationController popViewControllerAnimated:YES];
	
	if (previousViewController != nil && [previousViewController isKindOfClass: [ServersViewController class]]) {
		
		if (!isNew) {
			[(ServersViewController *)previousViewController updateServer:currentServerProfile];
		} else {
			[(ServersViewController *)previousViewController addServer:currentServerProfile];
		}
	}
}

// Create a textfield for a specific cell...
- (UITextField *)newTextFieldForCell:(UITableViewCell *)cell {
    CGSize labelSize = [cell.textLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:17]];
    labelSize.width = ceil(labelSize.width/5) * 5;
    CGRect frame;

	frame = CGRectMake(labelSize.width + 30, 11, cell.frame.size.width - labelSize.width - 50, 28);	
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    textField.adjustsFontSizeToFitWidth = YES;
    textField.textColor = [UIColor blackColor];
    textField.backgroundColor = [UIColor clearColor];
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.textAlignment = UITextAlignmentLeft;
    textField.delegate = self;
    textField.clearButtonMode = UITextFieldViewModeNever;
    textField.enabled = YES;
    textField.returnKeyType = UIReturnKeyDone;
	
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    return textField;
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {    
	return JSCustomLocalizedString(@"servers.profile.details.title", nil);
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6; // section is 0?
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {   // User details...
        
		if (indexPath.row == 0) {
            self.aliasCell = [tableView dequeueReusableCellWithIdentifier:@"AliasCell"];
            
            if (self.aliasCell == nil) {
				self.aliasCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AliasCell"];
				self.aliasCell.textLabel.text = JSCustomLocalizedString(@"servers.name.label", nil);
				aliasTextField = [self newTextFieldForCell:self.aliasCell];
				aliasTextField.placeholder = JSCustomLocalizedString(@"servers.myserver.label", nil);
				aliasTextField.keyboardType = UIKeyboardTypeDefault;
				aliasTextField.returnKeyType = UIReturnKeyNext;
				if(currentServerProfile != nil && currentServerProfile.alias != nil) {
                    aliasTextField.text = currentServerProfile.alias;
                }
				[self.aliasCell addSubview:aliasTextField];
			}
			
			return self.aliasCell;
               
		} else if (indexPath.row == 1) {
			self.urlCell = [tableView dequeueReusableCellWithIdentifier:@"UrlCell"];
			if (self.urlCell == nil) {
				self.urlCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UrlCell"];
				self.urlCell.textLabel.text = JSCustomLocalizedString(@"servers.url.label", nil);
				urlTextField = [self newTextFieldForCell:self.urlCell];
				urlTextField.placeholder = JSCustomLocalizedString(@"servers.url.tip", nil);
				urlTextField.keyboardType = UIKeyboardTypeURL;
				urlTextField.returnKeyType = UIReturnKeyNext;
				if(currentServerProfile != nil && currentServerProfile.serverUrl != nil)
					urlTextField.text = currentServerProfile.serverUrl;
				[self.urlCell addSubview:urlTextField];
			}
			return self.urlCell;
               
		} else if (indexPath.row == 2) {
			self.organizationCell = [tableView dequeueReusableCellWithIdentifier:@"OrganizationCell"];
			if (self.organizationCell == nil) {
				self.organizationCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OrganizationCell"];
				self.organizationCell.textLabel.text = JSCustomLocalizedString(@"servers.orgid.label", nil);
				organizationTextField = [self newTextFieldForCell:self.organizationCell];
				organizationTextField.placeholder = JSCustomLocalizedString(@"servers.orgid.tip", nil);
				organizationTextField.keyboardType = UIKeyboardTypeDefault;
				organizationTextField.returnKeyType = UIReturnKeyNext;
				if(currentServerProfile != nil && currentServerProfile.organization != nil)
					organizationTextField.text = currentServerProfile.organization;
				[self.organizationCell addSubview:organizationTextField];
			}
			return self.organizationCell;
               
		} else if (indexPath.row == 3) {
			self.usernameCell = [tableView dequeueReusableCellWithIdentifier:@"UsernameCell"];
			if (self.usernameCell == nil) {
				self.usernameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"];
				self.usernameCell.textLabel.text = JSCustomLocalizedString(@"servers.username.label", nil);
				usernameTextField = [self newTextFieldForCell:self.usernameCell];
				usernameTextField.placeholder = JSCustomLocalizedString(@"servers.username.tip", nil);
				usernameTextField.keyboardType = UIKeyboardTypeDefault;
				usernameTextField.returnKeyType = UIReturnKeyNext;
				if(currentServerProfile != nil && currentServerProfile.username != nil)
					usernameTextField.text = currentServerProfile.username;
				[self.usernameCell addSubview:usernameTextField];
			}
			return self.usernameCell;
               
		} else if (indexPath.row == 4) {
			self.passwordCell = [tableView dequeueReusableCellWithIdentifier:@"PasswordCell"];
			if (self.passwordCell == nil) {
				self.passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"];
				self.passwordCell.textLabel.text = JSCustomLocalizedString(@"servers.password.label", nil);
				passwordTextField = [self newTextFieldForCell:self.passwordCell];
				passwordTextField.placeholder = JSCustomLocalizedString(@"servers.password.tip", nil);
				passwordTextField.keyboardType = UIKeyboardTypeDefault;
				passwordTextField.returnKeyType = UIReturnKeyDone;
				passwordTextField.secureTextEntry = YES;
				passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
				passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                
                ///~ @TODO finish this
                if (!currentServerProfile.askPassword.boolValue) {
                    passwordTextField.text = currentServerProfile.password;// ?: profile.tempPassword;
                } else {
                    passwordTextField.textColor = [UIColor lightGrayColor];
                    passwordTextField.enabled = NO;
                    self.passwordCell.textLabel.textColor = [UIColor lightGrayColor];
                }
                
				[self.passwordCell addSubview:passwordTextField];
			}
			return self.passwordCell;
               
		} else if (indexPath.row == 5) {
            UITableViewCell *askPasswordCell = [tableView dequeueReusableCellWithIdentifier:@"AskPasswordCell"];
			if (askPasswordCell == nil) {
                askPasswordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AskPasswordCell"];
                askPasswordCell.textLabel.text = JSCustomLocalizedString(@"servers.askpassword.label", nil);
                askPasswordCell.selectionStyle = UITableViewCellSelectionStyleNone;
                askPasswordCell.textLabel.font = [UIFont systemFontOfSize:15];
                
                NSInteger xSpace = 55;
                if ([UIDevice currentDevice].systemVersion.integerValue < 5) {
                    xSpace = 30;
                }
                
                CGSize labelSize = [askPasswordCell.textLabel.text sizeWithFont:askPasswordCell.textLabel.font];
                CGRect frame = CGRectMake(225, 8, askPasswordCell.frame.size.width - labelSize.width - 50, 28);
                askPasswordSwitch = [[UISwitch alloc] initWithFrame:frame];
                askPasswordSwitch.on = currentServerProfile.askPassword.boolValue;
                [askPasswordSwitch addTarget:self action:@selector(askPasswordSwitchToggled:) forControlEvents:UIControlEventTouchUpInside];
                
                [askPasswordCell addSubview:askPasswordSwitch];
            }
            
            return askPasswordCell;
        }
	}
	// We shouldn't reach this point, but return an empty cell just in case
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoCell"];
				    
}

- (void)askPasswordSwitchToggled:(id)sender {
    UITableViewCell *askPasswordCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    
    if ([sender isOn]) {
        passwordTextField.enabled = NO;
        passwordTextField.textColor = [UIColor lightGrayColor];
        [askPasswordCell textLabel].textColor = [UIColor lightGrayColor];
    } else {
        passwordTextField.enabled = YES;
        passwordTextField.textColor = [UIColor blackColor];
        [askPasswordCell textLabel].textColor = [UIColor blackColor];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField.returnKeyType == UIReturnKeyNext) {
        UITableViewCell *cell = (UITableViewCell *)[textField superview];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:indexPath.section];
        UITableViewCell *nextCell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        if (nextCell) {
            for (UIView *subview in [nextCell subviews]) {
                if ([subview isKindOfClass:[UITextField class]]) {
                    [subview becomeFirstResponder];
                    break;
                }
            }
        }
    }
	[textField resignFirstResponder];
	return NO;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

@end
