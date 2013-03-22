/*

 File: LeTemperatureAlarmService.m
 
 Abstract: Temperature Alarm Service Code - Connect to a peripheral 
 get notified when the temperature changes and goes past settable
 maximum and minimum temperatures.
 
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

#import "LeTemperatureAlarmService.h"
#import "LeDiscovery.h"
#import "Quartz.h"

// gray
static NSData *rawData;
static int currentPacketRate;    // current packet rate
static int currentPressure;      // current pressure
static NSData *currentBattery;   // current battery
static int currentButtonUp;      // current battery
static int currentButtonDown;    // current battery
static int currentRSSI;          // current RSSI
static NSMutableString *currentErrorCode;// current error
static int currentErrorRate;     // current error rate
static bool isDisconnect;
static bool isRestartTimerOK;

NSString *kTemperatureServiceUUIDString = @"DEADF154-0000-0000-0000-0000DEADF154";
NSString *kCurrentTemperatureCharacteristicUUIDString = @"CCCCFFFF-DEAD-F154-1319-740381000000";
NSString *kMinimumTemperatureCharacteristicUUIDString = @"C0C0C0C0-DEAD-F154-1319-740381000000";
NSString *kMaximumTemperatureCharacteristicUUIDString = @"EDEDEDED-DEAD-F154-1319-740381000000";
NSString *kAlarmCharacteristicUUIDString = @"AAAAAAAA-DEAD-F154-1319-740381000000";

NSString *kAlarmServiceEnteredBackgroundNotification = @"kAlarmServiceEnteredBackgroundNotification";
NSString *kAlarmServiceEnteredForegroundNotification = @"kAlarmServiceEnteredForegroundNotification";

@interface LeTemperatureAlarmService() <CBPeripheralDelegate> {
@private
    CBPeripheral		*servicePeripheral;
    
    CBService			*temperatureAlarmService;
    
    CBCharacteristic    *tempCharacteristic;
    CBCharacteristic	*minTemperatureCharacteristic;
    CBCharacteristic    *maxTemperatureCharacteristic;
    CBCharacteristic    *alarmCharacteristic;
    
    CBUUID              *temperatureAlarmUUID;
    CBUUID              *minimumTemperatureUUID;
    CBUUID              *maximumTemperatureUUID;
    CBUUID              *currentTemperatureUUID;

    id<LeTemperatureAlarmProtocol>	peripheralDelegate;
    
    NSTimer *timer3;
}
@end

@implementation LeTemperatureAlarmService

@synthesize peripheral = servicePeripheral;

#pragma mark -
#pragma mark Init
/****************************************************************************/
/*								Init										*/
/****************************************************************************/
- (id) initWithPeripheral:(CBPeripheral *)peripheral controller:(id<LeTemperatureAlarmProtocol>)controller
{
    self = [super init];
    if (self) {
        servicePeripheral = [peripheral retain];
        [servicePeripheral setDelegate:self];
		peripheralDelegate = controller;
        
        minimumTemperatureUUID	= [[CBUUID UUIDWithString:kMinimumTemperatureCharacteristicUUIDString] retain];
        maximumTemperatureUUID	= [[CBUUID UUIDWithString:kMaximumTemperatureCharacteristicUUIDString] retain];
        currentTemperatureUUID	= [[CBUUID UUIDWithString:kCurrentTemperatureCharacteristicUUIDString] retain];
        temperatureAlarmUUID	= [[CBUUID UUIDWithString:kAlarmCharacteristicUUIDString] retain];
	}
    
    NSLog(@"start timer3");
    timer3 = [NSTimer scheduledTimerWithTimeInterval: 2
                                             target: self
                                           selector: @selector(handleTimer3:)
                                           userInfo: nil
                                            repeats: YES];
    
    currentErrorCode = [[NSMutableString alloc] initWithCapacity:0];
    currentPressure = 0;
    isRestartTimerOK = false;

    return self;
}


- (void) dealloc {
	if (servicePeripheral) {
		[servicePeripheral setDelegate:[LeDiscovery sharedInstance]];
		[servicePeripheral release];
		servicePeripheral = nil;
        
        [minimumTemperatureUUID release];
        [maximumTemperatureUUID release];
        [currentTemperatureUUID release];
        [temperatureAlarmUUID release];
    }
    [super dealloc];
}

- (void) reset
{
	if (servicePeripheral) {
		[servicePeripheral release];
		servicePeripheral = nil;
	}
}

#pragma mark -
#pragma mark Service interaction
/****************************************************************************/
/*							Service Interactions							*/
/****************************************************************************/
- (void) start
{
    //gray
    NSLog(@"start\n");

	CBUUID	*serviceUUID_hid	= [CBUUID UUIDWithString:@"1812"];      // HID
	CBUUID	*serviceUUID_hrm	= [CBUUID UUIDWithString:@"180D"];      // heartrate
    CBUUID	*serviceUUID_bat	= [CBUUID UUIDWithString:@"180F"];      // battery
//  CBUUID	*serviceUUID	= [CBUUID UUIDWithString:@"1800"];      // generic access
//  CBUUID	*serviceUUID	= [CBUUID UUIDWithString:@"1801"];      // generic access
    CBUUID	*serviceUUID_dev	= [CBUUID UUIDWithString:@"180A"];      // device info
    
	NSArray	*serviceArray	= [NSArray arrayWithObjects:serviceUUID_hrm, serviceUUID_bat, serviceUUID_hid, serviceUUID_dev, nil];
//	NSArray	*serviceArray	= [NSArray arrayWithObjects:serviceUUID, nil];
    
    [servicePeripheral discoverServices:serviceArray];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"didDiscoverServices\n");
	NSArray		*services	= nil;

	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong Peripheral.\n");
		return ;
	}
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
		return ;
	}

	services = [peripheral services];

    NSLog(@"services count = %d\n", [services count]);
    
	if (!services || ![services count]) {

        if (!services) {
            NSLog(@"return, no services exit\n");
        }
        
        if (![services count]) {
            NSLog(@"return, services count = %d\n", [services count]);
        } 
            
        NSLog(@"return, (!services || ![services count])\n");
		return ;
	}

	temperatureAlarmService = nil;
 
 	for (CBService *service in services) {
        
        //gray
        NSLog(@"service UUID %@", [service UUID]);
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"180D"]] )    // HeartRate service
//        if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"1812"]] )    // HID sevices
//        if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"180F"]] )    // Battery sevices
//        if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"180A"]] )    // device info
        {
            NSLog(@"HeartRate service");
			temperatureAlarmService = service;
            if (temperatureAlarmService) {
                [peripheral discoverCharacteristics:nil forService:temperatureAlarmService];
            }
            else
            {
                NSLog(@"temperatureAlarmService == null\n");
            }
		}
        
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:@"180F"]] )    // Battery service
        {
            NSLog(@"Battery service");
			[peripheral discoverCharacteristics:nil forService:service];
		}
	}

}


- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
{
    NSLog(@"didDiscoverCharacteristicsForService\n");
	NSArray		*characteristics	= [service characteristics];
	CBCharacteristic *characteristic;
    
	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong Peripheral.\n");
		return ;
	}
	
//	if (service != temperatureAlarmService) {
//		NSLog(@"Wrong Service.\n");
//		return ;
//	}
    
    if (error != nil) {
		NSLog(@"Error %@\n", error);
		return ;
	}
    
	for (characteristic in characteristics) {
        NSLog(@"characteristic UUID:%@", [characteristic UUID]);
        
		if ([[characteristic UUID] isEqual:minimumTemperatureUUID]) { // Min Temperature.
            NSLog(@"Discovered Minimum Alarm Characteristic");
			minTemperatureCharacteristic = [characteristic retain];
			[peripheral readValueForCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:maximumTemperatureUUID]) { // Max Temperature.
            NSLog(@"Discovered Maximum Alarm Characteristic");
			maxTemperatureCharacteristic = [characteristic retain];
			[peripheral readValueForCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:temperatureAlarmUUID]) { // Alarm
            NSLog(@"Discovered Alarm Characteristic");
			alarmCharacteristic = [characteristic retain];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
        else if ([[characteristic UUID] isEqual:currentTemperatureUUID]) { // Current Temp

            NSLog(@"Discovered Temperature Characteristic");
			tempCharacteristic = [characteristic retain];
			[peripheral readValueForCharacteristic:tempCharacteristic];
			[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
        
        //gray
        else if (    [[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A37"]] ) {
                NSLog(@"in 2a37");
//                tempCharacteristic = [characteristic retain];
                [peripheral readValueForCharacteristic:characteristic];
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if (    [[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A38"]] ) {
                
                NSLog(@"in 2a38");
//                tempCharacteristic = [characteristic retain];
                [peripheral readValueForCharacteristic:characteristic];
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        // HID
        else if (    [[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A4D"]] ) {
            
            NSLog(@"in 2a4d");
            tempCharacteristic = [characteristic retain];
            [peripheral readValueForCharacteristic:tempCharacteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        // battery
        else if (    [[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A19"]] ) {
            
            NSLog(@"in 2a19");
//            tempCharacteristic = [characteristic retain];
            [peripheral readValueForCharacteristic:characteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        // device info
        else if (    [[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A29"]] ) {
            
            NSLog(@"in 2a29");
            tempCharacteristic = [characteristic retain];
            [peripheral readValueForCharacteristic:tempCharacteristic];
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        
        isRestartTimerOK = true;
        //gray
        
	}
}

#pragma mark -
#pragma mark Characteristics interaction
/****************************************************************************/
/*						Characteristics Interactions						*/
/****************************************************************************/
- (void) writeLowAlarmTemperature:(int)low 
{
    NSLog(@"writeLowAlarmTemperature\n");
    NSData  *data	= nil;
    int16_t value	= (int16_t)low;
    
    if (!servicePeripheral) {
        NSLog(@"Not connected to a peripheral");
		return ;
    }

    if (!minTemperatureCharacteristic) {
        NSLog(@"No valid minTemp characteristic");
        return;
    }
    
    data = [NSData dataWithBytes:&value length:sizeof (value)];
    [servicePeripheral writeValue:data forCharacteristic:minTemperatureCharacteristic type:CBCharacteristicWriteWithResponse];
}


- (void) writeHighAlarmTemperature:(int)high
{
    NSLog(@"writeHighAlarmTemperature\n");
    NSData  *data	= nil;
    int16_t value	= (int16_t)high;

    if (!servicePeripheral) {
        NSLog(@"Not connected to a peripheral");
    }

    if (!maxTemperatureCharacteristic) {
        NSLog(@"No valid minTemp characteristic");
        return;
    }

    data = [NSData dataWithBytes:&value length:sizeof (value)];
    [servicePeripheral writeValue:data forCharacteristic:maxTemperatureCharacteristic type:CBCharacteristicWriteWithResponse];
}


/** If we're connected, we don't want to be getting temperature change notifications while we're in the background.
 We will want alarm notifications, so we don't turn those off.
 */
- (void)enteredBackground
{
    NSLog(@"enteredBackground\n");
    // Find the fishtank service
    for (CBService *service in [servicePeripheral services]) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:kTemperatureServiceUUIDString]]) {
            
            // Find the temperature characteristic
            for (CBCharacteristic *characteristic in [service characteristics]) {
                if ( [[characteristic UUID] isEqual:[CBUUID UUIDWithString:kCurrentTemperatureCharacteristicUUIDString]] ) {
                    
                    // And STOP getting notifications from it
                    [servicePeripheral setNotifyValue:NO forCharacteristic:characteristic];
                }
            }
        }
    }
}

/** Coming back from the background, we want to register for notifications again for the temperature changes */
- (void)enteredForeground
{
    NSLog(@"enteredForeground\n");
    // Find the fishtank service
    for (CBService *service in [servicePeripheral services]) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:kTemperatureServiceUUIDString]]) {
            
            // Find the temperature characteristic
            for (CBCharacteristic *characteristic in [service characteristics]) {
                if ( [[characteristic UUID] isEqual:[CBUUID UUIDWithString:kCurrentTemperatureCharacteristicUUIDString]] ) {
                    
                    // And START getting notifications from it
                    [servicePeripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (CGFloat) minimumTemperature
{
    NSLog(@"minimumTemperature\n");
    CGFloat result  = NAN;
    int16_t value	= 0;
	
    if (minTemperatureCharacteristic) {
        [[minTemperatureCharacteristic value] getBytes:&value length:sizeof (value)];
        result = (CGFloat)value / 10.0f;
    }else{
        NSLog(@"minTemperatureCharacteristic = null\n");
    }
    return result;
}


- (CGFloat) maximumTemperature
{
    NSLog(@"maximumTemperature\n");
    CGFloat result  = NAN;
    int16_t	value	= 0;
    
    if (maxTemperatureCharacteristic) {
        [[maxTemperatureCharacteristic value] getBytes:&value length:sizeof (value)];
        result = (CGFloat)value / 10.0f;
    }else{
        NSLog(@"maxTemperatureCharacteristic = null\n");
    }
    return result;
}


- (NSData*) temperature
{
//    NSLog(@"temperature update\n");
//    CGFloat result  = NAN;
//    int16_t	value	= 0;
//    int value = 0;
//    char value[10];

//	if (tempCharacteristic) {
//        [[tempCharacteristic value] getBytes:&value length:sizeof(value)];
//    }
    
    return rawData;
}

- (NSData*) getBattery
{
//    NSLog(@"getBattery\n");
    return currentBattery;
}


+ (int) packetRate
{
//    NSLog(@"packetRate\n");
    int temp = currentPacketRate;
    currentPacketRate = 0;
    return temp;
}

+ (int) getPressure
{
//    NSLog(@"getPressure\n");
    return currentPressure;
}

+ (int) getButtonUp
{
//    NSLog(@"getButtonUp\n");
    return currentButtonUp;
}

+ (int) getButtonDown
{
//    NSLog(@"getButtonDown\n");
    return currentButtonDown;
}

+ (int) getRSSI
{
//    NSLog(@"getRSSI\n");
    return currentRSSI;
}

+ (NSString*) getErrorCode
{
//    NSLog(@"getErrorCode\n");
    return currentErrorCode;
}

+ (int) getErrorRate
{
//    NSLog(@"getErrorRate\n");
    int temp = currentErrorRate;
    currentErrorRate = 0;
    return temp;
    
}

+ (bool) isRestartTimer
{
//    NSLog(@"isRestartTimer\n");
    return isRestartTimerOK;
    
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error;
{
//    NSLog(@"peripheralDidUpdateRSSI, error:%@", error);
    if (!peripheral) {
//        NSLog(@"peripheralDidUpdateRSSI, error:%@\n", [error localizedDescription]);
        return;
    }
    
    if (error != nil) {
//        NSLog(@"peripheralDidUpdateRSSI, error:%@\n", [error localizedDescription]);
//        NSString *temp = [[NSString alloc] initWithFormat:@"update RSSI error; Error code:%d; %@\n", [error code], [error localizedDescription]];
//        [currentErrorCode appendString:temp];
        return;
    }
 
    currentRSSI = [peripheral.RSSI integerValue];
}

- (void) handleTimer3: (NSTimer *) timer
{
//    NSLog(@"handleTimer3");
    if (!isDisconnect) {
         [servicePeripheral readRSSI];
    } else {
        NSLog(@"stop Timer3");
        [timer3 invalidate];
        timer3 = nil;
        isDisconnect = false;   // reset state
    }
}

+ (void) setError: (NSError*) error
{
    NSLog(@"setError, err:%@\n", currentErrorCode);
    NSString *temp = [[NSString alloc] initWithFormat:@"Error code:%d; %@\n", [error code], [error localizedDescription]];
    [currentErrorCode appendString:temp];
    isDisconnect = true;
    isRestartTimerOK = false;
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
//    NSLog(@"didUpdateValueForCharacteristic, characteristic UUID %@", [characteristic UUID]);
    
	if (peripheral != servicePeripheral) {
		NSLog(@"Wrong peripheral\n");
		return ;
	}
    
    // count and record error
    if ([error code] != 0) {
//        NSLog(@"didUpdateValueForCharacteristic, error:%@\n", [error localizedDescription]);
        NSString *temp = [[NSString alloc] initWithFormat:@"update data error; Error code:%d; %@\n", [error code], [error localizedDescription]];
        [currentErrorCode appendString:temp];
        currentErrorRate++;
		return ;
	}

    // heartrate
    if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A37"]]) {
//        NSLog(@"characteristic.value:%@", characteristic.value);
//        NSLog(@"sizeof(characteristic.value):%ld", sizeof(characteristic.value));
        currentPacketRate++;
        rawData = characteristic.value;
        NSInteger rawDataLen = [rawData length];
        unsigned char temp[10];
        [rawData getBytes:temp length:rawDataLen];
        currentPressure = temp[5]<<8 | temp[4];
        currentButtonUp = temp[8];
        currentButtonDown = temp[8];
        [peripheralDelegate alarmServiceDidChangeTemperature:self];
        return;
    }
    
    // battery
    else if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:@"2A19"]]) {
//        NSLog(@"characteristic.value:%@", characteristic.value);
//        NSLog(@"currentBattery length:%d", [currentBattery length]);        
        currentBattery = characteristic.value;
        unsigned char temp2[1];
        [currentBattery getBytes:temp2 length:[currentBattery length]];
        [peripheralDelegate alarmServiceDidChangeBattery:self];
        
    }
    
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didWriteValueForCharacteristic\n");
    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
    [peripheral readValueForCharacteristic:characteristic];
    
    /* Upper or lower bounds changed */
    if ([characteristic.UUID isEqual:minimumTemperatureUUID] || [characteristic.UUID isEqual:maximumTemperatureUUID]) {
        [peripheralDelegate alarmServiceDidChangeTemperatureBounds:self];
    }
}


@end
