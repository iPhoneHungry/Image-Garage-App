//
//  SDBrightnessFilters.m
//  SimpleDrawing
//
//  Created by android on 6/9/13.
//  Copyright (c) 2013 Nathanial Woolls. All rights reserved.
//

#import "SDBrightnessFilters.h"
#import <QuartzCore/QuartzCore.h>

@interface SDBrightnessFilters ()

@end

@implementation SDBrightnessFilters





-(void)amountEntered:(NSInteger)amount{
    
    //[delegate amountEntered:amount];
}

- (IBAction)filterCancelButton:(UIBarButtonItem *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}
/*
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
 {
 self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
 if (self) {
 // Custom initialization
 }
 return self;
 }
 
 */


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}







- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Filter List";
    [self amountEntered:5];
    NSLog(@"alskjflsjfls");
    
    
    
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.rowHeight = 70;
	self.tableView.backgroundColor = [UIColor clearColor];
	//imageView.image = [UIImage imageNamed:@"gradientBackground.png"];
	
    //    [self.navigationController.view ];
    //  self.navigationController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradientBackground.png"]];
    
    
    UIImage *image = [UIImage imageNamed:@"gradientBackground.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
	self.tableView.backgroundView = imageView;
    //
	// Create a header view. Wrap it in a container to allow us to position
	// it better.
	//
    
    
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Disable the last filter (Core Image face detection) if running on iOS 4.0
    // if ([GPUImageContext supportsFastTextureUpload])
    // {
    //     return GPUIMAGE_NUMFILTERS;
    //}
    // else
    // {
    // return 54;
    return 10;
    // }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    //new stuff below here
    
    
    //topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
    //  bottomLabel = (UILabel *)[cell viewWithTag:BOTTOM_LABEL_TAG];
    
    
    //topLabel.text = [NSString stringWithFormat:@"Cell at row %ld.", (long)[indexPath row]];
    //bottomLabel.text = [NSString stringWithFormat:@"Some other information.", [indexPath row]];
    
    //
    // Set the background and selected background images for the text.
    // Since we will round the corners at the top and bottom of sections, we
    // need to conditionally choose the images based on the row index and the
    // number of rows in the section.
    //
    UIImage *rowBackground;
    UIImage *selectionBackground;
    //NSInteger sectionRows = [ UITableView numberOfRowsInSection:[NSIndexPath section]];
    //NSInteger row = [NSIndexPath row];
    
    //
    // Here I set an image based on the row. This is just to have something
    // colorful to show on each row.
    //
    
    
    
    
    
    
    
    
    
    
	NSInteger index = [indexPath row];
	myCustomFilterCell *cell = (myCustomFilterCell *)[tableView dequeueReusableCellWithIdentifier:@"myCustomFilterCell"];
	if (cell == nil)
	{
        NSArray* views = [[NSBundle mainBundle]   loadNibNamed:@"myCustomFilterCell" owner:nil options:nil];
        
        for (UIView *view in views) {
            if([view isKindOfClass:[UITableViewCell class]])
            {
                cell = (myCustomFilterCell*)view;
            }
        }
	}
    
    // cell.imageView.bounds = CGRectMake(10.0, 10.0, 45.0, 45.0);
    
    NSInteger sectionRows = [tableView numberOfRowsInSection:[indexPath section]];
	NSInteger row = [indexPath row];
	if (row == 0 && row == sectionRows - 1)
	{
		rowBackground = [UIImage imageNamed:@"topAndBottomRow.png"];
		selectionBackground = [UIImage imageNamed:@"topAndBottomRowSelected.png"];
	}
	else if (row == 0)
	{
		rowBackground = [UIImage imageNamed:@"topRow.png"];
		selectionBackground = [UIImage imageNamed:@"topRowSelected.png"];
	}
	else if (row == sectionRows - 1)
	{
		rowBackground = [UIImage imageNamed:@"bottomRow.png"];
		selectionBackground = [UIImage imageNamed:@"bottomRowSelected.png"];
	}
	else
	{
		rowBackground = [UIImage imageNamed:@"middleRow.png"];
		selectionBackground = [UIImage imageNamed:@"middleRowSelected.png"];
	}
    
    UIImageView *av = [[UIImageView alloc] initWithFrame:cell.backgroundView.frame];
    av.backgroundColor = [UIColor clearColor];
    av.opaque = NO;
    av.image = rowBackground;
    cell.backgroundView = av;
    
    
    UIImageView *imgView =  [[UIImageView alloc] initWithFrame:cell.selectedBackgroundView.frame];
    [imgView setImage:selectionBackground];
    [cell.selectedBackgroundView addSubview:imgView];
    
    
    
    
    switch (index)
	{
		case 0:            
            cell.inCellLabel.text = @"Brightness";
            cell.inCellImage.image = [UIImage imageNamed:@"brightnessPreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
           // chosen_Filter_Was = 2;
            
            break;
		case 1:             
            
            cell.inCellLabel.text = @"Contrast";
            cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
           // chosen_Filter_Was = 1;
            break;
		case 2:
            cell.inCellLabel.text = @"Vignette";
            cell.inCellImage.image = [UIImage imageNamed:@"vignettePreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
            // chosen_Filter_Was = 48;
            break;
		case 3: //cell.textLabel.text = @"Levels";
            cell.inCellLabel.text = @"levels";
            cell.inCellImage.image = [UIImage imageNamed:@"levelsPreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
            //chosen_Filter_Was = 3;
            
            break;
		case 4: //cell.textLabel.text = @"Exposure";
            cell.inCellLabel.text = @"Exposure";
            cell.inCellImage.image = [UIImage imageNamed:@"exposurePreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
           // chosen_Filter_Was = 4;
            break;
        case 5: //cell.textLabel.text = @"RGB";
            
            cell.inCellLabel.text = @"Gamma";
            cell.inCellImage.image = [UIImage imageNamed:@"gammaPreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
           // chosen_Filter_Was = 10;
            break;
        case 6:
            cell.inCellLabel.text = @"Highlights & Shadows";
            cell.inCellImage.image = [UIImage imageNamed:@"highlightsPreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
            //chosen_Filter_Was = 12;
            break;
        case 7:
            cell.inCellLabel.text = @"Haze";
            cell.inCellImage.image = [UIImage imageNamed:@"hazePreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
            //chosen_Filter_Was = 13;
            break;
        case 8:
            cell.inCellLabel.text = @"Dilation";
            cell.inCellImage.image = [UIImage imageNamed:@"dilatePreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
           // chosen_Filter_Was = 45;
            break;
        case 9:
            cell.inCellLabel.text = @"Erosion";
            cell.inCellImage.image = [UIImage imageNamed:@"erosionPreview.png"];
            cell.inCellImage.layer.cornerRadius = 5;
            cell.inCellImage.layer.masksToBounds = YES;
           // chosen_Filter_Was = 46;
            break;
       
            
    }
    
    
    // [cell.backgroundView setBackgroundColor:[UIColor colorWithPatternImage:rowBackground]];
    // [cell.selectedBackgroundView setBackgroundColor:[UIColor colorWithPatternImage:selectionBackground]];
	
	//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    /*
     
     switch (index)
     {
     case 0:// cell.textLabel.text = @"Saturation";
     
     cell.inCellLabel.text = @"Saturation";
     cell.inCellImage.image = [UIImage imageNamed:@"saturationPreivew.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 0;
     
     break;
     case 1: //cell.textLabel.text = @"Contrast";
     
     cell.inCellLabel.text = @"Contrast";
     cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 1;
     break;
     case 2: //cell.textLabel.text = @"Brightness";
     cell.inCellLabel.text = @"Brightness";
     cell.inCellImage.image = [UIImage imageNamed:@"brightnessPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 2;
     break;
     case 3: //cell.textLabel.text = @"Levels";
     cell.inCellLabel.text = @"levels";
     cell.inCellImage.image = [UIImage imageNamed:@"levelsPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 3;
     break;
     case 4: //cell.textLabel.text = @"Exposure";
     cell.inCellLabel.text = @"Exposure";
     cell.inCellImage.image = [UIImage imageNamed:@"exposurePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 4;
     break;
     case 5: //cell.textLabel.text = @"RGB";
     
     cell.inCellLabel.text = @"RGB";
     cell.inCellImage.image = [UIImage imageNamed:@"rgbPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 5;
     break;
     case 6: //cell.textLabel.text = @"Hue";
     
     cell.inCellLabel.text = @"Hue";
     cell.inCellImage.image = [UIImage imageNamed:@"huePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 6;
     break;
     case 7: //cell.textLabel.text = @"White balance";
     
     cell.inCellLabel.text = @"White Balance";
     cell.inCellImage.image = [UIImage imageNamed:@"whiteBalancePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 7;
     
     break;
     case 8: // cell.textLabel.text = @"Monochrome";
     
     cell.inCellLabel.text = @"Monochrome";
     cell.inCellImage.image = [UIImage imageNamed:@"monochromePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 8;
     break;
     case 9: //cell.textLabel.text = @"Sharpen";
     
     cell.inCellLabel.text = @"Sharpen";
     cell.inCellImage.image = [UIImage imageNamed:@"sharpenPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 9;
     
     break;
     case 10: //cell.textLabel.text = @"Gamma";
     
     cell.inCellLabel.text = @"Gamma";
     cell.inCellImage.image = [UIImage imageNamed:@"gammaPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 10;
     break;
     case 11: //cell.textLabel.text = @"Tone curve";
     
     cell.inCellLabel.text = @"Tone Curve";
     cell.inCellImage.image = [UIImage imageNamed:@"toneCurvePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 11;
     break;
     case 12: //cell.textLabel.text = @"Highlights and shadows";
     
     cell.inCellLabel.text = @"Highlights & Shadows";
     cell.inCellImage.image = [UIImage imageNamed:@"highlightsPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 12;
     break;
     case 13: //cell.textLabel.text = @"Haze";
     
     cell.inCellLabel.text = @"Haze";
     cell.inCellImage.image = [UIImage imageNamed:@"hazePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 13;
     break;
     
     case 14: // cell.textLabel.text = @"lum remove 14";
     
     cell.inCellLabel.text = @"Lum remove 14";
     cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 14;
     break;
     case 15: // cell.textLabel.text = @"Threshold";
     
     cell.inCellLabel.text = @"Threshold";
     cell.inCellImage.image = [UIImage imageNamed:@"thresholdPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 15;
     break;
     case 16: //cell.textLabel.text = @"Adaptive threshold";
     
     cell.inCellLabel.text = @"Adaptive Threshold";
     cell.inCellImage.image = [UIImage imageNamed:@"adaptiveThresholdPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 16;
     break;
     case 17: //cell.textLabel.text = @"Average luminance threshold";
     
     cell.inCellLabel.text = @"Average Luminance";
     cell.inCellImage.image = [UIImage imageNamed:@"averageLuminPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 17;
     break;
     case 18: //cell.textLabel.text = @"Transform (3-D)";
     
     cell.inCellLabel.text = @"Transform 3D";
     cell.inCellImage.image = [UIImage imageNamed:@"3dPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 18;
     break;
     case 19: //cell.textLabel.text = @"Color invert";
     
     cell.inCellLabel.text = @"Color Invert";
     cell.inCellImage.image = [UIImage imageNamed:@"invertPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 19;
     break;
     case 20: //cell.textLabel.text = @"Grayscale";
     
     cell.inCellLabel.text = @"Grayscale";
     cell.inCellImage.image = [UIImage imageNamed:@"grayscalePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 20;
     break;
     case 21: //cell.textLabel.text = @"Sepia tone";
     
     cell.inCellLabel.text = @"Sepia Tone";
     cell.inCellImage.image = [UIImage imageNamed:@"sepiaPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 21;
     break;
     case 22: //cell.textLabel.text = @"Pixellate";
     
     cell.inCellLabel.text = @"Pixellate";
     cell.inCellImage.image = [UIImage imageNamed:@"pixellaePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 22;
     break;
     case 23: //cell.textLabel.text = @"Polar pixellate";
     
     cell.inCellLabel.text = @"Polor Pixellate";
     cell.inCellImage.image = [UIImage imageNamed:@"polarPixelPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 23;
     break;
     case 24:// cell.textLabel.text = @"Pixellate (position)";
     
     cell.inCellLabel.text = @"Pixellate position";
     cell.inCellImage.image = [UIImage imageNamed:@"PixellatePositionPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 24;
     break;
     case 25: //cell.textLabel.text = @"Polka dot";
     
     cell.inCellLabel.text = @"Polka Dot";
     cell.inCellImage.image = [UIImage imageNamed:@"polkaDotPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 25;
     break;
     case 26: //cell.textLabel.text = @"Halftone";
     
     cell.inCellLabel.text = @"Halftone";
     cell.inCellImage.image = [UIImage imageNamed:@"halftonePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was =26;
     break;
     case 27: //cell.textLabel.text = @"Crosshatch";
     cell.inCellLabel.text = @"Crosshatch";
     cell.inCellImage.image = [UIImage imageNamed:@"crosshatchPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 27;
     break;
     case 28: //cell.textLabel.text = @"Canny edge detection";
     
     cell.inCellLabel.text = @"Edge Detect 1";
     cell.inCellImage.image = [UIImage imageNamed:@"cannyedgePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 28;
     break;
     case 29: //cell.textLabel.text = @"Threshold edge detection";
     
     
     cell.inCellLabel.text = @"Edge Detect 2";
     cell.inCellImage.image = [UIImage imageNamed:@"thresholdedgePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was =29;
     break;
     case 30: //cell.textLabel.text = @"XY derivative";
     
     cell.inCellLabel.text = @"xy remove 30";
     cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 30;
     break;
     case 31: //cell.textLabel.text = @"Image buffer";
     
     cell.inCellLabel.text = @"buffer REMOVE 31";
     cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 31;
     break;
     case 32: //cell.textLabel.text = @"Sketch";
     
     cell.inCellLabel.text = @"Sketch";
     cell.inCellImage.image = [UIImage imageNamed:@"sketchPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 32;
     break;
     case 33: //cell.textLabel.text = @"Threshold Sketch";
     cell.inCellLabel.text = @"Sketch 2";
     cell.inCellImage.image = [UIImage imageNamed:@"thresholdSketchPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 33;
     break;
     case 34: //cell.textLabel.text = @"Toon";
     cell.inCellLabel.text = @"REMOVE TOON 34";
     cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 34;
     break;
     case 35: //cell.textLabel.text = @"Smooth toon";
     cell.inCellLabel.text = @"Toon";
     cell.inCellImage.image = [UIImage imageNamed:@"smoothToonPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 35;
     break;
     case 36: //cell.textLabel.text = @"Tilt shift";
     cell.inCellLabel.text = @"Tilt Shift";
     cell.inCellImage.image = [UIImage imageNamed:@"tiltshiftPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 36;
     break;
     case 37: //cell.textLabel.text = @"CGA colorspace";
     cell.inCellLabel.text = @"CGA Colorspace";
     cell.inCellImage.image = [UIImage imageNamed:@"cgaColorPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 37;
     break;
     case 38: //cell.textLabel.text = @"Emboss";
     cell.inCellLabel.text = @"Emboss";
     cell.inCellImage.image = [UIImage imageNamed:@"embossPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 38;
     break;
     case 39: //cell.textLabel.text = @"Laplacian";
     cell.inCellLabel.text = @"REMOVE LAP 39";
     cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 39;
     break;
     case 40: //cell.textLabel.text = @"Posterize";
     cell.inCellLabel.text = @"Posterize";
     cell.inCellImage.image = [UIImage imageNamed:@"posterizePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 40;
     break;
     case 41: //cell.textLabel.text = @"Swirl";
     cell.inCellLabel.text = @"Swirl";
     cell.inCellImage.image = [UIImage imageNamed:@"swirlPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 41;
     break;
     case 42: //cell.textLabel.text = @"Bulge";
     cell.inCellLabel.text = @"Bulge";
     cell.inCellImage.image = [UIImage imageNamed:@"bulgePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 42;
     break;
     case 43: //cell.textLabel.text = @"Pinch";
     cell.inCellLabel.text = @"Pinch";
     cell.inCellImage.image = [UIImage imageNamed:@"pinchPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 43;
     break;
     case 44: //cell.textLabel.text = @"Stretch";
     cell.inCellLabel.text = @"Stretch";
     cell.inCellImage.image = [UIImage imageNamed:@"stretchPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 44;
     
     break;
     case 45: //cell.textLabel.text = @"Dilation";
     
     cell.inCellLabel.text = @"Dilation";
     cell.inCellImage.image = [UIImage imageNamed:@"dilatePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 45;
     break;
     case 46: //cell.textLabel.text = @"Erosion";
     cell.inCellLabel.text = @"Erosion";
     cell.inCellImage.image = [UIImage imageNamed:@"erosionPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 46;
     break;
     case 47: //cell.textLabel.text = @"Local binary pattern";
     cell.inCellLabel.text = @"Local Binary Pattern";
     cell.inCellImage.image = [UIImage imageNamed:@"localBinaryPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 47;
     break;
     case 48: //cell.textLabel.text = @"Vignette";
     cell.inCellLabel.text = @"Vignette";
     cell.inCellImage.image = [UIImage imageNamed:@"vignettePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 48;
     break;
     case 49: //cell.textLabel.text = @"Gaussian blur";
     cell.inCellLabel.text = @"Gaussian Blur";
     cell.inCellImage.image = [UIImage imageNamed:@"gaussianPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 49;
     break;
     case 50: //cell.textLabel.text = @"Motion blur";
     cell.inCellLabel.text = @"REMOVE MOTION BLUR 50";
     cell.inCellImage.image = [UIImage imageNamed:@"contrastPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 50;
     break;
     case 51: //cell.textLabel.text = @"Zoom blur";
     
     cell.inCellLabel.text = @"Zoom Blur";
     cell.inCellImage.image = [UIImage imageNamed:@"zoomBlurPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 51;
     break;
     case 52:// cell.textLabel.text = @"Gaussian selective blur";
     cell.inCellLabel.text = @"Gaussian blur 2";
     cell.inCellImage.image = [UIImage imageNamed:@"gaussianSelectivePreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 52;
     break;
     case 53: //cell.textLabel.text = @"Gaussian (centered)";
     cell.inCellLabel.text = @"Gaussian Centered";
     cell.inCellImage.image = [UIImage imageNamed:@"gaussianCenteredPreview.png"];
     cell.inCellImage.layer.cornerRadius = 5;
     cell.inCellImage.layer.masksToBounds = YES;
     chosen_Filter_Was = 53;
     
     break;
     }
     */
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*   ShowcaseFilterViewController *filterViewController = [[ShowcaseFilterViewController alloc] initWithFilterType:indexPath.row];
     [self.navigationController pushViewController:filterViewController animated:YES];
     */
    // [self newFilterSelected:indexPath];
    
    switch ([indexPath row]) {
        case 0:
            chosen_Filter_Was = 2;
            break;
        case 1:
            chosen_Filter_Was = 1;
            break;
        case 2:
            chosen_Filter_Was = 48;
            break;
        case 3:
            chosen_Filter_Was = 3;
            break;
        case 4:
            chosen_Filter_Was = 4;
            break;
        case 5:
            chosen_Filter_Was = 10;
            break;
        case 6:
            chosen_Filter_Was = 12;
            break;
        case 7:
            chosen_Filter_Was = 13;
            break;
        case 8:
            chosen_Filter_Was = 45;
            break;
        case 9:
            chosen_Filter_Was = 46;
            break;
       
        default:
            break;
    }
  
    
    
   
     
     NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chosen_Filter_Was] forKey:@"someKey"];
     [[NSNotificationCenter defaultCenter] postNotificationName: @"TestNotification" object:nil userInfo:userInfo];
     
     [self dismissViewControllerAnimated:YES completion:nil];
     
}

-(void)newFilterSelected:(NSIndexPath *)indexPath{
    
    //if ([self.delegate respondsToSelector:@selector(newFilterSelected:)]) {
    // [delegate newFilterSelected:indexPath];
    
    // [self.delegate amountEntered:4];
    //[self dismissViewControllerAnimated:YES completion:nil];
}
@end