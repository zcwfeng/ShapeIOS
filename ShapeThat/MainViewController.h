//
//  MainViewController.h
//  ShapeThat
//
//  Created by Lilian Erhan on 7/30/13.
//  Copyright (c) 2013 Lilian Erhan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ELCAssetTablePicker.h"
#import "ELCImagePickerController.h"

@interface MainViewController : UIViewController <ELCImagePickerControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    UIImagePickerController *imagePickerController;
    IBOutlet UILabel        *titleLabel;
}

@property (nonatomic, retain) NSArray *chosenImages;

- (IBAction)photo:(id)sender;
- (IBAction)camera:(id)sender;

@end
