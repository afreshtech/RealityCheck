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


#import "EAGLViewController.h"
#import "QCARControl.h"


@implementation EAGLViewController

//------------------------------------------------------------------------------
#pragma mark - Lifecycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    
    if (nil != self) {
        viewFrame = frame;
    }
    
    return self;
}


- (void)dealloc
{
    [eaglView release];

    [super dealloc];
}


- (void)loadView
{
    // Create the EAGLView
    eaglView = [[EAGLView alloc] initWithFrame:viewFrame];
    [self setView:eaglView];
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  Inform the EAGLView
    [eaglView finishOpenGLESCommands];
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Inform the EAGLView
    [eaglView freeOpenGLESResources];
}


//------------------------------------------------------------------------------
#pragma mark - Autorotation

// The EAGLView is fixed in a single orientation, so the video feed from the
// camera is not rotated relative to the real world as the device changes
// orientation
- (NSUInteger)supportedInterfaceOrientations
{
    // iOS >= 6
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    // iOS < 6
    return UIInterfaceOrientationPortrait == toInterfaceOrientation;
}

@end
