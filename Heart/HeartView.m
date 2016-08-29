//
//  HeartView.m
//  Heart
//
//  Created by zzzzz on 16/8/27.
//  Copyright © 2016年 zzzzz. All rights reserved.
//

#import "HeartView.h"

@implementation HeartView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.pointArray = @[];
    
    return self;
}

- (void)setPointArray:(NSArray<NSNumber *> *)pointArray {
    if (_pointArray != pointArray) {
        _pointArray = pointArray;
    }
//    [self drawLine];
}

- (void)drawLine {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 1);//线宽
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
    CGContextBeginPath(context);
    
    for (int i = 0; i < (int)[self.pointArray count] - 1; i++) {
        CGContextMoveToPoint(context, self.frame.size.width - i, _pointArray[i].integerValue);
        CGContextAddLineToPoint(context, self.frame.size.width - i - 1, _pointArray[i + 1].integerValue);
    }
    
    CGContextStrokePath(context);
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 1);//线宽
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
    CGContextBeginPath(context);
    
    for (int i = 0; i < (int)[self.pointArray count] - 1; i++) {
        CGContextMoveToPoint(context, self.frame.size.width - i, _pointArray[i].integerValue);
        CGContextAddLineToPoint(context, self.frame.size.width - i - 1, _pointArray[i + 1].integerValue);
    }
    
    CGContextStrokePath(context);
    
    
    
    
    
    
    
    
    
    
    
}

@end
