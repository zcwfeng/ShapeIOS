//
//  MainViewController.m
//  ShapeThat
//
//  Created by Lilian Erhan on 7/30/13.
//  Copyright (c) 2013 Lilian Erhan. All rights reserved.
//

#import "MainViewController.h"
#import "EditViewController.h"
#import "ELCAlbumPickerController.h"

@interface MainViewController ()

@property (nonatomic, retain) ALAssetsLibrary *assetsLibrary;

@end

@implementation MainViewController
@synthesize assetsLibrary = _assetsLibrary;
@synthesize chosenImages = _chosenImages;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (ALAssetsLibrary *)assetsLibrary
{
    if (!_assetsLibrary)
    {
        _assetsLibrary = [ALAssetsLibrary new];
    }
    return _assetsLibrary;
}

- (IBAction)photo:(id)sender
{
    NSMutableArray *groups = [NSMutableArray array];
    
    [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop)
    {
         if (group)
         {
             [groups addObject:group];
         }
         else
         {
             [self displayPickerForGroup:[groups objectAtIndex:0]];
         }
    }
    failureBlock:^(NSError *error)
    {
         self.chosenImages = nil;
         UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
         [alert show];
         [alert release];
         
         NSLog(@"A problem occured %@", [error description]);
    }];
}

- (IBAction)camera:(id)sender
{
    BOOL cameraAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    if(!cameraAvailable)
    {
        NSLog(@"Camera is not available");
        return;
    }
    
    [_assetsLibrary release];
    _assetsLibrary = nil;
    
    imagePickerController = [[UIImagePickerController alloc] init];
    [imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
    [imagePickerController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)displayPickerForGroup:(ALAssetsGroup *)group
{
	ELCAssetTablePicker *tablePicker = [[ELCAssetTablePicker alloc] initWithNibName:nil bundle:nil];
    tablePicker.selectionCount = 1;
    
	ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initWithRootViewController:tablePicker];
    elcPicker.delegate = self;
	tablePicker.parent = elcPicker;
    tablePicker.assetGroup = group;
    [tablePicker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    [self presentViewController:elcPicker animated:YES completion:nil];
	[tablePicker release];
    [elcPicker release];
}

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:[info count]];
	
	for (ALAsset *asset in info)
    {
        UIImage *image = [UIImage imageWithCGImage:asset.defaultRepresentation.fullResolutionImage];
        [images addObject:image];
	}
    
    self.chosenImages = images;
    
    [self dismissViewControllerAnimated:YES completion:^
     {
         [self presentEditController];
     }];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSMutableArray *images = [NSMutableArray array];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    [images addObject:image];
    self.chosenImages = images;
    
    [imagePickerController dismissViewControllerAnimated:NO completion:^
     {
         [self presentEditController];
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)presentEditController
{
    [_assetsLibrary release];
    _assetsLibrary = nil;
    
    EditViewController *editController = [[EditViewController alloc] initWithImage:_chosenImages[0]];
    [self presentViewController:editController animated:YES completion:nil];
    [editController release];
}

- (void)viewDidLoad
{
    titleLabel.font = [UIFont fontWithName:@"WisdomScriptAI" size:iPad?40:20];
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    if (imagePickerController)
    {
        [imagePickerController release];
    }
    [_chosenImages release];
    [_assetsLibrary release];
    _assetsLibrary = nil;
    
    [super dealloc];
}

@end
