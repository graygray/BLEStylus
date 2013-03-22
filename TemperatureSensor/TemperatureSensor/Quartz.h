//
//  Quartz.h
//  TemperatureSensor
//
//  Created by primax on 1/17/13.
//  Copyright (c) 2013 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CIRCLE1_CENTER_X 150
#define CIRCLE1_CENTER_Y 400
#define CIRCLE2_CENTER_X 350
#define CIRCLE2_CENTER_Y 150
#define CIRCLE3_CENTER_X 550
#define CIRCLE3_CENTER_Y 300
#define CIRCLE_DIAMETER 50
#define LINE_DIFF CIRCLE_DIAMETER/2
#define DRAW_LEVEL 51

@interface Quartz : UIView {
    
    UIColor *brushPattern;    
    UIBezierPath *bzpathArray[DRAW_LEVEL];
    Boolean bzpathUse[DRAW_LEVEL];
    CGPoint PreviousTouchPoint;
    UIBezierPath *pCircle1;
    
    CGContextRef contextf;
    UIBezierPath *bezier;
    
    
}

+(void)setPenS:(int)s;
-(void)setPoint;
-(void)setLine;

@end
