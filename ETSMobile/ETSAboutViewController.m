//
//  ETSAboutViewController.m
//  ETSMobile
//
//  Created by Jean-Philippe Martin on 2014-04-06.
//  Copyright (c) 2014 ApplETS. All rights reserved.
//

#import "ETSAboutViewController.h"
#import "MFSideMenu.h"

@implementation ETSAboutViewController

- (IBAction)panLeftMenu:(id)sender
{
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{}];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.8
                          delay:0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.aboutLabel.alpha = 1;
                     }
                     completion:nil];
}

@end