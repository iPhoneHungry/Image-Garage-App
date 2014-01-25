#import <UIKit/UIKit.h>

@protocol ShowcaseFilterListControllerDelegate <NSObject>


-(void) newFilterSelected: (NSIndexPath *)indexPath;
@end;

@interface ShowcaseFilterListController : UITableViewController
{
   
    
    NSIndexPath *theUserSelectedPath;
}

@property (weak) id <ShowcaseFilterListControllerDelegate> delegate;

@end

