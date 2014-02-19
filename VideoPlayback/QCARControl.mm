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


#import <QCAR/QCAR.h>
#import <QCAR/QCAR_iOS.h>
#import <QCAR/CameraDevice.h>
#import <QCAR/VideoBackgroundConfig.h>
#import <QCAR/Renderer.h>
#import <QCAR/TrackerManager.h>
#import <QCAR/ImageTracker.h>

#import "QCARControl.h"


namespace {
    // --- Data private to this unit ---
    
    // The one and only instance of QCARControl
    QCARControl* qcarControl = nil;
}


@interface QCARControl (PrivateMethods)

- (void)initQCARInBackground;
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight;
- (void)initTracker:(QCAR::Tracker::TYPE)trackerType;
- (void)loadAndActivateDataSetInBackground:(id)obj;
- (QCAR::DataSet*)loadDataSetFromFile:(NSString*)dataSetFilename;
- (BOOL)activateDataSet:(QCAR::DataSet*)qcarDataSet;

@end


@implementation QCARControl
@synthesize contentScalingFactor;
//------------------------------------------------------------------------------
#pragma mark - Lifecycle

// Return the one and only instance of QCARControl
+ (QCARControl*)getInstance
{
    if (nil == qcarControl) {
        qcarControl = [[QCARControl alloc] init];
    }
    
    return qcarControl;
}


- (void)dealloc
{
    [self setDelegate:nil];
    
    [super dealloc];
}


//------------------------------------------------------------------------------
#pragma mark - QCAR control

// Initialise QCAR
- (void)initQCAR
{
    NSLog(@"QCARControl initQCAR");
    
    // Initialising QCAR is a potentially lengthy operation, so perform it on a
    // background thread
    [self performSelectorInBackground:@selector(initQCARInBackground) withObject:nil];
}


// Deinitialise QCAR
- (void)deinitQCAR
{
    NSLog(@"QCARControl deinitQCAR");
    QCAR::deinit();
}


// Resume QCAR
- (void)resumeQCAR
{
    NSLog(@"QCARControl resumeQCAR");
    QCAR::onResume();
}


// Pause QCAR
- (void)pauseQCAR
{
    NSLog(@"QCARControl pauseQCAR");
    QCAR::onPause();
}


// Load the image tracker data set
- (BOOL)loadAndActivateImageTrackerDataSet:(NSString*)dataFile
{
    NSLog(@"QCARControl loadAndActivateImageTrackerDataSet");
    BOOL ret = YES;
    
    // Initialise the image tracker
    [self initTracker:QCAR::Tracker::IMAGE_TRACKER];
    
    // Get the QCAR tracker manager image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::Tracker::IMAGE_TRACKER));
    
    if (NULL == imageTracker) {
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
        ret = NO;
    }
    else {
        // Loading tracker data is a potentially lengthy operation, so perform
        // it on a background thread
        [self performSelectorInBackground:@selector(loadAndActivateDataSetInBackground:) withObject:dataFile];
    }
    
    return ret;
}


// Deactivate the image tracker data set (not used in this sample, but provided
// to partner loadAndActivateImageTrackerDataSet:)
- (BOOL)deactivateDataSet
{
    NSLog(@"QCARControl deactivateDataSet");
    BOOL ret = NO;
    
    // Get the image tracker from the QCAR tracker manager
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::Tracker::IMAGE_TRACKER));
    
    if (NULL != imageTracker) {
        // Activate the data set
        if (imageTracker->deactivateDataSet(dataSet)) {
            NSLog(@"INFO: successfully deactivated data set");
            ret = YES;
        }
        else {
            NSLog(@"ERROR: failed to deactivate data set");
        }
    }
    else {
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
    }
    
    return ret;
}


// Start QCAR camera with the specified view size
- (void)startCameraForViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    NSLog(@"QCARControl startCameraForViewWidth:andHeight:");
    
    if (QCAR::CameraDevice::getInstance().init(QCAR::CameraDevice::CAMERA_BACK)) {
        if (QCAR::CameraDevice::getInstance().start()) {
            NSLog(@"QCARControl camera started");
            
            // Configure QCAR video background
            [self configureVideoBackgroundWithViewWidth:viewWidth andHeight:viewHeight];
            
            // Cache the projection matrix
            const QCAR::CameraCalibration& cameraCalibration = QCAR::CameraDevice::getInstance().getCameraCalibration();
            _projectionMatrix = QCAR::Tool::getProjectionGL(cameraCalibration, 2.0f, 2500.0f);
        }
    }
}


// Stop QCAR camera
- (void)stopCamera
{
    NSLog(@"QCARControl stopCamera");
    
    // Stop and deinit the camera
    QCAR::CameraDevice::getInstance().stop();
    QCAR::CameraDevice::getInstance().deinit();
}


// Deinitialise the tracker
- (void)deinitTracker:(QCAR::Tracker::TYPE)trackerType
{
    NSLog(@"QCARControl deinitTracker type %d", trackerType);

    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    trackerManager.deinitTracker(trackerType);
}


// Start the tracker
- (BOOL)startTracker:(QCAR::Tracker::TYPE)trackerType
{
    NSLog(@"QCARControl startTracker type %d", trackerType);

    // Start the tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(trackerType);
    BOOL ret = NO;

    if (NULL != tracker) {
        if (true == tracker->start()) {
            NSLog(@"INFO: successfully started tracker");
            ret = YES;
        }
        else {
            NSLog(@"ERROR: failed to start tracker");
        }
    }
    else {
        NSLog(@"ERROR: failed to get the TextTracker from the tracker manager");
    }

    return ret;
}


// Stop the tracker
- (BOOL)stopTracker:(QCAR::Tracker::TYPE)trackerType
{
    NSLog(@"QCARControl stopTracker type %d", trackerType);

    // Stop the tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.getTracker(trackerType);
    BOOL ret = NO;

    if (NULL != tracker) {
        tracker->stop();
        NSLog(@"INFO: successfully stopped tracker");
        ret = YES;
    }
    else {
        NSLog(@"ERROR: failed to get the tracker from the tracker manager");
    }

    return ret;
}


// Set QCAR hint
- (void)setHint:(unsigned int)hint toValue:(int)value
{
    (void)QCAR::setHint(hint, value);
}


// Focus the camera
- (BOOL)cameraTriggerAutoFocus
{
    // Trigger an auto-focus to happen now, then switch back to continuous
    // auto-focus mode.  This allows the user to trigger an auto-focus if the
    // continuous mode fails to focus when required
    BOOL ret = NO;

    if (true == QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_TRIGGERAUTO)) {
        ret = true == QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO) ? YES : NO;
    }

    return ret;
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

// Initialise QCAR
// *** Performed on a background thread ***
- (void)initQCARInBackground
{
    // Background thread must have its own autorelease pool
    @autoreleasepool {
        QCAR::setInitParameters(self.QCARInitFlags);
        
        // QCAR::init() will return positive numbers up to 100 as it progresses
        // towards success.  Negative numbers indicate error conditions
        NSInteger initSuccess = 0;
        do {
            initSuccess = QCAR::init();
        } while (0 <= initSuccess && 100 > initSuccess);
        
        ErrorReport* error = nil;
        
        if (100 == initSuccess) {
            NSLog(@"INFO: successfully initialised QCAR");
        }
        else {
            // Failed to initialise QCAR
            error = [[ErrorReport alloc] initWithMessage:"ERROR: failed to initialise QCAR"];
        }
        
        // Inform the delegate that QCAR initialisation has completed (on the
        // main thread)
        [self.delegate performSelectorOnMainThread:@selector(initQCARComplete:) withObject:error waitUntilDone:NO];
    }
}


// Configure QCAR with the video background size
- (void)configureVideoBackgroundWithViewWidth:(float)viewWidth andHeight:(float)viewHeight
{
    NSLog(@"Configuring video background (%fw x %fh)", viewWidth, viewHeight);
    
    // Get the default video mode
    QCAR::CameraDevice& cameraDevice = QCAR::CameraDevice::getInstance();
    QCAR::VideoMode videoMode = cameraDevice.getVideoMode(QCAR::CameraDevice::MODE_DEFAULT);
    
    // Configure the video background
    QCAR::VideoBackgroundConfig config;
    config.mEnabled = true;
    config.mSynchronous = true;
    config.mPosition.data[0] = 0.0f;
    config.mPosition.data[1] = 0.0f;
    
    // Determine the orientation of the view.  Note, this simple test assumes
    // that a view is portrait if its height is greater than its width.  This is
    // not always true: it is perfectly reasonable for a view with portrait
    // orientation to be wider than it is high.  The test is suitable for the
    // dimensions used in this sample
    if (viewWidth < viewHeight) {
        // --- View is portrait ---
        
        // Compare aspect ratios of video and screen.  If they are different we
        // use the full screen size while maintaining the video's aspect ratio,
        // which naturally entails some cropping of the video
        float aspectRatioVideo = (float)videoMode.mWidth / (float)videoMode.mHeight;
        float aspectRatioView = viewHeight / viewWidth;
        
        if (aspectRatioVideo < aspectRatioView) {
            // Video (when rotated) is wider than the view: crop left and right
            // (top and bottom of video)
            
            // --============--
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // - =          = _
            // --============--
            
            config.mSize.data[0] = (int)videoMode.mHeight * (viewHeight / (float)videoMode.mWidth);
            config.mSize.data[1] = (int)viewHeight;
        }
        else {
            // Video (when rotated) is narrower than the view: crop top and
            // bottom (left and right of video).  Also used when aspect ratios
            // match (no cropping)
            
            // ------------
            // -          -
            // -          -
            // ============
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // =          =
            // ============
            // -          -
            // -          -
            // ------------
            
            config.mSize.data[0] = (int)viewWidth;
            config.mSize.data[1] = (int)videoMode.mWidth * (viewWidth / (float)videoMode.mHeight);
        }
    }
    else {
        // --- View is landscape ---
        
        // Compare aspect ratios of video and screen.  If they are different we
        // use the full screen size while maintaining the video's aspect ratio,
        // which naturally entails some cropping of the video
        float aspectRatioVideo = (float)videoMode.mWidth / (float)videoMode.mHeight;
        float aspectRatioView = viewWidth / viewHeight;
        
        if (aspectRatioVideo < aspectRatioView) {
            // Video is taller than the view: crop top and bottom
            
            // --------------------
            // ====================
            // =                  =
            // =                  =
            // =                  =
            // =                  =
            // ====================
            // --------------------
            
            config.mSize.data[0] = (int)viewWidth;
            config.mSize.data[1] = (int)videoMode.mHeight * (viewWidth / (float)videoMode.mWidth);
        }
        else {
            // Video is wider than the view: crop left and right.  Also used
            // when aspect ratios match (no cropping)
            
            // ---====================---
            // -  =                  =  -
            // -  =                  =  -
            // -  =                  =  -
            // -  =                  =  -
            // ---====================---
            
            config.mSize.data[0] = (int)videoMode.mWidth * (viewHeight / (float)videoMode.mHeight);
            config.mSize.data[1] = (int)viewHeight;
        }
    }
    
    // Set the config
    QCAR::Renderer::getInstance().setVideoBackgroundConfig(config);
}


// Initialise the tracker
- (void)initTracker:(QCAR::Tracker::TYPE)trackerType
{
    NSLog(@"QCARControl initTracker type %d", trackerType);

    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::Tracker* tracker = trackerManager.initTracker(trackerType);

    if (NULL == tracker) {
        NSLog(@"INFO: failed to initialise the tracker (it may have been initialised already)");
    }
    else {
        NSLog(@"INFO: successfully initialised the tracker");
    }
}


// Load image tracker data set and activate it
// *** Performed on a background thread ***
- (void)loadAndActivateDataSetInBackground:(id)obj
{
    // Background thread must have its own autorelease pool
    @autoreleasepool {
        ErrorReport* error = nil;
        
        // Load the data set
        NSString* dataFile = obj;
        dataSet = [self loadDataSetFromFile:dataFile];
        
        if (NULL != dataSet) {
            NSLog(@"INFO: successfully loaded data set");
            
            // Activate the data set
            if (YES == [self activateDataSet:dataSet]) {
                NSLog(@"INFO: successfully activated data set");
            }
            else {
                error = [[ErrorReport alloc] initWithMessage:"ERROR: failed to activate data set"];
            }
        }
        else {
            error = [[ErrorReport alloc] initWithMessage:"ERROR: failed to load data set"];
        }
        
        // Inform the delegate that data set loading and activation has
        // completed (on the main thread)
        [self.delegate performSelectorOnMainThread:@selector(loadAndActivateImageTrackerDataSetComplete:) withObject:error waitUntilDone:NO];
    }
}


// Load an image tracker data set from file
- (QCAR::DataSet*)loadDataSetFromFile:(NSString*)dataSetFilename
{
    QCAR::DataSet* qcarDataSet = NULL;
    static const char* msg = NULL;
    
    // Get the image tracker from the QCAR tracker manager
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::Tracker::IMAGE_TRACKER));
    
    if (NULL != imageTracker) {
        // Create the data set
        qcarDataSet = imageTracker->createDataSet();
        
        if (NULL == qcarDataSet) {
            msg = "ERROR: failed to create a new tracking data";
        }
        else {
            // Load the data set from the app's resources location
            if (!qcarDataSet->load([dataSetFilename cStringUsingEncoding:NSASCIIStringEncoding], QCAR::DataSet::STORAGE_APPRESOURCE)) {
                msg = "ERROR: failed to load data set";
                imageTracker->destroyDataSet(qcarDataSet);
                qcarDataSet = NULL;
            }
        }
    }
    else {
        msg = "ERROR: failed to get the ImageTracker from the tracker manager";
    }
    
    if (NULL == qcarDataSet) {
        // Failed to load the data set
        NSString* nsMsg = [NSString stringWithCString:msg encoding:NSASCIIStringEncoding];
        NSLog(@"%@", nsMsg);
    }
    
    return qcarDataSet;
}


// Activate an image tracker data set
- (BOOL)activateDataSet:(QCAR::DataSet*)qcarDataSet
{
    BOOL ret = NO;
    
    // Get the image tracker
    QCAR::TrackerManager& trackerManager = QCAR::TrackerManager::getInstance();
    QCAR::ImageTracker* imageTracker = static_cast<QCAR::ImageTracker*>(trackerManager.getTracker(QCAR::Tracker::IMAGE_TRACKER));
    
    if (NULL != imageTracker) {
        // Activate the data set
        if (imageTracker->activateDataSet(qcarDataSet)) {
            ret = YES;
        }
    }
    else {
        NSLog(@"ERROR: failed to get the ImageTracker from the tracker manager");
    }
    
    return ret;
}

@end
