//
//  NineReading.h
//  BTLE Transfer
//
//  Created by XXXX on 27/06/2016.
//  Copyright © 2016 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NineReading : NSObject

@property NSTimeInterval timeStamp;

@property NSString *sensorReadingM11;
@property NSString *sensorReadingM12;
@property NSString *sensorReadingM13;

@property NSString *sensorReadingM21;
@property NSString *sensorReadingM22;
@property NSString *sensorReadingM23;

@property NSString *sensorReadingM31;
@property NSString *sensorReadingM32;
@property NSString *sensorReadingM33;

@end
