//
//  MainViewController.h
//  MetalSamples
//
//  Created by Andrea Melle on 23/06/2015.
//  Copyright (c) 2015 Andrea Melle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISlider *blurRadiusSlider;
@property (weak, nonatomic) IBOutlet UISlider *saturationSlider;

- (IBAction)blurRadiusDidChange:(id)sender;
- (IBAction)saturationDidChange:(id)sender;

@end
