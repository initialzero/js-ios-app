//
//  JMMenuTableViewCell.m
//  JasperMobile
//
//  Created by Vlad Zavadskii on 5/8/14.
//  Copyright (c) 2014 com.jaspersoft. All rights reserved.
//

#import "JMLibraryTableViewCell.h"
#import "JMConstants.h"

@implementation JMLibraryTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if (selected) {
        [self.img setImage:[UIImage imageNamed:@"circle_selected.png"]];
    } else {
        [self.img setImage:[UIImage imageNamed:@"circle.png"]];
    }
}

@end
