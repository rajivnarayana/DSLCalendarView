/*
 DSLCalendarView.m
 
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
#import "DSLCalenderMonthSelectorView.h"
#import "DSLCalendarMonthView.h"
#import "DSLCalendarView.h"
#import "DSLCalendarDayView.h"


@interface DSLCalendarView ()

@property (nonatomic, copy) NSDateComponents *draggingFixedDay;
@property (nonatomic, copy) NSDateComponents *draggingStartDay;
@property (nonatomic, assign) BOOL draggedOffStartDay;

@property (nonatomic, strong) NSMutableDictionary *monthViews;
@property (nonatomic, strong) UIView *monthContainerView;
@property (nonatomic, strong) UIView *monthContainerViewContentView;
@property (nonatomic, strong) DSLCalenderMonthSelectorView *monthSelectorView;

@end


@implementation DSLCalendarView {
    CGSize _dayViewSize;
}


#pragma mark - Memory management

- (void)dealloc {
}


#pragma mark - Initialisation

// Designated initialisers

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self commonInit];
    }

    return self;
}

- (void)commonInit {
    _dayViewSize = CGSizeMake(floorf(self.bounds.size.width / 7.0), 44);
    CGFloat monthPadding = self.bounds.size.width - (_dayViewSize.width * 7.0);
    monthPadding = floorf(monthPadding / 2.0);
    
    self.visibleMonth = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSCalendarCalendarUnit fromDate:[NSDate date]];
    self.visibleMonth.day = 1;
    
    self.monthSelectorView = [DSLCalenderMonthSelectorView view];
    self.monthSelectorView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.monthSelectorView];
    
    [self.monthSelectorView.backButton addTarget:self action:@selector(didTapMonthBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.monthSelectorView.forwardButton addTarget:self action:@selector(didTapMonthForward:) forControlEvents:UIControlEventTouchUpInside];

    // Month views are contained in a content view inside a container view - like a scroll view, but not a scroll view so we can have proper control over animations
    CGRect frame = self.bounds;
    frame.origin.x = monthPadding;
    frame.size.width = _dayViewSize.width * 7.0;
    frame.origin.y = CGRectGetMaxY(self.monthSelectorView.frame);
    frame.size.height -= frame.origin.y;
    self.monthContainerView = [[UIView alloc] initWithFrame:frame];
    self.monthContainerView.clipsToBounds = YES;
    [self addSubview:self.monthContainerView];
    
    self.monthContainerViewContentView = [[UIView alloc] initWithFrame:self.monthContainerView.bounds];
    [self.monthContainerView addSubview:self.monthContainerViewContentView];
    
    self.monthViews = [[NSMutableDictionary alloc] init];

    [self updateMonthLabelMonth:self.visibleMonth];
    [self positionDayViewsForMonth:self.visibleMonth fromMonth:self.visibleMonth];
}


#pragma mark - Properties

+ (Class)monthViewClass {
    return [DSLCalendarMonthView class];
}

+ (Class)dayViewClass {
    return [DSLCalendarDayView class];
}

- (void)setSelectedRange:(DSLCalendarRange *)selectedRange {
    _selectedRange = selectedRange;
    
    for (DSLCalendarMonthView *monthView in self.monthViews.allValues) {
        [monthView updateDaySelectionStatesForRange:self.selectedRange];
    }
}


#pragma mark - Events

- (void)didTapMonthBack:(id)sender {
    NSDateComponents *fromMonth = [self.visibleMonth copy];
    [self.visibleMonth setMonth:self.visibleMonth.month - 1];
    
    [self updateMonthLabelMonth:self.visibleMonth];
    [self positionDayViewsForMonth:self.visibleMonth fromMonth:fromMonth];
}

- (void)didTapMonthForward:(id)sender {
    NSDateComponents *fromMonth = [self.visibleMonth copy];
    [self.visibleMonth setMonth:self.visibleMonth.month + 1];

    [self updateMonthLabelMonth:self.visibleMonth];
    [self positionDayViewsForMonth:self.visibleMonth fromMonth:fromMonth];
}


#pragma mark - 

- (void)updateMonthLabelMonth:(NSDateComponents*)month {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MMMM yyyy";
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [calendar dateFromComponents:month];
    
    self.monthSelectorView.titleLabel.text = [formatter stringFromDate:date];
}

- (NSString*)monthViewKeyForMonth:(NSDateComponents*)month {
    month = [month.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit fromDate:month.date];
    return [NSString stringWithFormat:@"%d.%d", month.year, month.month];
}

- (DSLCalendarMonthView*)cachedOrCreatedMonthViewForMonth:(NSDateComponents*)month {
    month = [month.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSCalendarCalendarUnit fromDate:month.date];

    NSString *monthViewKey = [self monthViewKeyForMonth:month];
    DSLCalendarMonthView *monthView = [self.monthViews objectForKey:monthViewKey];
    if (monthView == nil) {
        monthView = [[[[self class] monthViewClass] alloc] initWithMonth:month dayViewClass:[[self class] dayViewClass] dayViewSize:_dayViewSize];
        [self.monthViews setObject:monthView forKey:monthViewKey];
        [self.monthContainerViewContentView addSubview:monthView];

        [monthView updateDaySelectionStatesForRange:self.selectedRange];
    }
    
    return monthView;
}

- (void)positionDayViewsForMonth:(NSDateComponents*)month fromMonth:(NSDateComponents*)fromMonth {
    self.userInteractionEnabled = NO;
    fromMonth = [fromMonth copy];
    month = [month copy];
    
    CGFloat nextVerticalPosition = 0;
    CGFloat startingVerticalPostion = 0;
    CGFloat restingVerticalPosition = 0;
    CGFloat restingHeight = 0;
    
    NSComparisonResult monthComparisonResult = [month.date compare:fromMonth.date];
    NSTimeInterval animationDuration = (monthComparisonResult == NSOrderedSame) ? 0.0 : 0.5;
    
    NSMutableArray *activeMonthViews = [[NSMutableArray alloc] init];
    
    // Create and position the month views for the final month and those around it
    for (NSInteger monthOffset = -2; monthOffset <= 2; monthOffset += 1) {
        NSDateComponents *offsetMonth = [month copy];
        offsetMonth.month = offsetMonth.month + monthOffset;
        offsetMonth = [offsetMonth.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSCalendarCalendarUnit fromDate:offsetMonth.date];
        
        // If this isn't the first month view we've created, check if this month should overlap the previous month
        if (monthOffset > -2 && offsetMonth.weekday - offsetMonth.calendar.firstWeekday != 0) {
            nextVerticalPosition -= _dayViewSize.height;
        }
        
        DSLCalendarMonthView *monthView = [self cachedOrCreatedMonthViewForMonth:offsetMonth];
        [activeMonthViews addObject:monthView];
        [monthView.superview bringSubviewToFront:monthView];

        CGRect frame = monthView.frame;
        frame.origin.y = nextVerticalPosition;
        nextVerticalPosition += frame.size.height;
        monthView.frame = frame;

        // Check if this view is where we should animate to or from
        if (monthOffset == 0) {
            restingVerticalPosition = monthView.frame.origin.y;
            restingHeight = monthView.bounds.size.height;
        }
        else if (monthOffset == 1 && monthComparisonResult == NSOrderedAscending) {
            startingVerticalPostion = monthView.frame.origin.y;
        }
        else if (monthOffset == -1 && monthComparisonResult == NSOrderedDescending) {
            startingVerticalPostion = monthView.frame.origin.y;
        }
    }
    
    CGRect frame = self.monthContainerViewContentView.frame;
    frame.size.height = CGRectGetMaxY([[activeMonthViews lastObject] frame]);
    self.monthContainerViewContentView.frame = frame;
    
    // Remove any old month views we don't need anymore
    NSArray *monthViewKeyes = self.monthViews.allKeys;
    for (NSString *key in monthViewKeyes) {
        UIView *monthView = [self.monthViews objectForKey:key];
        if (![activeMonthViews containsObject:monthView]) {
            [monthView removeFromSuperview];
            [self.monthViews removeObjectForKey:key];
        }
    }
    
    // Position the content view to show where we're animating from
    if (monthComparisonResult != NSOrderedSame) {
        CGRect frame = self.monthContainerViewContentView.frame;
        frame.origin.y = -startingVerticalPostion;
        self.monthContainerViewContentView.frame = frame;
    }
    
    [UIView animateWithDuration:animationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        for (NSInteger index = 0; index < activeMonthViews.count; index++) {
            DSLCalendarMonthView *monthView = [activeMonthViews objectAtIndex:index];
             for (DSLCalendarDayView *dayView in monthView.dayViews) {
                 dayView.inCurrentMonth = (index == 2);
             }
        }
        
        // Animate the content view to show the target month
        CGRect frame = self.monthContainerViewContentView.frame;
        frame.origin.y = -restingVerticalPosition;
        self.monthContainerViewContentView.frame = frame;
        
        // Resize the container view to show the height of the target month
        frame = self.monthContainerView.frame;
        frame.size.height = restingHeight;
        self.monthContainerView.frame = frame;
        
        // Resize the our frame to show the height of the target month
        frame = self.frame;
        frame.size.height = CGRectGetMaxY(self.monthContainerView.frame);
        self.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            self.userInteractionEnabled = YES;
        }
    }];
}


#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    DSLCalendarDayView *touchedView = [self dayViewForTouches:touches];
    if (touchedView == nil) {
        self.draggingStartDay = nil;
        return;
    }
    
    self.draggingStartDay = touchedView.day;
    self.draggingFixedDay = touchedView.day;
    self.draggedOffStartDay = NO;
    
    if (self.selectedRange == nil) {
        self.selectedRange = [[DSLCalendarRange alloc] initWithStartDay:touchedView.day endDay:touchedView.day];
    }
    else if (![self.selectedRange.startDay isEqual:touchedView.day] && ![self.selectedRange.endDay isEqual:touchedView.day]) {
        self.selectedRange = [[DSLCalendarRange alloc] initWithStartDay:touchedView.day endDay:touchedView.day];
    }
    else if ([self.selectedRange.startDay isEqual:touchedView.day]) {
        self.draggingFixedDay = self.selectedRange.endDay;
    }
    else {
        self.draggingFixedDay = self.selectedRange.startDay;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.draggingStartDay == nil) {
        return;
    }
    
    DSLCalendarDayView *touchedView = [self dayViewForTouches:touches];
    if (touchedView == nil) {
        self.draggingStartDay = nil;
        return;
    }
    
    if ([touchedView.day.date compare:self.draggingFixedDay.date] == NSOrderedAscending) {
        self.selectedRange = [[DSLCalendarRange alloc] initWithStartDay:touchedView.day endDay:self.draggingFixedDay];
    }
    else {
        self.selectedRange = [[DSLCalendarRange alloc] initWithStartDay:self.draggingFixedDay endDay:touchedView.day];
    }
    
    if (!self.draggedOffStartDay) {
        if (![self.draggingStartDay isEqual:touchedView.day]) {
            self.draggedOffStartDay = YES;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.draggingStartDay == nil) {
        return;
    }
    
    DSLCalendarDayView *touchedView = [self dayViewForTouches:touches];
    if (touchedView == nil) {
        self.draggingStartDay = nil;
        return;
    }
    
    if (!self.draggedOffStartDay && [self.draggingStartDay isEqual:touchedView.day]) {
        self.selectedRange = [[DSLCalendarRange alloc] initWithStartDay:touchedView.day endDay:touchedView.day];
    }
    
    self.draggingStartDay = nil;
    
    
    NSDateComponents *month = [touchedView.day.calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSCalendarCalendarUnit fromDate:touchedView.day.date];
    if (month.year != self.visibleMonth.year || month.month != self.visibleMonth.month) {
        NSDateComponents *fromMonth = [self.visibleMonth copy];
        self.visibleMonth.month = month.month;
        self.visibleMonth.year = month.year;
        
        [self updateMonthLabelMonth:self.visibleMonth];
        [self positionDayViewsForMonth:self.visibleMonth fromMonth:fromMonth];
    }
}


- (DSLCalendarDayView*)dayViewForTouches:(NSSet*)touches {
    if (touches.count != 1) {
        return nil;
    }
    
    // Work out which day view was touched. We can't just use hit test on a root view because the month views can overlap
    UITouch *touch = [touches anyObject];
    for (DSLCalendarMonthView *monthView in self.monthViews.allValues) {
        UIView *view = [monthView hitTest:[touch locationInView:monthView] withEvent:nil];
        if (view == nil) {
            continue;
        }
        
        while (view != monthView) {
            if ([view isKindOfClass:[DSLCalendarDayView class]]) {
                return (DSLCalendarDayView*)view;
            }
            
            view = view.superview;
        }
    }
    
    return nil;
}

@end