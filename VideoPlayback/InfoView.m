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

#import "InfoView.h"

@implementation InfoView

@synthesize continueButton;

- (id)init
{
    self = [super init];
    
    if (nil != self) {
        // Make this view the same size and orientation as the splashscreen
        // (landscape right)
        
        // ----- View -----
        // Get the main screen bounds
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGRect viewFrame;
        viewFrame.origin.x = 0.0f;
        viewFrame.origin.y = 0.0f;
        viewFrame.size.width = screenBounds.size.height;
        viewFrame.size.height = screenBounds.size.width;
        [self setFrame:viewFrame];
        
        // Adjust the rectangle (viewFrame) to use as reference for positioning
        // other UI elements
        viewFrame.origin.y = viewFrame.size.height * 0.1;
        viewFrame.size.height *= 0.8;
        
        // Set the view's position (its centre) to be the centre of the window,
        // so we can rotate it from portrait to landscape
        CGPoint pos;
        pos.x = screenBounds.size.width / 2;
        pos.y = screenBounds.size.height / 2;
        [self setCenter:pos];
        [self setTransform:CGAffineTransformMakeRotation(90 * M_PI / 180)];
        
        // View is not opaque
        [self setOpaque:NO];
        
        // ----- Text -----
        CGRect textFrame;
        textFrame.origin.x = viewFrame.size.width * 0.1f;
        textFrame.origin.y = viewFrame.origin.y + viewFrame.size.height * 0.1f;
        textFrame.size.width = viewFrame.size.width * 0.8f;
        textFrame.size.height = 0.0f;
        
        CGFloat fontSize;
        
        if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
            // iPad
            fontSize = 31;
        }
        else {
            fontSize = 14;
        }
        
//        UIFont *font = [UIFont fontWithName:@"Arial" size:fontSize];
//        UILabel* textLabel = [[[UILabel alloc] initWithFrame:textFrame] autorelease];
//        [textLabel setFont:font];
//        [textLabel setBackgroundColor:[UIColor clearColor]];
//        [textLabel setNumberOfLines:0];
//        [textLabel setLineBreakMode:UILineBreakModeWordWrap];
//        [textLabel setTextColor:[UIColor whiteColor]];
//        [textLabel setText:@"This sample application shows how to play a video in AR mode.\n\nVideo from local files can be played directly on the image target.  Playback of remote files is supported in full screen mode only."];
//        [textLabel sizeToFit];
        
//        [self addSubview:textLabel];
        
        // ----- Button -----
        // Add continue button
        continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        // Button image and position
        UIImage* buttonImage;
        UIImage* buttonSelectedImage;
        
        if (UIUserInterfaceIdiomPad == [[UIDevice currentDevice] userInterfaceIdiom]) {
            // iPad
            buttonImage = [UIImage imageNamed:@"start_large.png"];
            buttonSelectedImage = [UIImage imageNamed:@"start_large_press.png"];
        }
        else {
            buttonImage = [UIImage imageNamed:@"start_medium.png"];
            buttonSelectedImage = [UIImage imageNamed:@"start_medium_press.png"];
        }
        
        // Make the button twice as high as its image
        CGSize imageSize = [buttonImage size];
        [continueButton setFrame:CGRectMake(viewFrame.size.width - imageSize.width, viewFrame.origin.y + viewFrame.size.height - imageSize.height * 2, imageSize.width, imageSize.height * 2)];
        [continueButton setBackgroundColor:[UIColor clearColor]];
        [continueButton setImage:buttonImage forState:UIControlStateNormal];
        [continueButton setImage:buttonSelectedImage forState:UIControlStateHighlighted];
        
        [self addSubview:continueButton];
    }
    
    return self;
}


// Overridden so we can draw the view's background
- (void)drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    UIColor* colorBackground = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.75];
    UIColor* colorDivider = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.50];
    
    // Adjust the rectangle (rect) to use as reference for drawing
    rect.origin.y = rect.size.height * 0.1;
    rect.size.height *= 0.8;
    CGRect fillRect = rect;
    CGFloat divider_Y = rect.size.height - [continueButton frame].size.height - 1;
    CGFloat divider_H = 1.0f;
    
    // Draw top and bottom rectangles
    CGContextSetFillColorWithColor(c, colorBackground.CGColor);
    fillRect.size.height = divider_Y;
    CGContextFillRect(c, fillRect);
    fillRect.origin.y = rect.origin.y + divider_Y + divider_H;
    fillRect.size.height = rect.size.height - divider_Y - divider_H;
    CGContextFillRect(c, fillRect);
    
    // Draw divider line
    CGContextSetFillColorWithColor(c, colorDivider.CGColor);
    fillRect.origin.y = rect.origin.y + divider_Y;
    fillRect.size.height = divider_H;
    CGContextFillRect(c, fillRect);
}

@end
