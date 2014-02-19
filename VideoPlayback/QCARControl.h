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
#import <QCAR/DataSet.h>
#import <QCAR/Tool.h>
#import <QCAR/Tracker.h>
#import "ErrorReport.h"


//------------------------------------------------------------------------------
// QCARControl is a simple helper class, used to control QCAR.  It allows the
// app to encapsulate all QCAR-specific code in one place


//------------------------------------------------------------------------------
// QCARControlDelegate: protocol used to inform our delegate of various events
@protocol QCARControlDelegate

@required
- (void)initQCARComplete:(ErrorReport*)error;
- (void)loadAndActivateImageTrackerDataSetComplete:(ErrorReport*)error;

@end


//------------------------------------------------------------------------------
// QCARControl: used to control QCAR via an Objective-C interface
@interface QCARControl : NSObject {
    //-----------arivu-------
   @public 
    struct tagViewport {        // shared between users of QCARutils
        int posX;
        int posY;
        int sizeX;
        int sizeY;
    } viewport;
    //-------------end-----------
@private
    // The current QCAR image tracker data set
    QCAR::DataSet* dataSet;
}


// --- Properties ---
// QCARControl delegate (if set, receives callbacks in response to particular
// events, such as completion of QCAR initialisation)
@property (nonatomic, retain) id delegate;

// QCAR initialisation flags (passed to QCAR before initialising)
@property (nonatomic, readwrite) int QCARInitFlags;

// The OpenGL ES projection matrix, calculated by QCAR and used by the app when
// rendering the scene
@property (nonatomic, readonly) QCAR::Matrix44F projectionMatrix;

@property (nonatomic) CGFloat contentScalingFactor;
// --- Public methods ---
// Get the one and only instance of QCARControl
+ (QCARControl*)getInstance;

// QCAR control
- (void)initQCAR;
- (void)deinitQCAR;
- (BOOL)loadAndActivateImageTrackerDataSet:(NSString*)dataFile;
- (BOOL)deactivateDataSet;
- (void)deinitTracker:(QCAR::Tracker::TYPE)trackerType;
- (void)resumeQCAR;
- (void)pauseQCAR;
- (void)startCameraForViewWidth:(float)viewWidth andHeight:(float)viewHeight;
- (void)stopCamera;
- (BOOL)startTracker:(QCAR::Tracker::TYPE)trackerType;
- (BOOL)stopTracker:(QCAR::Tracker::TYPE)trackerType;
- (void)setHint:(unsigned int)hint toValue:(int)value;
- (BOOL)cameraTriggerAutoFocus;

@end
