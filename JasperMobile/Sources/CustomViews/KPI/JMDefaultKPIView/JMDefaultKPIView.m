/*
 * TIBCO JasperMobile for iOS
 * Copyright © 2005-2014 TIBCO Software, Inc. All rights reserved.
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
//  JMDefaultKPIView.m
//  TIBCO JasperMobile
//

#import "JMDefaultKPIView.h"
#import "JMBaseKPIModel.h"

@implementation JMDefaultKPIView

#pragma mark - Public API
- (void)setupViewWithKPIModel:(JMBaseKPIModel *)kpiModel
{
    self.backgroundColor = [UIColor colorWithRed:24/255.0f green:27/255.0f blue:31/255.0f alpha:1.0];

    [self setupIndicatorTextWithModel:kpiModel];
    [self setupGraphWithModel:kpiModel];
}

#pragma mark - Private API
- (void)setupIndicatorTextWithModel:(JMBaseKPIModel *)kpiModel
{
    CGFloat indicatorLabelOriginX = 0.1 * CGRectGetWidth(self.frame);
    CGFloat indicatorLabelOriginY = 0.2 * CGRectGetHeight(self.frame);
    CGFloat indicatorLabelWidth = 0.8 * CGRectGetWidth(self.frame);
    CGFloat indicatorLabelHeight = 0.2 * CGRectGetHeight(self.frame);
    CGRect indicatorLabelFrame = CGRectMake(indicatorLabelOriginX, indicatorLabelOriginY, indicatorLabelWidth, indicatorLabelHeight);
    UILabel *indicatorLabel = [[UILabel alloc] initWithFrame:indicatorLabelFrame];

    NSString *indicatorValueString = [NSString stringWithFormat:@"$%.0f", kpiModel.value.doubleValue];

    NSMutableAttributedString *indicatorValueAttributedString = [[NSMutableAttributedString alloc] initWithString:indicatorValueString];

    // setup value font
    NSDictionary *valueAttributes = @{
            NSForegroundColorAttributeName: [UIColor whiteColor],
            NSFontAttributeName : [UIFont boldSystemFontOfSize:16]
    };
    NSRange valueRange = NSMakeRange(0, indicatorValueString.length);
    [indicatorValueAttributedString addAttributes:valueAttributes range:valueRange];

    // set text
    indicatorLabel.attributedText = indicatorValueAttributedString;
    //indicatorLabel.textAlignment = NSTextAlignmentCenter;

    [self addSubview:indicatorLabel];
}

- (void)setupGraphWithModel:(JMBaseKPIModel *)kpiModel
{
    CGFloat graphOriginX = 0.1 * CGRectGetWidth(self.frame);
    CGFloat graphOriginY = 0.4 * CGRectGetHeight(self.frame);
    CGFloat graphWidth = 0.8 * CGRectGetWidth(self.frame);
    CGFloat graphHeight = 0.5 * CGRectGetHeight(self.frame);
    CGRect graphFrame = CGRectMake(graphOriginX, graphOriginY, graphWidth, graphHeight);

    UIImageView *graphView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sample_graph"]];
    graphView.frame = graphFrame;
    [self addSubview:graphView];
}

@end