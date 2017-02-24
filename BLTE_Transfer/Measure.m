//
//  Measure.m
//  BTLE Transfer
//
//  Created by XXXX on 27/06/2016.
//  Copyright © 2016 Apple. All rights reserved.
//

#import "Measure.h"
#import "Global.h"
#import "ThreeReading.h"
#import "FourReading.h"
#import "NineReading.h"


@implementation Measure

BOOL finishTest = NO;;
NSTimeInterval interval = 0.6;
int testNum = 0;
int numberOfTestsPerTransaction = 10;

- (id)initWithRootDir:(NSString *)rootDir
{
    if (self = [super init])
    {
        _rootDirName = rootDir;
        [Global Log:@"Measure object initialised"];
        
        //Test title is extracted from full directory path and hash tag removed. Hash tag removed because in analysis phase test names had to be the same to identify both ends of a transaction, adding #terminal or #device meant this was'nt the case and such they were removed
        NSArray *myWords = [rootDir componentsSeparatedByString:@"/Documents/"];
        NSArray *myArr = [myWords[1] componentsSeparatedByString:@"#"];
        
        _testName = myArr[0];
        return self;
    }
    else
    {
        return nil;
    }
    
}

- (void)startTestOrientation:(NSTimeInterval *)tinterval testNumber:(int)testNo
{
    //Magnetometer Motion Manager
    interval = *tinterval;
    testNum = testNo;
    [self startMeasuringMagnometerMotionManager];
    [Global Log:@"Orientation Test started from inside Measure object"];
    //After time given at interval the method in selector field is executed
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(stopMeasuringMagnometerMotionManager)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)startTestAmbient:(NSTimeInterval *)tinterval testNumber:(int)testNo location:(NSTimeInterval *)loc
{
    interval = *tinterval;
    testNum = testNo;
    [self startMeasuringLocation];
    [Global Log:@"Ambient Test started from inside Measure object"];
    
    [NSTimer scheduledTimerWithTimeInterval:*loc
                                     target:self
                                   selector:@selector(stopMeasuringLocation)
                                   userInfo:nil
                                    repeats:NO];

}

// 1. MAGNETOMETER - CORE MOTION - START

- (void)startMeasuringMagnometerMotionManager
{
    _cmManager = [[CMMotionManager alloc]init];
    _MagMotionManagerReadings = [NSMutableArray arrayWithCapacity:1];
    
    [Global Log:@"Motion Manager for Magnetometer Started.."];
    
    //Callback executed every time magnetometer has new readings
    [_cmManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMMagnetometerData * _Nullable magnetometerData, NSError * _Nullable error)
     {
         CMMagneticField mf = [magnetometerData magneticField];
         ThreeReading *temp = [[ThreeReading alloc] init];//Object which holds three readings and a time stamp in epoch time
         
         NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
         NSString *readingX = [NSString stringWithFormat:@"%f", mf.x];
         NSString *readingY = [NSString stringWithFormat:@"%f", mf.y];
         NSString *readingZ = [NSString stringWithFormat:@"%f", mf.z];
         
         [temp setTimeStamp:ts];
         [temp setSensorReadingX:readingX];
         [temp setSensorReadingY:readingY];
         [temp setSensorReadingZ:readingZ];
         
         [_MagMotionManagerReadings addObject:temp];
     }];
    
}

- (void)stopMeasuringMagnometerMotionManager
{
    //Stop recording magnetometer data
    [_cmManager stopMagnetometerUpdates];
    
    [Global Log:@"Motion Manager for Magnetometer Stopped.."];
    
    //Magnetometer Location Manager
    [self startMeasuringMagnometerLocationManager];
    //Next sensor variant started and then stopped with method in selector after interval, continues in this vain until all sensors tested.
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(stopMeasuringMagnometerLocationManager)
                                   userInfo:nil
                                    repeats:NO];
    
}

// 2. MAGNETOMETER - CORE LOCATION (HEADING) - START

- (void)startMeasuringMagnometerLocationManager
{
    _locManager = [[CLLocationManager alloc] init];
    _MagLocationManagerReadings = [NSMutableArray arrayWithCapacity:1];
    
    [Global Log:@"Location Manager for Magnetometer Started.."];
    
    if ([CLLocationManager headingAvailable] == NO)
    {
        // No compass is available. This application cannot function without a compass,
        // so a dialog will be displayed and no magnetic data will be measured.
        _locManager = nil;
        UIAlertView *noCompassAlert = [[UIAlertView alloc] initWithTitle:@"No Compass!"
                                                                 message:@"This device does not have the ability to measure magnetic fields."
                                                                delegate:nil
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:nil];
        [noCompassAlert show];
        
    }
    else
    {
        // heading service configuration
        _locManager.headingFilter = kCLHeadingFilterNone;
        
        // setup delegate callbacks
        _locManager.delegate = self;
        
        // start the compass
        [_locManager startUpdatingHeading];
    }
}

// This delegate method is invoked when the location manager has heading data.
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading
{
    ThreeReading *temp = [[ThreeReading alloc] init];
    
    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
    NSString *readingX = [NSString stringWithFormat:@"%f", heading.x];
    NSString *readingY = [NSString stringWithFormat:@"%f", heading.y];
    NSString *readingZ = [NSString stringWithFormat:@"%f", heading.z];
    
    [temp setTimeStamp:ts];
    [temp setSensorReadingX:readingX];
    [temp setSensorReadingY:readingY];
    [temp setSensorReadingZ:readingZ];
    
    [_MagLocationManagerReadings addObject:temp];
    
}

// This delegate method is invoked when the location managed encounters an error condition.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] == kCLErrorDenied)
    {
        // This error indicates that the user has denied the application's request to use location services.
        [Global Log:@"User has denied the application's request to use location services"];
        [manager stopUpdatingHeading];
    }
    else if ([error code] == kCLErrorHeadingFailure)
    {
        // This error indicates that the heading could not be determined, most likely because of strong magnetic interference.
        [Global Log:@"Heading could not be determined, most likely because of strong magnetic interference."];
    }
    else
    {
        [Global Log:[error localizedDescription]];
    }
}

- (void)stopMeasuringMagnometerLocationManager
{
    [_locManager stopUpdatingHeading];
    
    [Global Log:@"Location Manager for Magnetometer Stopped.."];
    
    [self startMeasuringMagnometerDeviceMotion];
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(stopMeasuringMagnometerDeviceMotion)
                                   userInfo:nil
                                    repeats:NO];
}



// 3. MAGNETOMETER - DEVICE MOTION - START

- (void)startMeasuringMagnometerDeviceMotion
{
    _cmManager = [[CMMotionManager alloc]init];
    
    _cmManager.showsDeviceMovementDisplay = true;
    _MagDeviceMotionReadings = [NSMutableArray arrayWithCapacity:1];
    
    [Global Log:@"Device Motion for Magnetometer Started.."];
    
    //Callback for Device motion updates
    [_cmManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXMagneticNorthZVertical toQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error)
     {
         CMCalibratedMagneticField mf = [motion magneticField];
         ThreeReading *temp = [[ThreeReading alloc] init];
         
         NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
         NSString *readingX = [NSString stringWithFormat:@"%f", mf.field.x];
         NSString *readingY = [NSString stringWithFormat:@"%f", mf.field.y];
         NSString *readingZ = [NSString stringWithFormat:@"%f", mf.field.z];
         
         [temp setTimeStamp:ts];
         [temp setSensorReadingX:readingX];
         [temp setSensorReadingY:readingY];
         [temp setSensorReadingZ:readingZ];
         
         [_MagDeviceMotionReadings addObject:temp];
     }];
    
}

- (void)stopMeasuringMagnometerDeviceMotion
{
    [_cmManager stopDeviceMotionUpdates];
    
    [Global Log:@"Device Motion for Magnetometer Stopped.."];
    
    //Magnetometer Location Manager, this phase is both the end of the Ambient sensors tests and the start of the Accelerometer tests for the orientation phase hence the logic to test which one it is. finishTest is set in the ambient sensor tests and informs this logic.
    if(finishTest == YES) //Finish tests as this run is for Ambient tests and its the end of the Ambient sensor tests
    {
        finishTest = NO;
        [Global Log:@"Ambient tests finished"];
        [self writeAllDataToFileAmbient];
        [Global Log:@"Test Finished"];
        if (testNum < numberOfTestsPerTransaction)
        {
            [self.delegate runAnotherTest:YES]; //Callback to relevant Bluetooth controller telling it to run another transaction
        }
        else
        {
            [self.delegate runAnotherTest:NO]; //This is the last transaction of this run and callback informs execution of the app to finish
        }
    }
    else //Move on to next pahse of Orientation tests as tihs run is for Orientation sensors
    {
        [self startMeasuringAcceleromterMotionManager];
        [NSTimer scheduledTimerWithTimeInterval:interval
                                         target:self
                                       selector:@selector(stopMeasuringAcceleromterMotionManager)
                                       userInfo:nil
                                        repeats:NO];
    }
}



// 4. ACCELEROMETER - CORE MOTION - START

- (void)startMeasuringAcceleromterMotionManager
{
    _cmManager = [[CMMotionManager alloc]init];
    _AccMotionManagerReadings = [NSMutableArray arrayWithCapacity:1];
    
    [Global Log:@"Motion Manager for Accelerometer Started.."];
    
    [_cmManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error)
     {
         CMAcceleration acc = [accelerometerData acceleration];
         ThreeReading *temp = [[ThreeReading alloc] init];
         
         NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
         NSString *readingX = [NSString stringWithFormat:@"%f", acc.x];
         NSString *readingY = [NSString stringWithFormat:@"%f", acc.y];
         NSString *readingZ = [NSString stringWithFormat:@"%f", acc.z];
         
         [temp setTimeStamp:ts];
         [temp setSensorReadingX:readingX];
         [temp setSensorReadingY:readingY];
         [temp setSensorReadingZ:readingZ];
         
         [_AccMotionManagerReadings addObject:temp];
     }];
    
}

- (void)stopMeasuringAcceleromterMotionManager
{
    [_cmManager stopAccelerometerUpdates];
    [Global Log:@"Motion Manager for Accelerometer Stopped.."];
    
    //Magnetometer Location Manager
    [self startMeasuringAccelerometerDeviceMotion];
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(stopMeasuringAccelerometerDeviceMotion)
                                   userInfo:nil
                                    repeats:NO];
    
}



// 5. ACCELEROMETER - CORE MOTION - START

- (void)startMeasuringAccelerometerDeviceMotion
{
    _cmManager = [[CMMotionManager alloc]init];
    _AccDeviceMotionReadings = [NSMutableArray arrayWithCapacity:1];
    
    [Global Log:@"Device Motion for Accelerometer Started.."];
    
    [_cmManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error)
     {
         CMAcceleration accData = [motion userAcceleration];
         ThreeReading *temp = [[ThreeReading alloc] init];
         
         NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
         NSString *readingX = [NSString stringWithFormat:@"%f", accData.x];
         NSString *readingY = [NSString stringWithFormat:@"%f", accData.y];
         NSString *readingZ = [NSString stringWithFormat:@"%f", accData.z];
         
         [temp setTimeStamp:ts];
         [temp setSensorReadingX:readingX];
         [temp setSensorReadingY:readingY];
         [temp setSensorReadingZ:readingZ];
         
         [_AccDeviceMotionReadings addObject:temp];
     }];
    
}

- (void)stopMeasuringAccelerometerDeviceMotion
{
    [_cmManager stopDeviceMotionUpdates];
    [Global Log:@"Device Motion for Accelerometer Stopped.."];
    
    //Magnetometer Location Manager
    [self startMeasuringAccelerometerDeviceMotionGravity];
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(stopMeasuringAccelerometerDeviceMotionGravity)
                                   userInfo:nil
                                    repeats:NO];
}


// 6. ACCELEROMETER - CORE MOTION - START

- (void)startMeasuringAccelerometerDeviceMotionGravity
{
    _cmManager = [[CMMotionManager alloc]init];
    _AccDeviceMotionGravReadings = [NSMutableArray arrayWithCapacity:1];
    
    [Global Log:@"Device Motion for Accelerometer Gravity Started.."];
    
    [_cmManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error)
     {
         CMAcceleration accData = [motion gravity];
         ThreeReading *temp = [[ThreeReading alloc] init];
         
         NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
         NSString *readingX = [NSString stringWithFormat:@"%f", accData.x];
         NSString *readingY = [NSString stringWithFormat:@"%f", accData.y];
         NSString *readingZ = [NSString stringWithFormat:@"%f", accData.z];
         
         [temp setTimeStamp:ts];
         [temp setSensorReadingX:readingX];
         [temp setSensorReadingY:readingY];
         [temp setSensorReadingZ:readingZ];
         
         [_AccDeviceMotionGravReadings addObject:temp];
     }];
    
}

- (void)stopMeasuringAccelerometerDeviceMotionGravity
{
    [_cmManager stopDeviceMotionUpdates];
    [Global Log:@"Device Motion for Accelerometer Gravity reading Stopped.."];
    
    //Magnetometer Location Manager
    [self startMeasuringAttitude];
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(stopMeasuringAttitude)
                                   userInfo:nil
                                    repeats:NO];
}


// 7. ATTITUDE

- (void)startMeasuringAttitude
{
    _cmManager = [[CMMotionManager alloc]init];
    _AttReadings = [NSMutableArray arrayWithCapacity:1];
    _AttReadingsQuarternion = [NSMutableArray arrayWithCapacity:1];
    _AttReadingsRotationMatrix = [NSMutableArray arrayWithCapacity:1];
    
    [Global Log:@"Device Motion for Attitude Started.."];
    
    [_cmManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error)
     {
         CMAttitude *attData = [motion attitude];
         ThreeReading *temp = [[ThreeReading alloc] init];
         
         NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
         NSString *readingX = [NSString stringWithFormat:@"%f", attData.roll]; //X
         NSString *readingY = [NSString stringWithFormat:@"%f", attData.pitch];//Y
         NSString *readingZ = [NSString stringWithFormat:@"%f", attData.yaw];  //Z
         
         [temp setTimeStamp:ts];
         [temp setSensorReadingX:readingX];
         [temp setSensorReadingY:readingY];
         [temp setSensorReadingZ:readingZ];
         
         [_AttReadings addObject:temp];
         
         //Quaternions
         CMQuaternion qData = [attData quaternion];
         FourReading *temp2 = [[FourReading alloc] init];
         
         NSString *readingQX = [NSString stringWithFormat:@"%f", qData.x];  //X
         NSString *readingQY = [NSString stringWithFormat:@"%f", qData.y];  //Y
         NSString *readingQZ = [NSString stringWithFormat:@"%f", qData.z];  //Z
         NSString *readingQW = [NSString stringWithFormat:@"%f", qData.w];  //W
         
         [temp2 setTimeStamp:ts];
         [temp2 setSensorReadingX:readingQX];
         [temp2 setSensorReadingY:readingQY];
         [temp2 setSensorReadingZ:readingQZ];
         [temp2 setSensorReadingW:readingQW];
         
         [_AttReadingsQuarternion addObject:temp2];
         
         //Rotation Matrixes
         CMRotationMatrix rMatrix = [attData rotationMatrix];
         NineReading *temp3 = [[NineReading alloc] init];
         
         NSString *readingM11 = [NSString stringWithFormat:@"%f", rMatrix.m11];  //X
         NSString *readingM12 = [NSString stringWithFormat:@"%f", rMatrix.m12];  //Y
         NSString *readingM13 = [NSString stringWithFormat:@"%f", rMatrix.m13];  //Z
         NSString *readingM21 = [NSString stringWithFormat:@"%f", rMatrix.m21];  //W
         NSString *readingM22 = [NSString stringWithFormat:@"%f", rMatrix.m22];  //X
         NSString *readingM23 = [NSString stringWithFormat:@"%f", rMatrix.m23];  //Y
         NSString *readingM31 = [NSString stringWithFormat:@"%f", rMatrix.m31];  //Z
         NSString *readingM32 = [NSString stringWithFormat:@"%f", rMatrix.m32];  //W
         NSString *readingM33 = [NSString stringWithFormat:@"%f", rMatrix.m33];  //W
         
         [temp3 setTimeStamp:ts];
         [temp3 setSensorReadingM11:readingM11];
         [temp3 setSensorReadingM12:readingM12];
         [temp3 setSensorReadingM13:readingM13];
         [temp3 setSensorReadingM21:readingM21];
         [temp3 setSensorReadingM22:readingM22];
         [temp3 setSensorReadingM23:readingM23];
         [temp3 setSensorReadingM31:readingM31];
         [temp3 setSensorReadingM32:readingM32];
         [temp3 setSensorReadingM33:readingM33];
         
         [_AttReadingsRotationMatrix addObject:temp3];
         
     }];
    
}

- (void)stopMeasuringAttitude
{
    [_cmManager stopDeviceMotionUpdates];
    [Global Log:@"Device Motion for Attitude Stopped.."];
    
    //All arrays conatining sensor readings are now written to respective csv files within test directory
    [self writeAllDataToFile];
    [Global Log:@"Test Finished"];
    
    //If last transaction then finish if not run another transaction, all done through callbacks to relevant bluetooth controller
    if (testNum < numberOfTestsPerTransaction)
    {
        [self.delegate runAnotherTest:YES];
    }
    else
    {
        [self.delegate runAnotherTest:NO];
    }
}

// AMBIENT SENSORS

// 1. LOCATION

- (void)startMeasuringLocation
{
    [Global Log:@"Location reading started.."];
    if (nil == _locManager)
        _locManager = [[CLLocationManager alloc] init];
    
    _locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    _locManager.delegate = self;
    
    _LocReadings = [NSMutableArray arrayWithCapacity:1];
    
    [_locManager requestAlwaysAuthorization];
    [_locManager startUpdatingLocation];

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *newLocation = [locations lastObject];
    [Global Log:[NSString stringWithFormat:@"%0.6f", newLocation.coordinate.latitude]];
    [Global Log:[NSString stringWithFormat:@"%0.6f", newLocation.coordinate.longitude]];
    
    ThreeReading *temp = [[ThreeReading alloc] init];
    
    NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
    NSString *readingX = [NSString stringWithFormat:@"%f", newLocation.coordinate.latitude];
    NSString *readingY = [NSString stringWithFormat:@"%f", newLocation.coordinate.longitude];
    NSString *readingZ = @"Blank";
    
    [temp setTimeStamp:ts];
    [temp setSensorReadingX:readingX];
    [temp setSensorReadingY:readingY];
    [temp setSensorReadingZ:readingZ];
    
    [_LocReadings addObject:temp];

    
}

- (void)stopMeasuringLocation
{
    [_locManager stopUpdatingLocation];
    [Global Log:@"Location reading Stopped.."];
    
    //No need for timer as interval for audio recording can be specified
    [self startMeasuringSound];
    
}

// 2. AUDIO

- (void)startMeasuringSound
{
    //Setup and initilaise recording session
    _session = [AVAudioSession sharedInstance];
    [_session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    //Setup directory in root to hold recording
    NSString *fullDir = [_rootDirName stringByAppendingString:@"/Sound/"];
    
    //Create directory
    NSFileManager *fileManager  = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:fullDir])
        [fileManager createDirectoryAtPath:fullDir withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
    
    //Create and initiliase array for record settings
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    //Setup recorder settings
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt: 16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithInt: AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];

    //Loop introduced to allow mulitple recordings to be made but decided to only record one sample, loop left in for convenience and flexibility
    for (int i = 1; i <= 1; i++)
    {
        //Setup recording name with .wav file extension
        NSString *tempFileName = [NSString stringWithFormat:@"%@Recording_%@.wav", fullDir, _testName];
        NSURL *url = [NSURL fileURLWithPath:tempFileName];
        
        [Global Log:tempFileName];
        
        _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:NULL];
        _recorder.delegate = self;
        _recorder.meteringEnabled = YES;
        [_recorder prepareToRecord];
        
        [Global Log:[NSString stringWithFormat:@"Recording started at: ###%@",[Global getUnixTime]]];
        BOOL *result = [_recorder recordForDuration:interval];
        
        [NSThread sleepForTimeInterval:(interval * 2)];
        
        [Global Log:[NSString stringWithFormat:@"Recording_%@.wav recorded successfully: %@", _testName, result ? @"YES" : @"NO"]];
        
    }
    
    [self stopRecordingSound];
}

- (void)stopRecordingSound
{
    finishTest = YES; //Alerts next phase that this is AMbient sensor testing and that testing should cease following Magnetometer tests
    [self startMeasuringMagnometerMotionManager];
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(stopMeasuringMagnometerMotionManager)
                                   userInfo:nil
                                    repeats:NO];
}

// HELPER FUNCTIONS

//Writes all sensor data in arrays to relevant directory and csv file for Orientation sensors
- (void)writeAllDataToFile
{
    //Magnetometer
    NSString *fullDir1 = [_rootDirName stringByAppendingString:@"/Magnetometer/"];
    [self writeToCsv:fullDir1 :@"CMManagerMag.csv" :_MagMotionManagerReadings :3];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir1]];
    
    [self writeToCsv:fullDir1 :@"CLManager.csv" :_MagLocationManagerReadings :3];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir1]];
    
    [self writeToCsv:fullDir1 :@"CMManagerDevMotMag.csv" :_MagDeviceMotionReadings :3];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir1]];

    //Accelerometer
    NSString *fullDir2 = [_rootDirName stringByAppendingString:@"/Accelerometer/"];
    [self writeToCsv:fullDir2 :@"CMManagerAcc.csv" :_AccMotionManagerReadings :3];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir2]];
    
    [Global Log:[NSString stringWithFormat:@"%@", fullDir2]];
    [self writeToCsv:fullDir2 :@"CMManagerDevMotAcc.csv" :_AccDeviceMotionReadings :3];
    
    [Global Log:[NSString stringWithFormat:@"%@", fullDir2]];
    [self writeToCsv:fullDir2 :@"CMManagerDevMotAccGrav.csv" :_AccDeviceMotionGravReadings :3];
    
    //Attitude
    NSString *fullDir = [_rootDirName stringByAppendingString:@"/Attitude/"];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir]];
    [self writeToCsv:fullDir :@"Attitude.csv" :_AttReadings :3];
    [self writeToCsv:fullDir :@"AttitudeQuarterion.csv" :_AttReadingsQuarternion :4];
    [self writeToCsv:fullDir :@"AttitudeRotationMatrix.csv" :_AttReadingsRotationMatrix :9];


}

//Does same as above but for Ambient sensors
- (void)writeAllDataToFileAmbient
{
    //Location
    NSString *fullDir = [_rootDirName stringByAppendingString:@"/Location/"];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir]];
    [self writeToCsv:fullDir :@"Location.csv" :_LocReadings :3];
    
    //Magnetometer
    NSString *fullDir1 = [_rootDirName stringByAppendingString:@"/Magnetometer/"];
    [self writeToCsv:fullDir1 :@"CMManagerMag.csv" :_MagMotionManagerReadings :3];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir1]];
    
    [self writeToCsv:fullDir1 :@"CLManager.csv" :_MagLocationManagerReadings :3];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir1]];
    
    [self writeToCsv:fullDir1 :@"CMManagerDevMotMag.csv" :_MagDeviceMotionReadings :3];
    [Global Log:[NSString stringWithFormat:@"%@", fullDir1]];
    
    //Sound is taken care of in the sound recording method as its not written to a csv its saved as a .wav file
    
}

//Actual function called for writing data in parameter to file in parameter
- (void)writeToCsv:(NSString *)directory : (NSString *)fileName : (NSMutableArray *)readingsArr : (NSInteger) items
{
    
    @try
    {
        NSMutableString *writeString = [NSMutableString stringWithCapacity:0]; //don't worry about the capacity, it will expand as necessary
        if(items == 3)
        {
            
            for (int i=0; i<[readingsArr count]; i++)
            {
                [writeString appendString:[NSString stringWithFormat:@"%f, %@, %@, %@\n",
                                           [[readingsArr objectAtIndex:i]timeStamp],
                                           [[readingsArr objectAtIndex:i]sensorReadingX],
                                           [[readingsArr objectAtIndex:i]sensorReadingY],
                                           [[readingsArr objectAtIndex:i]sensorReadingZ]]];
            }
        }
        else if(items == 4)
        {
            
            for (int j=0; j<[readingsArr count]; j++)
            {
                [writeString appendString:[NSString stringWithFormat:@"%f, %@, %@, %@, %@\n",
                                           [[readingsArr objectAtIndex:j]timeStamp],
                                           [[readingsArr objectAtIndex:j]sensorReadingX],
                                           [[readingsArr objectAtIndex:j]sensorReadingY],
                                           [[readingsArr objectAtIndex:j]sensorReadingZ],
                                           [[readingsArr objectAtIndex:j]sensorReadingW]]];
            }
            
        }
        else if(items == 9)
        {
             for (int k=0; k<[readingsArr count]; k++)
            {
                [writeString appendString:[NSString stringWithFormat:@"%f, %@, %@, %@, %@, %@, %@, %@, %@, %@\n", [[readingsArr objectAtIndex:k]timeStamp],
                                           [[readingsArr objectAtIndex:k]sensorReadingM11],
                                           [[readingsArr objectAtIndex:k]sensorReadingM12],
                                           [[readingsArr objectAtIndex:k]sensorReadingM13],
                                           [[readingsArr objectAtIndex:k]sensorReadingM21],
                                           [[readingsArr objectAtIndex:k]sensorReadingM22],
                                           [[readingsArr objectAtIndex:k]sensorReadingM23],
                                           [[readingsArr objectAtIndex:k]sensorReadingM31],
                                           [[readingsArr objectAtIndex:k]sensorReadingM32],
                                           [[readingsArr objectAtIndex:k]sensorReadingM33]]];
                
            }
            
        }
        
        NSFileManager *fileManager  = [NSFileManager defaultManager];
        
        NSError *error = nil;
        if (![fileManager fileExistsAtPath:directory])
            [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
        
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        
        
        NSError *errora = nil;
        [writeString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&errora];
        
        [Global Log:[NSString stringWithFormat:@"%@ file written", fileName]];
    }
    @catch(NSException *exception)
    {
        [self logException:exception];
    }
}

//Any exceptions are processed and recorded in log file
- (void)logException:(NSException *)ex
{
    NSString *n = [NSString stringWithFormat:@"An exception occurred: %@", ex.name];
    NSString *r = [NSString stringWithFormat:@"An exception occurred: %@", ex.reason];
    [Global Log:n];
    [Global Log:r];
}


@end
