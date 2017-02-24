//
//  Measure.h
//  BTLE Transfer
//
//  Created by XXXX on 27/06/2016.
//  Copyright © 2016 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
@protocol MeasureDelegate <NSObject>
-(void)runAnotherTest:(BOOL)res;
@end


@interface Measure : NSObject <CLLocationManagerDelegate, AVAudioRecorderDelegate>

@property (nonatomic,strong) id <MeasureDelegate> delegate;
@property (nonatomic,strong) CMMotionManager *cmManager; //Used for both DeviceMotion and Magnetometer 1 and 3
@property (nonatomic,strong) CLLocationManager *locManager; //Used for both Location and Heading
@property (nonatomic,strong) AVAudioRecorder *recorder;
@property (nonatomic,strong) AVAudioSession *session;

@property (nonatomic,strong) NSMutableArray *MagDeviceMotionReadings;
@property (nonatomic,strong) NSMutableArray *MagMotionManagerReadings;
@property (nonatomic,strong) NSMutableArray *MagLocationManagerReadings;

@property (nonatomic,strong) NSMutableArray *AccMotionManagerReadings;
@property (nonatomic,strong) NSMutableArray *AccDeviceMotionReadings;
@property (nonatomic,strong) NSMutableArray *AccDeviceMotionGravReadings;

@property (nonatomic,strong) NSMutableArray *AttReadings;
@property (nonatomic,strong) NSMutableArray *AttReadingsQuarternion;
@property (nonatomic,strong) NSMutableArray *AttReadingsRotationMatrix;

@property (nonatomic,strong) NSMutableArray *LocReadings;

@property (nonatomic,strong) NSString *logFileName;
@property (nonatomic,strong) NSString *rootDirName;
@property (nonatomic,strong) NSString *testName;
@property (nonatomic) NSTimeInterval *sensorTime;

- (id)initWithRootDir:(NSString *)rootDir;
- (void)startTestAmbient:(NSTimeInterval *)tinterval testNumber:(int)testNo location:(NSTimeInterval *)loc;
- (void)startTestOrientation:(NSTimeInterval *)tinterval testNumber:(int)testNo;

@end
