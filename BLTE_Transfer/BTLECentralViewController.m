/*
 
 File: LECentralViewController.m
 
 Abstract: Interface to use a CBCentralManager to scan for, and receive
 data from, a version of the app in Peripheral Mode
 
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

#import "BTLECentralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#import "TransferService.h"
#import "Measure.h"
#import "Global.h"

@interface BTLECentralViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>


@property (strong, nonatomic) IBOutlet UIButton     *initialiseBtn;
@property (strong, nonatomic) IBOutlet UIButton     *scanButtonProp;
@property (strong, nonatomic) IBOutlet UITextField  *nameText;
@property (strong, nonatomic) IBOutlet UILabel      *foundCtrlr;
@property (strong, nonatomic) IBOutlet UISwitch     *testType;
@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableData         *data;
@property (strong, nonatomic) NSMutableArray        *logFiles;
@property (strong, nonatomic) NSMutableArray        *testDirs;
@property (strong) Measure                          *measure;
@property (nonatomic, strong) NSString              *testRootDirLocal;
@property (strong, nonatomic) IBOutlet UILabel      *testStarted;
@property (strong, nonatomic) IBOutlet UILabel      *testFinished;

@end



@implementation BTLECentralViewController

BOOL ambientSensors;
int testTimerTer = 0;

#pragma mark - View Lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Somewhere to store the incoming data
    _data = [[NSMutableData alloc] init];
    
    //Add done key to keyboard
    [_nameText setReturnKeyType:UIReturnKeyDone];
    _nameText.delegate = self;
    
    //Set up GUI states
    [self guiInitialState];
    [_testType setOn:YES animated:YES];
    ambientSensors = NO;
    [_testType setEnabled:NO];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    //Don't keep it going while we're not showing.
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    [super viewWillDisappear:animated];
}

#pragma mark - GUI Elements

- (void)guiInitialState
{
    [_scanButtonProp setEnabled:NO]; //Block scan button to begin but dont use function as it uses Log and log file not set up yet
    [_testType setEnabled:NO];
    [_initialiseBtn setEnabled:YES];
    [_nameText setEnabled:YES];
}

- (IBAction)btnScan:(id)sender
{
    [self scan];
}

- (IBAction)initialiseTest:(id)sender
{
    _logFiles = [NSMutableArray arrayWithCapacity:1];
    _testDirs = [NSMutableArray arrayWithCapacity:1];
    
    //Directories for all ten of the transactions are created in the Documents file of the app
    for (int i = 1; i <= 10; i++) //10 is the ammount of transactions run per execution of the software
    {
    
        NSString *trimmedString = [_nameText.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]]; //Remove any whitespaces
    
        NSString *temp = [NSString stringWithFormat:@"%@%d#_Terminal", trimmedString, i]; //Add a hash tag of terminal as this is the terminal end of the transaction
        NSArray *myArr = [Global initRootDir:temp];
    
        _testRootDirLocal = (NSString *)[myArr objectAtIndex:0];
        NSString *logFullPath = (NSString *)[myArr objectAtIndex:1];
        [_logFiles addObject:logFullPath]; //Add log file path
        [_testDirs addObject:_testRootDirLocal]; //Add full direcotry path
    
        //First log file gets all the bluetooth logs, subsequent logs record only information relevant to transaction to which log file pertains
        if (i == 1)
        {
            [Global setLogFile:logFullPath];
        }
    
        NSFileManager *fileManager  = [NSFileManager defaultManager];
    
        //Check Directory has been created, if not exit and record in log
        if (![fileManager fileExistsAtPath:_testRootDirLocal])
        {
            NSLog(@"Folder %@ not created", _testRootDirLocal);
            return;
        }
    
        //Check Directory has been created, if not exit and record in log
        if (![fileManager fileExistsAtPath:logFullPath])
        {
            NSLog(@"Log file %@ not created", logFullPath); //CAN START USING LOG FUNCTION IN GLOBAL, NOT YET INITIALISED
            return;
        }
    }

    [self enableScanBtn:YES];
    [self enableTestTypeSwitch:YES];
    [_initialiseBtn setEnabled:NO];
    [_nameText setEnabled:NO];
    _testFinished.textColor = [UIColor blackColor];
    [Global Log:@"Test directories created"];

    //Create the Central or Slave Object end of the Bluetooth connection, this woudl normally be a device with the other end being a peripheral. I have chosen to refer to it as the slave end as its the end which waits for a signal from the peripheral and acts accordingly. In our context its the terminal end as the sensor recording is initiated by the payment device end of the connection
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}

//Action method for the test type switch
- (IBAction)testTypeValueChanged:(id)sender
{
    if (self.testType.isOn)
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //Done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    return YES;
}

- (void)enableScanBtn:(BOOL)set
{
    [_scanButtonProp setEnabled:set];
    [Global Log:[NSString stringWithFormat:@"Scan button enabled set to %@", set ? @"YES" : @"NO"]];
}

- (void)enableTestTypeSwitch:(BOOL)set
{
    [_testType setEnabled:set];
    [Global Log:[NSString stringWithFormat:@"Test type switch enabled set to %@", set ? @"YES" : @"NO"]];
}

#pragma mark - Central Methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        [Global Log:@"Central: Bluetooth switched on so scan can start..."];
        //[self scan];
    }
    else if (central.state == CBCentralManagerStatePoweredOff)
    {
        [Global Log:@"Central: Bluetooth State CBCentralManagerStatePoweredOff discovered"];
    }
    else if (central.state == CBCentralManagerStateUnauthorized)
    {
        [Global Log:@"Central: Bluetooth State CBCentralManagerStateUnauthorized discovered"];
    }
    else if (central.state == CBCentralManagerStateUnsupported)
    {
        [Global Log:@"Central: Bluetooth State CBCentralManagerStateUnsupported discovered"];
    }
    else if (central.state == CBCentralManagerStateResetting)
    {
        [Global Log:@"Central: Bluetooth State CBCentralManagerStateResetting discovered"];
    }
    else if (central.state == CBCentralManagerStateUnknown)
    {
        [Global Log:@"Central: Bluetooth State CBCentralManagerStateUnknown discovered"];
    }
        
}

- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]
                                                options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
    [Global Log:@"Scanning started"];
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15)
    {
        [Global Log:@"Central: RSSI > -15, value rejected"];
        return;
    }
        
    //Reject if the signal strength is too low to be close enough (Close is around -22dB)
    if (RSSI.integerValue < -35)
    {
        [Global Log:@"Central: RSSI < -35, value rejected"];
        return;
    }
    
    [Global Log:[NSString stringWithFormat:@"Discovered %@ at %@", peripheral.name, RSSI]];
    
    //Ok, it's in range - have we already seen it?
    if (self.discoveredPeripheral != peripheral)
    {
        //Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it
        self.discoveredPeripheral = peripheral;
        
        //And connect
        [Global Log:[NSString stringWithFormat:@"Connecting to peripheral %@", peripheral]];

        [self.centralManager connectPeripheral:peripheral options:nil];
        
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [Global Log:[NSString stringWithFormat:@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]]];
    
    [self cleanup];
}


- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [Global Log:[NSString stringWithFormat:@"Peripheral %@ Connected", peripheral]];

    //Stop scanning
    [self.centralManager stopScan];
    [Global Log:@"Scanning stopped to save power"];
    
    //Clear the data that we may already have
    [self.data setLength:0];
    
    //Make sure we get the discovery callbacks, set delegate for peripheral
    peripheral.delegate = self;
    
    //Search only for services that match our UUID
    [peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        [Global Log:[NSString stringWithFormat:@"Error discovering services: %@", [error localizedDescription]]];
        [self cleanup];
        return;
    }
    
    // Discover the characteristic we want...
    
    //Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services)
    {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //Deal with errors (if any)
    if (error)
    {
        [Global Log:[NSString stringWithFormat:@"Error discovering characteristics: %@", [error localizedDescription]]];
        [self cleanup];
        return;
    }
    
    //Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        //And check if it's the right one
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
        {
            //If it is, subscribe to it
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            self.foundCtrlr.textColor = [UIColor greenColor];
        }
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [Global Log:[NSString stringWithFormat:@"Error with updating characteristics: %@", [error localizedDescription]]];
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    // Have we got everything we need?
    if ([stringFromData isEqualToString:@"a"])
    {
        [Global Log:[NSString stringWithFormat:@"Received data: <%@>", stringFromData]];
        
        // Cancel our subscription to the characteristic
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        [Global Log:@"Subscription cancelled"];
        
        // and disconnect from the peripehral
        [self.centralManager cancelPeripheralConnection:peripheral];
        [Global Log:@"Disconnected from peripheral"];
        
        // START TESTS
        [self runTests];
        
    }
    
}

-(void)runTests
{
    _testRootDirLocal = [_testDirs objectAtIndex:testTimerTer]; //Root directory for the test/transaction
    [Global setLogFile:[_logFiles objectAtIndex:testTimerTer]]; //Set log file for the transaction
    //Incremented after use in array as used in text later on so better starting at 1 than 0. Used in array to select relevant full test path and log file from arrays
    testTimerTer = testTimerTer + 1;
    
    _measure = [[Measure alloc]initWithRootDir:_testRootDirLocal]; //Create/Initialise Measure object
    _measure.delegate = self; //Callback informing this object that a test has finished
    
    NSTimeInterval temp = 1.0; //Legitimate transaction collection time 1 second to account for drift and synchronisation
    NSTimeInterval temploc = 0.5; //Location sensors only return approx 4 readings so no synchronisation takes place
    
    if(ambientSensors == NO) //Switch in GUI
    {
        //ORIENTATION
        [Global Log:[NSString stringWithFormat:@"Orientation Sensor Test %d Begun", testTimerTer]];
        _testStarted.textColor = [UIColor greenColor];
        [Global Log:[NSString stringWithFormat:@"Time on starting Terminal ##%@", [Global getUnixTime]]];
        //Start Orientation tests
        [_measure startTestOrientation:&temp testNumber:testTimerTer];
    }
    else
    {
        //AMBIENT
        [Global Log:[NSString stringWithFormat:@"Ambient Sensor Test %d Begun", testTimerTer]];
        _testStarted.textColor = [UIColor greenColor];
        [Global Log:[NSString stringWithFormat:@"Time on starting Terminal ##%@", [Global getUnixTime]]];
        //Start Ambient tests
        [_measure startTestAmbient:&temp testNumber:testTimerTer location:&temploc];
        
    }
    
    [self guiInitialState];
}

//Callback function from Measure object which inidcates whether or not to run another transaction
-(void)runAnotherTest:(BOOL)res
{
    if(res == YES) //Run another transaction
    {
        _testStarted.textColor = [UIColor blackColor];
        NSLog(@"Sleeping for 5 seconds");
        [NSThread sleepForTimeInterval:5.0]; //Gives a good bit of space between transactions to try and mimic real life
        [self runTests];
    }
    else //Finish as this is last transaction
    {
        _testStarted.textColor = [UIColor blackColor];
        _testFinished.textColor = [UIColor greenColor];
        testTimerTer = 0; //Reset for any more tests that are run in this execution.
    }
    
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        [Global Log:[NSString stringWithFormat:@"Error changing notification state: %@", [error localizedDescription]]];
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]])
    {
        [Global Log:@"Not transfer characteristic we were looking for so exiting"];
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying)
    {
        [Global Log:[NSString stringWithFormat:@"Notification began on %@", characteristic]];
    }
    
    // Notification has stopped
    else
    {
        // so disconnect from the peripheral
        [Global Log:[NSString stringWithFormat:@"Notification stopped on %@.  Disconnecting", characteristic]];

        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error)
    {
        [Global Log:[NSString stringWithFormat:@"Error removing local copy of peripheral: %@", [error localizedDescription]]];
    }
    
    [Global Log:[NSString stringWithFormat:@"Peripheral %@ Disconnected", peripheral]];

    self.discoveredPeripheral = nil;
    self.foundCtrlr.textColor = [UIColor redColor];
    
    [self cleanup];
}



/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
    if (!(self.discoveredPeripheral.state == 2))
    {
        return;
    }
    
    [Global Log:@"Central: cleanup started"];
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.discoveredPeripheral.services != nil) {
        for (CBService *service in self.discoveredPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            
                            // And we're done.
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
    
    self.foundCtrlr.textColor = [UIColor redColor];
}


@end
