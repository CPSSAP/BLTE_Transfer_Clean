/*
 
 File: LEPeripheralViewController.m
 
 Abstract: Interface to allow the user to enter data that will be
 transferred to a version of the app in Central Mode, when it is brought
 close enough.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */



#import "BTLEPeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"
#import "Measure.h"
#import "Global.h"


@interface BTLEPeripheralViewController () <CBPeripheralManagerDelegate, UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField      *nameText;
@property (strong, nonatomic) IBOutlet UIButton         *initialiseBtn;
@property (strong, nonatomic) IBOutlet UISwitch         *advertisingSwitch;
@property (strong, nonatomic) IBOutlet UIButton         *releaseData;
@property (strong, nonatomic) IBOutlet UILabel          *slaveHasSubd;
@property (strong, nonatomic) IBOutlet UIButton         *startButton;
@property (strong, nonatomic) IBOutlet UISwitch         *testTypeSwitch;
@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic) NSMutableArray            *logFiles;
@property (strong, nonatomic) NSMutableArray            *testDirs;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (strong, nonatomic) Measure                   *measure;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (nonatomic, strong) NSString                  *testRootDirLocal;
@property (strong, nonatomic) IBOutlet UILabel          *testStarted;
@property (strong, nonatomic) IBOutlet UILabel          *testFinished;

@end



#define NOTIFY_MTU      20

@implementation BTLEPeripheralViewController

BOOL ambientSensors;
int testTimerDev = 0;

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    //Adds done key to keyboard
    [_nameText setReturnKeyType:UIReturnKeyDone];
    _nameText.delegate = self;
    
    //Dont use function becasue Global Log file is not yet created
    [_advertisingSwitch setEnabled:NO];
    [_nameText setEnabled:YES];
    [_initialiseBtn setEnabled:YES];
    [_testTypeSwitch setOn:YES animated:YES];
    ambientSensors = NO;
    [_testTypeSwitch setEnabled:NO];
    [_startButton setEnabled:NO];
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [self.peripheralManager stopAdvertising];

    [super viewWillDisappear:animated];
}

#pragma mark GUI Elements

- (IBAction)initialiseTest:(id)sender
{
    _logFiles = [NSMutableArray arrayWithCapacity:1];
    _testDirs = [NSMutableArray arrayWithCapacity:1];

    //Creates test directories in a similar fashion to BLTECentralViewController
    for (int i = 1; i <= 10; i++)
    {
        NSString *trimmedString = [_nameText.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    
        //Add hashtag indicating this is the payment Device end of a legitimate transaction
        NSString *temp = [NSString stringWithFormat:@"%@%d#_Device", trimmedString, i];
        NSArray *myArr = [Global initRootDir:temp];
    
        _testRootDirLocal = (NSString *)[myArr objectAtIndex:0];
        NSString *logFullPath = (NSString *)[myArr objectAtIndex:1];
        [_logFiles addObject:logFullPath];
        [_testDirs addObject:_testRootDirLocal];

        if (i == 1)//First log file gets all the bluetoth logs
        {
            [Global setLogFile:logFullPath];
        }
    
        NSFileManager *fileManager  = [NSFileManager defaultManager];
    
        if (![fileManager fileExistsAtPath:_testRootDirLocal])
        {
            NSLog(@"Folder %@ not created", _testRootDirLocal);
            return;
        }
    
        if (![fileManager fileExistsAtPath:logFullPath])
        {
            NSLog(@"Log file %@ not created", logFullPath); //CAN START USING LOG FUNCTION IN GLOBAL
            return;
        }
    }
    [self enableAdvertisingBtn:YES];
    [_nameText setEnabled:NO];
    [self enableInitialiseBtn:NO];
    _testFinished.textColor = [UIColor blackColor];

    [Global Log:@"Test directories created"];
    // Start up the CBPeripheralManager
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
}


/** Start advertising
 */
- (IBAction)switchChanged:(id)sender
{
    if (self.advertisingSwitch.on)
    {
        // All we advertise is our service's UUID
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
        [Global Log:@"Service UUID now being advertised - Started Advertising"];
    }
    else
    {
        [self.peripheralManager stopAdvertising];
        [Global Log:@"Stopped Advertising"];
    }
}

//Carries out same function as in BLTECentralViewController
- (IBAction)testTypeValueChanged:(id)sender
{
    if (self.testTypeSwitch.isOn)
    {
        ambientSensors = NO;
        [Global Log:[NSString stringWithFormat:@"Orientation sensors selected.. BOOL set to: %@", ambientSensors ? @"YES" : @"NO"]];

    }
    else
    {
        ambientSensors = YES;
        [Global Log:[NSString stringWithFormat:@"Ambient sensors selected.. BOOL set to: %@", ambientSensors ? @"YES" : @"NO"]];

    }
}

- (IBAction)sendDataBtn:(id)sender
{
    // Start sending
    [Global Log:@"Send Data Button Push"];
    
    [self sendData];
}

- (void)enableStartBtn:(BOOL)set
{
    [_startButton setEnabled:set];
    [Global Log:[NSString stringWithFormat:@"Scan button enabled set to %@", set ? @"YES" : @"NO"]];
}

- (void)enableAdvertisingBtn:(BOOL)set
{
    [_advertisingSwitch setEnabled:set];
    [Global Log:[NSString stringWithFormat:@"Advertising switch set to %@", set ? @"ON" : @"OFF"]];
}

- (void)enableInitialiseBtn:(BOOL)set
{
    [_initialiseBtn setEnabled:set];
    [Global Log:[NSString stringWithFormat:@"Initialise button set to %@", set ? @"ON" : @"OFF"]];
}

- (void)enableTestTypeSwitch:(BOOL)set
{
    [_testTypeSwitch setEnabled:set];
    [Global Log:[NSString stringWithFormat:@"Test type switch set to %@", set ? @"ON" : @"OFF"]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    return YES;
}

/** Adds the 'Done' button to the title bar
 */
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // We need to add this manually so we have a way to dismiss the keyboard
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonSystemItemDone target:self action:@selector(dismissKeyboard)];
    self.navigationItem.rightBarButtonItem = rightButton;
}


#pragma mark - Peripheral Methods



/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (peripheral.state == CBPeripheralManagerStatePoweredOn)
    {
        // We're in CBPeripheralManagerStatePoweredOn state...
        [Global Log:@"Peripheral: peripheralManager powered on."];
        
        // ... so build our service.
        
        // Start with the CBMutableCharacteristic
        self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                         properties:CBCharacteristicPropertyNotify
                                                                              value:nil
                                                                        permissions:CBAttributePermissionsReadable];
        
        // Then the service
        CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                                                           primary:YES];
        
        // Add the characteristic to the service
        transferService.characteristics = @[self.transferCharacteristic];
        
        // And add it to the peripheral manager
        [self.peripheralManager addService:transferService];
        
        [Global Log:@"Charcteristic built and added to service"];
        
    }
    else if (peripheral.state == CBPeripheralManagerStatePoweredOff)
    {
        [Global Log:@"Peripheral: CBPeripheralManagerStatePoweredOff state discovered"];
    }
    else if (peripheral.state == CBPeripheralManagerStateUnauthorized)
    {
        [Global Log:@"Peripheral: CBPeripheralManagerStateUnauthorized state discovered"];
    }
    else if (peripheral.state == CBPeripheralManagerStateUnsupported)
    {
        [Global Log:@"Peripheral: CBPeripheralManagerStateUnsupported state discovered"];
    }
    else if (peripheral.state == CBPeripheralManagerStateResetting)
    {
        [Global Log:@"Peripheral: CBPeripheralManagerStateResetting state discovered"];
    }
    else if (peripheral.state == CBPeripheralManagerStateUnknown)
    {
        [Global Log:@"Peripheral: CBPeripheralManagerStateUnknown state discovered"];
    }
    
}


/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    [Global Log:@"Peripheral: Central subscribed to characteristic"];
    
    // Get the data
    self.dataToSend = [@"a" dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    
    self.slaveHasSubd.textColor = [UIColor greenColor];
    
    [self enableTestTypeSwitch:YES];
    [self enableStartBtn:YES];
    
    [Global Log:@"Peripheral: Ready to send"];
}


/** Recognise when the central unsubscribes
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    [Global Log:@"Peripheral: Central unsubscribed from characteristic"];
    self.slaveHasSubd.textColor = [UIColor redColor];
}

/** Sends the next amount of data to the connected central
 */
- (void)sendData //send signal
{
    NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
    NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
    //updates the value to which the Slave end of the bluetooth connection is subscribed. It detects this change and starts the tests at that end
    BOOL didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
    
    [Global Log:[NSString stringWithFormat:@"Data was %@ successfully", didSend ? @"SENT" : @"NOT SENT"]];
    
    //Used for debug purposes to make sure data is being sent correctly
    NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
    [Global Log:[NSString stringWithFormat:@"Sent: %@", stringFromData]];
    
    [self enableStartBtn:NO];
    [_advertisingSwitch setOn:NO animated:YES];
    
    //START TESTING
    [self runTests];
    
}

//See CentralViewController for comments, operates in same way
-(void)runTests
{
    _testRootDirLocal = [_testDirs objectAtIndex:testTimerDev];
    [Global setLogFile:[_logFiles objectAtIndex:testTimerDev]];
    testTimerDev = testTimerDev + 1;

    _measure = [[Measure alloc]initWithRootDir:_testRootDirLocal];
    _measure.delegate = self;
    
    NSTimeInterval temp = 1.0;
    NSTimeInterval temploc = 0.5;
    
    if(ambientSensors == NO)
    {
        //ORIENTATION
        [Global Log:[NSString stringWithFormat:@"Orientation Sensor Test %d Begun", testTimerDev]];
        _testStarted.textColor = [UIColor greenColor];
        [Global Log:[NSString stringWithFormat:@"Time on starting Device ##%@", [Global getUnixTime]]];
        [_measure startTestOrientation:&temp testNumber:testTimerDev];
    }
    else
    {
        //AMBIENT
        [Global Log:@"Ambient Sensor Tests Begun"];
        _testStarted.textColor = [UIColor greenColor];
        [Global Log:[NSString stringWithFormat:@"Time on starting device ##%@", [Global getUnixTime]]];
        [_measure startTestAmbient:&temp testNumber:testTimerDev location:&temploc];
    }
    
    [_nameText setEnabled:YES];
    [self enableInitialiseBtn:YES];
}

//See CentralViewController for comments, operates in same way
-(void)runAnotherTest:(BOOL)res
{
    if(res == YES)
    {
        _testStarted.textColor = [UIColor blackColor];
        NSLog(@"Sleeping for 5 seconds");
        [NSThread sleepForTimeInterval:5.0];
        [self runTests];
    }
    else
    {
        _testStarted.textColor = [UIColor blackColor];
        _testFinished.textColor = [UIColor greenColor];
        testTimerDev = 0; //Reset for any more tests that are run in this execution.
    }
    
}


/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    //Used for debug purposes
    [Global Log:@"Peripheral: Raedy to send next chunk of data"];
}


@end
