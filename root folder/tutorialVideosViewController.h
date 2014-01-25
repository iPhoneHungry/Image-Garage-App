//
//  tutorialVideosViewController.h
//  SimpleDrawing
//
//  Created by android on 6/17/13.
//  Copyright (c) 2013 Nathanial Woolls. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface tutorialVideosViewController : UIViewController<UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *tutorialWebView;

@end
