/*==============================================================================
            Copyright (c) 2012-2013 QUALCOMM Austria Research Center GmbH.
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


@file
    VideoPlaybackAppDelegate.mm

@brief
    This sample application shows how to play a video in AR mode.
    
    Video from local files can be played directly on the image target.  Playback
    of remote files is supported in full screen mode only.
==============================================================================*/


#import "VideoPlaybackAppDelegate.h"
#import "QCARControl.h"
#import "EAGLViewController.h"
#import "SplashViewController.h"
#import "InfoViewController.h"
#import <QCAR/QCAR.h>
#import <QCAR/QCAR_iOS.h>


// Flag to show if the device has a retina display
BOOL displayIsRetina = NO;


@interface VideoPlaybackAppDelegate (PrivateMethods)

- (void)determineDeviceDisplayType;
- (void)splashTimerFired:(NSTimer*)timer;

@end


@implementation VideoPlaybackAppDelegate

- (void)dealloc
{
    [_window release];
    
    [super dealloc];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //com.KloudnationEnterprise.RealityCheck
    //com.qualcomm.qcar.testapps.${PRODUCT_NAME:rfc1034identifier},${PRODUCT_NAME}
    // Determine the device display type (is it retina?)
//        http://login.onlineskillscoach.com/mobile/installer/AutoCheck/AutoCheck.ipa
    [self determineDeviceDisplayType];
    
    // Create the EAGLView with the screen dimensions
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    boundsEAGLView = screenBounds;
    
    // Create app window
    self.window = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
    
    // Create the EAGLViewController (the view controller of the EAGLView, which
    // is used to render the augmented scene)
    eaglViewController = [[EAGLViewController alloc] initWithFrame:boundsEAGLView];
    
    // If this device has a retina display, scale the EAGLView bounds that will
    // be passed to QCAR; this allows it to calculate the size and position of
    // the viewport correctly when rendering the video background
    if (YES == displayIsRetina) {
        boundsEAGLView.size.width *= 2.0;
        boundsEAGLView.size.height *= 2.0;
    }
    
    // Set ourselves as the QCARControl delegate, so it can inform us of
    // significant events, such as the completion of QCAR initialisation, which
    // is performed asynchronously
    [[QCARControl getInstance] setDelegate:self];
    
    // Set the root view controller
    [self.window setRootViewController:eaglViewController];

    [self.window makeKeyAndVisible];
    
    // Prevent screen dimming after idle time
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    // Start video playback from the current position (the beginning) on the
    // first run of the app
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        videoPlaybackTime[i] = VIDEO_PLAYBACK_CURRENT_POSITION;
    }

    return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Hide the status bar (exiting the app whilst the MPMoviePlayerController
    // is displayed can cause the status bar to be shown the next time the app
    // is launched)
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    // Initialise QCAR.  As we are QCARControl's delegate, it will call our
    // initQCARComplete method when initialisation has completed
    [[QCARControl getInstance] initQCAR];
    qcarCameraIsActive = NO;
    
    // Present the splash screen
    SplashViewController* splashViewController = [[[SplashViewController alloc] init] autorelease];
    [self rootViewControllerPresentViewController:splashViewController inContext:NO];
    
    // Start a timer to dismiss the splash screen
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(splashTimerFired:) userInfo:nil repeats:NO];

#ifdef EXAMPLE_CODE_REMOTE_FILE
    // Load a remote file for playback
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        VideoPlayerHelper* player = [(EAGLView*)eaglViewController.view getVideoPlayerHelper:i];
        [player load:@"http://login.onlineskillscoach.com/OSCFiles/Messages/Files/kelly@onlineskillscoach.com_Under_Armour_Highlight_Cleat_9.10.2013_1.49.41_68.mp4" playImmediately:YES fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
    }
#else
    // For each video-augmented target
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        // Load a local file for playback and resume playback if video was
        // playing when the app went into the background
        
        VideoPlayerHelper* player = [(EAGLView*)eaglViewController.view getVideoPlayerHelper:i];
        NSString* filename;
        
        switch (i) {
            case 0:
                filename = @"VuforiaSizzleReel_1.m4v";
//                filename=@"https://vines.s3.amazonaws.com/videos/08C49094-DFB4-46DF-8110-EEEC7D4D6115-1133-000000B8AD9BE72C_1.0.1.mp4";
//                filename = @"clientVideo.mp4";
                break;
            case 1:
                filename = @"VuforiaSizzleReel_2.m4v";
//                filename=@"testvideo.mp4";
//                 filename=@"http://login.onlineskillscoach.com/OSCFiles/Messages/Files/kelly@onlineskillscoach.com_Under_Armour_Highlight_Cleat_9.10.2013_1.49.41_68.mp4";
//                filename = @"kelly@onlineskillscoach.com_Under_Armour_Highlight_Cleat_9.10.2013_1.49.41_68.mp4";
                break;

//            default:
//                filename = @"VuforiaSizzleReel_2.m4v";
//                break;
        }
        
        if (NO == [player load:filename playImmediately:NO fromPosition:videoPlaybackTime[i]]) {
            NSLog(@"Failed to load media");
        }
    }
#endif
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Remove any presented view controller that may be on display
    [self rootViewControllerDismissPresentedViewController];
    
    // Tidy up video playback state
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        VideoPlayerHelper* player = [(EAGLView*)eaglViewController.view getVideoPlayerHelper:i];
        
        // If the video is playing, pause it
        if (PLAYING == [player getStatus]) {
            [player pause];
        }
        
        // Store the current video playback time for use when resuming
        videoPlaybackTime[i] = [player getCurrentPosition];
        
        // Unload the video
        if (NO == [player unload]) {
            NSLog(@"Failed to unload media");
        }
    }

    // Stop the camera
    QCARControl* control = [QCARControl getInstance];
    [control stopCamera];
    qcarCameraIsActive = NO;

    // Stop and deinitialise the tracker
    [control stopTracker:QCAR::Tracker::IMAGE_TRACKER];
    [control deinitTracker:QCAR::Tracker::IMAGE_TRACKER];

    // Pause and deinitialise QCAR
    [control pauseQCAR];
    [control deinitQCAR];

    // Be a good OpenGL ES citizen: now that QCAR is paused and the render
    // thread is not executing, inform the root view controller that the
    // EAGLView should finish any OpenGL ES commands
    [eaglViewController finishOpenGLESCommands];
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Be a good OpenGL ES citizen: inform the root view controller that the
    // EAGLView should free any easily recreated OpenGL ES resources
    [eaglViewController freeOpenGLESResources];
}


//------------------------------------------------------------------------------
#pragma mark - Public methods

// Present a view controller using the root view controller (eaglViewController)
- (void)rootViewControllerPresentViewController:(UIViewController*)viewController inContext:(BOOL)currentContext
{
    if (YES == currentContext) {
        // Use UIModalPresentationCurrentContext so the root view is not hidden
        // when presenting another view controller
        [eaglViewController setModalPresentationStyle:UIModalPresentationCurrentContext];
    }
    else {
        // Use UIModalPresentationFullScreen so the presented view controller
        // covers the screen
        [eaglViewController setModalPresentationStyle:UIModalPresentationFullScreen];
    }
    
    if ([eaglViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // iOS > 4
        [eaglViewController presentViewController:viewController animated:NO completion:nil];
    }
    else {
        // iOS 4
        [eaglViewController presentModalViewController:viewController animated:NO];
    }
}


// Dismiss a view controller presented by the root view controller
// (eaglViewController)
- (void)rootViewControllerDismissPresentedViewController
{
    // Dismiss the presented view controller (return to the root view
    // controller)
    if ([eaglViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        // iOS > 4
        [eaglViewController dismissViewControllerAnimated:NO completion:nil];
    }
    else {
        // iOS 4
        [eaglViewController dismissModalViewControllerAnimated:NO];
    }
}


//------------------------------------------------------------------------------
#pragma mark - QCARControlDelegate methods

- (void)initQCARComplete:(ErrorReport*)error
{
    // QCARControl is informing us that QCAR initialisation has completed
    
    if (nil != error) {
        [error log];
        [error release];
        return;
    }
    
    // Frames from the camera are always landscape, no matter what the
    // orientation of the device.  Tell QCAR to rotate the video background (and
    // the projection matrix it provides to us for rendering our augmentation)
    // by 90 degrees, as our EAGLView is fixed in portrait orientation
    QCAR::setRotation(QCAR::ROTATE_IOS_90);
    
    // Tell QCAR we've created a drawing surface
    QCAR::onSurfaceCreated();
    
    // Tell QCAR the size of the drawing surface
    QCAR::onSurfaceChanged(boundsEAGLView.size.width, boundsEAGLView.size.height);
    
    // We need an image tracker, which will track our target, so initialise it
    // and load its data now.  As we are QCARControl's delegate, it will call
    // our loadAndActivateImageTrackerDataSetComplete method when tracker
    // initialisation, loading and activation has completed
     [[QCARControl getInstance] loadAndActivateImageTrackerDataSet:@"Demotest.xml"];
//    [[QCARControl getInstance] loadAndActivateImageTrackerDataSet:@"StonesAndChips.xml"];
}


- (void)loadAndActivateImageTrackerDataSetComplete:(ErrorReport*)error
{
    // QCARControl is informing us that image tracker data loading has completed
    
    if (nil != error) {
        [error log];
        [error release];
        return;
    }
    
    // Set the number of simultaneous trackables to two
    [[QCARControl getInstance] setHint:QCAR::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS toValue:NUM_VIDEO_TARGETS];
    
    // Resume QCAR
    [[QCARControl getInstance] resumeQCAR];
    
    // Start the camera.  This causes QCAR to locate our EAGLView in the view
    // hierarchy, start a render thread, and then call renderFrameQCAR on the
    // view periodically
    [[QCARControl getInstance] startCameraForViewWidth:boundsEAGLView.size.width andHeight:boundsEAGLView.size.height];
    qcarCameraIsActive = YES;

    // Start the tracker
    [[QCARControl getInstance] startTracker:QCAR::Tracker::IMAGE_TRACKER];
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

// Determine whether the device has a retina display
- (void)determineDeviceDisplayType
{
    // If UIScreen mainScreen responds to selector
    // displayLinkWithTarget:selector: and the scale property is 2.0, then this
    // is a retina display
    displayIsRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && 2.0 == [UIScreen mainScreen].scale);
}


- (void)splashTimerFired:(NSTimer*)timer
{
    // If the QCAR camera is active
    if (YES == qcarCameraIsActive) {
        // Dismiss the splash screen, which is the view controller currently
        // presented by the root view controller
        [self rootViewControllerDismissPresentedViewController];

        // Now display the info view
        InfoViewController* infoViewController = [[[InfoViewController alloc] init] autorelease];
        [self rootViewControllerPresentViewController:infoViewController inContext:YES];
    }
    else {
        // QCAR camera is not yet active, schedule another timer
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(splashTimerFired:) userInfo:nil repeats:NO];
    }
}

@end
