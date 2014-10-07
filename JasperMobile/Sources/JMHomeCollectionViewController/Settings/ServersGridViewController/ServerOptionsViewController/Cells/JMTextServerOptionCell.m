//
//  JMTextServerOptionCell.m
//  JasperMobile
//
//  Created by Oleksii Gubariev on 7/24/14.
//  Copyright (c) 2014 JasperMobile. All rights reserved.
//

#import "JMTextServerOptionCell.h"
#import "UITableViewCell+Additions.h"

@interface JMTextServerOptionCell () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation JMTextServerOptionCell
- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textField.background = [self.textField.background resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10.0f, 0, 10.0f)];
    self.textField.inputAccessoryView = [self toolbarForInputAccessoryView];
}

-(void)setServerOption:(JMServerOption *)serverOption
{
    [super setServerOption:serverOption];
    self.textField.enabled = serverOption.editable;
    self.textField.text = serverOption.optionValue;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat textFieldPadding = self.contentView.frame.size.width - self.textField.frame.size.width - self.textField.frame.origin.x;
    
    CGRect textLabelFrame = self.textLabel.frame;
    textLabelFrame.size.width = self.contentView.frame.size.width - self.textField.frame.size.width - textLabelFrame.origin.x - 2 * textFieldPadding;
    self.textLabel.frame = textLabelFrame;
    
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;
    detailTextLabelFrame.size.width = self.contentView.frame.size.width - self.textField.frame.size.width - detailTextLabelFrame.origin.x - 2 * textFieldPadding;
    self.detailTextLabel.frame = detailTextLabelFrame;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.serverOption.errorString) {
        self.serverOption.errorString = nil;
        [self updateDisplayingOfErrorMessage];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [textField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.serverOption.optionValue = textField.text;
}

#pragma mark - Actions

- (void)doneButtonTapped:(id)sender
{
    [self.textField resignFirstResponder];
}

@end
