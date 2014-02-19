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
#import "QCARControl.h"
#import "Texture.h"
#import "Quad.h"
#import "SampleMath.h"

#import <QCAR/Renderer.h>
#import <QCAR/ImageTarget.h>
#import <QCAR/Vectors.h>
#import <QCAR/VideoBackgroundConfig.h>
#import <QCAR/TrackableResult.h>

#import "ShaderUtils.h"
#define MAKESTRING(x) #x
#import "Shaders/Shader.fsh"
#import "Shaders/Shader.vsh"


#import <QCAR/Image.h>


//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the QCAR camera, which causes QCAR to locate our EAGLView and start
//    the render thread.
// 3) QCAR calls our renderFrameQCAR method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************


extern BOOL displayIsRetina;


namespace {
    // --- Data private to this unit ---
    
    // Augmentation model scale factor
    const float kObjectScale = 3.0f;
    
    // Texture filenames (an Object3D object is created for each texture)
    const char* textureFilenames[NUM_AUGMENTATION_TEXTURES] = {
        "icon_play.png",
        "icon_loading.png",
        "icon_error.png",
        "ua.png",
        "superhigh.png"
//        "VuforiaSizzleReel_1.png",
//        "VuforiaSizzleReel_2.png"
    };
    
    enum tagObjectIndex {
        OBJECT_PLAY_ICON,
        OBJECT_BUSY_ICON,
        OBJECT_ERROR_ICON,
        OBJECT_KEYFRAME_1,
        OBJECT_KEYFRAME_2,
    };
    
    const NSTimeInterval DOUBLE_TAP_INTERVAL = 0.3f;
    const NSTimeInterval TRACKING_LOST_TIMEOUT = 2.0f;
    
    // Playback icon scale factors
    const float SCALE_ICON = 2.0f;
    const float SCALE_ICON_TRANSLATION = 1.98f;
    
    // Video quad texture coordinates
    const GLfloat videoQuadTextureCoords[] = {
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
    };
    
    struct tagVideoData {
        // Needed to calculate whether a screen tap is inside the target
        QCAR::Matrix44F modelViewMatrix;
        
        // Trackable dimensions
        QCAR::Vec2F targetPositiveDimensions;
        
        // Currently active flag
        BOOL isActive;
    } videoData[NUM_VIDEO_TARGETS];
    
    int touchedTarget = 0;
    
    
}


@interface EAGLView (PrivateMethods)

- (void)initShaders;
- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

- (void)tapTimerFired:(NSTimer*)timer;
- (void)createTrackingLostTimer;
- (void)terminateTrackingLostTimer;
- (void)trackingLostTimerFired:(NSTimer*)timer;

@end


@implementation EAGLView
@synthesize cameraImage;
// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}
//---------------------------------Arivu---------------------------------------------
- (CATransform3D) GLtoCATransform3D:(QCAR::Matrix44F)m
{
    CATransform3D t = CATransform3DIdentity;
    t.m11 = m.data[0];
    t.m12 = m.data[1];
    t.m13 = m.data[2];
    t.m14 = m.data[3];
    t.m21 = m.data[4];
    t.m22 = m.data[5];
    t.m23 = m.data[6];
    t.m24 = m.data[7];
    t.m31 = m.data[8];
    t.m32 = m.data[9];
    t.m33 = m.data[10];
    t.m34 = m.data[11];
    t.m41 = m.data[12];
    t.m42 = m.data[13];
    t.m43 = m.data[14];
    t.m44 = m.data[15];
    
    return t;
}
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
#pragma mark - Lifecycle
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        // Enable retina mode if available on this device
        if (YES == displayIsRetina) {
            [self setContentScaleFactor:2.0f];
        }
        
        // Load the augmentation textures
        for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
            augmentationTexture[i] = [[Texture alloc] initWithImageFile:[NSString stringWithCString:textureFilenames[i] encoding:NSASCIIStringEncoding]];
        }
        
        // Create the data lock
        dataLock = [[NSLock alloc] init];
        
        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        // For each target, create a VideoPlayerHelper object and zero the
        // target dimensions
        for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
            videoPlayerHelper[i] = [[VideoPlayerHelper alloc] init];
            
            videoData[i].targetPositiveDimensions.data[0] = 0.0f;
            videoData[i].targetPositiveDimensions.data[1] = 0.0f;
        }
        
        // Generate the OpenGL ES texture and upload the texture data for use
        // when rendering the augmentation
        for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
            GLuint textureID;
            glGenTextures(1, &textureID);
            [augmentationTexture[i] setTextureID:textureID];
            glBindTexture(GL_TEXTURE_2D, textureID);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [augmentationTexture[i] width], [augmentationTexture[i] height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[augmentationTexture[i] pngData]);
            
            // Set appropriate texture parameters (for NPOT textures)
            if (OBJECT_KEYFRAME_1 <= i) {
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            }
        }
        
        [self initShaders];
      qUtils = [QCARControl getInstance] ;
        // Set the QCAR initialisation flags (informs QCAR of the OpenGL ES
        // version)
//        [[QCARControl getInstance] setQCARInitFlags:QCAR::GL_20];
        if ([self isRetinaEnabled])
        {
            self.contentScaleFactor = 2.0f;
            qUtils.contentScalingFactor = self.contentScaleFactor;
        }
        
        
        
        [qUtils setQCARInitFlags:QCAR::GL_20];
        CAEAGLLayer *layer = (CAEAGLLayer *)self.layer;
        layer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                    nil];
        
//        context_ = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        frameCount = 0;
        cameraLayer = [CALayer layer];
        cameraLayer.contentsGravity = kCAGravityResizeAspectFill;
        cameraLayer.frame = self.layer.bounds;
        [self.layer addSublayer:cameraLayer];
        
        hideVideo = YES;
    }
    
    return self;
}


- (void)dealloc
{
    [self deleteFramebuffer];

    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }

    [context release];
    [dataLock release];

    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        [videoPlayerHelper[i] release];
    }

    for (int i = 0; i < NUM_AUGMENTATION_TEXTURES; ++i) {
        [augmentationTexture[i] release];
    }

    [super dealloc];
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}


//------------------------------------------------------------------------------
#pragma mark - User interaction
// The user touched the screen
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    
    // Store the current touch location
    touchLocation_X = point.x;
    touchLocation_Y = point.y;
    
    // Determine which target was touched (if no target was touch, touchedTarget
    // will be -1)
    touchedTarget = [self tapInsideTargetWithID];
    NSLog(@"touchedTarget value %d",touchedTarget);
    // Ignore touches when videoPlayerHelper is playing in fullscreen mode
    if (-1 != touchedTarget && PLAYING_FULLSCREEN != [videoPlayerHelper[touchedTarget] getStatus]) {
        if (NO == tapPending) {
            [NSTimer scheduledTimerWithTimeInterval:DOUBLE_TAP_INTERVAL target:self selector:@selector(tapTimerFired:) userInfo:nil repeats:NO];
        }
    }
    tapPending=YES;
}


- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    // Ignore touches when videoPlayerHelper is playing in fullscreen mode
    if (-1 != touchedTarget && PLAYING_FULLSCREEN != [videoPlayerHelper[touchedTarget] getStatus]) {
        // If the user double-tapped the screen
        if (YES == tapPending) {
            tapPending = NO;
            MEDIA_STATE mediaState = [videoPlayerHelper[touchedTarget] getStatus];
            
            if (ERROR != mediaState && NOT_READY != mediaState) {
                // Play the video
                NSLog(@"Playing video with native player");
                [videoPlayerHelper[touchedTarget] play:YES fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
            }
            
            // If any on-texture video is playing, pause it
            for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
                if (PLAYING == [videoPlayerHelper[i] getStatus]) {
                    [videoPlayerHelper[i] pause];
                }
            }
        }
        else {
            tapPending = YES;
        }
    }
}



// Fires if the user tapped the screen (no double tap)
- (void)tapTimerFired:(NSTimer*)timer
{
    if (YES == tapPending) {
        tapPending = NO;
        
        // Get the state of the video player for the target the user touched
        MEDIA_STATE mediaState = [videoPlayerHelper[touchedTarget] getStatus];
        
#ifdef EXAMPLE_CODE_REMOTE_FILE
        // With remote files, single tap starts playback using the native player
        if (ERROR != mediaState && NOT_READY != mediaState) {
            // Play the video
            NSLog(@"Playing video with native player");
            [videoPlayerHelper[touchedTarget] play:YES fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
        }
#else
        // If any on-texture video is playing, pause it
        for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
            if (PLAYING == [videoPlayerHelper[i] getStatus]) {
                [videoPlayerHelper[i] pause];
            }
        }
        
        // For the target the user touched
        if (ERROR != mediaState && NOT_READY != mediaState && PLAYING != mediaState) {
            // Play the video
            NSLog(@"Playing video with on-texture player");
            [videoPlayerHelper[touchedTarget] play:NO fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
        }
#endif
    }
}


// Determine whether a screen tap is inside the target
- (int)tapInsideTargetWithID
{
    QCAR::Vec3F intersection, lineStart, lineEnd;
    // Get the current projection matrix
    QCAR::Matrix44F projectionMatrix = [[QCARControl getInstance] projectionMatrix];
    QCAR::Matrix44F inverseProjMatrix = SampleMath::Matrix44FInverse(projectionMatrix);
    CGRect rect = [self bounds];
    int touchInTarget = -1;
    
    // ----- Synchronise data access -----
    [dataLock lock];
    
    // The target returns as pose the centre of the trackable.  Thus its
    // dimensions go from -width / 2 to width / 2 and from -height / 2 to
    // height / 2.  The following if statement simply checks that the tap is
    // within this range
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        SampleMath::projectScreenPointToPlane(inverseProjMatrix, videoData[i].modelViewMatrix, rect.size.width, rect.size.height,
                                              QCAR::Vec2F(touchLocation_X, touchLocation_Y), QCAR::Vec3F(0, 0, 0), QCAR::Vec3F(0, 0, 1), intersection, lineStart, lineEnd);
        
        if ((intersection.data[0] >= -videoData[i].targetPositiveDimensions.data[0]) && (intersection.data[0] <= videoData[i].targetPositiveDimensions.data[0]) &&
            (intersection.data[1] >= -videoData[i].targetPositiveDimensions.data[1]) && (intersection.data[1] <= videoData[i].targetPositiveDimensions.data[1])) {
            // The tap is only valid if it is inside an active target
            if (YES == videoData[i].isActive) {
                touchInTarget = i;
                break;
            }
        }
    }

    [dataLock unlock];
    // ----- End synchronise data access -----
    
    return touchInTarget;
}


// Get a pointer to a VideoPlayerHelper object held by this EAGLView
- (VideoPlayerHelper*)getVideoPlayerHelper:(int)index
{
    return videoPlayerHelper[index];
}


////////////////////////////////////////////////////////////////////////////////
// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method on a single background thread ***
- (void)renderFrameQCAR{
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Begin QCAR rendering for this frame, retrieving the tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    
    // Render the video background
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    
    // We must detect if background reflection is active and adjust the culling
    // direction.  If the reflection is active, this means the pose matrix has
    // been reflected as well, therefore standard counter clockwise face culling
    // will result in "inside out" models
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON) {
        // Front camera
        glFrontFace(GL_CW);
    }
    else {
        // Back camera
        glFrontFace(GL_CCW);
    }

    // Get the active trackables
    int numActiveTrackables = state.getNumTrackableResults();
//    if (numActiveTrackables>0) {
//        NSString *filename;
//        switch (numActiveTrackables) {
//            case 1:
//                               filename=@"https://vines.s3.amazonaws.com/videos/08C49094-DFB4-46DF-8110-EEEC7D4D6115-1133-000000B8AD9BE72C_1.0.1.mp4";
//                break;
//            case 2:
//                                 filename=@"http://login.onlineskillscoach.com/OSCFiles/Messages/Files/kelly@onlineskillscoach.com_Under_Armour_Highlight_Cleat_9.10.2013_1.49.41_68.mp4";
//                break;
//                
//           
//        }
//        NSURL *url=[NSURL URLWithString:filename];
//        [self initVideo:url];
//        glDisable(GL_DEPTH_TEST);
//        glDisable(GL_CULL_FACE);
//        
//        QCAR::Renderer::getInstance().end();
//        [self renderFrame];
//        return;
//    }
    NSLog(@"=====================================");
    
    // ----- Synchronise data access -----
    [dataLock lock];
    
    // Assume all targets are inactive (used when determining tap locations)
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        videoData[i].isActive = NO;
    }
    
    // Did we find any trackables this frame?
    for (int i = 0; i < numActiveTrackables; ++i) {
        // Get the trackable
        const QCAR::TrackableResult* trackableResult = state.getTrackableResult(i);
        const QCAR::ImageTarget& imageTarget = (const QCAR::ImageTarget&) trackableResult->getTrackable();

        // VideoPlayerHelper to use for current target
        int playerIndex = 0;    // stones
        
        if (strcmp(imageTarget.getName(), "ua") == 0)
        {
            playerIndex = 1;
        }
        
        // Mark this video (target) as active
        videoData[playerIndex].isActive = YES;
        
        // Get the target size (used to determine if taps are within the target)
        if (0.0f == videoData[playerIndex].targetPositiveDimensions.data[0] ||
            0.0f == videoData[playerIndex].targetPositiveDimensions.data[1]) {
            const QCAR::ImageTarget& imageTarget = (const QCAR::ImageTarget&) trackableResult->getTrackable();
            
            videoData[playerIndex].targetPositiveDimensions = imageTarget.getSize();
            // The pose delivers the centre of the target, thus the dimensions
            // go from -width / 2 to width / 2, and -height / 2 to height / 2
            videoData[playerIndex].targetPositiveDimensions.data[0] /= 2.0f;
            videoData[playerIndex].targetPositiveDimensions.data[1] /= 2.0f;
        }
        
        // Get the current trackable pose
        const QCAR::Matrix34F& trackablePose = trackableResult->getPose();
        
        // This matrix is used to calculate the location of the screen tap
        videoData[playerIndex].modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(trackablePose);
        
        float aspectRatio;
        const GLvoid* texCoords;
        GLuint frameTextureID;
        BOOL displayVideoFrame = YES;
        
        // Retain value between calls
        static GLuint videoTextureID[NUM_VIDEO_TARGETS] = {0};
        
        MEDIA_STATE currentStatus = [videoPlayerHelper[playerIndex] getStatus];
//            [videoPlayerHelper[playerIndex] play:NO fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
        [videoPlayerHelper[playerIndex] playUrlVideo:NO view:self fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
            currentStatus = [videoPlayerHelper[playerIndex] getStatus];
      
        // --- INFORMATION ---
        // One could trigger automatic playback of a video at this point.  This
        // could be achieved by calling the play method of the VideoPlayerHelper
        // object if currentStatus is not PLAYING.  You should also call
        // getStatus again after making the call to play, in order to update the
        // value held in currentStatus.
        // --- END INFORMATION ---
        
        switch (currentStatus) {
            case PLAYING: {
                // If the tracking lost timer is scheduled, terminate it
                if (nil != trackingLostTimer) {
                    // Timer termination must occur on the same thread on which
                    // it was installed
                    [self performSelectorOnMainThread:@selector(terminateTrackingLostTimer) withObject:nil waitUntilDone:YES];
                }
                
                // Upload the decoded video data for the latest frame to OpenGL
                // and obtain the video texture ID
                GLuint videoTexID = [videoPlayerHelper[playerIndex] updateVideoData];
                
                if (0 == videoTextureID[playerIndex]) {
                    videoTextureID[playerIndex] = videoTexID;
                }
                
                // Fallthrough
            }
            case PAUSED:
                if (0 == videoTextureID[playerIndex]) {
                    // No video texture available, display keyframe
                    displayVideoFrame = NO;
                }
                else {
                    // Display the texture most recently returned from the call
                    // to [videoPlayerHelper updateVideoData]
                    frameTextureID = videoTextureID[playerIndex];
                }
                
                break;
//            case STOPPED:
//                [videoPlayerHelper stop];
//                break;
            default:
                videoTextureID[playerIndex] = 0;
                displayVideoFrame = NO;
                break;
        }
        
        if (YES == displayVideoFrame) {
            // ---- Display the video frame -----
            aspectRatio = (float)[videoPlayerHelper[playerIndex] getVideoHeight] / (float)[videoPlayerHelper[playerIndex] getVideoWidth];
            texCoords = videoQuadTextureCoords;
        }
        else {
            // ----- Display the keyframe -----
            Texture* t = augmentationTexture[OBJECT_KEYFRAME_1 + playerIndex];
            frameTextureID = [t textureID];
            aspectRatio = (float)[t height] / (float)[t width];
            texCoords = quadTexCoords;
        }
        
        // Get the current projection matrix
        QCAR::Matrix44F projMatrix = [[QCARControl getInstance] projectionMatrix];
        
        // If the current status is valid (not NOT_READY or ERROR), render the
        // video quad with the texture we've just selected
        if (NOT_READY != currentStatus) {
            // Convert trackable pose to matrix for use with OpenGL
            QCAR::Matrix44F modelViewMatrixVideo = QCAR::Tool::convertPose2GLMatrix(trackablePose);
            QCAR::Matrix44F modelViewProjectionVideo;
            
            ShaderUtils::translatePoseMatrix(0.0f, 0.0f, videoData[playerIndex].targetPositiveDimensions.data[0],
                                             &modelViewMatrixVideo.data[0]);
            
            ShaderUtils::scalePoseMatrix(videoData[playerIndex].targetPositiveDimensions.data[0], 
                                         videoData[playerIndex].targetPositiveDimensions.data[0] * aspectRatio, 
                                         videoData[playerIndex].targetPositiveDimensions.data[0],
                                         &modelViewMatrixVideo.data[0]);
            
            ShaderUtils::multiplyMatrix(projMatrix.data,
                                        &modelViewMatrixVideo.data[0] ,
                                        &modelViewProjectionVideo.data[0]);
            
            glUseProgram(shaderProgramID);
            
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, frameTextureID);
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionVideo.data[0]);
            glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, quadIndices);
            
            glDisableVertexAttribArray(vertexHandle);
            glDisableVertexAttribArray(normalHandle);
            glDisableVertexAttribArray(textureCoordHandle);
            
            glUseProgram(0);
        }

        // If the current status is not PLAYING, render an icon
        if (PLAYING != currentStatus) {
            GLuint iconTextureID;
            
            switch (currentStatus) {
                case READY:
                case REACHED_END:
                case PAUSED:
                case STOPPED: {
                    // ----- Display play icon -----
                    iconTextureID = [augmentationTexture[OBJECT_PLAY_ICON] textureID];
                    break;
                }
                    
                case ERROR: {
                    // ----- Display error icon -----
                    iconTextureID = [augmentationTexture[OBJECT_ERROR_ICON] textureID];
                    break;
                }
                    
                default: {
                    // ----- Display busy icon -----
                    iconTextureID = [augmentationTexture[OBJECT_BUSY_ICON] textureID];
                    break;
                }
            }
            
            // Convert trackable pose to matrix for use with OpenGL
            QCAR::Matrix44F modelViewMatrixButton = QCAR::Tool::convertPose2GLMatrix(trackablePose);
            QCAR::Matrix44F modelViewProjectionButton;
            
            ShaderUtils::translatePoseMatrix(0.0f, 0.0f, videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON_TRANSLATION, &modelViewMatrixButton.data[0]);
            
            ShaderUtils::scalePoseMatrix(videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                         videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                         videoData[playerIndex].targetPositiveDimensions.data[1] / SCALE_ICON,
                                         &modelViewMatrixButton.data[0]);
            
            ShaderUtils::multiplyMatrix(projMatrix.data,
                                        &modelViewMatrixButton.data[0] ,
                                        &modelViewProjectionButton.data[0]);
            
            glDepthFunc(GL_LEQUAL);
            
            glUseProgram(shaderProgramID);
            
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, quadTexCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            // Blend the icon over the background
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, iconTextureID);
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionButton.data[0] );
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, quadIndices);
            
            glDisable(GL_BLEND);
            
            glDisableVertexAttribArray(vertexHandle);
            glDisableVertexAttribArray(normalHandle);
            glDisableVertexAttribArray(textureCoordHandle);
            
            glUseProgram(0);
            
            glDepthFunc(GL_LESS);
        }
        
        ShaderUtils::checkGlError("VideoPlayback renderFrameQCAR");
//    }
        
    }
    // --- INFORMATION ---
    // One could pause automatic playback of a video at this point.  Simply call
    // the pause method of the VideoPlayerHelper object without setting the
    // timer (as below).
    // --- END INFORMATION ---
    
    // If a video is playing on texture and we have lost tracking, create a
    // timer on the main thread that will pause video playback after
    // TRACKING_LOST_TIMEOUT seconds
  
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        if (nil == trackingLostTimer && NO == videoData[i].isActive && PLAYING == [videoPlayerHelper[i] getStatus]) {
            [self performSelectorOnMainThread:@selector(createTrackingLostTimer) withObject:nil waitUntilDone:YES];
            break;
        }
    }
    
    [dataLock unlock];
    // ----- End synchronise data access -----
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];
   }


// Create the tracking lost timer
- (void)createTrackingLostTimer
{
    trackingLostTimer = [NSTimer scheduledTimerWithTimeInterval:TRACKING_LOST_TIMEOUT target:self selector:@selector(trackingLostTimerFired:) userInfo:nil repeats:NO];
}


// Terminate the tracking lost timer
- (void)terminateTrackingLostTimer
{
    [trackingLostTimer invalidate];
    trackingLostTimer = nil;
}


// Tracking lost timer fired, pause video playback
- (void)trackingLostTimerFired:(NSTimer*)timer
{
    // Tracking has been lost for TRACKING_LOST_TIMEOUT seconds, pause playback
    // (we can safely do this on all our VideoPlayerHelpers objects)
    for (int i = 0; i < NUM_VIDEO_TARGETS; ++i) {
        [videoPlayerHelper[i] stop];
    }
    trackingLostTimer = nil;
}


//------------------------------------------------------------------------------
#pragma mark - Private methods

//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

// Initialise OpenGL 2.x shaders
- (void)initShaders
{
    shaderProgramID = ShaderUtils::createProgramFromBuffer(vertexShader, fragmentShader);
    
    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}

- (CGImageRef)createCGImage:(const QCAR::Image *)qcarImage
{
    int width = qcarImage->getWidth();
    int height = qcarImage->getHeight();
    int bitsPerComponent = 8;
    int bitsPerPixel = QCAR::getBitsPerPixel(QCAR::RGB888);
    int bytesPerRow = qcarImage->getBufferWidth() * bitsPerPixel / bitsPerComponent;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, qcarImage->getPixels(), QCAR::getBufferSize(width, height, QCAR::RGB888), NULL);
    
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    
    return (CGImageRef)[(id)imageRef autorelease];
}

//- (void)createFrameBuffer {
//    
//    // This is called on main thread
//    
//    if (context && !defaultFramebuffer)
//        [EAGLContext setCurrentContext:context];
//    
//    glGenFramebuffers(1, &defaultFramebuffer);
//    glGenRenderbuffers(1, &defaultFramebuffer);
//    
//    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
//    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer_);
//    
//    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
//    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer_);
//    
//}


////----------------------------------Arivu--------------------------------------------
//- (void)renderFrame {
////    if (!defaultFramebuffer) {
////        
////        [self performSelectorOnMainThread:@selector(createFrameBuffer) withObject:nil waitUntilDone:YES];
////    }
////    [self setFramebuffer];
//    
////    [EAGLContext setCurrentContext:context];
////    
////    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
////    glBindRenderbuffer(GL_RENDERBUFFER, defaultFramebuffer);
//    
//    //glRenderbufferStorage(GL_RENDERBUFFER, GL_RGB565, 1, 1);
//    
//    /*GLint width, height;
//     glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
//     glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
//     glViewport(0, 0, width, height);*/
//    
//    if (frameCount < 5) {
//        frameCount++;
//        return;
//    }
//    
//    [self render];
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        
//        
//        [CATransaction begin];
//        [CATransaction setValue:(id)kCFBooleanTrue
//                         forKey:kCATransactionDisableActions];
//        cameraLayer.contents = cameraImage;
//        
//        playerLayer.transform = transform;
//        playerLayer.hidden = hideVideo;
//        [CATransaction commit];
//    });
//    
//}

- (void)initVideo:(NSURL *)videoUrl {
    
    //Replace the URL by yours
    //     NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"kelly@onlineskillscoach.com_Under_Armour_Highlight_Cleat_9.10.2013_1.49.41_68.mp4" ofType:nil]];
//    NSURL *url = [NSURL URLWithString:@"http://login.onlineskillscoach.com/OSCFiles/Messages/Files/kelly@onlineskillscoach.com_Under_Armour_Highlight_Cleat_9.10.2013_1.49.41_68.mp4"];
    
    AVURLAsset *avasset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithAsset:avasset];
    player = [[AVPlayer alloc] initWithPlayerItem:item];
    
    playerLayer = [[AVPlayerLayer playerLayerWithPlayer:player] retain];
    CGSize size = self.bounds.size;
    float x = size.width/2.0-187.0;
    float y = size.height/2.0 - 125.0;
    
    playerLayer.frame = CGRectMake(x, y, 374, 270);
    playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    [cameraLayer addSublayer:playerLayer];
    playerLayer.hidden = hideVideo;
    transform = CATransform3DIdentity;
    
    NSString *tracksKey = @"tracks";
    
    [avasset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:tracksKey] completionHandler:
     ^{
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            NSError *error = nil;
                            AVKeyValueStatus status = [avasset statusOfValueForKey:tracksKey error:&error];
                            
                            if (status == AVKeyValueStatusLoaded) {
                                
                                NSLog(@"Video loaded");
                                videoInitialized = YES;
                            }
                            else {
                                // You should deal with the error appropriately.
                                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                            }
                        });
     }];
}

// test to see if the screen has hi-res mode
- (BOOL) isRetinaEnabled
{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)]
            &&
            ([UIScreen mainScreen].scale == 2.0));
}
- (void)render {
    // Render video background and retrieve tracking state
    QCAR::setFrameFormat(QCAR::RGB888, true);
    
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    //QCAR::Renderer::getInstance().drawVideoBackground();
    
    QCAR::Frame ff = state.getFrame();
    if (ff.getNumImages() <= 0) {
        QCAR::Renderer::getInstance().end();
        return;
    }
    
    for (int i = 0; i < ff.getNumImages(); i++) {
        const QCAR::Image *qcarImage = ff.getImage(i);
        if (qcarImage->getFormat() == QCAR::RGB888)
        {
            
            self.cameraImage = (id)[self createCGImage:qcarImage];
            break;
        }
    }
    
    NSLog(@"getTrackable Results %d",state.getNumTrackableResults());
//     || videoInitialized == NO
    if (state.getNumTrackableResults() == 0) {
        [player pause];
        hideVideo = YES;
        QCAR::Renderer::getInstance().end();
        return;
    }
    hideVideo = NO;
    if (player.rate == 0) {
        [player play];
    }
    
    NSLog(@" Results %d",state.getNumTrackableResults());
    // Get the trackable
    const QCAR::TrackableResult* trackable = state.getTrackableResult(0);
    
    QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(trackable->getPose());
    
    CGFloat ScreenScale = [[UIScreen mainScreen] scale];
    float xscl = qUtils->viewport.sizeX/ScreenScale/2;
    float yscl = qUtils->viewport.sizeY/ScreenScale/2;
    
    QCAR::Matrix44F scalingMatrix = {xscl,0,0,0,
        0,yscl,0,0,
        0,0,1,0,
        0,0,0,1};
    
    QCAR::Matrix44F flipY = { 1, 0,0,0,
        0,-1,0,0,
        0, 0,1,0,
        0, 0,0,1};
    
    ShaderUtils::translatePoseMatrix(0.0f, 0.0f, 3, &modelViewMatrix.data[0]);
    ShaderUtils::multiplyMatrix(&modelViewMatrix.data[0], &flipY.data[0], &modelViewMatrix.data[0]);
    ShaderUtils::multiplyMatrix(&qUtils.projectionMatrix.data[0],&modelViewMatrix.data[0], &modelViewMatrix.data[0]);
    ShaderUtils::multiplyMatrix(&scalingMatrix.data[0], &modelViewMatrix.data[0], &modelViewMatrix.data[0]);
    ShaderUtils::multiplyMatrix(&flipY.data[0], &modelViewMatrix.data[0], &modelViewMatrix.data[0]);
    transform = [self GLtoCATransform3D:modelViewMatrix];
    
    QCAR::Renderer::getInstance().end();
    
}

//------------------------------------------------------------------------------
@end
