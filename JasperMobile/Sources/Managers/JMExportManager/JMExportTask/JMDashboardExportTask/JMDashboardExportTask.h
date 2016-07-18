//
//  JMDashboardExportTask.h
//  TIBCO JasperMobile
//
//  Created by Alexey Gubarev on 7/13/16.
//  Copyright © 2016 TIBCO JasperMobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMExportTask.h"
#import "JSDashboard.h"

@interface JMDashboardExportTask : JMExportTask
@property (nonatomic, strong, readonly) JSDashboard *dashboard;

- (instancetype)initWithDashboard:(JSDashboard *)dashboard name:(NSString *)name format:(NSString *)format;

@end
