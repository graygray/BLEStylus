//
//  Quartz.m
//  TemperatureSensor
//
//  Created by primax on 1/17/13.
//  Copyright (c) 2013 Apple Inc. All rights reserved.
//

#import "Quartz.h"

// gray
static int penS=0;                       // pen's point or line size
static Boolean isDrawLine=true;          // draw line or point
static Boolean isDrawForTest=false;

@implementation Quartz

- (id)initWithFrame:(CGRect)frame
{
//    NSLog(@"initWithFrame");

    // init static variable
    //penS = 1;
    //isDrawLine = true;
    //isDrawForTest = false;
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor=[UIColor whiteColor];
        
        //init array
        for (int i=0; i<DRAW_LEVEL; i++) {
            bzpathArray[i] = [[UIBezierPath alloc] init];
            bzpathArray[i].lineCapStyle=kCGLineCapRound;
            bzpathArray[i].miterLimit=0;
            bzpathArray[i].lineWidth=(i+5);
        }
        
        brushPattern=[UIColor blueColor];
    }

    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
//    NSLog(@"drawRect");
    
    [self drawCircles];

    [brushPattern setStroke];
    // Drawing code
    for (int i=0; i<DRAW_LEVEL; i++) {
        if (bzpathUse[i]) {
//            NSLog(@"for loop, i:%d\n", i);
            [bzpathArray[i] strokeWithBlendMode:kCGBlendModeNormal alpha:1.0];
        }
    }
    
//    contextf = UIGraphicsGetCurrentContext();
//    
//    // Draw them with a 2.0 stroke width so they are a bit more visible.
//	CGContextSetLineWidth(contextf, 9.0);
//	
//	// Draw a single line from left to right
//	CGContextMoveToPoint(contextf, 10.0, 30.0);
//	CGContextAddLineToPoint(contextf, 19.0, 39.0);
//
//	CGContextStrokePath(contextf);
//    CGContextSetLineWidth(contextf, 3.0);
//	
//	// Draw a single line from left to right
//	CGContextMoveToPoint(contextf, 310.0, 30.0);
//	CGContextAddLineToPoint(contextf, 510.0, 30.0);
//	CGContextStrokePath(contextf);
//    
// 
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGContextSetLineWidth(context, 2.0);
//    
//    CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
//    
//    CGContextSetLineWidth(context, 3.0);
//    CGContextMoveToPoint(context, 100, 100);
//    CGContextAddLineToPoint(context, 150, 150);
//    CGContextStrokePath(context);
//    
//    CGContextSetLineWidth(context, 7.0);
//    CGContextMoveToPoint(context, 150, 150);
//    CGContextAddLineToPoint(context, 100, 200);
//    CGContextStrokePath(context);
//   
//    CGContextSetLineWidth(context, 11.0);
//    CGContextMoveToPoint(context, 100, 200);
//    CGContextAddLineToPoint(context, 50, 150);
//    CGContextStrokePath(context);
//    
//    CGContextSetLineWidth(context, 15.0);
//    CGContextMoveToPoint(context, 50, 150);
//    CGContextAddLineToPoint(context, 100, 100);
//    CGContextStrokePath(context);
}

#pragma mark - Touch Methods
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"touchesBegan");
    
    UITouch *mytouch=[[touches allObjects] objectAtIndex:0];
    // record start touch point
    PreviousTouchPoint = [mytouch locationInView:self];
        
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
//    NSLog(@"touchesMoved, pen size:%d\n", penS);
    if (isDrawForTest) {
        penS = (penS+1) % DRAW_LEVEL;
    }

    UITouch *mytouch=[[touches allObjects] objectAtIndex:0];
    int i = penS;
    bzpathUse[i] = true;
    if (isDrawLine) {
//        NSLog(@"i:%d\n", i);
        [bzpathArray[i] moveToPoint:PreviousTouchPoint];
        PreviousTouchPoint = [mytouch locationInView:self];
    } else {
        [bzpathArray[i] moveToPoint:[mytouch locationInView:self]];
    }
    [bzpathArray[i] addLineToPoint:[mytouch locationInView:self]];

    
    [self setNeedsDisplay];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
//    NSLog(@"touchesEnded, pen size:%d", penS);

 }

- (void)dealloc
{
    NSLog(@"dealloc");
    [brushPattern release];
    [super dealloc];
}

+(void)setPenS:(int)s{
//    NSLog(@"setPenS:%d", s);
    
    if (isDrawForTest) {
        penS = s+1;
    } else {
        penS = s;
    }
    
}

-(void)setPoint{
    NSLog(@"setPoint");
    isDrawLine = false;

}

-(void)setLine{
    NSLog(@"setLine");
    isDrawLine = true;

}

- (void)drawCircles {
    
//    [[UIColor yellowColor] set];
//    UIBezierPath *circle1 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CIRCLE1_CENTER_X, CIRCLE1_CENTER_Y, CIRCLE_DIAMETER, CIRCLE_DIAMETER)];
//    [circle1 setLineWidth:5];
//    [circle1 stroke];
//    
//    [[UIColor greenColor] set];
//    UIBezierPath *circle2 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CIRCLE2_CENTER_X, CIRCLE2_CENTER_Y, CIRCLE_DIAMETER, CIRCLE_DIAMETER)];
//    [circle2 setLineWidth:5];
//    [circle2 stroke];
//    
//    [[UIColor redColor] set];
//    UIBezierPath *circle3 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CIRCLE3_CENTER_X, CIRCLE3_CENTER_Y, CIRCLE_DIAMETER, CIRCLE_DIAMETER)];
//    [circle3 setLineWidth:5];
//    [circle3 stroke];
//    
//    [[UIColor blackColor] set];
//    CGPoint startPoint = CGPointMake(CIRCLE1_CENTER_X+LINE_DIFF,CIRCLE1_CENTER_Y+LINE_DIFF);
//    CGPoint endPoint = CGPointMake(CIRCLE2_CENTER_X+LINE_DIFF,CIRCLE2_CENTER_Y+LINE_DIFF);
//    UIBezierPath *line1 = [[UIBezierPath alloc]init];
//    line1.lineWidth = 5;
//    [line1 moveToPoint:startPoint];
//    [line1 addLineToPoint:endPoint];
//    [line1 stroke];
//    
//    startPoint = CGPointMake(CIRCLE2_CENTER_X+LINE_DIFF-2,CIRCLE2_CENTER_Y+LINE_DIFF-2);
//    endPoint = CGPointMake(CIRCLE3_CENTER_X+LINE_DIFF,CIRCLE3_CENTER_Y+LINE_DIFF);
////    line1 = [[UIBezierPath alloc]init];
////    line1.lineWidth = 5;
//    [line1 moveToPoint:startPoint];
//    [line1 addLineToPoint:endPoint];
//    [line1 stroke];
//    [line1 release];
}

@end
