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
==============================================================================*/

#import "EAGLView.h"
#import "VideoPlayerHelper.h"
#import "Texture.h"
#import <QCAR/UIGLViewProtocol.h>
#import "QCARControl.h"
// Define to load and play a video file from a remote location
//#define EXAMPLE_CODE_REMOTE_FILE

#define NUM_VIDEO_TARGETS 2
#define NUM_AUGMENTATION_TEXTURES 5

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView
// subclass.  The view content is basically an EAGL surface you render your
// OpenGL scene into.  Note that setting the view non-opaque will only work if
// the EAGL surface has an alpha channel.

// EAGLView is a subclass of UIView and conforms to the informal protocol
// UIGLViewProtocol
@interface EAGLView : UIView <UIGLViewProtocol>
{
@private
    // Instantiate one VideoPlayerHelper per target
    VideoPlayerHelper* videoPlayerHelper[NUM_VIDEO_TARGETS];
    
    // Used to differentiate between taps and double taps
    BOOL tapPending;
    
    // Timer to pause on-texture video playback after tracking has been lost.
    // Note: written/read on two threads, but never concurrently
    NSTimer* trackingLostTimer;
    
    // Coordinates of user touch
    float touchLocation_X;
    float touchLocation_Y;
    
    // Lock to synchronise data that is (potentially) accessed concurrently
    NSLock* dataLock;
    
    // OpenGL ES context
    EAGLContext *context;
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    
    // Shader handles
    GLuint shaderProgramID;
    GLint vertexHandle;
    GLint normalHandle;
    GLint textureCoordHandle;
    GLint mvpMatrixHandle;
    GLint texSampler2DHandle;
    
    // Texture used when rendering augmentation
    Texture* augmentationTexture[NUM_AUGMENTATION_TEXTURES];
    
    
    ////////////arivu/////////
    CALayer *cameraLayer;
    AVPlayer *player;
    AVPlayerLayer *playerLayer;
    BOOL videoInitialized;
    CATransform3D transform;
    QCARControl  *qUtils;
    int frameCount;
    BOOL hideVideo;

}

@property (nonatomic, retain) id cameraImage;
// --- Public methods ---
- (VideoPlayerHelper*)getVideoPlayerHelper:(int)index;
- (int)tapInsideTargetWithID;
- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;

@end
