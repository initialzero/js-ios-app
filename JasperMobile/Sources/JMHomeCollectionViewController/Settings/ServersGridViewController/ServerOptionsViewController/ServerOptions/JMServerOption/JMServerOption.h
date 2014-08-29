//
//  JMServerOption.h
//  JasperMobile
//
//  Created by Oleksii Gubariev on 7/24/14.
//  Copyright (c) 2014 JasperMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMServerOption : NSObject

@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, strong) NSString *errorString;
@property (nonatomic, strong) id        optionValue;
@property (nonatomic, strong) NSString *cellIdentifier;
@property (nonatomic, assign) BOOL      editable;       // By default YES

@end
