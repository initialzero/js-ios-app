//
//  JMResourcesCollectionViewController.h
//  JasperMobile
//
//  Created by Vlad Zavadskii on 6/16/14.
//  Copyright (c) 2014 com.jaspersoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMResourceClientHolder.h"
#import "JMPagination.h"

@interface JMResourcesCollectionViewController : UIViewController <JMResourceClientHolder, JMPagination>

@end
