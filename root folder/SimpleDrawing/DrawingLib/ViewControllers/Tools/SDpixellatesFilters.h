//
//  SDpixellatesFilters.h
//  SimpleDrawing
//
//  Created by android on 6/9/13.
//  Copyright (c) 2013 Nathanial Woolls. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "myCustomFilterCell.h"

@interface SDpixellatesFilters : UITableViewController <UITableViewDelegate, UITableViewDataSource>
{
    NSIndexPath *theUserSelectedPath;
     int chosen_Filter_Was;
    
}


-(void) newFilterSelected: (NSIndexPath *)indexPath;
-(void)amountEntered:(NSInteger)amount;

- (IBAction)filterCancelButton:(UIBarButtonItem *)sender;
@property (strong, nonatomic) IBOutlet UITableView *tableView;


@end
