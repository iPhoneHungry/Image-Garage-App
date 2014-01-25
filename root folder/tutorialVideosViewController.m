//
//  tutorialVideosViewController.m
//  SimpleDrawing
//
//  Created by android on 6/17/13.
//  Copyright (c) 2013 Nathanial Woolls. All rights reserved.
//

#import "tutorialVideosViewController.h"

@interface tutorialVideosViewController ()

@end

@implementation tutorialVideosViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSString *tutorialsLink = @"http://www.imagegarageapp.com/tutorials.html";
    NSURL *tutorialsUrl = [NSURL URLWithString:tutorialsLink];
    NSURLRequest *loadTutorials = [NSURLRequest requestWithURL:tutorialsUrl];
    [self.tutorialWebView loadRequest:loadTutorials];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTutorialWebView:nil];
    [super viewDidUnload];
}
@end
