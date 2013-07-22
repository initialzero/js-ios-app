//
//  JMResourceClientHolder.h
//  JasperMobile
//
//  Created by Vlad Zavadskii on 6/7/13.
//  Copyright (c) 2013 com.jaspersoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <jaspersoft-sdk/JSRESTResource.h>
#import <jaspersoft-sdk/JSResourceDescriptor.h>

/**
 This protocol aggregates all the information implementing object should know about 
 to work with JasperServer Repository Service
 */
@protocol JMResourceClientHolder <NSObject>

@required
@property (nonatomic, strong) JSRESTResource *resourceClient;

@optional
@property (nonatomic, strong) JSResourceDescriptor *resourceDescriptor;

@end
