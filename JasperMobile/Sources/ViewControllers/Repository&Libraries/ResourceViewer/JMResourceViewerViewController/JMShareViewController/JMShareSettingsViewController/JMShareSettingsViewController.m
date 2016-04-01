//
//  JMShareSettingsViewController.m
//  TIBCO JasperMobile
//
//  Created by Oleksii Gubariev on 4/1/16.
//  Copyright © 2016 TIBCO JasperMobile. All rights reserved.
//

#import "JMShareSettingsViewController.h"

@interface JMShareSettingsViewController ()
@property (weak, nonatomic) IBOutlet UILabel *brushTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *brushValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *brushSlider;
@property (weak, nonatomic) IBOutlet UIImageView *brushPreviewImageView;

@property (weak, nonatomic) IBOutlet UILabel *opacityTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *opacityValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *opacitySlider;
@property (weak, nonatomic) IBOutlet UIImageView *opacityPreviewImageView;

@property (weak, nonatomic) IBOutlet UILabel *rgbPaletteTitleLabel;
@property (weak, nonatomic) IBOutlet UISlider *redSlider;
@property (weak, nonatomic) IBOutlet UILabel *redValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *greenSlider;
@property (weak, nonatomic) IBOutlet UILabel *greenValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *blueSlider;
@property (weak, nonatomic) IBOutlet UILabel *blueValueLabel;


@property (nonatomic, assign) CGFloat redComponent;
@property (nonatomic, assign) CGFloat greenComponent;
@property (nonatomic, assign) CGFloat blueComponent;

@end

@implementation JMShareSettingsViewController
@dynamic drawingColor;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.brushSlider.value = self.brushWidth;
    [self sliderValueChanged:self.brushSlider];
    
    self.opacitySlider.value = self.opacity;
    [self sliderValueChanged:self.opacitySlider];
    
    int redIntValue = self.redComponent * 255.0;
    self.redSlider.value = redIntValue;
    [self sliderValueChanged:self.redSlider];

    int greenIntValue = self.greenComponent * 255.0;
    self.greenSlider.value = greenIntValue;
    [self sliderValueChanged:self.greenSlider];

    int blueIntValue = self.blueComponent * 255.0;
    self.blueSlider.value = blueIntValue;
    [self sliderValueChanged:self.blueSlider];
}

#pragma mark - Custom Accessors
- (UIColor *)drawingColor
{
    return [UIColor colorWithRed:self.redComponent green:self.greenComponent blue:self.blueComponent alpha:1.f];
}

- (void)setDrawingColor:(UIColor *)drawingColor
{
    [drawingColor getRed:&_redComponent green:&_greenComponent blue:&_blueComponent alpha:nil];
}

#pragma mark - Actions
- (IBAction)applyButtonDidTapped:(id)sender
{
    [self.delegate settingsDidChangedOnController:self];
}

- (IBAction)sliderValueChanged:(id)sender
{
    UISlider * changedSlider = (UISlider*)sender;
    
    if(changedSlider == self.brushSlider) {
        self.brushWidth = self.brushSlider.value;
        self.brushValueLabel.text = [NSString stringWithFormat:@"%.1f", self.brushWidth];
    } else if(changedSlider == self.opacitySlider) {
        self.opacity = self.opacitySlider.value;
        self.opacityValueLabel.text = [NSString stringWithFormat:@"%.1f", self.opacity];
    } else if(changedSlider == self.redSlider) {
        self.redComponent = self.redSlider.value/255.0;
        self.redValueLabel.text = [NSString stringWithFormat:@"Red: %d", (int)self.redSlider.value];
    } else if(changedSlider == self.greenSlider){
        self.greenComponent = self.greenSlider.value/255.0;
        self.greenValueLabel.text = [NSString stringWithFormat:@"Green: %d", (int)self.greenSlider.value];
    } else if (changedSlider == self.blueSlider){
        self.blueComponent = self.blueSlider.value/255.0;
        self.blueValueLabel.text = [NSString stringWithFormat:@"Blue: %d", (int)self.blueSlider.value];
    }
    
    UIGraphicsBeginImageContext(self.brushPreviewImageView.bounds.size);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(),self.brushWidth);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), self.redComponent, self.greenComponent, self.blueComponent, 1.0);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), CGRectGetMidX(self.brushPreviewImageView.bounds), CGRectGetMidY(self.brushPreviewImageView.bounds));
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), CGRectGetMidX(self.brushPreviewImageView.bounds), CGRectGetMidY(self.brushPreviewImageView.bounds));
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.brushPreviewImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIGraphicsBeginImageContext(self.opacityPreviewImageView.bounds.size);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(),self.brushWidth);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), self.redComponent, self.greenComponent, self.blueComponent, self.opacity);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(), CGRectGetMidX(self.opacityPreviewImageView.bounds), CGRectGetMidY(self.opacityPreviewImageView.bounds));
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), CGRectGetMidX(self.opacityPreviewImageView.bounds), CGRectGetMidY(self.opacityPreviewImageView.bounds));
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    self.opacityPreviewImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

@end
