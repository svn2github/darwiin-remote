//
//  WiiRemote.m
//  DarwiinRemote
//
//  Created by KIMURA Hiroaki on 06/12/04.
//  Copyright 2006 KIMURA Hiroaki. All rights reserved.
//

#import "WiiRemote.h"


@implementation WiiRemote

- (id) init{
	
	accX = 0x10;
	accY = 0x10;
	accZ = 0x10;
	buttonData = 0;
	leftPoint = -1;

	
	inquiry = [IOBluetoothDeviceInquiry inquiryWithDelegate: self];
	[inquiry setDelegate:self];
	

	_delegate = nil;
	wiiDevice = nil;
	
	ichan = nil;
	cchan = nil;
	
	isIRSensorEnabled = NO;
	isMotionSensorEnabled = NO;
	isVibrationEnabled = NO;
	
	
	IOReturn ret = [self inquiry];
	if (ret == kIOReturnSuccess){
		[inquiry retain];
	}
	
	return self;
}

- (void)dealloc{
	[self close];
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

- (BOOL)connect{
	
	isConnecting = YES;
	
	int trycount = 0;
	
	if (wiiDevice == nil){
		return NO;
	}
	
	while ([wiiDevice isConnected] && [wiiDevice closeConnection] != kIOReturnSuccess){
		
		if (trycount == 10){
			NSLog(@"could not close existing conection...");
			return NO;
		}
		trycount++;
	}
	
	trycount = 0;
	while ([wiiDevice openConnection] != kIOReturnSuccess){
		if (trycount == 10){
			NSLog(@"could not open the connection...");
			return NO;
		}
		trycount++;
	}
	
	//[wiiDevice registerForDisconnectNotification:self selector:@selector(disconnected:fromDevice:)];
	
	
	trycount = 0;
	while ([wiiDevice performSDPQuery:nil] != kIOReturnSuccess){
		if (trycount == 10){
			NSLog(@"could not perform SDP Query...");
			return NO;
		}
		trycount++;
	}
	
	trycount = 0;
	while ([wiiDevice openL2CAPChannelSync:&cchan withPSM:17 delegate:self] != kIOReturnSuccess){
		if (trycount == 10){
			NSLog(@"could not open L2CAP channel cchan");
			cchan = nil;
			[wiiDevice closeConnection];
			return NO;			
		}
		trycount++;
	}	
	
	trycount = 0;
	while ([wiiDevice openL2CAPChannelSync:&ichan withPSM:19 delegate:self] != kIOReturnSuccess){	// this "19" is magic number ;-)
		if (trycount == 10){
			NSLog(@"could not open L2CAP channel ichan");
			ichan = nil;
			[cchan closeChannel];
			[wiiDevice closeConnection];
			
			return NO;			
		}
		trycount++;
	}
	
	//sensor enable...
	[self setMotionSensorEnabled:NO];
	[self setIRSensorEnabled:NO];
	//stop force feedback
	[self setForceFeedbackEnabled:NO];
	//turn LEDs off
	[self setLEDEnabled1:NO enabled2:NO enabled3:NO enabled4:NO];
	return YES;
}

- (void)disconnected: (IOBluetoothUserNotification*)note fromDevice: (IOBluetoothDevice*)device {
	NSLog(@"disconnected.");
	[wiiDevice release];
	wiiDevice = nil;
	
	[_delegate wiiRemoteDisconnected];
	
}

- (BOOL)sendCommand:(const unsigned char*)data length:(size_t)length{
	
	
	unsigned char buf[40];
	memset(buf,0,40);
	buf[0] = 0x52;
	memcpy(buf+1, data, length);
	if (buf[1] == 0x16) length=23;
	else				length++;
	
	int i = 0;
	
	for (i = 0; i < 10; i++){
		if ([cchan writeSync:buf length:length] == kIOReturnSuccess)
			break;
	}
	
	if (i == 10)
		return NO;
	
	return YES;
}

- (BOOL)setMotionSensorEnabled:(BOOL)enabled{
	BOOL success = false;
	
	if (isIRSensorEnabled)
		success = [self sendCommand:(unsigned char[]){0x12, 0x00, 0x33} length:3];
	else if (enabled)
		success = [self sendCommand:(unsigned char[]){0x12, 0x00, 0x31} length:3];
	else
		success = [self sendCommand:(unsigned char[]){0x12, 0x00, 0x30} length:3];
	
	if (success){
		isMotionSensorEnabled = enabled;
		return YES;
	}
	
	return NO;
}


- (BOOL)setForceFeedbackEnabled:(BOOL)enabled{
	
	unsigned char cmd[] = {0x13, 0x00};
	if (enabled)	cmd[1] |= 0x01;
	if (isIRSensorEnabled)	cmd[1] |= 0x04;
	
	if ([self sendCommand:cmd length:2]){
		isVibrationEnabled = enabled;
		return YES;
	}

	return NO;
}

- (BOOL)setLEDEnabled1:(BOOL)enabled1 enabled2:(BOOL)enabled2 enabled3:(BOOL)enabled3 enabled4:(BOOL)enabled4{
	unsigned char cmd[] = {0x11, 0x00};
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (enabled1)	cmd[1] |= 0x10;
	if (enabled2)	cmd[1] |= 0x20;
	if (enabled3)	cmd[1] |= 0x40;
	if (enabled4)	cmd[1] |= 0x80;
	
	
	return 	[self sendCommand:cmd length:2];
}


//based on Ian's codes. thanks!
- (void)setIRSensorEnabled:(BOOL)enabled{
	
	isIRSensorEnabled = enabled;

	// set register 0x12 (report type)
	[self setMotionSensorEnabled:isMotionSensorEnabled];
	
	// set register 0x13 (ir enable/vibe)
	[self setForceFeedbackEnabled:isVibrationEnabled];
	
	// set register 0x1a (ir enable 2)
	unsigned char cmd[] = {0x1a, 0x00};
	if (enabled)	cmd[1] |= 0x04;
	[self sendCommand:cmd length:2];
	
	if(enabled){
		// based on marcan's method, found on wiili wiki:
		// tweaked to include some aspects of cliff's setup procedure in the hopes
		// of it actually turning on 100% of the time (was seeing 30-40% failure rate before)
		[self writeData:(unsigned char[]){0x01} at:0x04B00030 length:1];
		[self writeData:(unsigned char[]){0x08} at:0x04B00030 length:1];
		[self writeData:(unsigned char[]){0x90} at:0x04B00006 length:1];
		[self writeData:(unsigned char[]){0xC0} at:0x04B00008 length:1];
		[self writeData:(unsigned char[]){0x40} at:0x04B0001A length:1];
		[self writeData:(unsigned char[]){0x33} at:0x04B00033 length:1];
		[self writeData:(unsigned char[]){0x08} at:0x04B00030 length:1];
		
	}else{
		// probably should do some writes to power down the camera, save battery
		// but don't know how yet.

	}
	

}


- (BOOL)writeData:(const unsigned char*)data at:(unsigned long)address length:(size_t)length{
	unsigned char cmd[22];
	int i;
	for(i=0 ; i<length ; i++) cmd[i+6] = data[i];
	for(;i<16 ; i++) cmd[i+6]= 0;
	cmd[0] = 0x16;
	cmd[1] = (address>>24)&0xFF;
	cmd[2] = (address>>16)&0xFF;
	cmd[3] = (address>> 8)&0xFF;
	cmd[4] = (address>> 0)&0xFF;
	cmd[5] = length;
	data = cmd;
	
	return [self sendCommand:cmd length:22];
}

- (IOReturn)inquiry{
	 return [inquiry start];
}

- (void)close{
	IOReturn ret;
	int trycount = 0;
	
	if (cchan){
		do{
			ret = [cchan closeChannel];
			trycount++;
		}while(ret != kIOReturnSuccess && trycount < 10);
	}

	
	trycount = 0;
	
	if (ichan){
		do{
			ret = [ichan closeChannel];
			trycount++;
		}while(ret != kIOReturnSuccess && trycount < 10);
	}

	
	trycount = 0;
	
	if (wiiDevice && [wiiDevice isConnected]){
		do{
			ret = [wiiDevice closeConnection];
			trycount++;
		}while(ret != kIOReturnSuccess && trycount < 10 && [wiiDevice isConnected]);
		[wiiDevice release];
		wiiDevice = nil;
	}
}


// thanks to Ian!
-(void)l2capChannelData:(IOBluetoothL2CAPChannel*)l2capChannel data:(void *)dataPointer length:(size_t)dataLength{
	
	unsigned char* dp = (unsigned char*)dataPointer;
	
	/*	printf ("wiidata%3d:", dataLength);
	int i;
	for(i=0 ; i<dataLength ; i++) {
		printf(" %02X", dp[i]);
	}
	printf("\n");*/
	
	if ((dp[1]&0xF0) == 0x30) {
		buttonData = ((short)dp[2] << 8) + dp[3];
		
		if (dp[1] & 0x01) {
			accX = dp[4];
			accY = dp[5];
			accZ = dp[6];
			
			lowZ = lowZ*.9 + accZ*.1;
			lowX = lowX*.9 + accX*.1;
			
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
		}
		
		if (dp[1] & 0x02) {
			int i;
			for(i=0 ; i<4 ; i++) {
				irData[i].x = dp[7+3*i];
				irData[i].y = dp[8+3*i];
				irData[i].s = dp[9+3*i];
				irData[i].x += (irData[i].s & 0x30)<<4;
				irData[i].y += (irData[i].s & 0xC0)<<2;
				irData[i].s &= 0x0F;
			} 
		}
	}
	
	float ox, oy;
	
	if (irData[0].s < 0x0F && irData[1].s < 0x0F) {
		int l = leftPoint, r;
		if (leftPoint == -1) {
			//	printf("Tracking.\n");
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
	
	[_delegate dataChanged:buttonData accX:accX accY:accY accZ:accZ mouseX:ox mouseY:oy];
	//[_delegate dataChanged:buttonData accX:irData[0].x/4 accY:irData[0].y/3 accZ:irData[0].s*16];
}

/////// IOBluetoothDeviceInquiry delegates //////

- (void) deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry*)sender	device:(IOBluetoothDevice*)device{
	
	if ([[device getName] isEqualToString:@"Nintendo RVL-CNT-01"]){
		[inquiry stop];
	}
}

- (void)deviceInquiryDeviceNameUpdated:(IOBluetoothDeviceInquiry*)sender device:(IOBluetoothDevice*)device devicesRemaining:(int)devicesRemaining{
	
	if ([[device getName] isEqualToString:@"Nintendo RVL-CNT-01"]){
		[inquiry stop];
	}
}

- (void)deviceInquiryComplete:(IOBluetoothDeviceInquiry*)sender	error:(IOReturn)error aborted:(BOOL)aborted{
	
	unsigned int i;
	for (i = 0; i < [[inquiry foundDevices] count]; i++){
		if ([[[[inquiry foundDevices] objectAtIndex:i] getName] isEqualToString:@"Nintendo RVL-CNT-01"]){
			wiiDevice = [[inquiry foundDevices] objectAtIndex:i];
			[_delegate wiiRemoteInquiryCompleted:YES];
			return;
		}
	}
	[_delegate wiiRemoteInquiryCompleted:NO];
}

@end
