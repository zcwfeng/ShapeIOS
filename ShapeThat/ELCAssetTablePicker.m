//
//  AssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"

@interface ELCAssetTablePicker ()

@property (nonatomic, assign) int columns;

@end

@implementation ELCAssetTablePicker
@synthesize parent = _parent;
@synthesize selectedAssetsLabel = _selectedAssetsLabel;
@synthesize assetGroup = _assetGroup;
@synthesize elcAssets = _elcAssets;
@synthesize columns = _columns;
@synthesize selectionCount = _selectionCount;

- (void)viewDidLoad
{
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
    [tempArray release];
	
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
	[self.navigationItem setLeftBarButtonItem:cancelButton];
    [self.navigationItem setTitle:@"Loading..."];
    [cancelButton release];

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.columns = self.view.bounds.size.width / 80;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.columns = self.view.bounds.size.width / 80;
    [self.tableView reloadData];
}

- (void)preparePhotos
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSLog(@"enumerating photos");
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop)
    {
        if (result == nil)
        {
            return;
        }

        ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
        [elcAsset setParent:self];
        [self.elcAssets addObject:elcAsset];
        [elcAsset release];
     }];
    NSLog(@"done enumerating photos");
    
    dispatch_sync(dispatch_get_main_queue(), ^
    {
        [self.tableView reloadData];
        
        int section = (int)[self numberOfSectionsInTableView:self.tableView] - 1;
        int row = (int)[self tableView:self.tableView numberOfRowsInSection:section] - 1;
        if (section >= 0 && row >= 0)
        {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:row inSection:section];
            [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
        
        [self.navigationItem setTitle:@"Pick Photos"];
    });
    
    [pool release];
}

- (void)doneAction:(id)sender
{	
	NSMutableArray *selectedAssetsImages = [[[NSMutableArray alloc] init] autorelease];
	    
	for (ELCAsset *elcAsset in self.elcAssets)
    {
		if ([elcAsset selected])
        {
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
        
    [self.parent selectedAssets:selectedAssetsImages];
}

- (void)assetSelected:(id)asset
{
    if (_selectionCount == [self totalSelectedAssets])
    {
        [self doneAction:nil];
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil([self.elcAssets count] / (float)self.columns);
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    int index = (int)path.row * self.columns;
    int length = (int)MIN(self.columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
    {
        cell = [[[ELCAssetCell alloc] initWithAssets:[self assetsForIndexPath:indexPath] reuseIdentifier:CellIdentifier] autorelease];

    }
    else
    {
		[cell setAssets:[self assetsForIndexPath:indexPath]];
	}
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return iPad?85:79;
}

- (int)totalSelectedAssets
{
    int count = 0;
    
    for (ELCAsset *asset in self.elcAssets)
    {
		if ([asset selected])
        {
            count++;	
		}
	}
    
    return count;
}

- (void)dealloc 
{
    [_assetGroup release];    
    [_elcAssets release];
    [_selectedAssetsLabel release];
    [super dealloc];    
}

@end
