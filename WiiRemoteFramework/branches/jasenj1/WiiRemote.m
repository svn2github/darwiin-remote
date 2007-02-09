//
//  WiiRemote.m
//  DarwiinRemote
//
//  Created by KIMURA Hiroaki on 06/12/04.
//  Copyright 2006 KIMURA Hiroaki. All rights reserved.
//

#import "WiiRemote.h"

// this type is used a lot (data array):
typedef unsigned char darr[];


typedef UInt16 WiiButtonBitMask;
enum {
	kWiiRemoteTwoButton					= 0x0001,
	kWiiRemoteOneButton					= 0x0002,
	kWiiRemoteBButton					= 0x0004,
	kWiiRemoteAButton					= 0x0008,
	kWiiRemoteMinusButton				= 0x0010,
	kWiiRemoteHomeButton				= 0x0080,
	kWiiRemoteLeftButton				= 0x0100,
	kWiiRemoteRightButton				= 0x0200,
	kWiiRemoteDownButton				= 0x0400,
	kWiiRemoteUpButton					= 0x0800,
	kWiiRemotePlusButton				= 0x1000,
	
	
	kWiiNunchukZButton					= 0x0001,
	kWiiNunchukCButton					= 0x0002,
	
	
	kWiiClassicControllerUpButton		= 0x0001,
	kWiiClassicControllerLeftButton		= 0x0002,
	kWiiClassicControllerZRButton		= 0x0004,
	kWiiClassicControllerXButton		= 0x0008,
	kWiiClassicControllerAButton		= 0x0010,
	kWiiClassicControllerYButton		= 0x0020,
	kWiiClassicControllerBButton		= 0x0040,
	kWiiClassicControllerZLButton		= 0x0080,
	kWiiClassicControllerUnUsedButton	= 0x0100,
	kWiiClassicControllerRButton		= 0x0200,
	kWiiClassicControllerPlusButton		= 0x0400,
	kWiiClassicControllerHomeButton		= 0x0800,
	kWiiClassicControllerMinusButton	= 0x1000,
	kWiiClassicControllerLButton		= 0x2000,
	kWiiClassicControllerDownButton		= 0x4000,
	kWiiClassicControllerRightButton	= 0x8000
	
};




@implementation WiiRemote

- (id) init{

	
	accX = 0x10;
	accY = 0x10;
	accZ = 0x10;
	buttonData = 0;
	leftPoint = -1;
	batteryLevel = 0;
	warningBatteryLevel = 0.05;

	
	_delegate = nil;
	wiiDevice = nil;
	
	ichan = nil;
	cchan = nil;
	
	isIRSensorEnabled = NO;
	isMotionSensorEnabled = NO;
	isVibrationEnabled = NO;
	
	isExpansionPortEnabled = NO;
	isExpansionPortAttached = NO;
	expType = WiiExpNotAttached;
	
	return self;
}

- (void)dealloc{
	[self closeConnection];


	[super dealloc];
}

- (void)setDelegate:(id)delegate{
	_delegate = delegate;
}

- (BOOL)available{
	if (wiiDevice != nil)
		return YES;
	
	return NO;
}

- (IOReturn)openIChan {
	int trycount = 0;
	IOReturn ret;
	
	while ((ret = [wiiDevice openL2CAPChannelSync:&ichan withPSM:19 delegate:self]) != kIOReturnSuccess){	// this "19" is magic number ;-)
		if (trycount == 10){
			NSLog(@"could not open L2CAP channel ichan");
			ichan = nil;
			[cchan closeChannel];
			[cchan release];
			[wiiDevice closeConnection];
			
			return ret;			
		}
		trycount++;
		usleep(10000); //  wait 10ms
	}
	[ichan retain];
	
	return ret;
}

- (IOReturn) openCChan {
	int trycount = 0;
	IOReturn ret;
	
	while ((ret = [wiiDevice openL2CAPChannelSync:&cchan withPSM:17 delegate:self]) != kIOReturnSuccess){
		if (trycount == 10){
			NSLog(@"could not open L2CAP channel cchan (%d)", ret);
			cchan = nil;
			[wiiDevice closeConnection];
			return ret;			
		}
		trycount++;
		usleep(10000); //  wait 10ms
	}	
	[cchan retain];

	return ret;
}


- (IOReturn)connectTo:(IOBluetoothDevice*)device{
	
	wiiDevice = device;
	
	int trycount = 0;
	IOReturn ret;
	
	if (wiiDevice == nil){
		return kIOReturnBadArgument;
	}
	
	trycount = 0;
	while ((ret = [wiiDevice openConnection]) != kIOReturnSuccess){
		if (trycount >= 10){
			NSLog(@"could not open the connection (%d)...", ret);
			return ret;
		}
		trycount++;
		usleep(10000); //  wait 10ms
	}
	
	disconnectNotification = [wiiDevice registerForDisconnectNotification:self selector:@selector(disconnected:fromDevice:)];
	
	trycount = 0;
	while ((ret = [wiiDevice performSDPQuery:nil]) != kIOReturnSuccess){
		if (trycount == 10){
			NSLog(@"could not perform SDP Query (%d)...", ret);
			[wiiDevice closeConnection];
			return ret;
		}
		trycount++;
		usleep(10000); //  wait 10ms
	}
	
	ret = [self openIChan];
	
	ret = [self openCChan];

	//turn LEDs off
	if (kIOReturnSuccess == ret)
		ret = [self setLEDEnabled1:NO enabled2:NO enabled3:NO enabled4:NO];
	
	if (kIOReturnSuccess != ret) {
		[self closeConnection];
		return ret;
	}
	
	// Get current status every 60 seconds.
	statusTimer = [[NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(getCurrentStatus:) userInfo:nil repeats:YES] retain];
	
	[self getCurrentStatus:nil];
	
	[self readData:0x0020 length:7]; // Get Accelerometer calibration data
	
	return ret;
}

- (void)disconnected: (IOBluetoothUserNotification*)note fromDevice: (IOBluetoothDevice*)device {
	
	if ([[device getAddressString] isEqualToString:[self address]]){
		[self closeConnection];
		if (nil != _delegate)
			[_delegate wiiRemoteDisconnected:device];
	}
	
}

- (IOReturn)sendCommand:(const unsigned char*)data length:(size_t)length{
	
	
	unsigned char buf[40];
	memset(buf,0,40);
	buf[0] = 0x52;
	memcpy(buf+1, data, length);
	if (buf[1] == 0x16) length=23;
	else				length++;
	
	int i;
	
	
//	printf ("send%3d:", length);
//	for(i=0 ; i<length ; i++) {
//		printf(" %02X", buf[i]);
//	}
//	printf("\n");
	
	IOReturn ret;
	
	for (i = 0; i < 10; i++){
		ret = [cchan writeSync:buf length:length];
		if (kIOReturnSuccess == ret)
			break;
		usleep(10000);
	}
	
	if (ret == kIOReturnNoDevice) {
		[self disconnected: nil fromDevice:wiiDevice];
	}
	
	NSLog(@"IOReturn for command %00X = %i", buf[1], ret);
	return ret;
}


- (double)batteryLevel{
	
	return batteryLevel;
}

- (NSString*)address{
	return [wiiDevice getAddressString];
}

- (IOReturn)setMotionSensorEnabled:(BOOL)enabled{
	// these variables indicate a desire, and should be updated regardless of the sucess of sending the command
	isMotionSensorEnabled = enabled;
	
	return [self requestUpdates];
}


- (IOReturn)setForceFeedbackEnabled:(BOOL)enabled{
	// these variables indicate a desire, and should be updated regardless of the sucess of sending the command
	isVibrationEnabled = enabled;
	
	unsigned char cmd[] = {0x13, 0x00};
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (isIRSensorEnabled)	cmd[1] |= 0x04;
	
	return [self sendCommand:cmd length:2];
}

- (IOReturn)setLEDEnabled1:(BOOL)enabled1 enabled2:(BOOL)enabled2 enabled3:(BOOL)enabled3 enabled4:(BOOL)enabled4{
	unsigned char cmd[] = {0x11, 0x00};
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (enabled1)	cmd[1] |= 0x10;
	if (enabled2)	cmd[1] |= 0x20;
	if (enabled3)	cmd[1] |= 0x40;
	if (enabled4)	cmd[1] |= 0x80;
	
	isLED1Illuminated = enabled1;
	isLED2Illuminated = enabled2;
	isLED3Illuminated = enabled3;
	isLED4Illuminated = enabled4;
	
	return 	[self sendCommand:cmd length:2];
}

- (IOReturn)requestUpdates {

	// Set the report type the Wiimote should send.
	unsigned char cmd[] = {0x12, 0x02, 0x30}; // Just buttons.
	
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (isMotionSensorEnabled)	cmd[2] |= 0x01;
	if (isIRSensorEnabled)	cmd[2] |= 0x02;
	if (isExpansionPortEnabled) cmd[2] = 0x37;
	
	return [self sendCommand:cmd length:3];

}

- (IOReturn)setExpansionPortEnabled:(BOOL)enabled{
	
	IOReturn ret;
	
	if (enabled) {
		NSLog(@"Enabling expansion port.");
	} else {
		NSLog(@"Disabling expansion port.");	
	}
	
	isExpansionPortEnabled = enabled;

	if (!isExpansionPortAttached) {
		isExpansionPortEnabled = NO;
	} else {
			
		ret = [self writeData:(darr){0x00} at:(unsigned long)0x04A40040 length:1]; // Init expansion device.
		
		if (ret == kIOReturnSuccess){
			// get calib data
			ret = [self readData:0x04A40020 length: 16];
		}
				
	}

	if (isExpansionPortEnabled) {
		NSLog(@"Expansion port enabled.");
	} else {
		NSLog(@"Expansion port disabled.");
	}
	
	ret = [self requestUpdates];

	return ret;
}


//based on Ian's codes. thanks!
- (IOReturn)setIRSensorEnabled:(BOOL)enabled{
	IOReturn ret;
	
	isIRSensorEnabled = enabled;

/*
	// set register 0x12 (report type)
	if (ret = [self setMotionSensorEnabled:isMotionSensorEnabled]) return ret;
	
	// set register 0x13 (ir enable/vibe)
	if (ret = [self setForceFeedbackEnabled:isVibrationEnabled]) return ret;
*/
	
	// set register 0x1a (ir enable 2)
	unsigned char cmd[] = {0x1a, 0x00};
	if (enabled)	cmd[1] |= 0x04;
	if (ret = [self sendCommand:cmd length:2]) return ret;
	
	if(enabled){
		// based on marcan's method, found on wiili wiki:
		// tweaked to include some aspects of cliff's setup procedure in the hopes
		// of it actually turning on 100% of the time (was seeing 30-40% failure rate before)
		// the sleeps help it it seems
		usleep(10000);
		if (ret = [self writeData:(darr){0x01} at:0x04B00030 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeData:(darr){0x08} at:0x04B00030 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeData:(darr){0x90} at:0x04B00006 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeData:(darr){0xC0} at:0x04B00008 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeData:(darr){0x40} at:0x04B0001A length:1]) return ret;
		usleep(10000);
		if (ret = [self writeData:(darr){0x33} at:0x04B00033 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeData:(darr){0x08} at:0x04B00030 length:1]) return ret;
		
	}else{
		// probably should do some writes to power down the camera, save battery
		// but don't know how yet.

		[self setMotionSensorEnabled:isMotionSensorEnabled];
		[self setForceFeedbackEnabled:isVibrationEnabled];
		[self setExpansionPortEnabled:isExpansionPortEnabled];
	}
	
	return kIOReturnSuccess;
}


- (IOReturn)writeData:(const unsigned char*)data at:(unsigned long)address length:(size_t)length{
	unsigned char cmd[22];
	//unsigned long addr = CFSwapInt32HostToBig(address);
	unsigned long addr = address;

	int i;
	for(i=0 ; i < length ; i++) {
		cmd[i+6] = data[i];
	}
	for(; i < 16; i++) {
		cmd[i+6]= 0;
	}
	
	cmd[0] = 0x16;
	cmd[1] = (addr >> 24) & 0xFF;
	cmd[2] = (addr >> 16) & 0xFF;
	cmd[3] = (addr >>  8) & 0xFF;
	cmd[4] = (addr >>  0) & 0xFF;
	cmd[5] = length;
	
	// and of course the vibration flag, as usual
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	
	data = cmd;
	
	return [self sendCommand:cmd length:22];
}


- (IOReturn)readData:(unsigned long)address length:(unsigned short)length{
	
	unsigned char cmd[7];
	
	//i'm still not sure whether i don't have to swap these args
	
	//unsigned long addr = CFSwapInt32HostToBig(address);
	unsigned long addr = address;
	//unsigned short len = CFSwapInt16HostToBig(length);
	unsigned short len = length;
	
	cmd[0] = 0x17; // read memory
	
	// address
	cmd[1] = (addr >> 24) & 0xFF;  // bit 2 being set indicates read from control registers, 0 indicates EEPROM Memory
	cmd[2] = (addr >> 16) & 0xFF;
	cmd[3] = (addr >>  8) & 0xFF;
	cmd[4] = (addr >>  0) & 0xFF;
	
	// Number of bytes to read
	cmd[5] = (len >> 8) & 0xFF;
	cmd[6] = (len >> 0) & 0xFF;
	
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	
	if (cmd[1] & 0x02) readingRegister = YES;
	
	return [self sendCommand:cmd length:7];
}


- (IOReturn)closeConnection{
	IOReturn ret = 0;
	int trycount = 0;
	
	if (disconnectNotification!=nil){
		[disconnectNotification unregister];
		disconnectNotification = nil;
	}
	
	
	if (cchan){
		if ([wiiDevice isConnected]) do {
			ret = [cchan closeChannel];
			trycount++;
		}while(ret != kIOReturnSuccess && trycount < 10);
		[cchan release];
	}

	
	trycount = 0;
	
	if (ichan){
		if ([wiiDevice isConnected]) do {
			ret = [ichan closeChannel];
			trycount++;
		}while(ret != kIOReturnSuccess && trycount < 10);
		[ichan release];
	}

	
	trycount = 0;
	
	if (wiiDevice){
		if ([wiiDevice isConnected]) do{
			ret = [wiiDevice closeConnection];
			trycount++;
		}while(ret != kIOReturnSuccess && trycount < 10);
		//NSLog(@"closed");
	}
	
	ichan = cchan = nil;
	wiiDevice = nil;
	
	// no longer a delegate
	if (statusTimer){
		[statusTimer invalidate];
		[statusTimer release];
		statusTimer = nil;

	}

	
	return ret;
}

	/**
	 * Handle report 0x21 (Read Data) from wiimote.
	 * dp[0] = Bluetooth header
	 * dp[1] = (0x21) Report/Channel ID
	 * dp[2] = Wiimote Buttons
	 * dp[3] = Wiimote Buttons
	 * dp[4] = High 4 bits = payload size; Low 4 bits = Error flag (0 = all good)	 
	 * dp[5] = Offset of memory read
	 * dp[6] = Offset of memory read
	 * dp[7+] = the Data.
	 **/
- (void) handleRAMData:(unsigned char *)dp length:(size_t)dataLength {
	/**
	if (dp[1] == 0x21){
		int i;
		
		printf ("ack%3d:", dataLength);
		for(i=0 ; i<dataLength ; i++) {
			printf(" %02X", dp[i]);
		}
		printf("\n");
	}**/

	// wiimote buttons
	buttonData = ((short)dp[2] << 8) + dp[3];
	[self sendWiiRemoteButtonEvent:buttonData];
	 
	// specify attached expasion device
	if ((dp[5] == 0x00) && (dp[6] == 0xF0)){
		NSLog(@"Expansion device connected.");
		
		if ([self decrypt:dp[21]] == 0x00){
				NSLog(@"Nunchuk connected.");
			if (expType != WiiNunchuk){
				expType = WiiNunchuk;
				[[NSNotificationCenter defaultCenter] postNotificationName:@"WiiRemoteExpansionPortChangedNotification" object:self];
			}
		}else if ([self decrypt:dp[21]] == 0x01){
			if (expType != WiiClassicController){
				expType = WiiClassicController;
				[[NSNotificationCenter defaultCenter] postNotificationName:@"WiiRemoteExpansionPortChangedNotification" object:self];					
			}
		}else{
			NSLog(@"Unknown device connected (%00X). ", [self decrypt:dp[21]]);
			expType = WiiExpNotAttached;
		}
		return;
	}
		
		
	// wiimote calibration data
	if (!readingRegister && dp[5] == 0x00 && dp[6] == 0x20){
		wiiCalibData.accX_zero = dp[7];
		wiiCalibData.accY_zero = dp[8];
		wiiCalibData.accZ_zero = dp[9];
		
		//dp[10] - unknown/unused
		
		wiiCalibData.accX_1g = dp[11];
		wiiCalibData.accY_1g = dp[12];
		wiiCalibData.accZ_1g = dp[13];
		return;
	}
	
	// expansion device calibration data.		
	if (readingRegister && dp[5] == 0x00 && dp[6] == 0x20){
		if (expType == WiiNunchuk) {
			//nunchuk calibration data
			nunchukCalibData.accX_zero =  [self decrypt:dp[7]];
			nunchukCalibData.accY_zero =  [self decrypt:dp[8]];
			nunchukCalibData.accZ_zero =  [self decrypt:dp[9]];
			
			nunchukCalibData.accX_1g =  [self decrypt:dp[11]];
			nunchukCalibData.accY_1g =  [self decrypt:dp[12]];
			nunchukCalibData.accZ_1g =  [self decrypt:dp[13]];
			
			nunchukJoyStickCalibData.x_max =  [self decrypt:dp[15]];
			nunchukJoyStickCalibData.x_min =  [self decrypt:dp[16]];
			nunchukJoyStickCalibData.x_center =  [self decrypt:dp[17]];
			
			nunchukJoyStickCalibData.y_max =  [self decrypt:dp[19]];
			nunchukJoyStickCalibData.y_min =  [self decrypt:dp[20]];
			nunchukJoyStickCalibData.y_center =  [self decrypt:dp[21]];	
			
			return;
		} else if (expType == WiiClassicController){
			//classic controller calibration data (probably)
		}
	} // expansion device calibration data
	
} // handleRAMData

-(void) handleStatusReport:(unsigned char *)dp length:(size_t)dataLength {

		NSLog(@"Status Report");
		
		batteryLevel = (double)dp[7];
		batteryLevel /= (double)0xC0; // C0 = fully charged.
		
		if (batteryLevel < warningBatteryLevel) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"WiiRemoteBatteryLowNotification" object:self];
		}
		
		if ((dp[4] & 0x02)) { //some device attached to Wiimote

			NSLog(@"Device Attached");
			if (isExpansionPortAttached == NO) {
				isExpansionPortAttached = YES;
				
				IOReturn ret = [self writeData:(darr){0x00} at:(unsigned long)0x04A40040 length:1]; // Initialize the device
				
				if (ret != kIOReturnSuccess) {
					isExpansionPortAttached = NO;
					return;
				}
				
				usleep(10000); // Give the write a chance to be processed.
				
				ret = [self readData:0x04A400F0 length:16]; // read expansion device type
				if (ret != kIOReturnSuccess) {
					isExpansionPortAttached = NO;
				}
				
				NSLog(@"Expansion Device initialized");
			}
			return;
		} else { // unplugged
			NSLog(@"Device Detached");
			isExpansionPortAttached = NO;
			expType = WiiExpNotAttached;

			[[NSNotificationCenter defaultCenter] postNotificationName:@"WiiRemoteExpansionPortChangedNotification" object:self];
			return;
		}
		
		if ((dp[4] & 0x10)){
			isLED1Illuminated = YES;
		}else{
			isLED1Illuminated = NO;
		}
		
		if ((dp[4] & 0x20)){
			isLED2Illuminated = YES;
		}else{
			isLED2Illuminated = NO;
		}
		
		if ((dp[4] & 0x40)){
			isLED3Illuminated = YES;
		}else{
			isLED3Illuminated = NO;
		}
		
		if ((dp[4] & 0x80)){
			isLED4Illuminated = YES;
		}else{
			isLED4Illuminated = NO;
		}
} // handleStatusReport


- (void)handleButtonReport:(unsigned char *)dp length:(size_t)dataLength {
		// wiimote buttons
		buttonData = ((short)dp[2] << 8) + dp[3];
		[self sendWiiRemoteButtonEvent:buttonData];
		
		//retrieve nunchuk data
		//if (dp[1] == 0x32 || dp[1] == 0x34 || dp[1] == 0x35 || dp[1] == 0x36 || dp[1] == 0x37 || dp[1] == 0x3D){
		if (dp[1] == 0x37) { // buttons, motion sensors, expansion port
			if (expType == WiiNunchuk) {
				nStickX = [self decrypt:dp[17]];
				nStickY = [self decrypt:dp[18]];
				nAccX   = [self decrypt:dp[19]];
				nAccY   = [self decrypt:dp[20]];
				nAccZ   = [self decrypt:dp[21]];
				nButtonData = [self decrypt:dp[22]];
			} else if (expType == WiiClassicController) {
				cButtonData = (unsigned short)([self decrypt:dp[21]] << 8) + [self decrypt:dp[22]];
				
				cStickX1 = [self decrypt:dp[17]] & 0x3F;
				cStickY1 = [self decrypt:dp[18]] & 0x3F;
				
				cStickX2 = ([self decrypt:dp[17]] & 0xC0) >> 3 + ([self decrypt:dp[18]] & 0xC0) >> 5 + ([self decrypt:dp[19]] & 0x80) >> 7; 
				cStickY2 =  [self decrypt:dp[19]] & 0x0F;
				
				cAnalogR =  [self decrypt:dp[20]] & 0x0F;
				cAnalogL = ( [self decrypt:dp[20]] & 0xE0) >> 5 + ( [self decrypt:dp[19]] & 0x60) >> 2;
			}
		} // buttons, motion sensors, expansion port
		
		if (isExpansionPortEnabled) {
			if (expType == WiiNunchuk) {
				[self sendWiiNunchukButtonEvent:nButtonData];
				[_delegate accelerationChanged:WiiNunchukAccelerationSensor accX:nAccX accY:nAccY accZ:nAccZ];
				[_delegate joyStickChanged:WiiNunchukJoyStick tiltX:nStickX tiltY:nStickY];
			} else if (expType == WiiClassicController){
				[self sendWiiClassicControllerButtonEvent:cButtonData];
				[_delegate joyStickChanged:WiiClassicControllerLeftJoyStick tiltX:cStickX1 tiltY:cStickY1];
				[_delegate joyStickChanged:WiiClassicControllerRightJoyStick tiltX:cStickX2 tiltY:cStickY2];
				
				[_delegate analogButtonChanged:WiiClassicControllerLeftButton amount:cAnalogL];
				[_delegate analogButtonChanged:WiiClassicControllerRightButton amount:cAnalogR];

			}			
		}
		
		
		// report contains motion sensor data
		if (dp[1] & 0x01) {
			
			accX = dp[4];
			accY = dp[5];
			accZ = dp[6];
			
			[_delegate accelerationChanged:WiiRemoteAccelerationSensor accX:accX accY:accY accZ:accZ];
			
			lowZ = lowZ * 0.9 + accZ * 0.1;
			lowX = lowX * 0.9 + accX * 0.1;
			
			float absx = abs(lowX-128), absz = abs(lowZ-128);
			
			if (orientation == 0 || orientation == 2) absx -= 5;
			if (orientation == 1 || orientation == 3) absz -= 5;
			
			if (absz >= absx) {
				if (absz > 5)
					orientation = (lowZ > 128)?0:2;
			} else {
				if (absx > 5)
					orientation = (lowX > 128)?3:1;
			}
			
			//	printf("orientation: %d\n", orientation);
		} // report contains motion sensor data
		
		// report contains IR data
		if (dp[1] & 0x02) {
			int i;
			for(i=0 ; i < 4 ; i++) { 
				irData[i].x = dp[7 + 3 * i];
				irData[i].y = dp[8 + 3 * i];
				irData[i].s = dp[9 + 3 * i];
				irData[i].x += (irData[i].s & 0x30) << 4;
				irData[i].y += (irData[i].s & 0xC0) << 2;
				irData[i].s &= 0x0F;
			} 
		} // report contains IR data

} // handleButtonReport


// thanks to Ian!
-(void)l2capChannelData:(IOBluetoothL2CAPChannel*)l2capChannel data:(void *)dataPointer length:(size_t)dataLength{
	
	if (!wiiDevice) {
		return;
	}
	
	unsigned char* dp = (unsigned char*)dataPointer;
	
	//controller status (expansion port and battery level data) - received when report 0x15 sent to Wiimote (getCurrentStatus:) or status of expansion port changes.
	if (dp[1] == 0x20 && dataLength >= 8) {
		[self handleStatusReport:dp length:dataLength];
		[self requestUpdates]; // Make sure we keep getting state change reports.
		return;
	}

	if (dp[1] == 0x21) {
		[self handleRAMData:dp length:dataLength];
		return;
	}

	if (dp[1] == 0x22) { // Write data response
		NSLog(@"Write data response: %00x %00x %00x %00x", dp[2], dp[3], dp[4], dp[5]);
		return;
	}
	
	// report contains button info
	if ((dp[1] & 0xF0) == 0x30) {
		[self handleButtonReport:dp length:dataLength];
	} 	// report contains button info
	
	
	// ??? Why does the below get executed regardless of the report type?
	float ox, oy;
	if (irData[0].s < 0x0F && irData[1].s < 0x0F) {
		int l = leftPoint, r;
		if (leftPoint == -1) {
			switch (orientation) {
				case 0: l = (irData[0].x < irData[1].x)?0:1; break;
				case 1: l = (irData[0].y > irData[1].y)?0:1; break;
				case 2: l = (irData[0].x > irData[1].x)?0:1; break;
				case 3: l = (irData[0].y < irData[1].y)?0:1; break;
			}
			leftPoint = l;
		}
		r = 1-l;
		
		float dx = irData[r].x - irData[l].x;
		float dy = irData[r].y - irData[l].y;
		
		float d = sqrt(dx*dx+dy*dy);
		
		dx /= d;
		dy /= d;
		
		float cx = (irData[l].x+irData[r].x)/1024.0 - 1;
		float cy = (irData[l].y+irData[r].y)/1024.0 - .75;
		
		//		float angle = atan2(dy, dx);
		
		ox = -dy*cy-dx*cx;
		oy = -dx*cy+dy*cx;
		//		printf("x:%5.2f;  y: %5.2f;  angle: %5.1f\n", ox, oy, angle*180/M_PI);
	} else {
		ox = oy = -100;
		if (leftPoint != -1) {
			//	printf("Not tracking.\n");
			leftPoint = -1;
		}
	}
	
	if (dp[1] & 0x02)
		[_delegate irPointMovedX:ox Y:oy];
		
	//if (nil != _delegate)
		//[_delegate dataChanged:buttonData accX:accX accY:accY accZ:accZ mouseX:ox mouseY:oy];
	//[_delegate dataChanged:buttonData accX:irData[0].x/4 accY:irData[0].y/3 accZ:irData[0].s*16];
} // l2capChannelData

- (unsigned char)decrypt:(unsigned char)data {
		return (data ^ 0x17) + 0x17;
	}

- (void)sendWiiRemoteButtonEvent:(UInt16)data{

	if (data & kWiiRemoteTwoButton){
		if (!buttonState[WiiRemoteTwoButton]){
			buttonState[WiiRemoteTwoButton] = YES;
			[_delegate buttonChanged:WiiRemoteTwoButton isPressed:buttonState[WiiRemoteTwoButton]];
		}
	}else{
		if (buttonState[WiiRemoteTwoButton]){
			buttonState[WiiRemoteTwoButton] = NO;
			[_delegate buttonChanged:WiiRemoteTwoButton isPressed:buttonState[WiiRemoteTwoButton]];
		}
	}

	if (data & kWiiRemoteOneButton){
		if (!buttonState[WiiRemoteOneButton]){
			buttonState[WiiRemoteOneButton] = YES;
			[_delegate buttonChanged:WiiRemoteOneButton isPressed:buttonState[WiiRemoteOneButton]];
		}
	}else{
		if (buttonState[WiiRemoteOneButton]){
			buttonState[WiiRemoteOneButton] = NO;
			[_delegate buttonChanged:WiiRemoteOneButton isPressed:buttonState[WiiRemoteOneButton]];
		}
	}
	
	if (data & kWiiRemoteAButton){
		if (!buttonState[WiiRemoteAButton]){
			buttonState[WiiRemoteAButton] = YES;
			[_delegate buttonChanged:WiiRemoteAButton isPressed:buttonState[WiiRemoteAButton]];
		}
	}else{
		if (buttonState[WiiRemoteAButton]){
			buttonState[WiiRemoteAButton] = NO;
			[_delegate buttonChanged:WiiRemoteAButton isPressed:buttonState[WiiRemoteAButton]];
		}
	}
	
	if (data & kWiiRemoteBButton){
		if (!buttonState[WiiRemoteBButton]){
			buttonState[WiiRemoteBButton] = YES;
			[_delegate buttonChanged:WiiRemoteBButton isPressed:buttonState[WiiRemoteBButton]];
		}
	}else{
		if (buttonState[WiiRemoteBButton]){
			buttonState[WiiRemoteBButton] = NO;
			[_delegate buttonChanged:WiiRemoteBButton isPressed:buttonState[WiiRemoteBButton]];
		}
	}
	
	if (data & kWiiRemoteMinusButton){
		if (!buttonState[WiiRemoteMinusButton]){
			buttonState[WiiRemoteMinusButton] = YES;
			[_delegate buttonChanged:WiiRemoteMinusButton isPressed:buttonState[WiiRemoteMinusButton]];
		}
	}else{
		if (buttonState[WiiRemoteMinusButton]){
			buttonState[WiiRemoteMinusButton] = NO;
			[_delegate buttonChanged:WiiRemoteMinusButton isPressed:buttonState[WiiRemoteMinusButton]];
		}
	}
	
	if (data & kWiiRemoteHomeButton){
		if (!buttonState[WiiRemoteHomeButton]){
			buttonState[WiiRemoteHomeButton] = YES;
			[_delegate buttonChanged:WiiRemoteHomeButton isPressed:buttonState[WiiRemoteHomeButton]];
		}
	}else{
		if (buttonState[WiiRemoteHomeButton]){
			buttonState[WiiRemoteHomeButton] = NO;
			[_delegate buttonChanged:WiiRemoteHomeButton isPressed:buttonState[WiiRemoteHomeButton]];
		}
	}
	
	if (data & kWiiRemotePlusButton){
		if (!buttonState[WiiRemotePlusButton]){
			buttonState[WiiRemotePlusButton] = YES;
			[_delegate buttonChanged:WiiRemotePlusButton isPressed:buttonState[WiiRemotePlusButton]];
		}
	}else{
		if (buttonState[WiiRemotePlusButton]){
			buttonState[WiiRemotePlusButton] = NO;
			[_delegate buttonChanged:WiiRemotePlusButton isPressed:buttonState[WiiRemotePlusButton]];
		}
	}
	
	if (data & kWiiRemoteUpButton){
		if (!buttonState[WiiRemoteUpButton]){
			buttonState[WiiRemoteUpButton] = YES;
			[_delegate buttonChanged:WiiRemoteUpButton isPressed:buttonState[WiiRemoteUpButton]];
		}
	}else{
		if (buttonState[WiiRemoteUpButton]){
			buttonState[WiiRemoteUpButton] = NO;
			[_delegate buttonChanged:WiiRemoteUpButton isPressed:buttonState[WiiRemoteUpButton]];
		}
	}
	
	if (data & kWiiRemoteDownButton){
		if (!buttonState[WiiRemoteDownButton]){
			buttonState[WiiRemoteDownButton] = YES;
			[_delegate buttonChanged:WiiRemoteDownButton isPressed:buttonState[WiiRemoteDownButton]];
		}
	}else{
		if (buttonState[WiiRemoteDownButton]){
			buttonState[WiiRemoteDownButton] = NO;
			[_delegate buttonChanged:WiiRemoteDownButton isPressed:buttonState[WiiRemoteDownButton]];
		}
	}

	if (data & kWiiRemoteLeftButton){
		if (!buttonState[WiiRemoteLeftButton]){
			buttonState[WiiRemoteLeftButton] = YES;
			[_delegate buttonChanged:WiiRemoteLeftButton isPressed:buttonState[WiiRemoteLeftButton]];
		}
	}else{
		if (buttonState[WiiRemoteLeftButton]){
			buttonState[WiiRemoteLeftButton] = NO;
			[_delegate buttonChanged:WiiRemoteLeftButton isPressed:buttonState[WiiRemoteLeftButton]];
		}
	}
	
	
	if (data & kWiiRemoteRightButton){
		if (!buttonState[WiiRemoteRightButton]){
			buttonState[WiiRemoteRightButton] = YES;
			[_delegate buttonChanged:WiiRemoteRightButton isPressed:buttonState[WiiRemoteRightButton]];
		}
	}else{
		if (buttonState[WiiRemoteRightButton]){
			buttonState[WiiRemoteRightButton] = NO;
			[_delegate buttonChanged:WiiRemoteRightButton isPressed:buttonState[WiiRemoteRightButton]];
		}
	}
}

- (void)sendWiiNunchukButtonEvent:(UInt16)data{
	if (!(data & kWiiNunchukCButton)){
		if (!buttonState[WiiNunchukCButton]){
			buttonState[WiiNunchukCButton] = YES;
			[_delegate buttonChanged:WiiNunchukCButton isPressed:buttonState[WiiNunchukCButton]];
		}
	}else{
		if (buttonState[WiiNunchukCButton]){
			buttonState[WiiNunchukCButton] = NO;
			[_delegate buttonChanged:WiiNunchukCButton isPressed:buttonState[WiiNunchukCButton]];
		}
	}
	
	if (!(data & kWiiNunchukZButton)){

		if (!buttonState[WiiNunchukZButton]){
			buttonState[WiiNunchukZButton] = YES;
			[_delegate buttonChanged:WiiNunchukZButton isPressed:buttonState[WiiNunchukZButton]];
		}
	}else{
		if (buttonState[WiiNunchukZButton]){
			buttonState[WiiNunchukZButton] = NO;
			[_delegate buttonChanged:WiiNunchukZButton isPressed:buttonState[WiiNunchukZButton]];
		}
	}
}

- (void)sendWiiClassicControllerButtonEvent:(UInt16)data{
	if (!(data & kWiiClassicControllerXButton)){
		
		if (!buttonState[WiiClassicControllerXButton]){
			buttonState[WiiClassicControllerXButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerXButton isPressed:buttonState[WiiClassicControllerXButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerXButton]){
			buttonState[WiiClassicControllerXButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerXButton isPressed:buttonState[WiiClassicControllerXButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerYButton)){
		
		if (!buttonState[WiiClassicControllerYButton]){
			buttonState[WiiClassicControllerYButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerYButton isPressed:buttonState[WiiClassicControllerYButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerYButton]){
			buttonState[WiiClassicControllerYButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerYButton isPressed:buttonState[WiiClassicControllerYButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerAButton)){
		
		if (!buttonState[WiiClassicControllerAButton]){
			buttonState[WiiClassicControllerAButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerAButton isPressed:buttonState[WiiClassicControllerAButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerAButton]){
			buttonState[WiiClassicControllerAButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerAButton isPressed:buttonState[WiiClassicControllerAButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerBButton)){
		
		if (!buttonState[WiiClassicControllerBButton]){
			buttonState[WiiClassicControllerBButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerBButton isPressed:buttonState[WiiClassicControllerBButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerBButton]){
			buttonState[WiiClassicControllerBButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerBButton isPressed:buttonState[WiiClassicControllerBButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerLButton)){
		
		if (!buttonState[WiiClassicControllerLButton]){
			buttonState[WiiClassicControllerLButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerLButton isPressed:buttonState[WiiClassicControllerLButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerLButton]){
			buttonState[WiiClassicControllerLButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerLButton isPressed:buttonState[WiiClassicControllerLButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerRButton)){
		
		if (!buttonState[WiiClassicControllerRButton]){
			buttonState[WiiClassicControllerRButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerRButton isPressed:buttonState[WiiClassicControllerRButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerRButton]){
			buttonState[WiiClassicControllerRButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerRButton isPressed:buttonState[WiiClassicControllerRButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerZLButton)){
		
		if (!buttonState[WiiClassicControllerZLButton]){
			buttonState[WiiClassicControllerZLButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerZLButton isPressed:buttonState[WiiClassicControllerZLButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerZLButton]){
			buttonState[WiiClassicControllerZLButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerZLButton isPressed:buttonState[WiiClassicControllerZLButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerZRButton)){
		
		if (!buttonState[WiiClassicControllerZRButton]){
			buttonState[WiiClassicControllerZRButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerZRButton isPressed:buttonState[WiiClassicControllerZRButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerZRButton]){
			buttonState[WiiClassicControllerZRButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerZRButton isPressed:buttonState[WiiClassicControllerZRButton]];
			
		}
	}
	
	
	if (!(data & kWiiClassicControllerUpButton)){
		
		if (!buttonState[WiiClassicControllerUpButton]){
			buttonState[WiiClassicControllerUpButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerUpButton isPressed:buttonState[WiiClassicControllerUpButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerUpButton]){
			buttonState[WiiClassicControllerUpButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerUpButton isPressed:buttonState[WiiClassicControllerUpButton]];
			
		}
	}
	
	
	if (!(data & kWiiClassicControllerDownButton)){
		
		if (!buttonState[WiiClassicControllerDownButton]){
			buttonState[WiiClassicControllerDownButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerDownButton isPressed:buttonState[WiiClassicControllerDownButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerDownButton]){
			buttonState[WiiClassicControllerDownButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerDownButton isPressed:buttonState[WiiClassicControllerDownButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerLeftButton)){
		
		if (!buttonState[WiiClassicControllerLeftButton]){
			buttonState[WiiClassicControllerLeftButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerLeftButton isPressed:buttonState[WiiClassicControllerLeftButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerLeftButton]){
			buttonState[WiiClassicControllerLeftButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerLeftButton isPressed:buttonState[WiiClassicControllerLeftButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerRightButton)){
		
		if (!buttonState[WiiClassicControllerRightButton]){
			buttonState[WiiClassicControllerRightButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerRightButton isPressed:buttonState[WiiClassicControllerRightButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerRightButton]){
			buttonState[WiiClassicControllerRightButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerRightButton isPressed:buttonState[WiiClassicControllerRightButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerMinusButton)){
		
		if (!buttonState[WiiClassicControllerMinusButton]){
			buttonState[WiiClassicControllerMinusButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerMinusButton isPressed:buttonState[WiiClassicControllerMinusButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerMinusButton]){
			buttonState[WiiClassicControllerMinusButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerMinusButton isPressed:buttonState[WiiClassicControllerMinusButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerHomeButton)){
		
		if (!buttonState[WiiClassicControllerHomeButton]){
			buttonState[WiiClassicControllerHomeButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerHomeButton isPressed:buttonState[WiiClassicControllerHomeButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerHomeButton]){
			buttonState[WiiClassicControllerHomeButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerHomeButton isPressed:buttonState[WiiClassicControllerHomeButton]];
			
		}
	}
	
	if (!(data & kWiiClassicControllerPlusButton)){
		
		if (!buttonState[WiiClassicControllerPlusButton]){
			buttonState[WiiClassicControllerPlusButton] = YES;
			[_delegate buttonChanged:WiiClassicControllerPlusButton isPressed:buttonState[WiiClassicControllerPlusButton]];
		}
	}else{
		if (buttonState[WiiClassicControllerPlusButton]){
			buttonState[WiiClassicControllerPlusButton] = NO;
			[_delegate buttonChanged:WiiClassicControllerPlusButton isPressed:buttonState[WiiClassicControllerPlusButton]];
			
		}
	}
}


- (void)getCurrentStatus:(NSTimer*)timer{
	unsigned char cmd[] = {0x15, 0x00};
	[self sendCommand:cmd length:2];
}

- (WiiExpansionPortType)expansionPortType{
	return expType;
}

- (BOOL)isExpansionPortAttached{
	return isExpansionPortAttached;
}

- (BOOL)isButtonPressed:(WiiButtonType)type{
	return buttonState[type];
}

- (WiiJoyStickCalibData)joyStickCalibData:(WiiJoyStickType)type{
	WiiJoyStickCalibData data;
	
	switch(type){
		case WiiNunchukJoyStick:
			return nunchukJoyStickCalibData;
		default:
			return data;
	}
}
- (WiiAccCalibData)accCalibData:(WiiAccelerationSensorType)type{
	WiiAccCalibData data;
	
	switch(type){
		case WiiRemoteAccelerationSensor:
			return wiiCalibData;
		case WiiNunchukAccelerationSensor:
			return nunchukCalibData;
		default:
			return data;
	}
}

@end