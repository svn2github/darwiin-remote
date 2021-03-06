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

typedef struct MemoryReadCallback {
	unsigned long address;
	size_t size, received;
	unsigned char *buffer;
	id	delegate;
	struct MemoryReadCallback *next;
} MemoryReadCallback;

@implementation WiiRemote

- (id) init{
	
	// unfortunately this shouldn't be required, but it keeps it from crashing.
	[self retain];
	[self retain];
	
	wiiDevice = nil;
	ichan = nil;
	cchan = nil;
	disconnectNotification = nil;
	
	btaddress = @"";
	forceFeedbackDisableTimer = nil;
	readList = nil;
	
	delegate = nil;
	rawDelegate = nil;
	
	isAccelerometerEnabled = NO;
	isVibrationEnabled = NO;
	irSensorMode = 0;
	
	xlrZero[0] = xlrZero[1] = xlrZero[2] = 128;
	
	buttons = 0;
	acceleration.x = acceleration.y = acceleration.z = 0;
	accelerationRaw[0] = accelerationRaw[1] = accelerationRaw[2] = 128;
	irPoints[0].x = irPoints[1].x = irPoints[2].x = irPoints[3].x = 0;
	irPoints[0].y = irPoints[1].y = irPoints[2].y = irPoints[3].y = 0;
	irPoints[0].s = irPoints[1].s = irPoints[2].s = irPoints[3].s = 0;
	irPoints[0].set = irPoints[1].set = irPoints[2].set = irPoints[3].set = NO;
	
	extensionType = kWiiExtensionNone;
	
	return self;
}

- (void)dealloc{
	[self disconnect];
	[super dealloc];
}

- (void)setDelegate:(id)inDelegate{
	delegate = inDelegate;
}

- (void)setRawDelegate:(id)inRawDelegate{
	rawDelegate = inRawDelegate;
}

#pragma mark -
#pragma mark Connection

- (BOOL)connected{
	return (wiiDevice != nil) && [wiiDevice isConnected];
}

- (WiiRemote*)initWith:(IOBluetoothDevice*)device{
	[self init];
	wiiDevice = device;
	ichan = nil;
	cchan = nil;
	disconnectNotification = nil;
	
	btaddress = [device getAddressString];
	
	return self;
}

- (IOReturn)startConnection {
	IOReturn ret;
	
	if (wiiDevice == nil){
		[delegate wiiRemoteError:self withDescription:@"Attempted to reconnect closed WiiRemote." withCode:kIOReturnNotOpen];
		return kIOReturnNotOpen;
	}
	
	do { //  not a loop, just a simple way of dropping to the bottom
		ret = [wiiDevice openConnection];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:@"Could not open the connection to Wii Remote." withCode:ret];
			break;
		}
		
		disconnectNotification = [wiiDevice registerForDisconnectNotification:self
			selector:@selector(disconnected:fromDevice:)];
		
		ret = [wiiDevice performSDPQuery:self];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:@"Could not perform SDP Query." withCode:ret];
			break;
		}
		
	//	NSLog(@"Waiting for SDP query to complete");
	} while(0);
	
	if (kIOReturnSuccess != ret) {
		[wiiDevice closeConnection];
		wiiDevice = nil;
	}
	
	return ret;
}

- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status {
	IOReturn ret;
	
	do { //  not a loop, just a simple way of dropping to the bottom
		if (kIOReturnSuccess != status) {
			[delegate wiiRemoteError:self withDescription:@"Error while performing SDP Query." withCode:ret];
			break;
		} else {
		//	NSLog(@"SDP Query complete");
		}
		
		ret = [wiiDevice openL2CAPChannelSync:&cchan withPSM:17 delegate:self];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:@"Could not open L2CAP channel 17." withCode:ret];
			break;
		}
		cchanDisconnectNotification = [cchan registerForChannelCloseNotification:self
			selector:@selector(channelClosed:channel:)];
		
		ret = [wiiDevice openL2CAPChannelSync:&ichan withPSM:19 delegate:self];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:@"Could not open L2CAP channel 19." withCode:ret];
			break;
		}
		ichanDisconnectNotification = [cchan registerForChannelCloseNotification:self
			selector:@selector(channelClosed:channel:)];
		
		[self readMemory:0x20 withLength:8 withDelegate:self];
		
		// initialize the Wii Remote
		
		ret = [self setAccelerometerEnabled:NO];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:
				@"An error ocurred while configurating the Wii Remote (Accelerometer)." withCode:ret];
			break;
		}
		
		ret = [self setIRSensorMode:kWiiRemoteIRModeOff];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:
				@"An error ocurred while configurating the Wii Remote (Report Type)." withCode:ret];
			break;
		}
		
		ret = [self setForceFeedbackEnabled:NO];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:
				@"An error ocurred while configurating the Wii Remote (Force Feedback)." withCode:ret];
			break;
		}
		
		ret = [self setLEDs:0];
		if (kIOReturnSuccess != ret) {
			[delegate wiiRemoteError:self withDescription:
				@"An error ocurred while configurating the Wii Remote (LEDs)." withCode:ret];
			break;
		}
		if (nil != delegate)
			[delegate wiiRemoteConnected:self];
	} while (0);
	
	if (kIOReturnSuccess != ret)
		[self disconnect];
}

- (void)channelClosed: (IOBluetoothUserNotification*)note channel: (IOBluetoothL2CAPChannel*)channel {
	if (channel == cchan) {
		[delegate wiiRemoteError:self withDescription:
			@"Wii Remote L2CAP communications channel 17 closed." withCode:0];
	} else if (channel == ichan) {
		[delegate wiiRemoteError:self withDescription:
			@"Wii Remote L2CAP communications channel 19 closed." withCode:0];
	} else {
		[delegate wiiRemoteError:self withDescription:
			@"Unknown Wii Remote L2CAP communications channel closed." withCode:0];
	}
	[self disconnect];
}

- (void)disconnect{
	if (nil != disconnectNotification) {
		[disconnectNotification unregister];
		disconnectNotification = nil;
	}
	if (nil != ichanDisconnectNotification) {
		[ichanDisconnectNotification unregister];
		ichanDisconnectNotification = nil;
	}
	if (nil != cchanDisconnectNotification) {
		[cchanDisconnectNotification unregister];
		cchanDisconnectNotification = nil;
	}
	
	if (nil != wiiDevice) {
		if (nil != cchan) {
			if ([wiiDevice isConnected])
				[cchan closeChannel];
		//	[cchan release];
		}
		
		if (nil != ichan) {
			if ([wiiDevice isConnected])
				[ichan closeChannel];
		//	[ichan release];
		}
		
		[wiiDevice closeConnection];
	//	[wiiDevice release];
	}
	
	ichan = cchan = nil;
	wiiDevice = nil;
}

- (void)disconnected: (IOBluetoothUserNotification*)note fromDevice: (IOBluetoothDevice*)device {
	NSLog(@"disconnected.");
	[self disconnect];
	
	if (nil != delegate)
		[delegate wiiRemoteDisconnected:self];
}

// recieves calibration data:
- (void) wiiRemoteReadComplete:(unsigned long)address dataReturned:(unsigned char*)data dataLength:(size_t)length {
	switch(address) {
		case 0x20: case 0x16:
			if (length != 8) break;
			[self setAccelerometerZeroPoint:data andOneGPoint:data+4];
			return;
		break;
	}
	NSLog(@"Received unexpected memory read data for 0x%08X/0x%X", address, length);
}

#pragma mark -
#pragma mark I/O

- (IOReturn)sendCommand:(const unsigned char*)data length:(size_t)length{
	
	
	unsigned char buf[40];
	memset(buf,0,40);
	buf[0] = 0x52;
	memcpy(buf+1, data, length);
	if (buf[1] == 0x16) length=23;
	else				length++;
	
//	int i;
	
/*	printf ("send%3d:", length);
	for(i=0 ; i<length ; i++) {
		printf(" %02X", buf[i]);
	}
	printf("\n");*/
	
	if (nil != rawDelegate)
		[rawDelegate wiiRemoteWroteData:self withData:buf withLength:length];
	
	IOReturn ret;
	
//	for (i = 0; i < 10; i++){
		ret = [cchan writeSync:buf length:length];
//		if (kIOReturnSuccess == ret)
//			break;
//		usleep(10000);
//	}
	
	
	
	return ret;
}


- (IOReturn)writeMemory:(const unsigned char*)data at:(unsigned long)address length:(size_t)length{
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
	
	// and of course the vibration flag, as usual
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	
	data = cmd;
	
	return [self sendCommand:cmd length:22];
}

- (IOReturn)readMemory:(unsigned long)address withLength:(size_t)length withDelegate:(id)inDelegate {
	MemoryReadCallback *callback = calloc(sizeof(MemoryReadCallback), 1);
	callback->address = address;
	callback->size = length;
	callback->received = 0;
	callback->buffer = calloc(length, 1);
	callback->delegate = inDelegate;
	callback->next = NULL;
	if (NULL == readList) {
		readList = callback;
	} else {
		MemoryReadCallback *after = readList;
		while (NULL != after->next)
			after = after->next;
		after->next = callback;
	}
	
	return [self sendCommand:(darr){0x17,
		(address>>24)&0xFF, (address>>16)&0xFF, (address>>8)&0xFF, address&0xFF,
		(length>>8)&0xFF, length&0xFF} length:7];
}


// thanks to Ian!
-(void)l2capChannelData:(IOBluetoothL2CAPChannel*)l2capChannel data:(void *)dataPointer length:(size_t)length{
	if (!wiiDevice)
		return;
	unsigned char* data = (unsigned char*)dataPointer;
	
	if (nil != rawDelegate)
		[rawDelegate wiiRemoteReadData:self withData:data withLength:length];
	
/*	if ((dp[1]&0xF0) != 0x30) {
		printf ("recv%3d:", dataLength);
		int i;
		for(i=0 ; i<dataLength ; i++) {
			printf(" %02X", dp[i]);
		}
		printf("\n");
	}*/
	
	if (length > 1 && (data[1] == 0x21)) {
		int len = (data[4]>>4)+1;
		int addr = (data[5]<<8) | data[6];
		MemoryReadCallback *seek = readList, *prev = NULL;
		while (NULL != readList) {
			if (((seek->address + seek->received)&0x0000FFFF) == addr) break;
			seek = seek->next;
		}
		if (NULL != seek) {
			if (data[4]&0x0F) {
				// error
				[seek->delegate wiiRemoteReadError:seek->address];
				if (NULL == prev) readList = seek->next;
				else prev->next = seek->next;
				free(seek->buffer);
				free(seek);
			} else {
				// data
				if (seek->size - seek->received < len)
					len = seek->size - seek->received;
				memcpy(seek->buffer + seek->received, data+7, len);
				seek->received += len;
				if (seek->received == seek->size) {
					[seek->delegate wiiRemoteReadComplete:seek->address 
						dataReturned:(unsigned char*)seek->buffer dataLength:seek->size];
					if (NULL == prev) readList = seek->next;
					else prev->next = seek->next;
					free(seek->buffer);
					free(seek);
				}
			}
		} else {
			NSLog(@"Received memory read data for address not in read queue 0x%04X", addr);
		}
	}
	
	unsigned int dataMask = kWiiRemoteHaveButtons;
	
	if (length > 1 && (data[1]&0xF0) == 0x30) {
		buttons = ((short)data[2] << 8) + data[3];
		
#if 0
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
#endif
	}

#if 0
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
#endif
	
	if (nil != delegate)
		[delegate wiiRemoteUpdate:self withChanges:dataMask];
	//[delegate dataChanged:buttonData accX:irData[0].x/4 accY:irData[0].y/3 accZ:irData[0].s*16];

}

#pragma mark -
#pragma mark API

- (NSString*) getAddress {
	return btaddress;
}

- (BOOL)isEqual:(id)cmpObject {
	return [[self getAddress] isEqual:[(WiiRemote*)cmpObject getAddress]];
}

- (IOReturn)setAccelerometerEnabled:(BOOL)enabled{
	// these variables indicate a desire, and should be updated regardless of the sucess of sending the command
	isAccelerometerEnabled = enabled;
	
	unsigned char cmd[] = {0x12, 0x00, 0x30};
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (isAccelerometerEnabled)	cmd[2] |= 0x01;
	if (kWiiRemoteIRModeSimple == irSensorMode) cmd[2] |= 0x02;
	
	return [self sendCommand:cmd length:3];
}

- (void)      setAccelerometerZeroPoint:(unsigned char[3])zero andOneGPoint:(unsigned char[3])oneg {
	xlrZero[0] = zero[0];
	xlrZero[1] = zero[1];
	xlrZero[2] = zero[2];
	xlrOneG[0] = oneg[0];
	xlrOneG[1] = oneg[1];
	xlrOneG[2] = oneg[2];
}


- (IOReturn)setForceFeedbackEnabled:(BOOL)enabled{
	// these variables indicate a desire, and should be updated regardless of the sucess of sending the command
	isVibrationEnabled = enabled;
	
	unsigned char cmd[] = {0x13, 0x00};
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (kWiiRemoteIRModeOff != irSensorMode) cmd[1] |= 0x04;
	
	return [self sendCommand:cmd length:2];
}

- (IOReturn)  pulseForceFeedbackForInterval:(NSTimeInterval)interval {
	return kIOReturnSuccess;
}

- (IOReturn)setLEDs:(unsigned int)leds{
	unsigned char cmd[] = {0x11, 0x00};
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (leds & kWiiRemoteLED1)	cmd[1] |= 0x10;
	if (leds & kWiiRemoteLED2)	cmd[1] |= 0x20;
	if (leds & kWiiRemoteLED3)	cmd[1] |= 0x40;
	if (leds & kWiiRemoteLED4)	cmd[1] |= 0x80;
	
	
	return 	[self sendCommand:cmd length:2];
}


//based on Ian's codes. thanks!
- (IOReturn)setIRSensorMode:(int)mode{
	IOReturn ret;
	
	irSensorMode = mode;

	// set register 0x12 (report type)
	if (ret = [self setAccelerometerEnabled:isAccelerometerEnabled]) return ret;
	
	// set register 0x13 (ir enable/vibe)
	if (ret = [self setForceFeedbackEnabled:isVibrationEnabled]) return ret;
	
	// set register 0x1a (ir enable 2)
	unsigned char cmd[] = {0x1a, 0x00};
	if (kWiiRemoteIRModeOff != irSensorMode)	cmd[1] |= 0x04;
	if (isVibrationEnabled)	cmd[1] |= 0x01;
	if (ret = [self sendCommand:cmd length:2]) return ret;
	
	if(kWiiRemoteIRModeOff != irSensorMode){
		// based on marcan's method, found on wiili wiki:
		// tweaked to include some aspects of cliff's setup procedure in the hopes
		// of it actually turning on 100% of the time (was seeing 30-40% failure rate before)
		// the sleeps help it it seems
		usleep(10000);
		if (ret = [self writeMemory:(darr){0x01} at:0x04B00030 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeMemory:(darr){0x08} at:0x04B00030 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeMemory:(darr){0x90} at:0x04B00006 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeMemory:(darr){0xC0} at:0x04B00008 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeMemory:(darr){0x40} at:0x04B0001A length:1]) return ret;
		usleep(10000);
		if (ret = [self writeMemory:(darr){0x33} at:0x04B00033 length:1]) return ret;
		usleep(10000);
		if (ret = [self writeMemory:(darr){0x08} at:0x04B00030 length:1]) return ret;
		
	}else{
		// probably should do some writes to power down the camera, save battery
		// but don't know how yet.

	}
	
	return kIOReturnSuccess;
}

- (IOReturn)  setIRSensitivity:(float)sensitivity {
	return kIOReturnSuccess;
}




@end
