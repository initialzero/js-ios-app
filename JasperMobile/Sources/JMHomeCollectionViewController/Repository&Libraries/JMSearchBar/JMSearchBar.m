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


#import "JMSearchBar.h"

#define kJMSearchBarCancelButtonWidth       80.f
#define kJMSearchBarPadding                 5.f

static NSString * const JMReplacingTextString = @"ReplacingTextString";
static NSString * const JMReplacingTextRange  = @"ReplacingTextRange";

@interface JMSearchBar () <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *clearButton;
@end

@implementation JMSearchBar
@dynamic text;
@dynamic placeholder;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        [super setBackgroundColor:kJMMainNavigationBarBackgroundColor];
        CGRect textFieldFrame = CGRectMake(kJMSearchBarPadding, kJMSearchBarPadding, frame.size.width - kJMSearchBarCancelButtonWidth - kJMSearchBarPadding, frame.size.height - 2 * kJMSearchBarPadding);
        self.textField = [[UITextField alloc] initWithFrame:textFieldFrame];
        self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.textField.font = [JMFont navigationItemsFont];
        self.textField.borderStyle = UITextBorderStyleRoundedRect;
        self.textField.textAlignment = NSTextAlignmentLeft;
        self.textField.delegate = self;
        self.textField.textColor = [UIColor whiteColor];
        self.textField.returnKeyType = UIReturnKeySearch;
        self.textField.backgroundColor = kJMSearchBarBackgroundColor;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        UIImageView *leftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, textFieldFrame.size.height, textFieldFrame.size.height)];
        leftView.image = [UIImage imageNamed:@"search_button"];
        leftView.backgroundColor = [UIColor clearColor];
        leftView.contentMode = UIViewContentModeCenter;
        self.textField.leftView = leftView;
        self.textField.leftViewMode = UITextFieldViewModeAlways;

        self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.clearButton.frame = CGRectMake(0, 0, textFieldFrame.size.height, textFieldFrame.size.height);
        self.clearButton.backgroundColor = [UIColor clearColor];
        [self.clearButton addTarget:self action:@selector(clearButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.clearButton setImage:[UIImage imageNamed:@"clear_button"] forState:UIControlStateNormal];
        [self.clearButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        self.textField.rightView = self.clearButton;
        self.textField.rightViewMode = UITextFieldViewModeNever;
        
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.cancelButton.frame = CGRectMake(frame.size.width - kJMSearchBarCancelButtonWidth, kJMSearchBarPadding, kJMSearchBarCancelButtonWidth, textFieldFrame.size.height);
        self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight;
        self.cancelButton.backgroundColor = [UIColor clearColor];
        self.cancelButton.titleLabel.font = [JMFont navigationItemsFont];
        [self.cancelButton addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton setTitle:JMCustomLocalizedString(@"dialog.button.cancel", nil) forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [self.cancelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        
        [self addSubview:self.cancelButton];
        [self addSubview:self.textField];
    }
    return self;
}

- (BOOL)isFirstResponder
{
    return self.textField.isFirstResponder;
}

- (BOOL)becomeFirstResponder
{
    return self.textField.becomeFirstResponder;
}

- (BOOL)resignFirstResponder
{
    return self.textField.resignFirstResponder & [super resignFirstResponder];
}

- (BOOL)canBecomeFirstResponder
{
    return self.textField.canBecomeFirstResponder;
}

- (BOOL)canResignFirstResponder
{
    return self.textField.canResignFirstResponder;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textField resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(searchBarSearchButtonClicked:)]) {
        [self.delegate searchBarSearchButtonClicked:self];
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if ([newString length]) {
        if (self.textField.rightViewMode != UITextFieldViewModeAlways) {
            self.textField.rightViewMode = UITextFieldViewModeAlways;
        }
    } else {
        self.textField.rightViewMode = UITextFieldViewModeNever;
    }
    
    if ([self.delegate respondsToSelector:@selector(searchBarDidChangeText:)]) {
        [((NSObject *)self.delegate) performSelector:@selector(searchBarDidChangeText:) withObject:self afterDelay: 0.1];
    }

    return YES;
}

#pragma mark - Actions
- (void)clearButtonTapped:(id)sender
{
    self.textField.text = @"";
    self.textField.rightViewMode = UITextFieldViewModeNever;
    if ([self.delegate respondsToSelector:@selector(searchBarDidChangeText:)]) {
        [self.delegate searchBarDidChangeText:self];
    }
}

- (void)cancelButtonTapped:(id)sender
{
    [self.textField resignFirstResponder];
    [self clearButtonTapped:self.clearButton];
    
    if ([self.delegate respondsToSelector:@selector(searchBarCancelButtonClicked:)]) {
        [self.delegate searchBarCancelButtonClicked:self];
    }
}

#pragma Properties
- (NSString *)text
{
    return self.textField.text;
}

- (void)setText:(NSString *)text
{
    self.textField.text = text;
}

- (NSString *)placeholder
{
    return self.textField.placeholder;
}

-(void)setPlaceholder:(NSString *)placeholder
{
    NSAttributedString *attrPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:[self attributesForPlaceholder]];
    self.textField.attributedPlaceholder = attrPlaceholder;
}

- (NSDictionary *)attributesForPlaceholder
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[UIColor grayColor], NSForegroundColorAttributeName, self.textField.font, NSFontAttributeName, nil];
}

@end