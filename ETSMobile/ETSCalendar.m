//
//  ETSCalendar.m
//  ETSMobile
//
//  Created by Jean-Philippe Martin on 2014-03-31.
//  Copyright (c) 2014 ApplETS. All rights reserved.
//

#import "ETSCalendar.h"


@implementation ETSCalendar

@dynamic course;
@dynamic end;
@dynamic id;
@dynamic room;
@dynamic start;
@dynamic summary;
@dynamic title;
@dynamic session;

- (NSDate *)day
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self.start];
    
    return [calendar dateFromComponents:components];
}

@end
