

#import "GPUImage.h"

#import "SDDrawingViewController.h"
#import "SDDrawingLayer.h"
#import "NSString+UUID.h"
#import "UIAlertView+BlocksKit.h"
#import "MBProgressHUD.h"
#import "UIActionSheet+BlocksKit.h"
#import "SDLayersViewController.h"
#import "SDToolSettingsViewController.h"
#import "SDDrawingToolsViewController.h"
#import "SDLineWidthViewController.h"
#import "SDTransparencyViewController.h"
#import "SDFontSizeViewController.h"
#import "UIImage+Tint.h"
#import "SDColorPickerViewController.h"
#import <Twitter/Twitter.h>
#import "SDRectangleStrokeTool.h"
#import "SDToolSettings.h"
#import "SDEllipseStrokeTool.h"
#import "SDLineTool.h"
#import "SDPhotoTool.h"
#import "SDEraserTool.h"
#import "SDPenTool.h"
#import "SDRectangleFillTool.h"
#import "SDEllipseFillTool.h"
#import "SDTextTool.h"
#import "FSDirectoryViewController.h"
#import "NSFileManager+DirectoryInfo.h"
#import "NSString+FileSize.h"
#import "SDDrawingFileNames.h"
#import "SDMapViewController.h"
#import "SDFillTool.h"
#import "SDBrushTool.h"
#import "ShowcaseFilterListController.h"
#import "SDfilterlistViewController.h"

@interface SDDrawingViewController () < UIImagePickerControllerDelegate, UINavigationControllerDelegate, SDLayersViewControllerDelegate, SDToolSettingsViewControllerDelegate, SDDrawingToolsViewControllerDelegate, SDLineWidthViewControllerDelegate, SDTransparencyViewControllerDelegate, SDFontSizeViewControllerDelegate, SDColorPickerViewControllerDelegate, MFMailComposeViewControllerDelegate, SDMapViewControllerDelegate, UITextFieldDelegate>

#pragma mark - IBOutlets

@property (strong, nonatomic) IBOutlet UIView *layerContainerView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *drawingToolButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *importButton;
@property (strong, nonatomic) IBOutlet UIButton *color1Button;
@property (strong, nonatomic) IBOutlet UIButton *color2Button;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *folderViewButton;
@property (strong, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (strong, nonatomic) IBOutlet UILabel *toolTitleLabel;

#pragma mark - Properties

@property (strong) UIPopoverController *popoverController;

#pragma mark - Layers handling

@property (strong) NSMutableArray *layers;
@property (readonly, strong) UIImageView *activeImageView;
@property (assign) int activeLayerIndex;

#pragma mark - Tool settings

@property (strong) SDToolSettings *toolSettings;

#pragma mark - Undo stack

@property (assign) int undoStackLocation;
@property (assign) int undoStackCount;

#pragma mark - Tracking touch

@property (assign) CGPoint lastPoint;

#pragma mark - Drawing

@property (assign) BOOL isNewDrawing;
@property (copy) NSString* drawingTitle;

#pragma mark - Drawing tools

@property (strong) SDPhotoTool *photoTool;
@property (strong) NSMutableArray *drawingTools;
@property (weak) GPUImageFilter *filter;
@end


@implementation SDDrawingViewController 
@synthesize uiUndoButton = _uiUndoButton;
@synthesize popoverController = __popoverViewController;
@synthesize filter = _filter;
@synthesize curPreFilteredImage;

-(void)amountEntered:(NSInteger)amount{
    
   // NSLog(@"here it issss %d",amount);
}

- (void)dismissCurrentPopover
{
    if (self.popoverController) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
    self.popoverController = nil;
}

#pragma mark - Populating views

- (void)updateFileSizeLabel {
    
    NSString *undoFilesPath = [self undoFilesDirectory];
    NSString *drawingFilesPath = [self photoDirectory];
    
    long fileCount = 0;
    long undoFilesSize = 0;
    long drawingFilesSize = 0;
    
    [NSFileManager subFileCount:&fileCount andSubFileSize:&undoFilesSize forDirectory:undoFilesPath];      
    [NSFileManager subFileCount:&fileCount andSubFileSize:&drawingFilesSize forDirectory:drawingFilesPath];
    
    drawingFilesSize -= undoFilesSize;    
    
    self.fileSizeLabel.text = [NSString stringWithFormat:@"Drawing files: %@, Undo files: %@", [NSString stringWithFileSize:drawingFilesSize], [NSString stringWithFileSize:undoFilesSize]];
    
}

- (void)setupViewBackground {
    
    UIImage *bgImage = [UIImage imageNamed:@"whitepl.png"];
    UIColor *color = [UIColor colorWithPatternImage:bgImage];
    self.view.backgroundColor = color;
    
}

- (void)updateDrawingToolButton
{
    SDDrawingTool *tool = [self activeTool];;
    self.drawToolButton.image = [UIImage imageNamed:tool.imageName];
}

- (void)updateDrawingToolTitle
{
    self.toolTitleLabel.text = self.toolSettings.drawingTool;
}

- (void)updateColorButtons {
    
    [self.color1Button setImage:[UIImage imageNamed:@"color-palette-mini-white.png" withTint:self.toolSettings.primaryColor] forState:UIControlStateNormal];
    [self.color2Button setImage:[UIImage imageNamed:@"color-palette-mini-white.png" withTint:self.toolSettings.secondaryColor] forState:UIControlStateNormal];
    
}

- (void)updateFileInfoControls {
    
    BOOL showFolderViewButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"FILE_SYSTEM_VIEW"];
    if (!showFolderViewButton) {
        [self removeFolderViewButton];
        self.fileSizeLabel.hidden = YES;
    }
    
}

- (void)removeFolderViewButton {
    
    NSMutableArray *newToolBarArray = [self.topToolbar.items mutableCopy];
    [newToolBarArray removeObject:self.folderViewButton];
    
    [self.topToolbar setItems:[@[newToolBarArray] objectAtIndex:0] animated:NO];
    
}

- (void)updateDrawingTitle {
    
    if (self.drawingTitle.length > 0) {
        [self.titleButton setTitle:self.drawingTitle forState:UIControlStateNormal];
    } else {
        [self.titleButton setTitle:@"Tap to add title" forState:UIControlStateNormal];
    }
    
}

#pragma mark - Orientation support for iOS 5

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    //force portrait for iPhone and landscape for iPad
    return (((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && ((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight))) || (orientation == UIInterfaceOrientationPortrait));
}

#pragma mark - Drawing sharing

- (void)shareDrawingWithActivityView:(UIImage*)imageToShare {

    UIActivityViewController *viewController = [[UIActivityViewController alloc] initWithActivityItems:@[imageToShare] applicationActivities:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        [self dismissCurrentPopover];
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
        [self.popoverController presentPopoverFromBarButtonItem:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        
        [self presentViewController:viewController animated:YES completion:nil];
        
    }

}

// support for iOS 5 - no UIActivityViewController available
- (void)shareDrawingWithActionSheet:(UIImage*)imageToShare {    
    
    UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"How would you like to share the current drawing?"];
    [sheet setDestructiveButtonWithTitle:@"Send with Mail" handler:^{
        if ([MFMailComposeViewController canSendMail]) {            
            [self shareDrawingWithMail:imageToShare];            
        } else {            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"You can't send an email right now. Make sure your device has an Internet connection and you have at least one email account setup."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    [sheet setDestructiveButtonWithTitle:@"Share with Twitter" handler:^{
        
        if([TWTweetComposeViewController canSendTweet])
        {

        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                            message:@"You can't send a tweet right now. Make sure your device has an Internet connection and you have at least one Twitter account setup."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
    }];
    [sheet setDestructiveButtonWithTitle:@"Save to Camera Roll" handler:^{
        
        UIImageWriteToSavedPhotosAlbum(imageToShare, nil, nil, nil);
        
    }];
    [sheet setDestructiveButtonWithTitle:@"Copy to Clipboard" handler:^{
        
        [UIPasteboard generalPasteboard].image = imageToShare;
        
    }];
    [sheet setCancelButtonWithTitle:@"Cancel" handler:nil];
    [sheet setDestructiveButtonIndex:-1];
    [sheet showInView:self.view];
    
}

- (void)shareDrawingWithTwitter:(UIImage*)imageToShare {
    
    TWTweetComposeViewController *tweetComposer = [[TWTweetComposeViewController alloc] init];
    [tweetComposer addImage:imageToShare];
    tweetComposer.completionHandler = ^(TWTweetComposeViewControllerResult result){
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:tweetComposer animated:YES completion:nil];
    
}

- (void)shareDrawingWithMail:(UIImage*)imageToShare {
    
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    composer.mailComposeDelegate = self;
    
    UIImage *flatImage = [self getFlattenedImageOfDrawing];
    NSData *imageData = UIImagePNGRepresentation(flatImage);
    [composer addAttachmentData:imageData mimeType:@"image/png" fileName:@"Drawing.png"];
    
    [self presentViewController:composer animated:YES completion:nil];
    
}

#pragma mark - Alerts, Sheets, HUDs

- (void)showImportPrompt {
    
    [self dismissCurrentPopover];
    
    
    
    UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"What would you like to import?"];
    [sheet addButtonWithTitle:@"Import Photo" handler:^{
         if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]){
        [self showPhotoPrompt];
         }
    }];
     
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]){
        
    
    [sheet addButtonWithTitle:@"Take Photo" handler:^{
        
       // [self performSegueWithIdentifier:@"MapViewSegue" sender:nil];
        [self showTakePhotoPrompt];
        
    }];
    }
    [sheet setCancelButtonWithTitle:@"Cancel" handler:nil];
    [sheet showInView:self.view];
    
}



-(void)showTakePhotoPrompt{
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.allowsEditing = YES;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        [self.popoverController presentPopoverFromBarButtonItem:self.importButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    
}

- (void)showPhotoPrompt {
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = YES;
  
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {        
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
        [self.popoverController presentPopoverFromBarButtonItem:self.importButton permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else {
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
    
}

- (void)showInfoHUD:(NSString*)message {
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    
    // Set custom view mode
    hud.mode = MBProgressHUDModeCustomView;
    
    hud.labelText = message;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud show:YES];
    [hud hide:YES afterDelay:2.0];
    
}

#pragma mark - Directory paths

- (NSString*)drawingsDirectory {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask ,YES);
    NSString *documentsDirectory = paths[0];
    NSString *drawingsDirectory = [documentsDirectory stringByAppendingPathComponent:kSDFileDrawingsDirectory];
    return drawingsDirectory;

}

- (NSString*)photoDirectory {
    
    NSString *photoDirectory = [[self drawingsDirectory] stringByAppendingPathComponent:self.drawingID];
    return photoDirectory;
    
}

- (NSString*)undoFilesDirectory {
    
    NSString *undoFilesDirectory = [[self photoDirectory] stringByAppendingPathComponent:@"undo"];
    return undoFilesDirectory;
    
}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField*)textField {
    
    self.drawingTitle = self.titleTextField.text;
    [self updateDrawingTitle];
    self.titleTextField.hidden = YES;
    self.titleButton.hidden = NO;
    
}

//UITextField Done button
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    
    [self.titleTextField resignFirstResponder];
    return YES;
    
}

#pragma mark - IBActions

- (IBAction)titleButtonTapped:(id)sender {
    
    self.titleButton.hidden = YES;
    self.titleTextField.text = self.drawingTitle;
    self.titleTextField.hidden = NO;
    [self.titleTextField becomeFirstResponder];
    
}

- (IBAction)folderViewTapped:(id)sender {
    
    //instantiate the view controller
    NSBundle *bundle = [NSBundle bundleForClass:[FSDirectoryViewController class]];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FSFileSystemView" bundle:bundle];
    UINavigationController *navigationController = [storyboard instantiateInitialViewController];
    FSDirectoryViewController *viewController = (FSDirectoryViewController*)navigationController.topViewController;
    
    //set properties on the view controller
    viewController.rootPath = [self drawingsDirectory];
    viewController.rootPathTitle = @"All Drawings";
    viewController.startingPath = [self photoDirectory];
    viewController.navigationItem.title = @"Drawing Contents";
    
    //present the view controller
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
        [self dismissCurrentPopover];
        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        [self.popoverController presentPopoverFromBarButtonItem:self.folderViewButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }
    
}

- (IBAction)swapColorsTapped:(id)sender {
    
    UIColor* tmpColor = self.toolSettings.primaryColor;
    self.toolSettings.primaryColor = self.toolSettings.secondaryColor;
    self.toolSettings.secondaryColor = tmpColor;
    
    [self updateColorButtons];
    
}

- (IBAction)cancelDrawingTapped:(id)sender {
   
    
    
    UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"Leave This Drawing Project?"];
    [sheet setDestructiveButtonWithTitle:@"Yes I am sure" handler:^{
        
        
        if (self.isNewDrawing) {
            [self deleteCurrentDrawing];
        }
        [self.delegate viewControllerDidCancelDrawing:self];
        
    }];
    [sheet setCancelButtonWithTitle:@"Cancel" handler:nil];
    [sheet showInView:self.view];
    
}

- (IBAction)deleteDrawingTapped:(id)sender {
    
    UIActionSheet *sheet = [UIActionSheet actionSheetWithTitle:@"Delete the current drawing?"];
    [sheet setDestructiveButtonWithTitle:@"Delete Drawing" handler:^{
        
        [self deleteCurrentDrawing];
        [self.delegate viewControllerDidSaveDrawing:self];
        
    }];
    [sheet setCancelButtonWithTitle:@"Cancel" handler:nil];
    [sheet showInView:self.view];
    
}

- (IBAction)shareDrawingTapped:(id)sender {
    
    UIImage *imageToShare = [self getFlattenedImageOfDrawing];
    
    if ([UIActivityViewController class]) {
        [self shareDrawingWithActivityView:imageToShare];
    } else {
        [self shareDrawingWithActionSheet:imageToShare];        
    }
    
}

- (IBAction)saveDrawingTapped:(id)sender {
    
    [self saveCurrentDrawing];    
    [self.delegate viewControllerDidSaveDrawing:self];
    
}

- (IBAction)undoActionTapped:(id)sender {
    // rezadd
  /*
    if (curPreFilteredImage != nil) {
        
    
    self.activeImageView.image = curPreFilteredImage;
    }
    
   */ 
     [self undoDrawingStep];
}

- (IBAction)redoActionTapped:(id)sender {
    
    [self redoDrawingStep];
    
}

- (IBAction)importTapped:(id)sender {
    
    [self showImportPrompt];
    
}

#pragma mark - Seugue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"ToolSettingsSegue"]) {
        
        SDToolSettingsViewController *viewController = (SDToolSettingsViewController*)((UINavigationController*)segue.destinationViewController).topViewController;
        viewController.tool = self.toolSettings.drawingTool;
        viewController.drawingTools = self.drawingTools;
        viewController.color1 = self.toolSettings.primaryColor;
        viewController.color2 = self.toolSettings.secondaryColor;
        viewController.lineWidth = self.toolSettings.lineWidth;
        viewController.transparency = self.toolSettings.transparency;
        viewController.fontSize = self.toolSettings.fontSize;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"LayersSegue"]) {
        
        SDLayersViewController *viewController = (SDLayersViewController*)((UINavigationController*)segue.destinationViewController).topViewController;
        viewController.layers = self.layers;
        viewController.activeLayerIndex = self.activeLayerIndex;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"DrawingToolsSegue"]) {
        
        SDDrawingToolsViewController *viewController = (SDDrawingToolsViewController*)((UINavigationController*)segue.destinationViewController).topViewController;
        viewController.tool = self.toolSettings.drawingTool;
        viewController.drawingTools = self.drawingTools;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"LineWidthSegue"]) {
        
        SDLineWidthViewController *viewController = (SDLineWidthViewController*)segue.destinationViewController;
        viewController.lineWidth = self.toolSettings.lineWidth;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"TransparencySegue"]) {
        
        SDTransparencyViewController *viewController = (SDTransparencyViewController*)segue.destinationViewController;
        viewController.transparency = self.toolSettings.transparency;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"FontSizeSegue"]) {
        
        SDFontSizeViewController *viewController = (SDFontSizeViewController*)segue.destinationViewController;
        viewController.fontSize = self.toolSettings.fontSize;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"ColorPickerSegue"]) {
        
        SDColorPickerViewController *viewController = (SDColorPickerViewController*)segue.destinationViewController;
        viewController.color = self.toolSettings.primaryColor;
        viewController.tag = 1;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"Color2PickerSegue"]) {
        
        SDColorPickerViewController *viewController = (SDColorPickerViewController*)segue.destinationViewController;
        viewController.color = self.toolSettings.secondaryColor;
        viewController.tag = 2;
        viewController.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"MapViewSegue"]) {
        SDMapViewController *viewController = (SDMapViewController*)segue.destinationViewController;
        viewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"filterListSegue"]){
        
       curPreFilteredImage = [self.activeImageView image];
       // SDfilterlistViewController *viewController =(SDfilterlistViewController *)segue.destinationViewController;
       
    
        
        
        NSLog(@"that seg");
    }
    
    //save reference to popopver controller
    if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
        
        [self dismissCurrentPopover];
        self.popoverController = ((UIStoryboardPopoverSegue*)segue).popoverController;
        
    }
    
}


-(void)receiveTestNotification:(NSNotification *) notification{
    
    NSLog(@"well that worked");
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *userValue = [userInfo objectForKey:@"someKey"];
    if ([userValue intValue] == 2000) {
        moverViewActive = YES;
        [self showMoveViewerAnimation];
    }else{
  // filterType = [userInfo objectForKey:@"someKey"];
    [self newFilterSelected:[userInfo objectForKey:@"someKey"]];
    [self showFxAnimation];
    }
}

-(void) showMoveViewerAnimation {
    
    moverViewButtonActive = 1;
    self.moveViewLabel.text = @"Pinch image to Scale";
    [self.scaleButtonUiLook setHighlighted:YES];
    [self.positionButtonUILook setHighlighted:NO];
    [self.rotateButtonUILook setHighlighted:NO];
    
    self.scaleHolderImage = self.activeImageView.image;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.65];
    [self.moverView setFrame:CGRectMake(0.0f, [UIScreen mainScreen].bounds.size.height - 140,320.0f , 150.0f)];
    [UIView commitAnimations];
    
    
    
}

-(void) hideMoveViewerAnimation {
    self.moveViewLabel.text = @"Pinch Image to Scale";
    moverViewButtonActive = 1;
    
    [UIView animateWithDuration:1.0 animations:^{
        
        [self.moverView setFrame:CGRectMake(0.0f, 1200.0f, 320.0f, 150.0f)];
        
        //= CGRectMake(0, 1200, 320, 200);
    }];
    
    
}









-(void) showFxAnimation {
    
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.65];
     [self.sliderFxSubView setFrame:CGRectMake(0.0f, [UIScreen mainScreen].bounds.size.height - 150,320.0f , 150.0f)];
    [UIView commitAnimations];
    
       
    
}

-(void) hideFxAnimation {
    
    [UIView animateWithDuration:1.0 animations:^{
        
        [self.sliderFxSubView setFrame:CGRectMake(0.0f, 1200.0f, 320.0f, 150.0f)];
        
        //= CGRectMake(0, 1200, 320, 200);
    }];
    
    
}


#pragma mark - SDMapViewController delegate

- (void)viewController:(SDMapViewController *)viewController wasDismissed:(BOOL)success {
    
    if (success) {
        self.photoTool.photo = [viewController imageOfMap];
        
        [self showInfoHUD:@"Trace a destination rectangle"];
    }
    
}

#pragma mark - MKMailComposerViewController delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - SDColorPickerViewController delegate

- (void)viewController:(SDColorPickerViewController *)viewController didPickColor:(UIColor *)color {
    
    if (viewController.tag == 2) {
        self.toolSettings.secondaryColor = color;
    } else {
        self.toolSettings.primaryColor = color;
    }
    
    [self updateColorButtons];
    
}

#pragma mark - SDLineWidthViewController delegate

- (void)viewController:(SDLineWidthViewController *)viewController didPickWidth:(int)lineWidth {
    
    self.toolSettings.lineWidth = lineWidth;
    
}

#pragma mark - SDTransparencyViewController delegate

- (void)viewController:(SDTransparencyViewController *)viewController didPickTransparency:(int)transparency {
    
    self.toolSettings.transparency = transparency;
    
}

#pragma mark - SDFontSizeViewController delegate

- (void)viewController:(SDFontSizeViewController *)viewController didPickFontSize:(int)fontSize {
    
    self.toolSettings.fontSize = fontSize;
    
}

#pragma mark - SDDrawingToolsViewController delegate

- (void)viewController:(SDDrawingToolsViewController *)viewController didPickTool:(NSString *)tool
{    
    self.toolSettings.drawingTool = tool;
    
    //cancel importing photo
    self.photoTool.photo = nil;
    
    [self updateDrawingToolButton];
    [self updateDrawingToolTitle];
    
    [self dismissCurrentPopover];    
}

#pragma mark - SDToolSettingsViewController delegate

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickTool:(NSString*)tool
{    
    self.toolSettings.drawingTool = tool;
    
    //cancel importing photo
    self.photoTool.photo = nil;
    
    [self updateDrawingToolButton];
    [self updateDrawingToolTitle];
}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickColor1:(UIColor*)color {
    
    self.toolSettings.primaryColor = color;

}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickColor2:(UIColor*)color {
    
    self.toolSettings.secondaryColor = color;

}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickWidth:(int)lineWidth {
    
    self.toolSettings.lineWidth = lineWidth;
    
}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickTransparency:(int)transparency {
    
    self.toolSettings.transparency = transparency;
    
}

- (void)settingsViewController:(SDToolSettingsViewController*)viewController didPickFontSize:(int)fontSize {
    
    self.toolSettings.fontSize = fontSize;
    
}

#pragma mark - SDLayersViewController delegate

- (void)viewController:(SDLayersViewController*)viewController didRenameLayer:(SDDrawingLayer*)layer {
        
}

- (void)viewController:(SDLayersViewController*)viewController didDeleteLayer:(SDDrawingLayer*)layer {
   
   [layer.imageView removeFromSuperview];
    
   /*
    [self addDrawingToUndoStack];
    
    curPreFilteredImage = self.activeImageView.image;
  //  self.filterSettingsSlider.hidden = YES;
    */
}

- (void)viewController:(SDLayersViewController*)viewController didMoveLayer:(SDDrawingLayer*)layer toIndex:(int)index {
    
    //index in from the end ot the subviews - subview order is oposite of list order
    [self.layerContainerView insertSubview:layer.imageView atIndex:self.layerContainerView.subviews.count - 1 - index];
    //curPreFilteredImage = self.activeImageView.image;
  
    
}

- (void)viewController:(SDLayersViewController*)viewController didAddLayer:(SDDrawingLayer*)layer {
        
    [self initializeNewLayer:layer];    
    self.activeLayerIndex = self.layers.count - 1;
    
    //add to undo stack so undoing a drawing op doesn't also undo the new layer
    //[self addDrawingToUndoStack];
   // curPreFilteredImage = self.activeImageView.image;

    
}

- (void)viewController:(SDLayersViewController*)viewController didActivateLayer:(SDDrawingLayer*)layer {
    
       self.activeLayerIndex = [self.layers indexOfObject:layer];
  
   
}

- (void)viewController:(SDLayersViewController*)viewController didChangeLayerVisibility:(SDDrawingLayer*)layer {
    
    [self setupLayerVisibility:layer];
    
}

- (void)viewController:(SDLayersViewController*)viewController didChangeLayerTransparency:(SDDrawingLayer*)layer {
    
    [self setupLayerVisibility:layer];
    
}

#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
        
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self dismissCurrentPopover];
    }
    else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }    
    
    
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        
         UIGraphicsBeginImageContextWithOptions(self.layerContainerView.bounds.size, NO, [UIScreen mainScreen].scale );
    }else UIGraphicsBeginImageContext(self.layerContainerView.bounds.size);
    
    
    UIImage *holderImage = info[UIImagePickerControllerEditedImage];
    CGSize imageSize = holderImage.size;
    CGSize viewSize = self.layerContainerView.bounds.size; // size in which you want to draw
    
    NSLog(@" %f %f", imageSize.height,imageSize.width);
    
    float hfactor = imageSize.width / viewSize.width;
    float vfactor = imageSize.height / viewSize.height;
    
    float factor = fmax(hfactor, vfactor);
    
    // Divide the size by the greater of the vertical or horizontal shrinkage factor
    float newWidth = imageSize.width / factor;
    float newHeight = imageSize.height / factor;
    float offSetX = (viewSize.width - newWidth) / 2;
    float offSetY = (viewSize.height - newHeight) / 2;
    
    CGRect newRect = CGRectMake(offSetX ,offSetY, newWidth, newHeight);
   // [holderImage drawInRect:newRect];
   
    
    //  UIGraphicsBeginImageContext(self.layerContainerView.bounds.size);
    
    // UIGraphicsBeginImageContextWithOptions(self.layerContainerView.bounds.size, NO, [UIScreen mainScreen].scale);
    
    // reversed as the z-order of the layer image views is the reverse of the layers array order
   
    
    [holderImage drawInRect:newRect];
    
    
    // get a UIImage from the image context
    self.activeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();

  
      self.activeImageView.contentMode = UIViewContentModeScaleAspectFit;
    
       // self.activeImageView.image = info[UIImagePickerControllerEditedImage];
        
       [self addDrawingToUndoStack];
     //   [self getFlattenedImageOfDrawing];
    
}

#pragma mark - File handling - Load / Save / Delete drawings

- (void)initializeDrawing {
    
    if (!self.drawingID) {
        
        [self initializeNewDrawing];
        
    } else {
        [self loadDrawingFromID];
    }
    
    [self addDrawingToUndoStack];
    
    [self updateDrawingTitle];
    
}

- (void)initializeNewDrawing {
    
    self.drawingID = [NSString UUIDString];
    self.isNewDrawing = YES;
    [self addNewLayer];
    
}

- (void)loadDrawingFromID {
    
    NSString *photoDirectory = [self photoDirectory];
    
    [self loadDrawingLayers:photoDirectory];
    [self loadDrawingTitle:photoDirectory];
    
}

- (void)loadDrawingLayers:(NSString*)photoDirectory {
   
    
    NSString *layersFileName = [photoDirectory stringByAppendingPathComponent:kSDFileLayersFile];
    
    self.layers = [[NSKeyedUnarchiver unarchiveObjectWithFile:layersFileName] mutableCopy];
    
    [self.layerContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    //iterate backward, setupImageViewForLayer will add at an inverted z-order
    for (int i = self.layers.count - 1; i >= 0; i--) {
        
        SDDrawingLayer *layer = self.layers[i];
        
        [self setupImageViewForLayer:layer];
        [self setupLayerVisibility:layer];
        
        NSString *layerImageName = [[photoDirectory stringByAppendingPathComponent:layer.layerID] stringByAppendingPathExtension:@"png"];
        
        //don't load with UIImage directly, causes an error saving as we move these files
        layer.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:layerImageName]];
     //rezandchange   layer.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
}

- (void)loadDrawingTitle:(NSString*)photoDirectory {
    
    NSString *textFilePath = [photoDirectory stringByAppendingPathComponent:kSDFileTitleFile];
    self.drawingTitle = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:textFilePath] encoding:NSUTF8StringEncoding error:nil];
    
}

- (void)saveCurrentDrawing {
    
    [self saveDrawingToDirectory:[self photoDirectory] saveFlatCopy:YES];
    
}

- (void)saveDrawingToDirectory:(NSString*)photoDirectory saveFlatCopy:(BOOL)saveFlatCopy {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //backup the current drawing files
    NSString *backupPhotoDirectory = [NSString stringWithFormat:@"%@_bak", photoDirectory];
    [fileManager moveItemAtPath:photoDirectory toPath:backupPhotoDirectory error:nil];
    
    [fileManager createDirectoryAtPath:photoDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    
    [self saveDrawingLayers:photoDirectory];
    [self saveDrawingTitle:photoDirectory];
    
    if (saveFlatCopy) {
        [self saveFlatDrawing:[photoDirectory stringByAppendingPathComponent:kSDFileFlatDrawing]];
    }
    
    //delete the backup drawing files now that drawing is saved
    [fileManager removeItemAtPath:backupPhotoDirectory error:nil];
    
}

- (void)saveFlatDrawing:(NSString*)photoFileName {
    
    UIImage *flatImage = [self getFlattenedImageOfDrawing];
    
  
    
   NSData *photoData = UIImagePNGRepresentation(flatImage);
    [photoData writeToFile:photoFileName atomically:YES];
    
}

- (UIImage*)getFlattenedImageOfDrawing {
    
    // create a new bitmap image context
  //  UIGraphicsBeginImageContext(self.activeImageView.bounds.size);
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(self.activeImageView.bounds.size, NO, [UIScreen mainScreen].scale);
    }else UIGraphicsBeginImageContext(self.activeImageView.bounds.size);
    
 
 //[self.layerContainerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
   // UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRef context = UIGraphicsGetCurrentContext ();
    
    // The color to fill the rectangle (in this case black)
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);
    
    // draw the filled rectangle
    CGContextFillRect (context,self.activeImageView.bounds);
    NSMutableArray *layersCopy = [self.layers mutableCopy];
    // reversed as the z-order of the layer image views is the reverse of the layers array order
    for (int i = layersCopy.count - 1; i >= 0; i--) {
        SDDrawingLayer *layer = (SDDrawingLayer*)layersCopy[i];
        if (layer.visible) {
            [layer.imageView.image drawInRect:layer.imageView.bounds blendMode:kCGBlendModeNormal alpha:1.0 - (layer.transparency / 100.0)];
        }
    }
       
    // get a UIImage from the image context
    UIImage *flatImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return flatImage;
    
}

-(void) myTestCodeRezand:(NSString *)recFilter{
  
    
    NSLog(@"this shouldnt be called anymore rezand test code");
  //  UIImage *rezandFilteredImage =  [[[GPUImageSketchFilter alloc] init] imageByFilteringImage:[self getFlattenedImageOfDrawing] ];
   // self.activeImageView.image = rezandFilteredImage;
    
    
}

- (void)saveDrawingLayers:(NSString*)photoDirectory {
    
    // rezadd
 /*    
    NSString *layersFileName = [photoDirectory stringByAppendingPathComponent:kSDFileLayersFile];
    
    [NSKeyedArchiver archiveRootObject:self.layers toFile:layersFileName];
    
    for (SDDrawingLayer* layer in self.layers) {
        
        
       // UIGraphicsBeginImageContextWithOptions(self.layerContainerView.layer.bounds.size, self.layerContainerView.opaque, [[UIScreen mainScreen] scale]);
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
            UIGraphicsBeginImageContextWithOptions(self.layerContainerView.layer.bounds.size, NO, [UIScreen mainScreen].scale);
        }else UIGraphicsBeginImageContext(self.layerContainerView.layer.bounds.size);
        
        // UIGraphicsBeginImageContextWithOptions(self.layerContainerView.bounds.size, self.layerContainerView.sizeToFit, 0.0);
        [layer.imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
        
        // UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
        
        
       
         // reversed as the z-order of the layer image views is the reverse of the layers array order
         for (int i = self.layers.count - 1; i >= 0; i--) {
         SDDrawingLayer *layer = (SDDrawingLayer*)self.layers[i];
         if (layer.visible) {
         [layer.imageView.image drawInRect:layer.imageView.bounds blendMode:kCGBlendModeNormal alpha:1.0 - (layer.transparency / 100.0)];
         }
         }
        
        // get a UIImage from the image context
        UIImage *flatImage = UIGraphicsGetImageFromCurrentImageContext();
        
        // clean up drawing environment
        
        
       
        
        
        
        
        
        
        NSString *layerImageName = [[photoDirectory stringByAppendingPathComponent:layer.layerID] stringByAppendingPathExtension:@"png"];
       
        
        
        
        NSData *photoData = UIImagePNGRepresentation(flatImage);
        [photoData writeToFile:layerImageName atomically:YES];
        UIGraphicsEndImageContext();
    }
    */
    NSMutableArray *layersCopy = [self.layers mutableCopy];
    NSString *layersFileName = [photoDirectory stringByAppendingPathComponent:kSDFileLayersFile];
    
    [NSKeyedArchiver archiveRootObject:layersCopy toFile:layersFileName];
    
    for (SDDrawingLayer* layer in layersCopy) {
        
        NSString *layerImageName = [[photoDirectory stringByAppendingPathComponent:layer.layerID] stringByAppendingPathExtension:@"png"];
        NSData *photoData = UIImagePNGRepresentation(layer.imageView.image);
        [photoData writeToFile:layerImageName atomically:YES];
        
    }
    
    
}

- (void)saveDrawingTitle:(NSString*)photoDirectory {
    
    NSString *textFilePath = [photoDirectory stringByAppendingPathComponent:kSDFileTitleFile];
    [self.drawingTitle writeToFile:textFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
}

- (void)deleteCurrentDrawing {
        
    [[NSFileManager defaultManager] removeItemAtPath:[self photoDirectory] error:nil];
    
}

#pragma mark - Touch handling

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (moverViewActive == YES) {
        
        if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && moverViewButtonActive == 1 ) {
            
            return YES;
            
        }else if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && moverViewButtonActive == 2){
            return YES;
        }else if ([gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]] && moverViewButtonActive == 3){
            return YES;
        }else return NO;

    }else return NO;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
        return NO;
   
}

-(void)highlightButton:(UIButton *)sender
{
    sender.highlighted = YES;
}

-(void)adjustImagefx
{
    
    
}

- (IBAction)scaleButtonPressed:(UIButton *)sender {
    moverViewButtonActive = 1;
  self.moveViewLabel.text = @"Pinch image to Scale";
    [self.rotateButtonUILook setHighlighted:NO];
    [self.positionButtonUILook  setHighlighted:NO];
   
    [self performSelector:@selector(highlightButton:) withObject:sender afterDelay:0.0];
    self.scaleHolderImage = [self.activeImageView.image copy];
}

- (IBAction)positionButtonTapped:(UIButton *)sender {
  
    moverViewButtonActive = 2;
    [self.scaleButtonUiLook setHighlighted:NO];
    [self.rotateButtonUILook setHighlighted:NO];
    self.moveViewLabel.text = @"Drag Image to Reposition";
  [self performSelector:@selector(highlightButton:) withObject:sender afterDelay:0.0];
   self.scaleHolderImage = [self.activeImageView.image copy];
   

}

- (IBAction)rotateButtonPressed:(UIButton *)sender {
    moverViewButtonActive = 3;
    [self.scaleButtonUiLook setHighlighted:NO];
    [self.positionButtonUILook setHighlighted:NO];
   // [self.positionButtonUILook  setHighlighted:NO];
    self.moveViewLabel.text = @"Use 2 Touches to Rotate";
   [self performSelector:@selector(highlightButton:) withObject:sender afterDelay:0.0];
   self.scaleHolderImage = [self.activeImageView.image copy];
}


- (IBAction)cancelMoveViewPressed:(UIButton *)sender {
    moverViewButtonActive = 1;
    self.moveViewLabel.text = @"Pinch image to Scale";
    moverViewActive = NO;
    [self hideMoveViewerAnimation];
    [self undoDrawingStep];
    
}

- (IBAction)doneMoverViewButtonPressed:(UIButton *)sender {
    // turn off ability to move & scale
    moverViewActive = NO;
    
  //  NSLog(@"%f %f",dragOfficialChange.x,dragOfficialChange.y);
  //  NSLog(@"%f",rotationOfficialChange);
  //  NSLog(@"%f",scalersOfficialChange);
    if (scalersOfficialChange < .5) {
        scalersOfficialChange = 1;
    }
  //  self.activeImageView.image =  [self imageByScalingAndCroppingForSize:CGSizeMake(self.layerContainerView.bounds.size.width, self.layerContainerView.bounds.size.height)];
    
    
    
 
   
    
    
    [self hideMoveViewerAnimation];
    [self addDrawingToUndoStack];
    //resets activeimageview coords
   // CGRect myFrame = CGRectMake(0, 0, self.layerContainerView.frame.size.width, self.layerContainerView.frame.size.height);
   // myFrame.origin.x = 0;
   // myFrame.origin.y = 0;
   // self.activeImageView.frame = myFrame;
    
    //reset changes values
    dragOfficialChange.x = 0;
    dragOfficialChange.y = 0;
    rotationOfficialChange = 0;
    scalersOfficialChange = 0;
    
    moverViewButtonActive = 1;
    self.moveViewLabel.text = @"Pinch image to Scale";

}
#define radians(degrees) (degrees * M_PI/180)

- (IBAction)rotationGest:(UIRotationGestureRecognizer *)sender{
    
 
    
    if ([sender state] == UIGestureRecognizerStateBegan || [sender state] ==
        UIGestureRecognizerStateChanged)
    {
     //  self.activeImageView.transform = CGAffineTransformRotate([self.activeImageView transform],[sender rotation]);
       // rotationOfficialChange = rotationOfficialChange + [sender rotation];
        
        
        CGSize size = CGSizeMake(self.activeImageView.frame.size.width, self.activeImageView.frame.size.height);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // If this is commented out, image is returned as it is.
      CGContextTranslateCTM( context, 0.5f * size.width, 0.5f * size.height ) ;
     CGContextRotateCTM (context, [sender rotation]);
      //  CGContextRotateCTM (context, [sender rotation]);
        
       [self.scaleHolderImage drawInRect:(CGRect){ { -size.width * 0.5f, -size.height * 0.5f }, size } ];
       self.activeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        
        
        
     NSLog(@"Rotate : %f",([sender rotation]* (90 / M_PI)) / 2);
       // [sender setRotation:0];
    }
    
     }

- (IBAction)pinchGest:(UIPinchGestureRecognizer *)sender{
   
    
    if (sender.state == UIGestureRecognizerStateEnded
        || sender.state == UIGestureRecognizerStateChanged) {
        NSLog(@"sender.scale = %f", sender.scale);
        
        CGFloat currentScale = self.activeImageView.frame.size.width / self.activeImageView.bounds.size.width;
        CGFloat newScale = currentScale * sender.scale;
        
        if (newScale < .5) {
            newScale = .5;
        }
        if (newScale > 4) {
            newScale = 4;
        }
        
        CGSize scaleTempSize = CGSizeMake(self.activeImageView.frame.size.width * newScale, self.activeImageView.frame.size.height * newScale);
        
        UIGraphicsBeginImageContextWithOptions(scaleTempSize, NO, 0.0);
        [self.scaleHolderImage drawInRect:CGRectMake(0, 0, self.layerContainerView.bounds.size.width, self.layerContainerView.bounds.size.height)];
       self.activeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
        /*
        CGAffineTransform transform = CGAffineTransformMakeScale(newScale, newScale);
        self.activeImageView.transform = transform;
        scalersOfficialChange = newScale;
        sender.scale = 1;
        */
    }
    
    
    
}

- (IBAction) dragging: (UIPanGestureRecognizer*) p {
  
    //  UIView* vv = self.activeImageView;
    if (p.state == UIGestureRecognizerStateBegan ||
        p.state == UIGestureRecognizerStateChanged) {
        CGPoint delta = [p translationInView: self.activeImageView];
      //  CGPoint c = vv.center;
        NSLog(@"%f %f deltas", delta.x, delta.y);
        dragOfficialChange.x = delta.x;
        dragOfficialChange.y = delta.y;
        
       // vv.center = c;
       // [p setTranslation: CGPointZero inView: vv.superview];
       // dragOfficialChange = self.activeImageView.frame.origin;
        
        
        if (dragOfficialChange.x < -285) {
            dragOfficialChange.x = -285;
        }
        if (dragOfficialChange.x > 285) {
            dragOfficialChange.x = 285;
        }
        
        if (dragOfficialChange.y < -285) {
            dragOfficialChange.y = -285;
        }
        if (dragOfficialChange.y > 285) {
            dragOfficialChange.y = 285;
        }
        
        CGSize newSize = CGSizeMake(self.layerContainerView.frame.size.width , self.layerContainerView.frame.size.height);
        
        
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
        
        
        
        CGRect rectToUSE = CGRectMake(dragOfficialChange.x, dragOfficialChange.y, self.layerContainerView.bounds.size.width, self.layerContainerView.bounds.size.height);
        
        //[self.activeImageView.image drawAsPatternInRect:rectToUSE];
        [self.scaleHolderImage drawInRect:rectToUSE];
        
        
        self.activeImageView.image = UIGraphicsGetImageFromCurrentImageContext();
        
        
        UIGraphicsEndImageContext();
        
    }
   
}


- (BOOL)shouldTrackTouch:(UITouch*)touch {
    
    //don't track when showing map view
    if (self.presentedViewController) {
        return NO;
    }
    
    CGPoint touchLocation = [touch locationInView:self.layerContainerView];
    if ((touchLocation.y < 0) || (touchLocation.y > self.layerContainerView.frame.size.height)) {
        return NO;
    }
    
    return YES;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
     if (moverViewActive == NO) {
         //do not respond to touch if the title UITextField is visible
    if (self.titleTextField && !self.titleTextField.hidden) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    
    if (![self shouldTrackTouch:touch]) {
        return;
    }
    
    if ([self tracingPhotoDestination]) {
        
        [self.photoTool touchBegan:touch inImageView:self.activeImageView withSettings:self.toolSettings];
        
    } else {
       
            
       
        SDDrawingTool *drawingTool = [self activeTool];
        if (drawingTool) {
            [drawingTool touchBegan:touch inImageView:self.activeImageView withSettings:self.toolSettings];
        }
        }
        
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //do not respond to touch if the title UITextField is visible
    if (self.titleTextField && !self.titleTextField.hidden) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    
    if (![self shouldTrackTouch:touch]) {
        return;
    }
    
    if ([self tracingPhotoDestination]) {
        
        [self.photoTool touchMoved:touch];
        
    } else if (moverViewActive == NO){
        
        SDDrawingTool *drawingTool = [self activeTool];
        if (drawingTool) {
            [drawingTool touchMoved:touch];
        }
        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //do not respond to touch if the title UITextField is visible
    if (self.titleTextField && !self.titleTextField.hidden) {
        //resign first responder status for title UITextField
        [self.titleTextField resignFirstResponder];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    
    if (![self shouldTrackTouch:touch]) {
        return;
    }
    
    if ([self tracingPhotoDestination]) {
        
        [self.photoTool touchEnded:touch];
        
    } else if (moverViewActive == NO){
        
        SDDrawingTool *drawingTool = [self activeTool];
        if (drawingTool) {
            
            [drawingTool touchEnded:touch];
            
        }
        
    }
    
}

#pragma mark - Undo stack

// add the current drawing to the undo stack
- (void)addDrawingToUndoStack {
  
    NSString *undoFilesDirectory = [self undoFilesDirectory];
    NSString *undoFileDirectory = [undoFilesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", ++self.undoStackLocation]];
        
    self.undoStackCount = self.undoStackLocation + 1;
       
   
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        //this will run on a background thread
        [[NSFileManager defaultManager] createDirectoryAtPath:undoFileDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
        
        [self saveDrawingToDirectory:undoFileDirectory saveFlatCopy:NO];
        
        //dispatch async to keep UI responsive
        dispatch_async(dispatch_get_main_queue(), ^{
            //this will run on the main thread
            [self updateFileSizeLabel];
        });
        
    });
   
}

// load the image for the current undo stack position
- (BOOL)loadImageFromUndoStack {
    
    NSString *undoFilesDirectory = [self undoFilesDirectory];
    NSString *undoFileDirectory = [undoFilesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", self.undoStackLocation]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:undoFileDirectory]) {
        [self loadDrawingLayers:undoFileDirectory];
        self.activeLayerIndex = 0;
        return YES;
    } else {
        return NO;
    }
    
}

- (void)undoDrawingStep {
    
    if (self.undoStackLocation > 0) {
        self.undoStackLocation--;
        
        if (self.isNewDrawing && (self.undoStackLocation == 0)) {
            //if this is a new drawing and we've undone to location 0, clear the image
            //we don't have a 0.png as we started with an empty drawing
            self.activeImageView.image = nil;
        } else if (![self loadImageFromUndoStack]) {
            //rever to old location if there was no undo image
            self.undoStackLocation++;
        }
    }
    
}

- (void)redoDrawingStep {
    
    if (self.undoStackLocation < self.undoStackCount - 1) {
        self.undoStackLocation++;
        
        if (![self loadImageFromUndoStack]) {
            //rever to old location if there was no undo image
            self.undoStackLocation--;
        }
    }
    
}

- (void)resetUndoStack {
    
    [self deletePersistedUndoCopies];
    self.undoStackLocation = -1;
    self.undoStackCount = 0;
    
}

// clear the undo stack contents persisted to file
- (void)deletePersistedUndoCopies {
    
    NSString *undoFilesDirectory = [self undoFilesDirectory];
    
    [[NSFileManager defaultManager] removeItemAtPath:undoFilesDirectory error:nil];
    
}

#pragma mark - Tools handling

- (BOOL)tracingPhotoDestination {
    return (self.photoTool.photo != nil);
}

- (SDDrawingTool*)activeTool {
    
    for (SDDrawingTool *tool in self.drawingTools) {
        if ([tool.toolName isEqualToString:self.toolSettings.drawingTool]) {
            return tool;
        }
    }
    
    return nil;
    
}

- (void)initializeTools {
    
    
    self.drawingTools = [[NSMutableArray alloc] init];
  
    
    
    //pen tool
    SDDrawingTool *tool = [[SDPenTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Pen";
    tool.imageName = @"pen-ink-mini.png";
    [self.drawingTools addObject:tool];
    
    //brush tool
    tool = [[SDBrushTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Brush";
    tool.imageName = @"paint-brush-mini.png";
    [self.drawingTools addObject:tool];
    
    //line tool
    tool = [[SDLineTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Line";
    tool.imageName = @"ruler-triangle-mini.png";
    [self.drawingTools addObject:tool];
    
    //text tool
    tool = [[SDTextTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Text";
    tool.imageName = @"text-capital-mini.png";
    [self.drawingTools addObject:tool];
    
    //rectangle stroke tool
    tool = [[SDRectangleStrokeTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Rectangle (stroke)";
    tool.imageName = @"multiple-mini.png";
    [self.drawingTools addObject:tool];
    
    //rectangle fill tool
    tool = [[SDRectangleFillTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Rectangle (fill)";
    tool.imageName = @"multiple-mini.png";
    [self.drawingTools addObject:tool];
    
    //ellipse stroke tool
    tool = [[SDEllipseStrokeTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Ellipse (stroke)";
    tool.imageName = @"circle-mini.png";
    [self.drawingTools addObject:tool];
    
    //ellipse fill tool
    tool = [[SDEllipseFillTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Ellipse (fill)";
    tool.imageName = @"circle-mini.png";
    
    
    [self.drawingTools addObject:tool];
    
    
   
    
    //fill tool
    /*
    tool = [[SDFillTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Fill (bucket)";
    tool.imageName = @"paint-mini.png";
    
    [self.drawingTools addObject:tool];
    */
     
     
    //eraser tool
    tool = [[SDEraserTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    tool.toolName = @"Eraser";
    tool.imageName = @"eraser-mini.png";
    [self.drawingTools addObject:tool];    
    
    //photo tool
    self.photoTool = [[SDPhotoTool alloc] initWithCompletion:^{
        
        [self addDrawingToUndoStack];
        
    }];
    
    if (self.toolListCustomization) {
        self.toolListCustomization(self.drawingTools);
    }
    
}

#pragma mark - Layer handling

- (UIImageView*)activeImageView {
    

    return ((SDDrawingLayer*)self.layers[self.activeLayerIndex]).imageView;
    
    
    
}

- (void)addNewLayer {
    
    SDDrawingLayer *newLayer = [[SDDrawingLayer alloc] init];
    [self.layers addObject:newLayer];
    
    [self initializeNewLayer:newLayer];
    
    self.activeLayerIndex = self.layers.count - 1;
    
}

- (void)initializeNewLayer:(SDDrawingLayer*)layer {
    
    layer.layerID = [NSString UUIDString];
    layer.layerName = [NSString stringWithFormat:@"Layer #%d", self.layers.count];
    layer.visible = YES;
    
    [self setupImageViewForLayer:layer];
    
}

- (void)setupImageViewForLayer:(SDDrawingLayer*)layer {
    
    UIImageView *layerView = [[UIImageView alloc] initWithFrame:self.layerContainerView.bounds];
    layerView.contentMode = UIViewContentModeScaleAspectFit;
    //absolutely necessary - layer may be added in viewDidLoad before frames are final
    layerView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    //add subview rather than inserting - newly added layers are in front
    [self.layerContainerView addSubview:layerView];
    layer.imageView = layerView;
    
}

- (void)setupLayerVisibility:(SDDrawingLayer*)layer {
    
    if (layer.visible) {
        layer.imageView.hidden = NO;
    } else {
        layer.imageView.hidden = YES;
    }
    
    layer.imageView.alpha = 1.0 - (layer.transparency / 100.00);
    
}

- (void)initializeLayers {
    
    self.layers = [[NSMutableArray alloc] init];
    
}

#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSLog(@"view appearedddd");
    [self addDrawingToUndoStack];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self dismissCurrentPopover];
    
    [self.toolSettings saveToUserDefaults];
    
}

#pragma mark - Memory management

- (void)viewDidLoad
{
    
    // self.layerContainerView.contentMode = UIViewContentModeScaleAspectFit;
    [super viewDidLoad];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveTestNotification:)
                                                 name:@"TestNotification"
                                               object:nil];

    [self initializeLayers];
    
    [self resetUndoStack];
    
    self.toolSettings = [[SDToolSettings alloc] init];
    [self.toolSettings loadFromUserDefaults];
    
    [self updateColorButtons];
    
    [self setupViewBackground];
    
    [self initializeDrawing];
    
    [self initializeTools];
    
    [self updateDrawingToolButton];
    [self updateDrawingToolTitle];
    
    [self updateFileInfoControls];
   
    UIGraphicsBeginImageContext(self.sliderFxSubView.bounds.size);
    [[UIImage imageNamed:@"fxslidermetal.png"] drawInRect:self.sliderFxSubView.bounds];
    UIImage *imageSliderBg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.sliderFxSubView.backgroundColor = [UIColor colorWithPatternImage:imageSliderBg];
  
    self.moverView.backgroundColor = [UIColor colorWithPatternImage:imageSliderBg];
    
    
    
    
    
    
      
    //additional customization of the view via a block
    if (self.customization) {
        self.customization(self);
    }
   
}

- (void)viewDidUnload {
    [self setLayerContainerView:nil];
    [self setFileSizeLabel:nil];
    [self setTopToolbar:nil];
    [self setTitleTextField:nil];
    [self setTitleButton:nil];
    [self setShareButton:nil];
    [self setBottomToolbar:nil];
    [self setToolTitleLabel:nil];
    [self setFilterSettingsSlider:nil];
    [self setUiUndoButton:nil];
    [self setSliderFxSubView:nil];
    [self setDrawToolButton:nil];
    [self setMoverView:nil];
    [self setScaleButtonUiLook:nil];
    [self setPositionButtonUILook:nil];
    [self setRotateButtonUILook:nil];
    [self setMoveViewLabel:nil];
    [super viewDidUnload];
}

-(void) newFilterSelected: (NSNumber *)indexPath{
    //rezand
    CGImageRef cgref = [self.activeImageView.image CGImage];
    CIImage *cim = [self.activeImageView.image CIImage];
    
    if (cim == nil && cgref == NULL)
    {
        NSLog(@"there was an error with active image at 1");
    }else{
        curPreFilteredImage = self.activeImageView.image;
        
        NSLog(@"%d",[indexPath intValue]);
   
        filterType = [indexPath intValue];

        switch (filterType)
    {
            
            NSLog(@"in");
        case GPUIMAGE_SEPIA:
        {
            self.title = @"Sepia Tone";
           self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
           // filter = [[GPUImageSepiaFilter alloc] init];
            
            GPUImageSepiaFilter *myTestFilter = [[GPUImageSepiaFilter alloc] init];
            [myTestFilter setIntensity:[self.filterSettingsSlider value]];
                                            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:[self.activeImageView image]];
           // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }; break;
        case GPUIMAGE_PIXELLATE:
        {
            self.title = @"Pixellate";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
           // filter = [[GPUImagePixellateFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImagePixellateFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
        }; break;
        case GPUIMAGE_POLARPIXELLATE:
        {
            self.title = @"Polar Pixellate";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:-0.1];
            [self.filterSettingsSlider setMaximumValue:0.1];
            
            //filter = [[GPUImagePolarPixellateFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImagePolarPixellateFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
        }; break;
        case GPUIMAGE_PIXELLATE_POSITION:
        {
            self.title = @"Pixellate (position)";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.25];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.5];
            
         //   filter = [[GPUImagePixellatePositionFilter alloc] init];
            
            UIImage *rezandFilteredImage =  [[[GPUImagePixellatePositionFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
        }; break;
        case GPUIMAGE_POLKADOT:
        {
            self.title = @"Polka Dot";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.05];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.3];
            
          //  filter = [[GPUImagePolkaDotFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImagePolkaDotFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
            
            
        }; break;
        case GPUIMAGE_HALFTONE:
        {
            self.title = @"Halftone";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.01];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:0.05];
            
         //   filter = [[GPUImageHalftoneFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageHalftoneFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
            
        }; break;
        case GPUIMAGE_CROSSHATCH:
        {
            self.title = @"Crosshatch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:0.03];
            [self.filterSettingsSlider setMinimumValue:0.01];
            [self.filterSettingsSlider setMaximumValue:0.06];
            
         //   filter = [[GPUImageCrosshatchFilter alloc] init];
            
            UIImage *rezandFilteredImage =  [[[GPUImageCrosshatchFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
            
        }; break;
        case GPUIMAGE_COLORINVERT:
        {
            self.title = @"Color Invert";
            self.filterSettingsSlider.hidden = YES;
            
     //       filter = [[GPUImageColorInvertFilter alloc] init];
            
            UIImage *rezandFilteredImage =  [[[GPUImageColorInvertFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
        }; break;
        case GPUIMAGE_GRAYSCALE:
        {
            self.title = @"Grayscale";
            self.filterSettingsSlider.hidden = YES;
            
      //      filter = [[GPUImageGrayscaleFilter alloc] init];
            
            UIImage *rezandFilteredImage =  [[[GPUImageGrayscaleFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
            
        }; break;
        case GPUIMAGE_MONOCHROME:
        {
            self.title = @"Monochrome";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
         //   filter = [[GPUImageMonochromeFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageMonochromeFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
          //  [(GPUImageMonochromeFilter *)filter setColor:(GPUVector4){0.0f, 0.0f, 1.0f, 1.f}];
        }; break;
  
    
            
        case GPUIMAGE_SATURATION:
        {
            self.title = @"Saturation";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            
      //      filter = [[GPUImageSaturationFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageSaturationFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_CONTRAST:
        {
            self.title = @"Contrast";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:1.0];
            
         //   filter = [[GPUImageContrastFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageContrastFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_BRIGHTNESS:
        {
            self.title = @"Brightness";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
            UIImage *rezandFilteredImage =  [[[GPUImageBrightnessFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
            
            
        }; break;
        case GPUIMAGE_LEVELS:
        {
            self.title = @"Levels";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.0];
            
          //  filter = [[GPUImageLevelsFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageLevelsFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_RGB:
        {
            self.title = @"RGB";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
          //  filter = [[GPUImageRGBFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageRGBFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_HUE:
        {
            
            GPUImageToneCurveFilter *myTestFilter = [[GPUImageToneCurveFilter alloc] init];
            [myTestFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 1.0)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
            
           self.activeImageView.image =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            
            curPreFilteredImage = self.activeImageView.image;
            
            self.title = @"Hue";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:360.0];
            [self.filterSettingsSlider setValue:90.0];
            
          //  filter = [[GPUImageHueFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageHueFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_WHITEBALANCE:
        {
            self.title = @"White Balance";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:2500.0];
            [self.filterSettingsSlider setMaximumValue:7500.0];
            [self.filterSettingsSlider setValue:5000.0];
            
         //   filter = [[GPUImageWhiteBalanceFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageWhiteBalanceFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_EXPOSURE:
        {
            self.title = @"Exposure";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-4.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
         //
          //  filter = [[GPUImageExposureFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageExposureFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_SHARPEN:
        {
            self.title = @"Sharpen";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:4.0];
            [self.filterSettingsSlider setValue:0.0];
            
         //   filter = [[GPUImageSharpenFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageSharpenFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
       
        case GPUIMAGE_GAMMA:
        {
            self.title = @"Gamma";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:3.0];
            [self.filterSettingsSlider setValue:1.0];
            
         //   filter = [[GPUImageGammaFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageGammaFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_TONECURVE:
        {
            self.title = @"Tone curve";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
          //  filter = [[GPUImageToneCurveFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageToneCurveFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
          //  [(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, 0.5)], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
        }; break;
        case GPUIMAGE_HIGHLIGHTSHADOW:
        {
            self.title = @"Highlights and Shadows";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setValue:1.0];
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            
         //   filter = [[GPUImageHighlightShadowFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageHighlightShadowFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
		case GPUIMAGE_HAZE:
        {
            self.title = @"Haze / UV";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-0.2];
            [self.filterSettingsSlider setMaximumValue:0.2];
            [self.filterSettingsSlider setValue:0.2];
            
          //  filter = [[GPUImageHazeFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageHazeFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
		
		case GPUIMAGE_LUMINOSITY:
        {
          //  self.title = @"Luminosity";
           self.filterSettingsSlider.hidden = YES;
            
         //   filter = [[GPUImageLuminosity alloc] init];
        //    UIImage *rezandFilteredImage =  [[[GPUImageLuminosity alloc] init] imageByFilteringImage:[self.activeImageView image] ];
          //  self.activeImageView.image = rezandFilteredImage;
        }; break;
		
		case GPUIMAGE_THRESHOLD:
        {
            self.title = @"Luminance Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
         //   filter = [[GPUImageLuminanceThresholdFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageLuminanceThresholdFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
		case GPUIMAGE_ADAPTIVETHRESHOLD:
        {
            self.title = @"Adaptive Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:1.0];
            
         //   filter = [[GPUImageAdaptiveThresholdFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageAdaptiveThresholdFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
		case GPUIMAGE_AVERAGELUMINANCETHRESHOLD:
        {
            self.title = @"Avg. Lum. Threshold";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
          //  filter = [[GPUImageAverageLuminanceThresholdFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageAverageLuminanceThresholdFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
       
	
        case GPUIMAGE_TRANSFORM3D:
        {
            self.title = @"Transform (3-D)";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:6.28];
            [self.filterSettingsSlider setValue:0.75];
            
        //    filter = [[GPUImageTransformFilter alloc] init];
            CATransform3D perspectiveTransform = CATransform3DIdentity;
            perspectiveTransform.m34 = 0.4;
            perspectiveTransform.m33 = 0.4;
            perspectiveTransform = CATransform3DScale(perspectiveTransform, 0.75, 0.75, 0.75);
            perspectiveTransform = CATransform3DRotate(perspectiveTransform, 0.75, 0.0, 1.0, 0.0);
            
            
            GPUImageTransformFilter *rezandFilteredImage =  [[GPUImageTransformFilter alloc] init];
            
            [rezandFilteredImage setTransform3D:perspectiveTransform];
            self.activeImageView.image = [rezandFilteredImage imageByFilteringImage:self.activeImageView.image];

           // [(GPUImageTransformFilter *)filter setTransform3D:perspectiveTransform];
		}; break;
       
        case GPUIMAGE_XYGRADIENT:
        {
            self.title = @"XY Derivative";
            self.filterSettingsSlider.hidden = YES;
            
           // filter = [[GPUImageXYDerivativeFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageXYDerivativeFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
  
 
             case GPUIMAGE_CANNYEDGEDETECTION:
        {
            self.title = @"Canny Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:1.0];
            
            //            [self.filterSettingsSlider setMinimumValue:0.0];
            //            [self.filterSettingsSlider setMaximumValue:0.5];
            //            [self.filterSettingsSlider setValue:0.1];
            
          //  filter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION:
        {
            self.title = @"Threshold Edge Detection";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
         //   filter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
        }; break;
        case GPUIMAGE_LOCALBINARYPATTERN:
        {
            self.title = @"Local Binary Pattern";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
       //     filter = [[GPUImageLocalBinaryPatternFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageLocalBinaryPatternFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_BUFFER:
        {
            self.title = @"Image Buffer";
            self.filterSettingsSlider.hidden = YES;
            
         //   filter = [[GPUImageBuffer alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageBuffer alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
              case GPUIMAGE_SKETCH:
        {
            self.title = @"Sketch";
            self.filterSettingsSlider.hidden = YES;
            
        //    filter = [[GPUImageSketchFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageSketchFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_THRESHOLDSKETCH:
        {
            self.title = @"Threshold Sketch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.9];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.9];
            
         //   filter = [[GPUImageThresholdSketchFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageThresholdSketchFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_TOON:
        {
            self.title = @"Toon";
            self.filterSettingsSlider.hidden = YES;
            
        //    filter = [[GPUImageToonFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageToonFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_SMOOTHTOON:
        {
            self.title = @"Smooth Toon";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
        //    filter = [[GPUImageSmoothToonFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageSmoothToonFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_TILTSHIFT:
        {
            self.title = @"Tilt Shift";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.2];
            [self.filterSettingsSlider setMaximumValue:0.8];
            [self.filterSettingsSlider setValue:0.5];
            
         //   filter = [[GPUImageTiltShiftFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageTiltShiftFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
         //   [(GPUImageTiltShiftFilter *)filter setTopFocusLevel:0.4];
         //   [(GPUImageTiltShiftFilter *)filter setBottomFocusLevel:/0.6];
       //     [(GPUImageTiltShiftFilter *)filter setFocusFallOffRate:0.2];
        }; break;
        case GPUIMAGE_CGA:
        {
            self.title = @"CGA Colorspace";
            self.filterSettingsSlider.hidden = YES;
            
         //   filter = [[GPUImageCGAColorspaceFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageCGAColorspaceFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
      
        case GPUIMAGE_EMBOSS:
        {
            self.title = @"Emboss";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:5.0];
            [self.filterSettingsSlider setValue:1.0];
            
         //   filter = [[GPUImageEmbossFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageEmbossFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_LAPLACIAN:
        {
            self.title = @"Laplacian";
            self.filterSettingsSlider.hidden = YES;
            
       //     filter = [[GPUImageLaplacianFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageLaplacianFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_POSTERIZE:
        {
            self.title = @"Posterize";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:1.0];
            [self.filterSettingsSlider setMaximumValue:20.0];
            [self.filterSettingsSlider setValue:10.0];
            
       //     filter = [[GPUImagePosterizeFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImagePosterizeFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_SWIRL:
        {
            self.title = @"Swirl";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:1.0];
            
          //  filter = [[GPUImageSwirlFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageSwirlFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_BULGE:
        {
            self.title = @"Bulge";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-1.0];
            [self.filterSettingsSlider setMaximumValue:1.0];
            [self.filterSettingsSlider setValue:0.5];
            
        //    filter = [[GPUImageBulgeDistortionFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageBulgeDistortionFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
      
        case GPUIMAGE_PINCH:
        {
            self.title = @"Pinch";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:-2.0];
            [self.filterSettingsSlider setMaximumValue:2.0];
            [self.filterSettingsSlider setValue:0.5];
            
          //  filter = [[GPUImagePinchDistortionFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImagePinchDistortionFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_STRETCH:
        {
            self.title = @"Stretch";
            self.filterSettingsSlider.hidden = YES;
            
         //   filter = [[GPUImageStretchDistortionFilter alloc] init];
            UIImage *rezandFilteredImage =  [[[GPUImageStretchDistortionFilter alloc] init] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_DILATION:
        {
            self.title = @"Dilation";
            self.filterSettingsSlider.hidden = YES;
            
          //  filter = [[GPUImageRGBDilationFilter alloc] initWithRadius:4];
            UIImage *rezandFilteredImage =  [[[GPUImageRGBDilationFilter alloc] initWithRadius:4] imageByFilteringImage:[self.activeImageView image] ];
            self.activeImageView.image = rezandFilteredImage;
		}; break;
        case GPUIMAGE_EROSION:
        {
            self.title = @"Erosion";
            self.filterSettingsSlider.hidden = YES;
            
          //  filter = [[GPUImageRGBErosionFilter alloc] initWithRadius:4];
            UIImage *rezandFilteredImage =  [[[GPUImageRGBErosionFilter alloc] initWithRadius:4] imageByFilteringImage:self.activeImageView.image];
            self.activeImageView.image = rezandFilteredImage;
		}; break;
     
       
  
   
      case GPUIMAGE_VIGNETTE:
        {
            self.title = @"Vignette";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.5];
            [self.filterSettingsSlider setMaximumValue:0.9];
            [self.filterSettingsSlider setValue:0.75];
            
            GPUImageVignetteFilter *myTestFilter = [[GPUImageVignetteFilter alloc] init];
            [myTestFilter setVignetteEnd:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:self.activeImageView.image];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_GAUSSIAN:
        {
            self.title = @"Gaussian Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:10.0];
            [self.filterSettingsSlider setValue:1.0];
      //
            GPUImageGaussianBlurFilter *myTestFilter = [[GPUImageGaussianBlurFilter alloc] init];
            [myTestFilter setBlurSize:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:self.activeImageView.image];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }; break;
    
        case GPUIMAGE_MOTIONBLUR:
        {
            self.title = @"Motion Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:180.0f];
            [self.filterSettingsSlider setValue:0.0];
            
            GPUImageMotionBlurFilter *myTestFilter = [[GPUImageMotionBlurFilter alloc] init];
            [myTestFilter setBlurAngle:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:self.activeImageView.image];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_ZOOMBLUR:
        {
            self.title = @"Zoom Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:2.5f];
            [self.filterSettingsSlider setValue:1.0];
            
            GPUImageZoomBlurFilter *myTestFilter = [[GPUImageZoomBlurFilter alloc] init];
            [myTestFilter setBlurSize:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }; break;
   
        case GPUIMAGE_GAUSSIAN_SELECTIVE:
        {
            self.title = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            GPUImageGaussianSelectiveBlurFilter *myTestFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            
            [myTestFilter setExcludeCircleRadius:40.0/320.0];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
          //  filter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
         //   [(GPUImageGaussianSelectiveBlurFilter*)filter setExcludeCircleRadius:40.0/320.0];
        }; break;
        case GPUIMAGE_GAUSSIAN_POSITION:
        {
            self.title = @"Selective Blur";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:.75f];
            [self.filterSettingsSlider setValue:40.0/320.0];
            
            
            GPUImageGaussianBlurPositionFilter *myTestFilter = [[GPUImageGaussianBlurPositionFilter alloc] init];
            
            [myTestFilter setBlurRadius:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
          
       //     [(GPUImageGaussianBlurPositionFilter*)filter setBlurRadius:40.0/320.0];
        }; break;
        case alpha54:
        {
            self.title = @"alpha";
            self.filterSettingsSlider.hidden = NO;
            
            [self.filterSettingsSlider setMinimumValue:0.0];
            [self.filterSettingsSlider setMaximumValue:1.0f];
            [self.filterSettingsSlider setValue:1.0f];
            
            
           self.activeImageView.alpha = self.filterSettingsSlider.value;
            
          
            
          
            // rezandFilteredImage.i
            
            
            
            //     [(GPUImageGaussianBlurPositionFilter*)filter setBlurRadius:40.0/320.0];
        }; break;
         
            
    }}
}

- (IBAction)sliderFxDoneButton:(UIButton *)sender {
    
    [self addDrawingToUndoStack];
    [self hideFxAnimation];
}

- (IBAction)filterSettingsSlider:(UISlider *)sender forEvent:(UIEvent *)event {
    
    
    CGImageRef cgref = [self.activeImageView.image CGImage];
    CIImage *cim = [self.activeImageView.image CIImage];
    
    if (cim == nil && cgref == NULL)
    {
        NSLog(@"there was an error with active image at 2");
    }else{
    
        
        CGImageRef cgref = [curPreFilteredImage CGImage];
        CIImage *cim = [curPreFilteredImage CIImage];
        
        if (cim == nil && cgref == NULL)
        {
            curPreFilteredImage = self.activeImageView.image;
        }
  
    switch(filterType)
    {
        case GPUIMAGE_SEPIA: {
            GPUImageSepiaFilter *myTestFilter = [[GPUImageSepiaFilter alloc] init];
            [myTestFilter setIntensity:[self.filterSettingsSlider value]];
            
          //  UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            
            UIImage *rezandFilteredImage = [myTestFilter imageByFilteringImage:curPreFilteredImage];
          
            self.activeImageView.image = rezandFilteredImage;
            
        }
            
            break;
        case GPUIMAGE_PIXELLATE: {
            GPUImagePixellateFilter *myTestFilter = [[GPUImagePixellateFilter alloc] init];
            [myTestFilter setFractionalWidthOfAPixel:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        } break;
        case GPUIMAGE_POLARPIXELLATE:{
            
            GPUImagePolarPixellateFilter *myTestFilter = [[GPUImagePolarPixellateFilter alloc] init];
            [myTestFilter setPixelSize:CGSizeMake([self.filterSettingsSlider value],[self.filterSettingsSlider value])];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }//[(GPUImagePolarPixellateFilter *)filter setPixelSize:CGSizeMake([(UISlider *)sender value], [(UISlider *)sender value])];
            
            break;
        case GPUIMAGE_PIXELLATE_POSITION: {
            
            GPUImagePixellatePositionFilter *myTestFilter = [[GPUImagePixellatePositionFilter alloc] init];
            [myTestFilter setRadius:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImagePixellatePositionFilter *)filter setRadius:[(UISlider *)sender value]];
            
            break;
            
           
        case GPUIMAGE_POLKADOT:{
            GPUImagePolkaDotFilter *myTestFilter = [[GPUImagePolkaDotFilter alloc] init];
            [myTestFilter setFractionalWidthOfAPixel:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImagePolkaDotFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_HALFTONE:{
            
            GPUImageHalftoneFilter *myTestFilter = [[GPUImageHalftoneFilter alloc] init];
            [myTestFilter setFractionalWidthOfAPixel:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageHalftoneFilter *)filter setFractionalWidthOfAPixel:[(UISlider *)sender value]];
            
            break;
        case GPUIMAGE_SATURATION:{
            GPUImageSaturationFilter *myTestFilter = [[GPUImageSaturationFilter alloc] init];
            [myTestFilter setSaturation:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        }//[(GPUImageSaturationFilter *)filter setSaturation:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_CONTRAST:{
            GPUImageContrastFilter *myTestFilter = [[GPUImageContrastFilter alloc] init];
            [myTestFilter setContrast:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        }//[(GPUImageContrastFilter *)filter setContrast:[(UISlider *)sender value]];
            
            break;
        case GPUIMAGE_BRIGHTNESS: {
            
            GPUImageBrightnessFilter *myTestFilter = [[GPUImageBrightnessFilter alloc] init];
            [myTestFilter setBrightness:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageBrightnessFilter *)filter setBrightness:[(UISlider *)sender value]];
            
            break;
        case GPUIMAGE_LEVELS: {
            GPUImageLevelsFilter  *filter = [[GPUImageLevelsFilter alloc] init];
           
           
            
        
            
            float value = [(UISlider *)sender value];
           [filter setRedMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
           [filter setGreenMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
           [ filter setBlueMin:value gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
            
            UIImage *rezandFilteredImage =  [filter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }; break;
        case GPUIMAGE_EXPOSURE:{
            
            GPUImageExposureFilter *myTestFilter = [[GPUImageExposureFilter alloc] init];
            [myTestFilter setExposure:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageExposureFilter *)filter setExposure:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_MONOCHROME:{
            
            GPUImageMonochromeFilter *myTestFilter = [[GPUImageMonochromeFilter alloc] init];
            [myTestFilter setIntensity:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }//[(GPUImageMonochromeFilter *)filter setIntensity:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_RGB:{
            GPUImageRGBFilter *myTestFilter = [[GPUImageRGBFilter alloc] init];
            [myTestFilter setGreen:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }//[(GPUImageRGBFilter *)filter setGreen:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_HUE: {
            GPUImageHueFilter *myTestFilter = [[GPUImageHueFilter alloc] init];
            [myTestFilter setHue:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageHueFilter *)filter setHue:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_WHITEBALANCE:{
            GPUImageWhiteBalanceFilter *myTestFilter = [[GPUImageWhiteBalanceFilter alloc] init];
            [myTestFilter setTemperature:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageWhiteBalanceFilter *)filter setTemperature:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_SHARPEN:{
            GPUImageSharpenFilter *myTestFilter = [[GPUImageSharpenFilter alloc] init];
            [myTestFilter setSharpness:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageSharpenFilter *)filter setSharpness:[(UISlider *)sender value]];
            break;
        
        
            //        case GPUIMAGE_UNSHARPMASK: [(GPUImageUnsharpMaskFilter *)filter setBlurSize:[(UISlider *)sender value]]; break;
        case GPUIMAGE_GAMMA: {
            
            GPUImageGammaFilter *myTestFilter = [[GPUImageGammaFilter alloc] init];
            [myTestFilter setGamma:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
        }//[(GPUImageGammaFilter *)filter setGamma:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_CROSSHATCH:{
            GPUImageCrosshatchFilter *myTestFilter = [[GPUImageCrosshatchFilter alloc] init];
            [myTestFilter setCrossHatchSpacing:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageCrosshatchFilter *)filter setCrossHatchSpacing:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_POSTERIZE: {
            GPUImagePosterizeFilter *myTestFilter = [[GPUImagePosterizeFilter alloc] init];
            [myTestFilter setColorLevels:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImagePosterizeFilter *)filter setColorLevels:round([(UISlider*)sender value])];
            break;
        case GPUIMAGE_HAZE: {
            GPUImageHazeFilter *myTestFilter = [[GPUImageHazeFilter alloc] init];
            [myTestFilter setDistance:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageHazeFilter *)filter setDistance:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_THRESHOLD:{
            
            GPUImageLuminanceThresholdFilter *myTestFilter = [[GPUImageLuminanceThresholdFilter alloc] init];
            [myTestFilter setThreshold:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageLuminanceThresholdFilter *)filter setThreshold:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_ADAPTIVETHRESHOLD: {
            
            GPUImageAdaptiveThresholdFilter *myTestFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
            [myTestFilter setBlurSize:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageAdaptiveThresholdFilter *)filter setBlurSize:[(UISlider*)sender value]];
            break;
        case GPUIMAGE_AVERAGELUMINANCETHRESHOLD:{
            
            GPUImageAverageLuminanceThresholdFilter *myTestFilter = [[GPUImageAverageLuminanceThresholdFilter alloc] init];
            [myTestFilter setThresholdMultiplier:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageAverageLuminanceThresholdFilter *)filter setThresholdMultiplier:[(UISlider *)sender value]];
            break;
     
       
      //  case GPUIMAGE_CHROMAKEYNONBLEND: [(GPUImageChromaKeyFilter *)filter setThresholdSensitivity:[(UISlider *)sender value]]; break;
        //case GPUIMAGE_KUWAHARA: [(GPUImageKuwaharaFilter *)filter setRadius:round([(UISlider *)sender value])]; break;
        case GPUIMAGE_SWIRL: {
            
            GPUImageSwirlFilter *myTestFilter = [[GPUImageSwirlFilter alloc] init];
            [myTestFilter setAngle:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageSwirlFilter *)filter setAngle:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_EMBOSS: {
            GPUImageEmbossFilter *myTestFilter = [[GPUImageEmbossFilter alloc] init];
            [myTestFilter setIntensity:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageEmbossFilter *)filter setIntensity:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_CANNYEDGEDETECTION:{
            GPUImageCannyEdgeDetectionFilter *myTestFilter = [[GPUImageCannyEdgeDetectionFilter alloc] init];
            [myTestFilter setBlurSize:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageCannyEdgeDetectionFilter *)filter setBlurSize:[(UISlider*)sender value]];
            break;
            //        case GPUIMAGE_CANNYEDGEDETECTION: [(GPUImageCannyEdgeDetectionFilter *)filter setLowerThreshold:[(UISlider*)sender value]]; break;

       // case GPUIMAGE_NOBLECORNERDETECTION: [(GPUImageNobleCornerDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
       // case GPUIMAGE_SHITOMASIFEATUREDETECTION: [(GPUImageShiTomasiFeatureDetectionFilter *)filter setThreshold:[(UISlider*)sender value]]; break;
        //case GPUIMAGE_HOUGHTRANSFORMLINEDETECTOR: [(GPUImageHoughTransformLineDetector *)filter setLineDetectionThreshold:[(UISlider*)sender value]]; break;
            //        case GPUIMAGE_HARRISCORNERDETECTION: [(GPUImageHarrisCornerDetectionFilter *)filter setSensitivity:[(UISlider*)sender value]]; break;
        case GPUIMAGE_THRESHOLDEDGEDETECTION:{
            GPUImageThresholdEdgeDetectionFilter *myTestFilter = [[GPUImageThresholdEdgeDetectionFilter alloc] init];
            [myTestFilter setThreshold:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageThresholdEdgeDetectionFilter *)filter setThreshold:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_SMOOTHTOON: {
            
            GPUImageSmoothToonFilter *myTestFilter = [[GPUImageSmoothToonFilter alloc] init];
            [myTestFilter setBlurSize:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        }//[(GPUImageSmoothToonFilter *)filter setBlurSize:[(UISlider*)sender value]];
            break;
        case GPUIMAGE_THRESHOLDSKETCH:{
            GPUImageThresholdSketchFilter *myTestFilter = [[GPUImageThresholdSketchFilter alloc] init];
            [myTestFilter setThreshold:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        }//[(GPUImageThresholdSketchFilter *)filter setThreshold:[(UISlider *)sender value]];
            
            break;
            //        case GPUIMAGE_BULGE: [(GPUImageBulgeDistortionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_BULGE:{
            
            GPUImageBulgeDistortionFilter *myTestFilter = [[GPUImageBulgeDistortionFilter alloc] init];
            [myTestFilter setScale:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageBulgeDistortionFilter *)filter setScale:[(UISlider *)sender value]];
            break;
      //  case GPUIMAGE_SPHEREREFRACTION: [(GPUImageSphereRefractionFilter *)filter setRadius:[(UISlider *)sender value]]; break;
       // case GPUIMAGE_GLASSSPHERE: [(GPUImageGlassSphereFilter *)filter setRadius:[(UISlider *)sender value]]; break;
        case GPUIMAGE_TONECURVE:{
            GPUImageToneCurveFilter *myTestFilter = [[GPUImageToneCurveFilter alloc] init];
            [myTestFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, [self.filterSettingsSlider value])], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageToneCurveFilter *)filter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)], [NSValue valueWithCGPoint:CGPointMake(0.5, [(UISlider *)sender value])], [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
            
            break;
        case GPUIMAGE_HIGHLIGHTSHADOW: {
            
            GPUImageHighlightShadowFilter *myTestFilter = [[GPUImageHighlightShadowFilter alloc] init];
            [myTestFilter setHighlights:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageHighlightShadowFilter *)filter setHighlights:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_PINCH: {
            GPUImagePinchDistortionFilter *myTestFilter = [[GPUImagePinchDistortionFilter alloc] init];
            [myTestFilter setScale:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        }//[(GPUImagePinchDistortionFilter *)filter setScale:[(UISlider *)sender value]];
            break;
      
       
        case GPUIMAGE_VIGNETTE: {
            
            GPUImageVignetteFilter *myTestFilter = [[GPUImageVignetteFilter alloc] init];
            [myTestFilter setVignetteEnd:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageVignetteFilter *)filter setVignetteEnd:[(UISlider *)sender value]];
            break;
        case GPUIMAGE_GAUSSIAN: {
            GPUImageGaussianBlurFilter *myTestFilter = [[GPUImageGaussianBlurFilter alloc] init];
            [myTestFilter setBlurSize:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        }//[(GPUImageGaussianBlurFilter *)filter setBlurSize:[(UISlider*)sender value]];
            break;
            //        case GPUIMAGE_BILATERAL: [(GPUImageBilateralFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
      
       
            //        case GPUIMAGE_FASTBLUR: [(GPUImageFastBlurFilter *)filter setBlurSize:[(UISlider*)sender value]]; break;
        case GPUIMAGE_MOTIONBLUR:{
            GPUImageMotionBlurFilter *myTestFilter = [[GPUImageMotionBlurFilter alloc] init];
            [myTestFilter setBlurAngle:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageMotionBlurFilter *)filter setBlurAngle:[(UISlider*)sender value]];
            break;
        case GPUIMAGE_ZOOMBLUR: {
            GPUImageZoomBlurFilter *myTestFilter = [[GPUImageZoomBlurFilter alloc] init];
            [myTestFilter setBlurSize:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
            
        }//[(GPUImageZoomBlurFilter *)filter setBlurSize:[(UISlider*)sender value]];
            break;
       
        case GPUIMAGE_GAUSSIAN_SELECTIVE:{
            GPUImageGaussianSelectiveBlurFilter *myTestFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
            [myTestFilter setExcludeCircleRadius:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageGaussianSelectiveBlurFilter *)filter setExcludeCircleRadius:[(UISlider*)sender value]];
            break;
            
        case GPUIMAGE_GAUSSIAN_POSITION:{
            GPUImageGaussianBlurPositionFilter *myTestFilter = [[GPUImageGaussianBlurPositionFilter alloc] init];
            [myTestFilter setBlurRadius:[self.filterSettingsSlider value]];
            
            UIImage *rezandFilteredImage =  [myTestFilter imageByFilteringImage:curPreFilteredImage];
            // rezandFilteredImage.i
            self.activeImageView.image = rezandFilteredImage;
            
        }//[(GPUImageGaussianBlurPositionFilter *)filter setBlurRadius:[(UISlider *)sender value]];
            break;
        case alpha54:
        {
           
         
          
            ((SDDrawingLayer*)self.layers[self.activeLayerIndex]).transparency = self.filterSettingsSlider.value;
            
            
            [self setupLayerVisibility:((SDDrawingLayer*)self.layers[self.activeLayerIndex])];
            
            // rezandFilteredImage.i
            
          //  self.activeImageView.alpha = self.filterSettingsSlider.value;
            
            //     [(GPUImageGaussianBlurPositionFilter*)filter setBlurRadius:40.0/320.0];
        }; break;        default: break;
            
          NSLog(@"1");
          
    
    }
    NSLog(@"2");
  //  self.activeImageView.image = [self getFlattenedImageOfDrawing];
    }
}

- (IBAction)myRedoButtonTapped:(UIBarButtonItem *)sender {
    
    
    if (self.undoStackLocation < self.undoStackCount - 1) {
        self.undoStackLocation++;
        
        if (![self loadImageFromUndoStack]) {
            //rever to old location if there was no undo image
            self.undoStackLocation--;
        }
    }
}











@end
