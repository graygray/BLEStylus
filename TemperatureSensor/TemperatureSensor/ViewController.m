/*
 
 File: ViewController.m
 
 Abstract: User interface to display a list of discovered peripherals
 and allow the user to connect to them.
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>

#import "ViewController.h"
#import "LeDiscovery.h"
#import "LeTemperatureAlarmService.h"
#import "Quartz.h"

@interface ViewController ()  <LeDiscoveryDelegate, LeTemperatureAlarmProtocol, UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) LeTemperatureAlarmService *currentlyDisplayingService;
@property (retain, nonatomic) NSMutableArray            *connectedServices;
@property (retain, nonatomic) IBOutlet UILabel          *currentlyConnectedSensor;
@property (retain, nonatomic) IBOutlet UILabel          *currentTemperatureLabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentPacketRateLabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentPressureLabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentBatteryLabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentButtonUpLabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentButtonDownLabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentRSSILabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentErrorCodeLabel;
@property (retain, nonatomic) IBOutlet UILabel          *currentErrorRateLabel;
@property (retain, nonatomic) IBOutlet UILabel          *maxAlarmLabel,*minAlarmLabel;
@property (retain, nonatomic) IBOutlet UITableView      *sensorsTable;
@property (retain, nonatomic) IBOutlet UIStepper        *maxAlarmStepper,*minAlarmStepper;
- (IBAction)maxStepperChanged;
- (IBAction)minStepperChanged;
@end



@implementation ViewController


@synthesize currentlyDisplayingService;
@synthesize connectedServices;
@synthesize currentlyConnectedSensor;
@synthesize sensorsTable;
@synthesize currentTemperatureLabel;
@synthesize currentPacketRateLabel;
@synthesize currentPressureLabel;
@synthesize currentBatteryLabel;
@synthesize currentButtonUpLabel;
@synthesize currentButtonDownLabel;
@synthesize currentRSSILabel;
@synthesize currentErrorCodeLabel;
@synthesize currentErrorRateLabel;
@synthesize maxAlarmLabel,minAlarmLabel;
@synthesize maxAlarmStepper,minAlarmStepper;

#pragma mark -
#pragma mark View lifecycle
/****************************************************************************/
/*								View Lifecycle                              */
/****************************************************************************/
- (void) viewDidLoad
{
    NSLog(@"viewDidLoad\n");
    [super viewDidLoad];
    
    connectedServices = [NSMutableArray new];
    
	[[LeDiscovery sharedInstance] setDiscoveryDelegate:self];
    [[LeDiscovery sharedInstance] setPeripheralDelegate:self];
    [[LeDiscovery sharedInstance] startScanningForUUIDString:kTemperatureServiceUUIDString];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:kAlarmServiceEnteredBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForegroundNotification:) name:kAlarmServiceEnteredForegroundNotification object:nil];
    
    //gray
    CGRect square = CGRectMake(DRAW_X, DRAW_Y, DRAW_WIDTH, DRAW_HEIGHT);
//    CGRect square = CGRectMake(1110, 1460, 1950, 1600);
    qz = [[Quartz alloc] initWithFrame:square];
    [self.view addSubview:qz];
    
    NSLog(@"start timer");
    timer = [NSTimer scheduledTimerWithTimeInterval: 1
                                             target: self
                                           selector: @selector(handleTimer:)
                                           userInfo: nil
                                            repeats: YES];

    NSLog(@"start timer2");
    timer2 = [NSTimer scheduledTimerWithTimeInterval: (1/TIMER2_PACKETRATE)      // temporary packet rate
                                             target: self
                                           selector: @selector(handleTimer2:)
                                           userInfo: nil
                                            repeats: YES];

    // UITextView
    CGRect textViewFrame = CGRectMake(155.0f, 220.0f, 530.0f, 30.0f);
    textView = [[UITextView alloc] initWithFrame:textViewFrame];
    textView.returnKeyType = UIReturnKeyDone;
    textView.editable = NO;
    textView.showsVerticalScrollIndicator=TRUE;
    textView.backgroundColor = [UIColor lightTextColor];
    [textView setFont:([UIFont systemFontOfSize:16.0])];
    [textView setTextColor:[UIColor redColor]];
    [self.view addSubview:textView];

}


- (void) viewDidUnload
{
    NSLog(@"viewDidUnload\n");
    [self setCurrentlyConnectedSensor:nil];
    [self setCurrentTemperatureLabel:nil];
    [self setMaxAlarmLabel:nil];
    [self setMinAlarmLabel:nil];
    [self setSensorsTable:nil];
    [self setMaxAlarmStepper:nil];
    [self setMinAlarmStepper:nil];
    [self setConnectedServices:nil];
    [self setCurrentlyDisplayingService:nil];
    
    [[LeDiscovery sharedInstance] stopScanning];
    
    [super viewDidUnload];
}


- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    NSLog(@"shouldAutorotateToInterfaceOrientation\n");
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void) dealloc 
{
    NSLog(@"dealloc\n");
    [[LeDiscovery sharedInstance] stopScanning];
    
    [currentTemperatureLabel release];
    [currentPacketRateLabel release];
    [currentPressureLabel release];
    [currentBatteryLabel release];
    [currentButtonUpLabel release];
    [currentButtonDownLabel release];
    [currentRSSILabel release];
    [currentErrorCodeLabel release];
    [currentErrorRateLabel release];
    [maxAlarmLabel release];
    [minAlarmLabel release];
    [sensorsTable release];
    [maxAlarmStepper release];
    [minAlarmStepper release];
    
    [currentlyConnectedSensor release];
    [connectedServices release];
    [currentlyDisplayingService release];
    
    [super dealloc];
}



#pragma mark -
#pragma mark LeTemperatureAlarm Interactions
/****************************************************************************/
/*                  LeTemperatureAlarm Interactions                         */
/****************************************************************************/
- (LeTemperatureAlarmService*) serviceForPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"serviceForPeripheral\n");
    for (LeTemperatureAlarmService *service in connectedServices) {
        if ( [[service peripheral] isEqual:peripheral] ) {
            return service;
        }
    }
    
    return nil;
}

- (void)didEnterBackgroundNotification:(NSNotification*)notification
{   
    NSLog(@"didEnterBackgroundNotification");
    for (LeTemperatureAlarmService *service in self.connectedServices) {
        [service enteredBackground];
    }
}

- (void)didEnterForegroundNotification:(NSNotification*)notification
{
    NSLog(@"didEnterForegroundNotification");
    for (LeTemperatureAlarmService *service in self.connectedServices) {
        [service enteredForeground];
    }    
}


#pragma mark -
#pragma mark LeTemperatureAlarmProtocol Delegate Methods
/****************************************************************************/
/*				LeTemperatureAlarmProtocol Delegate Methods					*/
/****************************************************************************/
/** Broke the high or low temperature bound */
- (void) alarmService:(LeTemperatureAlarmService*)service didSoundAlarmOfType:(AlarmType)alarm
{
    NSLog(@"didSoundAlarmOfType\n");
    if (![service isEqual:currentlyDisplayingService])
        return;
    
    NSString *title;
    NSString *message;
    
	switch (alarm) {
		case kAlarmLow: 
			NSLog(@"Alarm low");
            title     = @"Alarm Notification";
            message   = @"Low Alarm Fired";
			break;
            
		case kAlarmHigh: 
			NSLog(@"Alarm high");
            title     = @"Alarm Notification";
            message   = @"High Alarm Fired";
			break;
	}
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}


/** Back into normal values */
- (void) alarmServiceDidStopAlarm:(LeTemperatureAlarmService*)service
{
    NSLog(@"alarmServiceDidStopAlarm");
}

/** Current HDM rawdata changed */
- (void) alarmServiceDidChangeTemperature:(LeTemperatureAlarmService*)service
{
//    NSLog(@"alarmServiceDidChangeTemperature\n");
    NSData *temp = [service temperature];
    [currentTemperatureLabel setText:[NSString stringWithFormat:@"%@", temp]];
}

/** Current battery changed */
- (void) alarmServiceDidChangeBattery:(LeTemperatureAlarmService*)service
{
//    NSLog(@"alarmServiceDidChangeBattery\n");
    NSData *temp = [service getBattery];
    [currentBatteryLabel setText:[NSString stringWithFormat:@"%@", temp]];
}


/** Max or Min change request complete */
- (void) alarmServiceDidChangeTemperatureBounds:(LeTemperatureAlarmService*)service
{
    NSLog(@"alarmServiceDidChangeTemperatureBounds\n");
    if (service != currentlyDisplayingService) 
        return;
    
    [maxAlarmLabel setText:[NSString stringWithFormat:@"MAX %dº", (int)[currentlyDisplayingService maximumTemperature]]];
    [minAlarmLabel setText:[NSString stringWithFormat:@"MIN %dº", (int)[currentlyDisplayingService minimumTemperature]]];
    
    [maxAlarmStepper setEnabled:YES];
    [minAlarmStepper setEnabled:YES];
}


/** Peripheral connected or disconnected */
- (void) alarmServiceDidChangeStatus:(LeTemperatureAlarmService*)service
{
    NSLog(@"alarmServiceDidChangeStatus\n");
    if ( [[service peripheral] isConnected] ) {
        NSLog(@"Service (%@) connected", service.peripheral.name);
        if (![connectedServices containsObject:service]) {
            [connectedServices addObject:service];
        }
    }
    
    else {
        NSLog(@"Service (%@) disconnected", service.peripheral.name);
        
        // gray kill timers
//        [timer invalidate];
//        timer = nil;
        
        NSLog(@"stop tomer2");
        [timer2 invalidate];
        timer2 = nil;

        if ([connectedServices containsObject:service]) {
            [connectedServices removeObject:service];
        }
    }
}


/** Central Manager reset */
- (void) alarmServiceDidReset
{
    NSLog(@"alarmServiceDidReset\n");
    [connectedServices removeAllObjects];
}


#pragma mark -
#pragma mark TableView Delegates
/****************************************************************************/
/*							TableView Delegates								*/
/****************************************************************************/
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"cellForRowAtIndexPath\n");
	UITableViewCell	*cell;
	CBPeripheral	*peripheral;
	NSArray			*devices;
	NSInteger		row	= [indexPath row];
    static NSString *cellID = @"DeviceList";
    
	cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	if (!cell)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] autorelease];
    
	if ([indexPath section] == 0) {
		devices = [[LeDiscovery sharedInstance] connectedServices];
        peripheral = [(LeTemperatureAlarmService*)[devices objectAtIndex:row] peripheral];
        
	} else {
		devices = [[LeDiscovery sharedInstance] foundPeripherals];
        peripheral = (CBPeripheral*)[devices objectAtIndex:row];
	}
    
    if ([[peripheral name] length])
        [[cell textLabel] setText:[peripheral name]];
    else
        [[cell textLabel] setText:@"Peripheral"];
		
    [[cell detailTextLabel] setText: [peripheral isConnected] ? @"Connected" : @"Not connected"];
    
	return cell;
}


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"numberOfSectionsInTableView\n");
	return 2;
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"numberOfRowsInSection\n");
	NSInteger	res = 0;
    
	if (section == 0)
		res = [[[LeDiscovery sharedInstance] connectedServices] count];
	else
		res = [[[LeDiscovery sharedInstance] foundPeripherals] count];
    
	return res;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath\n");
	CBPeripheral	*peripheral;
	NSArray			*devices;
	NSInteger		row	= [indexPath row];
	
	if ([indexPath section] == 0) {
        NSLog(@"select connectedServices");
		devices = [[LeDiscovery sharedInstance] connectedServices];
        peripheral = [(LeTemperatureAlarmService*)[devices objectAtIndex:row] peripheral];
	} else {
        NSLog(@"select foundPeripherals");
		devices = [[LeDiscovery sharedInstance] foundPeripherals];
    	peripheral = (CBPeripheral*)[devices objectAtIndex:row];
	}
    
	if (![peripheral isConnected]) {
        NSLog(@"connect peripheral");
		[[LeDiscovery sharedInstance] connectPeripheral:peripheral];
        [currentlyConnectedSensor setText:[peripheral name]];
        
        [currentlyConnectedSensor setEnabled:NO];
        [currentTemperatureLabel setEnabled:NO];
    }
    
	else {
        NSLog(@"disconnect peripheral");
        [[LeDiscovery sharedInstance] disconnectPeripheral:peripheral];
    }
}


#pragma mark -
#pragma mark LeDiscoveryDelegate 
/****************************************************************************/
/*                       LeDiscoveryDelegate Methods                        */
/****************************************************************************/
- (void) discoveryDidRefresh 
{
    NSLog(@"discoveryDidRefresh\n");
    [sensorsTable reloadData];
}

- (void) discoveryStatePoweredOff 
{
    NSLog(@"discoveryStatePoweredOff\n");
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to use LE";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}



#pragma mark -
#pragma mark App IO
/****************************************************************************/
/*                              App IO Methods                              */
/****************************************************************************/
/** Increase or decrease the maximum alarm setting */
- (IBAction) maxStepperChanged
{
    NSLog(@"maxStepperChanged\n");
    int newTemp = [currentlyDisplayingService maximumTemperature] * 10;
    
    if (maxAlarmStepper.value > 0) {
        newTemp+=10;
        NSLog(@"increasing MAX temp to %d", newTemp);
    }
    
    if (maxAlarmStepper.value < 0) {
        newTemp-=10;
        NSLog(@"decreasing MAX temp to %d", newTemp);
    }
    
    // We're not interested in the actual VALUE of the stepper, just if it's increased or decreased, so reset it to 0 after a press
    [maxAlarmStepper setValue:0];
    
    // Disable the stepper so we don't send multiple requests to the peripheral
    [maxAlarmStepper setEnabled:NO];
    
    [currentlyDisplayingService writeHighAlarmTemperature:newTemp];
}


/** Increase or decrease the minimum alarm setting */
- (IBAction) minStepperChanged
{
    NSLog(@"minStepperChanged\n");
    int newTemp = [currentlyDisplayingService minimumTemperature] * 10;
    
    if (minAlarmStepper.value > 0) {
        newTemp+=10;
        NSLog(@"increasing MIN temp to %d", newTemp);
    }
    
    if (minAlarmStepper.value < 0) {
        newTemp-=10;
        NSLog(@"decreasing MIN temp to %d", newTemp);
    }
    
    // We're not interested in the actual VALUE of the stepper, just if it's increased or decreased, so reset it to 0 after a press
    [minAlarmStepper setValue:0];    
    
    // Disable the stepper so we don't send multiple requests to the peripheral
    [minAlarmStepper setEnabled:NO];
    
    [currentlyDisplayingService writeLowAlarmTemperature:newTemp];
}

//gray
-(IBAction)clearView:(id)sender{
    NSLog(@"clearView");
    
    CGRect square = CGRectMake(DRAW_X, DRAW_Y, DRAW_WIDTH, DRAW_HEIGHT);
    qz = [[Quartz alloc] initWithFrame:square];
    [self.view addSubview:qz];

}

-(IBAction)setPoint:(id)sender{
    NSLog(@"setPoint");
    
    qz = [[Quartz alloc] init];
    [qz setPoint];
    
}

-(IBAction)setLine:(id)sender{
    NSLog(@"setLine");
    
    qz = [[Quartz alloc] init];
    [qz setLine];
    
}

-(IBAction)reScan:(id)sender{
    NSLog(@"reScan");
    
    connectedServices = [NSMutableArray new];
    
	[[LeDiscovery sharedInstance] setDiscoveryDelegate:self];
    [[LeDiscovery sharedInstance] setPeripheralDelegate:self];
    [[LeDiscovery sharedInstance] startScanningForUUIDString:kTemperatureServiceUUIDString];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:kAlarmServiceEnteredBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterForegroundNotification:) name:kAlarmServiceEnteredForegroundNotification object:nil];
    
}

-(IBAction)startTest:(id)sender{
    NSLog(@"startTest");

}

- (void) handleTimer: (NSTimer *) timer
{
//    NSLog(@"handleTimer");
    [currentPacketRateLabel setText:[NSString stringWithFormat:@"%d", [LeTemperatureAlarmService packetRate]]];
    [currentErrorRateLabel setText:[NSString stringWithFormat:@"%d", [LeTemperatureAlarmService getErrorRate]]];
    
//    [currentErrorCodeLabel setText:[NSString stringWithFormat:@"%@", [LeTemperatureAlarmService getErrorCode]]];
    [textView setText:[LeTemperatureAlarmService getErrorCode]];
    
    if([LeTemperatureAlarmService isRestartTimer] && timer2 == nil) {
        
        sleep(1);
        NSLog(@"start timer2");
        timer2 = [NSTimer scheduledTimerWithTimeInterval: (1/TIMER2_PACKETRATE)      // temporary packet rate
                                                  target: self
                                                selector: @selector(handleTimer2:)
                                                userInfo: nil
                                                 repeats: YES];
    }
    
}

- (void) handleTimer2: (NSTimer *) timer
{
//    NSLog(@"handleTimer2");
    int currentPressure = [LeTemperatureAlarmService getPressure];
//    int tempPressure = currentPressure;
//    if (tempPressure < 0) {
//        tempPressure = 0;
//    } else if (tempPressure > MAX_PRESSURE_LEVEL){
//        tempPressure = MAX_PRESSURE_LEVEL;
//    }
    if (currentPressure >=0 && currentPressure <= MAX_PRESSURE_LEVEL) {
        [Quartz setPenS:(int)(currentPressure*(DRAW_LEVEL-1)/MAX_PRESSURE_LEVEL)];
    }

    [currentPressureLabel setText:[NSString stringWithFormat:@"%d", currentPressure]];
    [currentRSSILabel setText:[NSString stringWithFormat:@"%d", [LeTemperatureAlarmService getRSSI]]];
    
    int temp;
    temp = [LeTemperatureAlarmService getButtonUp];
    if (temp & 0x02) {
        [currentButtonUpLabel setText:[NSString stringWithFormat:@"O"]];
        currentButtonUpLabel.textColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    } else {
        [currentButtonUpLabel setText:[NSString stringWithFormat:@"X"]];
        currentButtonUpLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
    }
 
    temp = [LeTemperatureAlarmService getButtonDown];
    if (temp & 0x01) {
        [currentButtonDownLabel setText:[NSString stringWithFormat:@"O"]];
        currentButtonDownLabel.textColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:1];
    } else {
        [currentButtonDownLabel setText:[NSString stringWithFormat:@"X"]];
        currentButtonDownLabel.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
    }
    
    

}
@end
