/*==============================================================================
            Copyright (c) 2013 QUALCOMM Austria Research Center GmbH.
            All Rights Reserved.
            Qualcomm Confidential and Proprietary

This Vuforia(TM) sample application in source code form ("Sample Code") for the
Vuforia Software Development Kit and/or Vuforia Extension for Unity
(collectively, the "Vuforia SDK") may in all cases only be used in conjunction
with use of the Vuforia SDK, and is subject in all respects to all of the terms
and conditions of the Vuforia SDK License Agreement, which may be found at
https://developer.vuforia.com/legal/license.

By retaining or using the Sample Code in any manner, you confirm your agreement
to all the terms and conditions of the Vuforia SDK License Agreement.  If you do
not agree to all the terms and conditions of the Vuforia SDK License Agreement,
then you may not retain or use any of the Sample Code in any manner.
==============================================================================*/


#import "InfoViewController.h"
#import "InfoView.h"
#import "VideoPlaybackAppDelegate.h"


@implementation InfoViewController

//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (void)loadView
{
    // Create the info view
    InfoView* v = [[[InfoView alloc] init] autorelease];
    
    // Set self as target for InfoView's continue button
    [[v continueButton] addTarget:self action:@selector(continueButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self setView:v];
}


//------------------------------------------------------------------------------
#pragma mark - Autorotation

// Support landscape interface orientations
- (NSUInteger)supportedInterfaceOrientations
{
    // iOS >= 6
    return UIInterfaceOrientationMaskLandscape;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    // iOS < 6
    return UIInterfaceOrientationLandscapeLeft == toInterfaceOrientation || UIInterfaceOrientationLandscapeRight == toInterfaceOrientation;
}


//------------------------------------------------------------------------------
#pragma mark - User interaction
// Continue button event handler
- (void)continueButtonPressed
{
    VideoPlaybackAppDelegate* app = (VideoPlaybackAppDelegate*)[[UIApplication sharedApplication] delegate];
    [app rootViewControllerDismissPresentedViewController];
}

@end
