//
//  EditViewController.h
//  ShapeThat
//
//  Created by Lilian Erhan on 7/31/13.
//  Copyright (c) 2013 Lilian Erhan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Twitter/Twitter.h>
#import <MessageUI/MessageUI.h>
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "Tool.h"

@interface EditViewController : UIViewController <UIScrollViewDelegate, MBProgressHUDDelegate>
{
    MBProgressHUD           *_hud;
    
    UIImage                 *editingImage;
    
    IBOutlet UIScrollView   *_scrollView;
    IBOutlet UIScrollView   *_maskScroll;
    IBOutlet UIImageView    *currentMask;
    IBOutlet UIView         *resizeView;
    IBOutlet UISlider       *resizeSlider;
    IBOutlet UIView         *opacityView;
    IBOutlet UISlider       *opacitySlider;
    IBOutlet UIView         *maskView;
    IBOutlet UIView         *shareView;
    IBOutlet UIView         *colorView;
    IBOutlet UIScrollView   *_colorScroll;
    NSArray                 *colorArray;
    UIImageView             *selectedMask;
    
    IBOutlet UIButton       *revertButton;
    IBOutlet UIButton       *scaleButton;
    IBOutlet UIButton       *alphaButton;
    IBOutlet UIButton       *colorButton;
    
    IBOutlet UILabel        *titleLabel;
    
    MaskMode                _maskMode;
    
    float                   resizeValue;
    float                   opacityValue;
}

@property (nonatomic, retain) UIImageView *editingImageView;

- (id)initWithImage:(UIImage *)image;

- (IBAction)backToMainController:(id)sender;
- (IBAction)showHideShareMenu:(id)sender;

- (IBAction)shitchMaskMode:(id)sender;

- (IBAction)showHideResizeView:(id)sender;
- (IBAction)showHideOpacityView:(id)sender;
- (IBAction)showColorPicker:(id)sender;
- (IBAction)changeMaskSize:(id)sender;
- (IBAction)changeOpacity:(id)sender;

@end
