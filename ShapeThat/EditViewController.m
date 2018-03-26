//
//  EditViewController.m
//  ShapeThat
//
//  Created by Lilian Erhan on 7/31/13.
//  Copyright (c) 2013 Lilian Erhan. All rights reserved.
//

#import "EditViewController.h"

@interface EditViewController ()

@end

@implementation EditViewController
@synthesize editingImageView = _editingImageView;

- (id)initWithImage:(UIImage *)image
{
    NSString *nibName = iPad?@"EditViewController-iPad":@"EditViewController";
    self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]];
    if (self)
    {
        editingImage = [Tool scaleImage:image toSize:CGSizeMake(iPad?768:320, iPad?768:320)];
    }
    return self;
}

- (UIImageView *)editingImageView
{
    if (!_editingImageView)
    {
        CGSize imageSize = editingImage.size;
        CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
        _editingImageView = [[UIImageView alloc] initWithFrame:imageRect];
        _editingImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_editingImageView setBackgroundColor:[UIColor redColor]];
        _editingImageView.image = editingImage;
        _scrollView.contentSize = imageSize;
    }
    return _editingImageView;
}

- (UIImage *)renderFinalImage
{
    CGSize size = CGSizeZero;
    float maskSize = maskView.layer.mask.contentsRect.size.width;
    size.width = size.height = _scrollView.frame.size.width / maskSize;
    
    UIImage *visibleImage = [Tool getVisibleAreaFromScroll:_scrollView sourceImage:self.editingImageView.image value:0 size:_scrollView.frame.size];

    UIGraphicsBeginImageContextWithOptions(maskView.frame.size, FALSE, [[UIScreen mainScreen] scale]);
    
    if (_maskMode == MaskModeNormal)
    {
        maskView.layer.mask.contents = (id)[[Tool reverseMask:currentMask.image] CGImage];
    }
    
    [maskView.layer.mask renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *resultMask = UIGraphicsGetImageFromCurrentImageContext();
    UIImage *resultImage = [Tool maskImage:visibleImage withMask:resultMask maskMode:_maskMode];
    UIImage *finalImage = [Tool renderImage:resultImage originalImage:visibleImage withView:maskView];
    
    if (_maskMode == MaskModeNormal)
    {
        maskView.layer.mask.contents = (id)[currentMask.image CGImage];
    }
    
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (IBAction)backToMainController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)shitchMaskMode:(id)sender
{
    NSString *hudText = @"";
    
    switch (_maskMode)
    {
        case MaskModeNormal:
        {
            hudText = @"Invert Mode ON";
            _maskMode = MaskModeRevert;
            [self setButton:revertButton on:YES imageName:@"inverse.png"];
            break;
        }
        case MaskModeRevert:
        {
            hudText = @"Invert Mode OFF";
            _maskMode = MaskModeNormal;
            [self setButton:revertButton on:NO imageName:@"inverse.png"];
            break;
        }
        default:
            break;
    }
    [self changeMaskSize:nil];
    
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:_hud];
	
	_hud.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]] autorelease];
	_hud.mode = MBProgressHUDModeCustomView;
    _hud.labelText = hudText;
	_hud.delegate = self;

	[_hud show:YES];
	[_hud hide:YES afterDelay:1];
}

- (IBAction)changeMaskSize:(id)sender
{
    CGRect contentsRect      = CGRectZero;
    contentsRect.origin.x    = -resizeSlider.value/2;
    contentsRect.origin.y    = -resizeSlider.value/2;
    contentsRect.size.width  = resizeSlider.value+1;
    contentsRect.size.height = resizeSlider.value+1;
    
    UIImage *maskImage = nil;
    switch (_maskMode)
    {
        case MaskModeNormal:
        {
            maskImage = currentMask.image;
            break;
        }
        case MaskModeRevert:
        {
            maskImage = [Tool reverseMask:currentMask.image];
            break;
        }
        default:
            break;
    }
    
    CALayer *_maskingLayer = [CALayer layer];
    _maskingLayer.frame = maskView.bounds;
    _maskingLayer.contentsRect = contentsRect;
    [_maskingLayer setContents:(id)[maskImage CGImage]];
    [maskView.layer setMask:_maskingLayer];
}

- (IBAction)changeOpacity:(id)sender
{
    maskView.alpha = opacitySlider.value;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.editingImageView;
}

- (void)colorButtonAction:(UIButton *)button
{
    maskView.backgroundColor = button.backgroundColor;
}

- (void)buttonAction:(UIButton *)button
{
    if (button)
    {
        [self moveSelectedMask:button];
    }
    NSString *fileName = [NSString stringWithFormat:@"mask%02zd.png",button?button.tag:1];
    currentMask.image = [UIImage imageNamed:fileName];
    [self changeMaskSize:nil];
}

- (void)moveSelectedMask:(UIButton *)button
{
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^
    {
         selectedMask.frame = CGRectMake(button.frame.origin.x, 0, button.frame.size.width, button.frame.size.height);
    }
    completion:^(BOOL finished)
    {
    }];
}

- (IBAction)showHideResizeView:(id)sender
{
    [self.view bringSubviewToFront:colorView];
    resizeValue = ([sender tag] != 4)?resizeSlider.value:resizeValue;
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^
    {
        resizeView.alpha = !resizeView.alpha;
        [self setButton:scaleButton on:resizeView.alpha imageName:@"resize.png"];
    }
    completion:^(BOOL finished)
    {
        if ([sender tag] == 4)
        {
            resizeSlider.value = resizeValue;
            [self changeMaskSize:nil];
        }
        
        if (resizeView.alpha)
        {
            opacityView.alpha = 0.0f;
            colorView.alpha = 0.0f;
            
            [self setButton:alphaButton on:NO imageName:@"opacity.png"];
            [self setButton:colorButton on:NO imageName:@"color.png"];
        }
    }];
}

- (IBAction)showHideOpacityView:(id)sender
{
    [self.view bringSubviewToFront:colorView];
    opacityValue = ([sender tag] != 4)?opacitySlider.value:opacityValue;
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^
    {
        opacityView.alpha = !opacityView.alpha;
        [self setButton:alphaButton on:opacityView.alpha imageName:@"opacity.png"];
    }
    completion:^(BOOL finished)
    {
        if ([sender tag] == 4)
        {
            opacitySlider.value = opacityValue;
            [self changeOpacity:nil];
        }
        
        if (opacityView.alpha)
        {
            resizeView.alpha = 0.0f;
            colorView.alpha = 0.0f;
            
            [self setButton:scaleButton on:NO imageName:@"resize.png"];
            [self setButton:colorButton on:NO imageName:@"color.png"];
        }
    }];
}

- (IBAction)showColorPicker:(id)sender
{
    [self.view bringSubviewToFront:colorView];
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^
    {
        colorView.alpha = !colorView.alpha;
        [self setButton:colorButton on:colorView.alpha imageName:@"color.png"];
    }
    completion:^(BOOL finished)
    {
        if (colorView.alpha)
        {
            resizeView.alpha = 0.0f;
            opacityView.alpha = 0.0f;
            
            [self setButton:alphaButton on:NO imageName:@"opacity.png"];
            [self setButton:scaleButton on:NO imageName:@"resize.png"];
        }
    }];
}

- (void)selectedColor:(UIColor *)color
{
    maskView.backgroundColor = color;
}

- (void)displayMasksFromFile:(NSString *)filePath
{
    for (UIView *view in _maskScroll.subviews)
    {
        [view removeFromSuperview];
        view = nil;
    }
    
    int posX = 0;
    UIImage *buttonImage = nil;
    NSMutableArray *dataArray = [NSMutableArray arrayWithContentsOfFile:filePath];
    for (int i=0; i<[dataArray count]; i++)
    {
        buttonImage = [UIImage imageNamed:dataArray[i][@"image"]];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(posX, iPad?13:5, 45, 45)];
        [button setTag:i+1];
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:buttonImage forState:UIControlStateNormal];
        [_maskScroll addSubview:button];
        
        posX += 50;
        [_maskScroll setContentSize:CGSizeMake(posX, 50)];
    }
    
    [self buttonAction:nil];
    
    selectedMask = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 45, 45)];
    selectedMask.image = [UIImage imageNamed:@"select.png"];
    selectedMask.contentMode = UIViewContentModeTop;
    [_maskScroll addSubview:selectedMask];
}

- (IBAction)showHideShareMenu:(UIButton *)sender
{
    UIImage *resultImage = [self renderFinalImage];
    NSArray *activityItem = @[resultImage];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItem applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
    
    if ([activityViewController respondsToSelector:@selector(popoverPresentationController)]) {
        activityViewController.popoverPresentationController.sourceView = self.view;
        activityViewController.popoverPresentationController.sourceRect = [sender frame];
    }
    
    [activityViewController release];
}


- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[_hud removeFromSuperview];
	[_hud release];
	_hud = nil;
}

- (void)setButton:(UIButton *)button on:(BOOL)on imageName:(NSString *)imageName
{
    UIImage *image = nil;
    if (on)
    {
         image = [[UIImage imageNamed:imageName] tintedImageWithColor:[UIColor redColor]];
    }
    else
    {
        image = [UIImage imageNamed:imageName];
    }
    [button setImage:image forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    _maskMode = MaskModeNormal;
    
    _scrollView.minimumZoomScale = 1.0;
    _scrollView.maximumZoomScale = 3.0;
    [_scrollView addSubview:self.editingImageView];
    
    colorArray = [NSArray arrayWithObjects:
                           [UIColor blackColor],
                           [UIColor lightGrayColor],
                           [UIColor whiteColor],
                           [UIColor grayColor],
                           [UIColor redColor],
                           [UIColor greenColor],
                           [UIColor blueColor],
                           [UIColor cyanColor],
                           [UIColor yellowColor],
                           [UIColor magentaColor],
                           [UIColor orangeColor],
                           [UIColor purpleColor],
                           [UIColor brownColor], nil];
    int posX = 0;
    for (int i=0; i<[colorArray count]; i++)
    {
        UIButton *_colorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_colorButton setFrame:CGRectMake(posX, 0, _colorScroll.frame.size.height, _colorScroll.frame.size.height)];
        [_colorButton setTag:i];
        [_colorButton addTarget:self action:@selector(colorButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_colorButton setBackgroundColor:colorArray[i]];
        [_colorScroll addSubview:_colorButton];
        
        posX += _colorScroll.frame.size.height;
        [_colorScroll setContentSize:CGSizeMake(posX, _colorScroll.frame.size.height)];
        
    }
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"MaskData" ofType:@"plist"];
    [self displayMasksFromFile:filePath];
    
    titleLabel.font = [UIFont fontWithName:@"WisdomScriptAI" size:iPad?40:20];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 5)
    {
        [resizeSlider setMinimumTrackImage:[[UIImage imageNamed:@"regulator2"] resizableImageWithCapInsets:UIEdgeInsetsFromString(@"8")] forState:UIControlStateNormal];
        [opacitySlider setMinimumTrackImage:[[UIImage imageNamed:@"regulator2"] resizableImageWithCapInsets:UIEdgeInsetsFromString(@"8")] forState:UIControlStateNormal];
    }
    else
    {
        [resizeSlider setMinimumTrackImage:[UIImage imageNamed:@"regulator2"] forState:UIControlStateNormal];
        [opacitySlider setMinimumTrackImage:[UIImage imageNamed:@"regulator2"] forState:UIControlStateNormal];
    }
    
    [resizeSlider setThumbImage:[UIImage imageNamed:@"regulator-button"] forState:UIControlStateNormal];
    [resizeSlider setMaximumTrackImage:[UIImage imageNamed:@"regulator1"] forState:UIControlStateNormal];
    [opacitySlider setThumbImage:[UIImage imageNamed:@"regulator-button"] forState:UIControlStateNormal];
    [opacitySlider setMaximumTrackImage:[UIImage imageNamed:@"regulator1"] forState:UIControlStateNormal];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [super dealloc];
}

@end
