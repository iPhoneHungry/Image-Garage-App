#import <UIKit/UIKit.h>
#import "myCustomFilterCell.h"

@class SDfilterlistViewController;




@interface SDfilterlistViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>
{
      NSIndexPath *theUserSelectedPath;
    int moverNumber;
   
}


-(void) newFilterSelected: (NSIndexPath *)indexPath;
-(void)amountEntered:(NSInteger)amount;

- (IBAction)filterCancelButton:(UIBarButtonItem *)sender;
@property (strong, nonatomic) IBOutlet UITableView *tableView;



@end