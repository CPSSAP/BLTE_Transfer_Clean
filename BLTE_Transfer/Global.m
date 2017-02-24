//
//  Global.m
//  BTLE Transfer
//
//  A series of helper functions used across the App
//
//  Created by XXXX on 28/06/2016.
//  Copyright © 2016 Apple. All rights reserved.
//

#import "Global.h"

static NSString *logFileFullPath = @"";

@implementation Global

//Initialise the root direcotry for the transactions
+ (NSArray *)initRootDir:(NSString *)testTitlea
{
    //This helps differentiate in case a mistake is made and two tests have the same name
    NSString *testTitle = [NSString stringWithFormat:@"%@_%@", [self getDateStamp], testTitlea]; //Add a time stamp before the test title
    
    //Setup the directory with the full directory path for creation
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *folderPath = [documentsDirectory stringByAppendingPathComponent:testTitle];
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    
    //Create the directory for the transactions in the Documents directory
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:folderPath])
    {
        [fileManager createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
    }
    NSLog(@"Root directory for test is \n%@", folderPath);
    
    //Setup full path for log file
    NSString *logFileName = [testTitle stringByAppendingString:@".log"];
    NSString *logFullPath = [folderPath stringByAppendingPathComponent:logFileName];
    logFileFullPath = logFullPath;
    
    //Create log file
    if(![fileManager fileExistsAtPath:logFullPath])
    {
        [fileManager createFileAtPath:logFullPath contents:nil attributes:nil];
    }
    NSLog(@"Log file for test is \n%@", logFullPath);
    NSLog(@"Log file for future reference by global functions is \n%@", logFullPath);
    
    NSArray *retArray = [NSArray arrayWithObjects:folderPath, logFileFullPath, nil];
    
    //Return both full direcotry path and full log file path
    return retArray;
}

//A global function to record/log text in the specified log file
+ (void)Log:(NSString *)logText
{
    NSString *entry = [NSString stringWithFormat:@"%@: %@\n", [self getTimeStampMilli], logText];
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:logFileFullPath]; //path to log
    [file seekToEndOfFile];
    [file writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
    NSLog(@"%@", logText);
}

//Retrieve a time stamp string which includes milliseconds to 3 significant figures
+ (NSString *)getTimeStampMilli
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-dd-MM HH:mm:ss.SSS"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    //NSLog(dateString);
    return dateString;
}

//Retrieve a time stamp string which includes seconds but not milliseconds and contains no characters that exclude its use in file names/directory paths
+ (NSString *)getTimeStamp
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY-MM-dd_HHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    //NSLog(dateString);
    return dateString;
}

//Returns string representation of epoch time, which is number of seconds since 0000hrs 01/01/1970 UTC
+ (NSString *)getUnixTime
{
    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
    NSString *temp = [NSString stringWithFormat:@"%f", ts];
    
    return temp;
}

//Returns string representation of date stamp in fomrat YY-MM-DD
+ (NSString *)getDateStamp
{
    NSDate *currentDate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YY-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    //NSLog(dateString);
    return dateString;
}

//Set the full path of the log file to a local variable used in the lof function of this object
+ (void)setLogFile:(NSString *)fullLogFilePath
{
    logFileFullPath = fullLogFilePath;
    NSLog(logFileFullPath);
}


@end
