//
//  SDLayersViewController.m
//  SimpleDrawing
//
//  Created by Nathanial Woolls on 10/15/12.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2012 Nathanial Woolls
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SDLayersViewController.h"
#import "SDLayerSettingsViewController.h"

@interface SDLayersViewController () <SDLayerSettingsViewControllerDelegate>

#pragma mark - IBOutlets

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;

@end

@implementation SDLayersViewController

@synthesize activeLayerIndex = _activeLayerIndex;

- (void)setActiveLayerIndex:(int)activeLayerIndex {
    
    _activeLayerIndex = activeLayerIndex;
  //  [self.delegate viewController:self didActivateLayer:self.layers[self.activeLayerIndex]];
    
}

- (int)activeLayerIndex {
    if (_activeLayerIndex < self.layers.count) {
        return _activeLayerIndex;
    } else return 0;
   
}

- (void)selectActiveLayer {
    
    if ((self.activeLayerIndex >= 0) && (self.activeLayerIndex < self.layers.count)) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.activeLayerIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self setActiveLayerIndex:self.activeLayerIndex];
    }else [self setActiveLayerIndex:0];
    
}

- (void)ensureActiveLayerSelected {
    // NSLog(@" cell count %d", self.layers.count);
    if (!self.tableView.indexPathForSelectedRow) {
        //rezand change below didnt crash with setactivelayer
        [self selectActiveLayer];
    }
    
}

#pragma mark - IBActions
- (IBAction)duplicateLayerTapped:(UIBarButtonItem *)sender {
     UIImage *holderImage = ((SDDrawingLayer*)self.layers[self.activeLayerIndex]).imageView.image;    
       
    
    SDDrawingLayer *newLayer = [[SDDrawingLayer alloc] init];
   
    NSLog(@"%d",self.activeLayerIndex);
    /*
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        
       
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 372), NO, [UIScreen mainScreen].scale );
    }else UIGraphicsBeginImageContext(CGSizeMake(320, 372));
    
    
    UIImage *holderImage = ((SDDrawingLayer*)self.layers[self.activeLayerIndex]).imageView.image;
    CGSize imageSize = holderImage.size;
    CGSize viewSize = CGSizeMake(320, 372); // size in which you want to draw
    
    NSLog(@" %f %f", imageSize.height,imageSize.width);
    
    float hfactor = imageSize.width / viewSize.width;
    float vfactor = imageSize.height / viewSize.height;
    
    float factor = fmax(hfactor, vfactor);
    
    // Divide the size by the greater of the vertical or horizontal shrinkage factor
    float newWidth = imageSize.width / factor;
    float newHeight = imageSize.height / factor;
    
    CGRect newRect = CGRectMake(0.0 ,0.0, newWidth, newHeight);
    // [holderImage drawInRect:newRect];
    
    
    //  UIGraphicsBeginImageContext(self.layerContainerView.bounds.size);
    
    // UIGraphicsBeginImageContextWithOptions(self.layerContainerView.bounds.size, NO, [UIScreen mainScreen].scale);
    
    // reversed as the z-order of the layer image views is the reverse of the layers array order
    
    
    [holderImage drawInRect:newRect];
    
    
    // get a UIImage from the image context
    newLayer.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
*/
    
  //  SDDrawingLayer *newLayer = [[SDDrawingLayer alloc] init];
    //SDDrawingLayer *newLayerBurnCopy = [[SDDrawingLayer alloc] init];
   // UIImage *copyImage = [UIImage imageWithContentsOfFile:@"Images2/Default.png"];
 // SDDrawingLayer*  newLayerBurnCopy = [self.layers objectAtIndex:self.activeLayerIndex];
  //  SDDrawingLayer* newLayer = newLayerBurnCopy;
   
    [self.layers insertObject:newLayer atIndex:0];
    
    
    
    // [self.layers addObject:[self.layers objectAtIndex:self.activeLayerIndex]];
    
    [self.delegate viewController:self didAddLayer:newLayer];
    ((SDDrawingLayer*)self.layers[0]).imageView.image =  holderImage;
    [self setActiveLayerIndex:0];
    
    
   
    
    [self selectActiveLayer];
   // ((SDDrawingLayer*)self.layers[0]).imageView.image =  ((SDDrawingLayer*)self.layers[1]).imageView.image;
 [self.tableView reloadData];

}

- (IBAction)addTapped:(id)sender {
    
    SDDrawingLayer *newLayer = [[SDDrawingLayer alloc] init];
    [self.layers insertObject:newLayer atIndex:0];
    
    [self.delegate viewController:self didAddLayer:newLayer];
    
    self.activeLayerIndex = 0;
    // NSLog(@" cell count %d", self.layers.count);
    
    [self.tableView reloadData];
    
    [self selectActiveLayer];
    
}

- (IBAction)doneTapped:(id)sender {
    
    [self.delegate viewController:self didActivateLayer:self.layers[self.activeLayerIndex]];
    [self dismissViewControllerAnimated:YES completion:^{}];
    
}

- (IBAction)editTapped:(id)sender {
    
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    
    if (self.tableView.editing) {
        self.editButton.title = @"Done";
       
    } else {
        self.editButton.title = @"Move Layers";
              
    }
    
}

#pragma mark - SDLayerSettingsViewController delegate

- (void)viewController:(SDLayerSettingsViewController*)viewController didChangeLayerVisibility:(BOOL)visible {
    
    viewController.layer.visible = visible;
    [self.delegate viewController:self didChangeLayerVisibility:viewController.layer];
    
}

- (void)viewController:(SDLayerSettingsViewController *)viewController didChangeLayerTransparency:(int)transparency {
    
    viewController.layer.transparency = transparency;
    [self.delegate viewController:self didChangeLayerTransparency:viewController.layer];
    
}

#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    
}

#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"LayerSettingsSegue"]) {
        SDLayerSettingsViewController *viewController = (SDLayerSettingsViewController*)segue.destinationViewController;
        int accessoryIndex = ((NSNumber*)sender).intValue;
        viewController.layer = (SDDrawingLayer*)self.layers[accessoryIndex];
        viewController.delegate = self;
    }
    
}

#pragma mark - Memory management

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self selectActiveLayer];
        
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.layers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
        
       // NSLog(@" cell count %d", self.layers.count);
    static NSString *CellIdentifier = @"LayersCell";
    
    UITableViewCell *cell;
    if ([tableView respondsToSelector:@selector(dequeueReusableCellWithIdentifier:forIndexPath:)]) {
        // iOS 6.0+
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = ((SDDrawingLayer*)self.layers[indexPath.row]).layerName;
    cell.imageView.image = ((SDDrawingLayer*)self.layers[indexPath.row]).imageView.image;
    
    return cell;
    
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
   // NSLog(@" cell count %d", self.layers.count);
    //this is needed to preserve cell selection when clicking Edit/Done
     [self ensureActiveLayerSelected];
    
    if (indexPath.row < self.layers.count) {
        return self.layers.count > 1;
    }else return NO;
    
    
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
   
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        int whatWasActive = self.activeLayerIndex;
        // self.activeLayerIndex = indexPath.row;
        NSLog(@"deleting layer number %d",indexPath.row);
        
        SDDrawingLayer *layer = self.layers[indexPath.row];
       
       
       
     [self.layers removeObjectAtIndex:indexPath.row];
       //  [self.delegate viewController:self didDeleteLayer:layer];        //call after removing row so proper undo objects are saved
        
       [self.delegate viewController:self didDeleteLayer:layer];
        
        if (indexPath.row <= self.activeLayerIndex) {
            if (self.activeLayerIndex > 0) {
                self.activeLayerIndex--;
                NSLog(@"active layer minus 1");
            }
        }
         if ((whatWasActive > 0) && (self.activeLayerIndex == 0)){
             self.activeLayerIndex = self.layers.count - 1;
        }
        
       
        
        if (self.layers.count == 1) {
            [tableView setEditing:NO animated:YES];
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    /*
    NSLog(@" cell count %d", self.layers.count);
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@" cell count %d", self.layers.count);
        if (indexPath.row < self.layers.count) {
             NSLog(@" cell count %d", self.layers.count);       
        SDDrawingLayer *layer = self.layers[indexPath.row];
            [self.delegate viewController:self didDeleteLayer:layer];
        [self.layers removeObjectAtIndex:indexPath.row];
         NSLog(@" cell count %d", self.layers.count);
            
            //call after removing row so proper undo objects are saved
              // self.activeLayerIndex = 0;
         NSLog(@" cell count %d", self.layers.count);
            
            if (self.activeLayerIndex >= self.layers.count) {
                self.activeLayerIndex = self.layers.count - 1;
            } else if (indexPath.row < self.activeLayerIndex) {
                self.activeLayerIndex--;
            }
        
        if (self.layers.count == 1) {
            [tableView setEditing:NO animated:YES];
        }
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
     NSLog(@" cell count %d", self.layers.count);
    
    [tableView reloadData];
     */
    [tableView reloadData];

}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
      NSLog(@"moving layer number %d to %d",fromIndexPath.row, toIndexPath.row);
    // fetch the object at the row being moved
    SDDrawingLayer *layer = self.layers[fromIndexPath.row];
    
    // remove the original from the data structure
    [self.layers removeObjectAtIndex:fromIndexPath.row];
    
    // insert the object at the target row
    [self.layers insertObject:layer atIndex:toIndexPath.row];
    
    [self.delegate viewController:self didMoveLayer:layer toIndex:toIndexPath.row];
    [self setActiveLayerIndex:toIndexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.activeLayerIndex = indexPath.row;
    
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    [self performSegueWithIdentifier:@"LayerSettingsSegue" sender:@(indexPath.row)];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    
    return 64;
}

@end