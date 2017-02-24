//
//  Global.h
//  BTLE Transfer
//
//  Created by XXXX on 28/06/2016.
//  Copyright © 2016 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Global : NSObject {}

@property NSString *logFileName;

+ (NSArray *)initRootDir:(NSString *)testTitle;
+ (void)Log:(NSString *)logText;
+ (void)setLogFile:(NSString *)fullLogFilePath;
+ (NSString *)getTimeStampMilli;
+ (NSString *)getTimeStamp;
+ (NSString *)getUnixTime;


@end
