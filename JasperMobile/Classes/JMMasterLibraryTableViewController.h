//
//  JMMasterLibraryTableViewController.h
//  JasperMobile
//
//  Created by Vlad Zavadsky on 3/18/14.
//  Copyright (c) 2014 com.jaspersoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMResourceClientHolder.h"

// TODO: make universal view controller
@interface JMMasterLibraryTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, JMResourceClientHolder>

@property (nonatomic, weak) JSConstants *constants;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
