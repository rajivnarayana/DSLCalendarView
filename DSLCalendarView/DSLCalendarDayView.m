/*
 DSLCalendarDayView.h
 
 Copyright (c) 2012 Dative Studios. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
 to endorse or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "DSLCalendarDayView.h"
#import "NSDate+DSLCalendarView.h"


@interface DSLCalendarDayView ()

@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSDate *dayAsDate;

@end


@implementation DSLCalendarDayView

@synthesize day = _day;

#pragma mark - Initialisation

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.backgroundColor = [UIColor whiteColor];
        _positionInWeek = DSLCalendarDayViewMidWeek;
        _dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        _dateLabel.font = [UIFont boldSystemFontOfSize:17.0];
        [self addSubview:_dateLabel];
    }
    
    return self;
}


#pragma mark Properties

- (void)setSelectionState:(DSLCalendarDayViewSelectionState)selectionState {
    _selectionState = selectionState;
    [self setNeedsDisplay];
}

- (void)setDay:(NSDateComponents *)day {
    _calendar = [day calendar];
    _dayAsDate = [day date];
    _day = nil;
    _dateLabel.text = [NSString stringWithFormat:@"%ld", (long)day.day];
}

- (NSDateComponents*)day {
    if (_day == nil) {
        _day = [_dayAsDate dslCalendarView_dayWithCalendar:_calendar];
    }
    
    return _day;
}

- (NSDate*)dayAsDate {
    return _dayAsDate;
}

- (void)setInCurrentMonth:(BOOL)inCurrentMonth {
    _inCurrentMonth = inCurrentMonth;
    _dateLabel.textColor = _inCurrentMonth ? [UIColor blackColor] : [UIColor grayColor];
}


#pragma mark UIView methods

- (void)drawRect:(CGRect)rect {
    if ([self isMemberOfClass:[DSLCalendarDayView class]]) {
        // If this isn't a subclass of DSLCalendarDayView, use the default drawing
        [self drawBackground];
    }
}


#pragma mark Drawing

- (void)drawBackground {
    UIColor *backgroundColor;
    if (self.isInCurrentMonth) {
        backgroundColor = [UIColor colorWithWhite:245.0/255.0 alpha:1.0];
    }
    else {
        backgroundColor = [UIColor colorWithWhite:225.0/255.0 alpha:1.0];
    }
    switch (self.selectionState) {
        case DSLCalendarDayViewStartOfSelection:
            [[self circleImageForStartOfSelectionWithBounds:self.bounds.size radius:self.bounds.size.height/3 color:_selectionDayColor backgroundColor:backgroundColor stripColor:_selectionRangeColor stripHeight:self.bounds.size.height/2 start:YES] drawInRect:self.bounds];
            break;
            
        case DSLCalendarDayViewEndOfSelection:
            [[self circleImageForStartOfSelectionWithBounds:self.bounds.size radius:self.bounds.size.height/3 color:_selectionDayColor backgroundColor:backgroundColor stripColor:_selectionRangeColor stripHeight:self.bounds.size.height/2 start:NO] drawInRect:self.bounds];
            break;
            
        case DSLCalendarDayViewWithinSelection:
            [[self stripImageForStartOfSelectionWithBounds:self.bounds.size height:self.bounds.size.height/2 color:_selectionRangeColor backgroundColor:backgroundColor] drawInRect:self.bounds];
            break;
            
        case DSLCalendarDayViewWholeSelection:
            [[self circleImageForSingleSelectionWithBounds:self.bounds.size radius:self.bounds.size.height/3 color:_selectionDayColor backgroundColor:backgroundColor] drawInRect:self.bounds];
            break;
            
        case DSLCalendarDayViewNotSelected:
        default:
            [backgroundColor setFill];
            UIRectFill(self.bounds);
    }
}

-(UIImage *)circleImageForStartOfSelectionWithBounds:(CGSize )size
                                              radius:(CGFloat)radius
                                               color:(UIColor *)color
                                     backgroundColor:(UIColor *)backgroundColor
                                          stripColor:(UIColor *)stripColor
                                         stripHeight:(CGFloat)stripHeight
                                               start:(BOOL)start {
    radius = MIN(MAX(size.width, size.height)/2-1, radius);
    stripHeight = MIN(size.height , stripHeight);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

    [stripColor setFill];
    UIRectFill(CGRectOffset(CGRectMake(start ?size.width/2 : 0, 0, size.width/2, stripHeight), 0, size.height/2 - stripHeight/2));

    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextSetLineWidth(context, 2); // set the line width
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGPathRef pathRef = CGPathCreateWithEllipseInRect(CGRectOffset(CGRectMake(0, 0, radius * 2, radius * 2), size.width/2 - radius, size.height/2- radius), nil);
    CGContextAddPath(context, pathRef);
    CGContextFillPath(context);
    CGContextAddPath(context, pathRef);
    CGContextStrokePath(context);
    CGPathRelease(pathRef);
    UIImage *ellipseImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ellipseImage;
}

-(UIImage *)stripImageForStartOfSelectionWithBounds:(CGSize)size height:(CGFloat)height color:(UIColor *)color backgroundColor:(UIColor *)backgroundColor {
    height = MIN(size.height , height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

    [color setFill];
    UIRectFill(CGRectOffset(CGRectMake(0, 0, size.width, height), 0, size.height/2 - height/2));
    UIImage *stripImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return stripImage;
}

//Draw two concentric circles.
-(UIImage *)circleImageForSingleSelectionWithBounds:(CGSize )size
                                              radius:(CGFloat)radius
                                               color:(UIColor *)color
                                     backgroundColor:(UIColor *)backgroundColor {
    CGFloat outerRadius = radius + 4;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 2); // set the line width
    CGContextSetStrokeColorWithColor(context, backgroundColor.CGColor);
    CGContextFillEllipseInRect(context, CGRectOffset(CGRectMake(0, 0, outerRadius * 2, outerRadius * 2), size.width/2 - outerRadius, size.height/2- outerRadius));
    CGContextStrokeEllipseInRect(context, CGRectOffset(CGRectMake(0, 0, radius * 2, radius * 2), size.width/2 - radius, size.height/2- radius));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
