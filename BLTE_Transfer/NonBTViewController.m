//
//  NonBTViewController.m
//  BTLE Transfer
//
//  Used for the illegititmate transactions as no bluetooth connectivity was required given the distances involved
//
//  Created by XXXX on 03/07/2016.
//  Copyright © 2016 Apple. All rights reserved.
//

#import "NonBTViewController.h"
#import "Global.h"
#import "Measure.h"

@interface NonBTViewController ()

@property (strong, nonatomic) IBOutlet UITextField *testTitle;
@property (strong, nonatomic) IBOutlet UIButton    *startBtn;
@property (strong, nonatomic) IBOutlet UIButton    *initialiseTestBtn;
@property (strong, nonatomic) IBOutlet UISwitch    *testType;
@property (strong, nonatomic) NSString             *testRootDirLocal;
@property (strong, nonatomic) NSMutableArray       *logFiles;
@property (strong, nonatomic) NSMutableArray       *testDirs;
@property (strong, nonatomic) IBOutlet UILabel     *testStarted;
@property (strong, nonatomic) IBOutlet UILabel     *testFinished;
@property (strong) Measure                         *measure;


@end

@implementation NonBTViewController

BOOL ambientSensors;
int testTimer = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add done key to keyboard
    [_testTitle setReturnKeyType:UIReturnKeyDone];
    _testTitle.delegate = self;

    [_startBtn setEnabled:NO];
    [_testType setOn:YES animated:YES];
    ambientSensors = NO;
    [_testType setEnabled:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)initialiseBtnPush:(id)sender
{
    _logFiles = [NSMutableArray arrayWithCapacity:1];
    _testDirs = [NSMutableArray arrayWithCapacity:1];
    
    //Creates test directories in a similar fashion to BLTECentralViewController
    for (int i = 1; i <= 10; i++)
    {
        NSString *trimmedString = [_testTitle.text stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    
        //Different hashtag indicating Non Bluetooth mode tests (Illegitimate Transactions/Relay Attack Attempts)
        NSString *temp = [NSString stringWithFormat:@"%@%d#_NonBTMode", trimmedString, i];
        NSArray *myArr = [Global initRootDir:temp];
    
        _testRootDirLocal = (NSString *)[myArr objectAtIndex:0];
        NSString *logFullPath = (NSString *)[myArr objectAtIndex:1];
        [_logFiles addObject:logFullPath];
        [_testDirs addObject:_testRootDirLocal];
        
        if (i == 1)//First log file gets all the bluetooth logs
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
    
    [_testType setEnabled:YES];
    [_startBtn setEnabled:YES];
    [_initialiseTestBtn setEnabled:NO];
    [_testTitle setEnabled:NO];
    _testFinished.textColor = [UIColor blackColor];
    
    [Global Log:@"Test directories created"];
}

//Carries out same function as in BLTECentralViewController
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

- (IBAction)startBtnPushed:(id)sender
{
    [self runTests];
}

//Runs in the same way as BLTECentralViewController, see somments there
-(void)runTests
{
    _testRootDirLocal = [_testDirs objectAtIndex:testTimer];
    [Global setLogFile:[_logFiles objectAtIndex:testTimer]];
    testTimer = testTimer + 1;
    
    _measure = [[Measure alloc]initWithRootDir:_testRootDirLocal];
    _measure.delegate = self;
    
    NSTimeInterval temp = 3.0; //Interval larger to account for any drift introduced by manual synchronisation
    NSTimeInterval temploc = 0.5;
    
    if(ambientSensors == NO)
    {
        //ORIENTATION
        _testStarted.textColor = [UIColor greenColor];
        [Global Log:[NSString stringWithFormat:@"Orientation Sensor Test %d Begun", testTimer]];
        _testStarted.textColor = [UIColor greenColor];
        [Global Log:[NSString stringWithFormat:@"Time on starting ##%@", [Global getUnixTime]]];
        [_measure startTestOrientation:&temp testNumber:testTimer];
    }
    else
    {
        //AMBIENT
        [Global Log:[NSString stringWithFormat:@"Ambient Sensor Test %d Begun", testTimer]];
        _testStarted.textColor = [UIColor greenColor];
        [Global Log:[NSString stringWithFormat:@"Time on starting ##%@", [Global getUnixTime]]];
        [_measure startTestAmbient:&temp testNumber:testTimer location:&temploc];
    }
    
    [_startBtn setEnabled:NO];
    [_testType setEnabled:NO];
    [_initialiseTestBtn setEnabled:YES];
    [_testTitle setEnabled:YES];
}

//Again see BLTECentralViewController as functions in the same way
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
        testTimer = 0; //Reset for any more tests that are run in this execution.
    }
    
}

@end
