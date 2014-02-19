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


#import "SplashViewController.h"


extern BOOL displayIsRetina;


@interface SplashViewController (PrivateMethods)

- (UIImage*)getSplashImageForOrientation:(BOOL)landscape;

@end


@implementation SplashViewController

//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (void)loadView
{
    // Create the splash image
    UIImage* image = [self getSplashImageForOrientation:NO];
    UIImageView* v = [[[UIImageView alloc] initWithImage:image] autorelease];
    [self setView:v];
}


//------------------------------------------------------------------------------
#pragma mark - Autorotation

// Support all interface orientations on iPad, but only portrait on iPhone and
// iPod
- (NSUInteger)supportedInterfaceOrientations
{
    // iOS >= 6
    UIInterfaceOrientationMask mask = UIInterfaceOrientationMaskAll;
    
    if (UIUserInterfaceIdiomPad != [[UIDevice currentDevice] userInterfaceIdiom]) {
        mask = UIInterfaceOrientationMaskPortrait;
    }
    
    return mask;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    // iOS < 6
    BOOL ret = YES;
    
    if (UIUserInterfaceIdiomPad != [[UIDevice currentDevice] userInterfaceIdiom]) {
        ret = UIInterfaceOrientationPortrait == toInterfaceOrientation;
    }
    
    return ret;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Ensure the correct splash screen image is displayed
    UIImage* image = [self getSplashImageForOrientation:UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    [(UIImageView*)[self view] setImage:image];
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

- (UIImage*)getSplashImageForOrientation:(BOOL)landscape
{
    NSString* splashImageName = @"Default.png";
    
    if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
        // iPad
        if (landscape) {
            if (YES == displayIsRetina) {
//                splashImageName = @"Default-Landscape@2x~ipad.png";
            }
            else {
//                splashImageName = @"Default-Landscape~ipad.png";
            }
        }
        else {
            if (YES == displayIsRetina) {
//                splashImageName = @"Default-Portrait@2x~ipad.png";
            }
            else {
//                splashImageName = @"Default-Portrait~ipad.png";
            }
        }
         splashImageName = @"Default-568h@2x.png";
    }
    else {
        // iPhone and iPod
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        
        if (568 == screenBounds.size.height) {
            // iPhone 5
            splashImageName = @"Default-568h@2x.png";
        }
        else if (YES == displayIsRetina) {
            splashImageName = @"Default@2x.png";
        }
    }
    
    return [UIImage imageNamed:splashImageName];
}

@end
