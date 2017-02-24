//
//  FourReading.h
//  BTLE Transfer
//
//  Created by XXXX on 27/06/2016.
//  Copyright © 2016 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FourReading : NSObject

@property NSTimeInterval timeStamp;
@property NSString *sensorReadingX;
@property NSString *sensorReadingY;
@property NSString *sensorReadingZ;
@property NSString *sensorReadingW;

@end
