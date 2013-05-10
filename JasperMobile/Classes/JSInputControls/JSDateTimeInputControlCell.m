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
//  JSDateTimeInputControl.m
//  Jaspersoft Corporation
//

#import "JSDateTimeInputControlCell.h"
#import "JSDateTimeSelectorViewController.h"
#import "JSLocalization.h"

#define JS_LBL_TEXT_WIDTH	160.0f

@implementation JSDateTimeInputControlCell

@synthesize dateFormat;

- (id)initWithResourceDescriptor:(JSResourceDescriptor *)rd tableViewController: (UITableViewController *)tv {
	if (self = [super initWithResourceDescriptor: rd tableViewController: tv]) {
		self.selectionStyle = UITableViewCellSelectionStyleBlue;
		height = 61.0f;		
		label = [[UILabel alloc] initWithFrame:CGRectMake(JS_CELL_PADDING + JS_CONTENT_PADDING + JS_LBL_WIDTH, 10.0,
																   JS_CELL_WIDTH - (2 * JS_CELL_PADDING + JS_CONTENT_PADDING + JS_LBL_WIDTH) - 20.0f, 22.0)];
		label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
		label.tag = 100;
		label.textAlignment = UITextAlignmentRight;
		label.font = [UIFont systemFontOfSize:14.0];
		label.textColor = [UIColor colorWithRed:.196 green:0.3098 blue:0.52 alpha:1.0];
		label.text = JSCustomLocalizedString(@"ic.value.notset", nil);
		label.numberOfLines = 2;
        label.backgroundColor = [UIColor clearColor];
		if (!self.readonly) self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[self addSubview: label];
	}
	
	return self;
}

- (id)initWithInputControlDescriptor:(JSInputControlDescriptor *)icDescriptor resourceDescriptor:(JSResourceDescriptor *)resourceDescriptor tableViewController:(UITableViewController *)tv {
    if (self = [super initWithInputControlDescriptor:icDescriptor resourceDescriptor:resourceDescriptor tableViewController:tv]) {
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
		height = 61.0f;		
		label = [[UILabel alloc] initWithFrame:CGRectMake(JS_CELL_PADDING + JS_CONTENT_PADDING + JS_LBL_WIDTH, 10.0,
                                                          JS_CELL_WIDTH - (2 * JS_CELL_PADDING + JS_CONTENT_PADDING + JS_LBL_WIDTH) - 20.0f, 22.0)];
		label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
		label.tag = 100;
		label.textAlignment = UITextAlignmentRight;
		label.font = [UIFont systemFontOfSize:14.0];
		label.textColor = [UIColor colorWithRed:.196 green:0.3098 blue:0.52 alpha:1.0];
		label.text = JSCustomLocalizedString(@"ic.value.notset", nil);
		label.numberOfLines = 2;
        label.backgroundColor = [UIColor clearColor];
        self.dateFormat = self.icDescriptor.validationRules.dateTimeFormatValidationRule.format;
		if (!self.readonly) self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[self addSubview: label];        
	}
	
	return self;
}

// Specifies if the user can select this cell
- (BOOL)selectable {
	return !self.readonly;
}

// Override the createNameLabel to adjust the label size...
- (void)createNameLabel {
	[super createNameLabel];
	
	// Adjust the label size...
	self.nameLabel.autoresizingMask = UIViewAutoresizingNone;
	CGRect rect = self.nameLabel.frame;
	rect.size.width = JS_LBL_TEXT_WIDTH;
	self.nameLabel.frame = rect;
}

- (void)setSelectedValue:(id)vals {
	[super setSelectedValue:vals];
    
	if (self.selectedValue == nil) {
		label.text = JSCustomLocalizedString(@"ic.value.notset", nil);
	} else {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        if ([self.dateFormat length]) {
            [dateFormatter setDateFormat:self.dateFormat];
            label.text = [dateFormatter stringFromDate:self.selectedValue];
        } else {
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            NSString *date = [dateFormatter stringFromDate: self.selectedValue];
            
            [dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            
            NSString *time = [dateFormatter stringFromDate: self.selectedValue];
            label.text = [NSString stringWithFormat:@"%@\n%@", date, time];
        }
	}
}

- (void)cellDidSelected {
    if (self.icDescriptor && self.icDescriptor.state.value.length) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:self.dateFormat];
        self.selectedValue = [dateFormatter dateFromString:self.icDescriptor.state.value];
    }
    
	JSDateTimeSelectorViewController *rvc = [[JSDateTimeSelectorViewController alloc] initWithStyle:UITableViewStyleGrouped];
	rvc.selectionDelegate = self;
	rvc.dateOnly = NO;
	rvc.mandatory = self.mandatory;
	rvc.selectedValue = self.selectedValue;
	[self.tableViewController.navigationController pushViewController: rvc animated: YES];
}

- (id)formattedSelectedValue {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:self.dateFormat];
    return [dateFormatter stringFromDate:self.selectedValue];
}

@end
