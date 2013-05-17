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
//  JSMultiselectListInputControlCell.m
//  Jaspersoft Corporation
//

#import "JSMultiselectListInputControlCell.h"
#import "JSResourceDescriptor+Helpers.h"
#import "JSLocalization.h"
#import "JSListItem.h"

#define JS_LBL_VALUE_WIDTH		160.0f

@implementation JSMultiselectListInputControlCell

- (id)initWithResourceDescriptor:(JSResourceDescriptor *)rd tableViewController: (UITableViewController *)tv {
	return [self initWithResourceDescriptor:rd tableViewController: tv dataSourceUri: nil];
}

- (id)initWithDescriptor:(JSResourceDescriptor *)rd tableViewController:(UITableViewController *)tv 
           dataSourceUri:(NSString *)dsUri resourceClient:(JSRESTResource *)resourceClient {
    JSConstants *constants = [JSConstants sharedInstance];
	if ((self = [super initWithResourceDescriptor: rd tableViewController: tv dataSourceUri: dsUri])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		self.resourceClient = resourceClient;
        
		NSInteger inputControlType = [[rd propertyByName:constants.PROP_INPUTCONTROL_TYPE].value integerValue];

		if (inputControlType == constants.IC_TYPE_MULTI_SELECT_LIST_OF_VALUES ||
			inputControlType == constants.IC_TYPE_MULTI_SELECT_LIST_OF_VALUES_CHECKBOX) {
            
			// Look for the LOV resource
			for (int i = 0; i < rd.childResourceDescriptors.count; ++i) {
				JSResourceDescriptor *rdChild = [rd.childResourceDescriptors objectAtIndex:i];
				if ( [[rdChild wsType] isEqualToString:constants.WS_TYPE_LOV]) {
					self.items = [rdChild listOfItems];
					break;
				}
			}
		} else if (inputControlType == constants.IC_TYPE_MULTI_SELECT_QUERY || 
                   inputControlType == constants.IC_TYPE_MULTI_SELECT_QUERY_CHECKBOX) {
			// Get the date from the input control
			// We need to reload the input control to get the data
			[self reloadInputControlQueryData: nil];
		}		
		
		self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y,
                                          JS_LBL_VALUE_WIDTH, self.nameLabel.frame.size.height);
		self.selectedValue = nil;
        self.nameLabel.backgroundColor = [UIColor clearColor];
        
		label = [[UILabel alloc] initWithFrame:CGRectMake(JS_CELL_PADDING + JS_CONTENT_PADDING + JS_LBL_VALUE_WIDTH, 10.0, 
														  JS_CELL_WIDTH - (2 * JS_CELL_PADDING + JS_CONTENT_PADDING + JS_LBL_VALUE_WIDTH) - 20.0f, 21.0)];
		
		label.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
		label.textAlignment = UITextAlignmentRight;
		label.tag = 100;
		label.font = [UIFont systemFontOfSize:14.0];
		label.textColor = [UIColor colorWithRed:.196 green:0.3098 blue:0.52 alpha:1.0];
		label.text = JSCustomLocalizedString(@"ic.value.notset", nil);
        label.backgroundColor = [UIColor clearColor];
            
		if (self.readonly) {
			label.frame = CGRectMake(246.0, 10.0, 53.0, 21.0);
		} else {
			self.selectionStyle = UITableViewCellSelectionStyleBlue;
			self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}	
		[self addSubview:label];
	}
	
	return self;
}

- (id)initWithInputControlDescriptor:(JSInputControlDescriptor *)icDescriptor resourceDescriptor:(JSResourceDescriptor *)resourceDescriptor tableViewController:(UITableViewController *)tv {
	if (self = [super initWithInputControlDescriptor:icDescriptor resourceDescriptor:resourceDescriptor tableViewController:tv]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	
	return self;
}

// User touched the InputControl cell
- (void)cellDidSelected {
	if (self.readonly) return;
	
	NSMutableArray *selectedVals = [NSMutableArray array];
	if (self.selectedValue != nil) {
		for (int i=0; i< [(NSMutableArray *)self.selectedValue count]; ++i) {
			[selectedVals addObject: [NSNumber numberWithInt: [self indexOfItemWithValue: [(NSMutableArray *)self.selectedValue objectAtIndex:i] ]]];
		}		
	}
	
	JSListSelectorViewController *rvc = [[JSListSelectorViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
	rvc.values  = self.items;
	rvc.singleSelection = NO;
    rvc.mandatory = self.mandatory;
	rvc.selectedValues = selectedVals;
	rvc.selectionDelegate = self;
	[self.tableViewController.navigationController pushViewController: rvc animated: YES];
}

- (BOOL)isModified:(id)valuesToSet {
    return [self.selectedValue isEqualToArray:valuesToSet];
}

// This method is invoked by the ListSelectorView
- (void)setSelectedIndexes:(NSMutableArray *)indexes {
	if (indexes.count == 0) {
		self.selectedValue = nil;
	} else {		
		NSMutableArray *newSelection = [NSMutableArray array];		
		for (int i = 0; i < indexes.count; ++i) {
			NSString *str =  [(JSListItem *)[self.items objectAtIndex: [[indexes objectAtIndex:i] intValue]] value];
			[newSelection addObject:str];
		}		
		self.selectedValue = newSelection;
	}
}

- (void)updateValueText {
	if (self.selectedValue == nil) {
		label.text = JSCustomLocalizedString(@"ic.value.notset", nil);
	} else if ([self.selectedValue isKindOfClass: [NSArray class]]) {
        if ([self.selectedValue count] > 1) {
            label.text = [NSString stringWithFormat:@"%d %@", [self.selectedValue count], JSCustomLocalizedString(@"ic.label.selected", nil)];
        } else {
            label.text = [NSString stringWithFormat:@"%@", [self.selectedValue objectAtIndex:0]];
        }
	} else {
		label.text = @"?";
	}	
}

// This method is used when data for this input control is changes, and we want to be sure that at least one
// element from the selection is actually selected if the input control is mandatory
// If a selection is already available, it tries to recycle it, otherwise the selection will be cleanup...
- (void)adjustSelection {
	NSMutableArray *newSelection = [NSMutableArray array];
	if (self.selectedValue != nil) {
		// remove all the values which are no longer valid here...
		for (int i = 0; i < [self.selectedValue count]; ++i) {
			NSInteger index = [self indexOfItemWithValue: [self.selectedValue objectAtIndex:i]];
			if (index >= 0) {
				[newSelection addObject:[self.selectedValue objectAtIndex:i]];
			}
		}
		
		if ([newSelection count] == [self.selectedValue count]) {
			// Nothing changed...
			[self updateValueText];
			return;
		}
	}
	
    //@TODO
	if ([newSelection count] == 0 && self.items.count > 0) {
        if (self.icDescriptor) {
            for (JSListItem *item in self.items) {
                if (item.selected) {
                    [newSelection addObject:item.value];
                }
            }
        } else {
            [newSelection addObject:[(JSListItem *)[self.items objectAtIndex:0] value]];
        }
    }

	newSelection = ([newSelection count] == 0) ? nil : newSelection;
	
	if (self.selectedValue != newSelection) {
		self.selectedValue = newSelection;
	} else {
		[self updateValueText];
	}
}

@end