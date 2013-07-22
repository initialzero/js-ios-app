//
//  JMServersTableViewController.m
//  JasperMobile
//
//  Created by Vlad Zavadskii on 7/8/13.
//  Copyright (c) 2013 com.jaspersoft. All rights reserved.
//

#import "JMServersTableViewController.h"
#import "JMConstants.h"
#import "JMLocalization.h"
#import "UIAlertView+LocalizedAlert.h"
#import "JMServerProfile+Helpers.h"
#import <CoreData/CoreData.h>
#import <Objection-iOS/Objection.h>

@interface JMServersTableViewController ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) UIBarButtonItem *editButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) NSMutableArray *servers;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *infoButton;

- (NSIndexPath *)indexPathForTheNewServerCell;
@end

@implementation JMServersTableViewController
objection_requires(@"managedObjectContext");

#pragma mark - Initialization

- (void)awakeFromNib
{
    [[JSObjection defaultInjector] injectDependencies:self];
    
    self.infoButton.title = JMCustomLocalizedString(@"dialog.button.info", nil);
    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editServers:)];
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneEditing:)];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = JMCustomLocalizedString(@"view.servers", nil);
    self.navigationItem.rightBarButtonItem = self.editButton;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ServerProfile"];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"alias" ascending:YES]];
    self.servers = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] mutableCopy] ?: [NSMutableArray array];

    for (JMServerProfile *server in self.servers) {
        server.password = [JMServerProfile passwordFromKeychain:[server encodedProfileID]];
    }
}

- (void)viewDidUnload
{
    [self setInfoButton:nil];
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableView.isEditing ? self.servers.count + 1 : self.servers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *serverCellIdentifier = @"ServerCell";
    static NSString *newServerCellIdentifier = @"NewServerCell";
    
    UITableViewCell *cell;
    
    if (self.tableView.isEditing && indexPath.row == self.servers.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:newServerCellIdentifier];
        cell.textLabel.text = JMCustomLocalizedString(@"servers.new.account.title", nil);
    } else {
        JMServerProfile *server = [self.servers objectAtIndex:indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:serverCellIdentifier];
        cell.textLabel.text = server.alias;
        cell.detailTextLabel.text = server.serverUrl;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return JMCustomLocalizedString(@"servers.profile.title", nil);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing && indexPath.row == self.servers.count) {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        JMServerProfile *serverProfile = [self.servers objectAtIndex:indexPath.row];
        
        // TODO: Check if profile is not active
        // ... isProfileUsed etc ...
        
        [self.servers removeObjectAtIndex:indexPath.row];
//        [self.managedObjectContext deleteObject:serverProfile];
//        [self.managedObjectContext save:nil];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{   
    if (!self.tableView.isEditing) {
        NSUInteger serversCount = self.servers.count;
        
        // TODO: change logic of displaying help and tips
        if (serversCount == 0) {
            return JMCustomLocalizedString(@"servers.profile.configure.help", nil);
        } else if(serversCount == 1) {
            return  JMCustomLocalizedString(@"servers.profile.configure.tips", nil);
        }
    }
    
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing) {
        
        
    } else {
        JMServerProfile *serverProfile = [self.servers objectAtIndex:indexPath.row];
        if (serverProfile.askPassword.boolValue) {
            
        }
        
        if (serverProfile.askPassword.boolValue) {
            serverProfile.password = nil;
            // TODO: need implementation for ask password
        } else {
            NSDictionary *userInfo = @{
                kJMServerProfileKey : serverProfile
            };
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kJMChangeServerProfileNotification
                                                                object:nil
                                                              userInfo:userInfo];
        }
    }
}

#pragma mark - Action

- (IBAction)editServers:(id)sender
{
    self.navigationItem.rightBarButtonItem = self.doneButton;
    // TODO: need implementation
    
    if (!self.servers.count) {
        // TODO: Redirect to Add New Server directly
        
    } else {
        [self.tableView setEditing:YES animated:YES];
        
        // Add "New server account" table view cell
        NSIndexPath *indexPath = [self indexPathForTheNewServerCell];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (IBAction)doneEditing:(id)sender
{
    self.navigationItem.rightBarButtonItem = self.editButton;
    // TODO: need implementation
    
    [self.tableView setEditing:NO animated:YES];
    
    NSIndexPath *indexPath = [self indexPathForTheNewServerCell];   
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (IBAction)applicationInfo:(id)sender
{
    NSString *message = JMCustomLocalizedString(@"servers.info", nil);
    // TODO: replace with normal version from app updater
    message = [NSString stringWithFormat:message, @1.6];
    [[UIAlertView localizedAlertWithTitle:nil
                         message:message
                        delegate:nil
               cancelButtonTitle:@"dialog.button.ok"
               otherButtonTitles:nil] show];
}

#pragma mark - Private

- (NSIndexPath *)indexPathForTheNewServerCell
{
    return [NSIndexPath indexPathForRow:self.servers.count inSection:0];
}

@end
