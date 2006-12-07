//
//  WiiRemote.m
//  WiiRemote
//
//  Created by KIMURA Hiroaki on 06/12/04.
//  Copyright 2006 Distributed and Ubiquitous Computing Lab.. All rights reserved.
//

#import "WiiRemote.h"


@implementation WiiRemote

- (id) init{
	
	accX = 0x10;
	accY = 0x10;
	accZ = 0x10;
	buttonData = 0;
	
	
	inquiry = [IOBluetoothDeviceInquiry inquiryWithDelegate: self];
	[inquiry setDelegate:self];
	
	IOReturn ret = [self inquiry];
	if (ret == kIOReturnSuccess){
		[inquiry retain];
	}
	_delegate = nil;
	wiiDevice = nil;
	
	ichan = nil;
	cchan = nil;
	
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
	
	if (wiiDevice == nil){
		return NO;
	}
	
	if ([wiiDevice isConnected] && [wiiDevice closeConnection] != kIOReturnSuccess ){
		NSLog(@"could not close existing conection...");
		return NO;
	}
	
	if ([wiiDevice openConnection] != kIOReturnSuccess){
		NSLog(@"could not open the connection...");
		return NO;
	}
	
	
	if ([wiiDevice performSDPQuery:nil] != kIOReturnSuccess){
		NSLog(@"could not perform SDP Query...");
		return NO;
	}
	
	if ([wiiDevice openL2CAPChannelSync:&cchan withPSM:17 delegate:self] != kIOReturnSuccess){
		NSLog(@"could not open L2CAP channel cchan");
		cchan = nil;
		[wiiDevice closeConnection];
		return NO;
	}	
	
	if ([wiiDevice openL2CAPChannelSync:&ichan withPSM:19 delegate:self] != kIOReturnSuccess){
		NSLog(@"could not open L2CAP channel ichan");
		ichan = nil;
		[cchan closeChannel];
		[wiiDevice closeConnection];

		return NO;
	}
	
	//sensor enable...
	[self setMotionSensorEnabled:YES];
	
	//stop force feedback
	[self setForceFeedbackEnabled:NO];

	
	//turn LEDs off
	[self setLEDEnabled1:NO enabled2:NO enabled3:NO enabled4:NO];

	return YES;
}

- (void)setMotionSensorEnabled:(BOOL)enabled{
	if (enabled){
		unsigned char buf[] = {0x52, 0x12, 0x00, 0x31};
		int count = 0;
		IOReturn ret;
		while ([cchan writeSync:buf length:4] != kIOReturnSuccess){
			
			if (count == 10)
				return NO;
			
			ret = [cchan writeSync:buf length:4];
			count++;
		} 
	}else{
		unsigned char buf[] = {0x52, 0x12, 0x00, 0x30};
		int count = 0;
		IOReturn ret;
		while ([cchan writeSync:buf length:4] != kIOReturnSuccess){
			
			if (count == 10)
				return NO;
			
			ret = [cchan writeSync:buf length:4];
			count++;
		} 
	}
}


- (void)setForceFeedbackEnabled:(BOOL)enabled{
	if(enabled){
		unsigned char buf2[] = {0x52, 0x13, 0x01};
		[cchan writeSync:buf2 length:3];
	}else{
		unsigned char buf2[] = {0x52, 0x13, 0x00};
		[cchan writeSync:buf2 length:3];
	}
}

- (void)setLEDEnabled1:(BOOL)enabled1 enabled2:(BOOL)enabled2 enabled3:(BOOL)enabled3 enabled4:(BOOL)enabled4{
	unsigned char data = 0;
	if (enabled4)
		data += 8;
	if (enabled3)
		data += 4;
	if (enabled2)
		data += 2;
	if (enabled1)
		data += 1;
		
	data = (data << 4);
	unsigned char buf2[] = {0x52, 0x11, data};
	[cchan writeSync:buf2 length:3];

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

-(void)l2capChannelData:(IOBluetoothL2CAPChannel*)l2capChannel data:(void *)dataPointer length:(size_t)dataLength{
	unsigned char* dp = (unsigned char*)dataPointer;

	if (dataLength >= 4){
		if (dp[1] >= 0x30){
			buttonData = ((short)dp[2] << 8) + dp[3];
			//buttonData = CFSwapInt16LittleToHost(buttonData);
		}
	}
	
	if (dataLength >= 7){
		if (dp[1] == 0x31 || dp[1] == 0x33 || dp[1] == 0x35 || dp[1] == 0x37 || dp[1] == 0x3e || dp[1] == 0x3f){
			accX = dp[4];
			accY = dp[5];
			accZ = dp[6];
		} 
	}

	[_delegate dataChanged:buttonData accX:accX accY:accY accZ:accZ];
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
			[_delegate wiiRemoteInquiryComplete:YES];
			return;
		}
	}
	[_delegate wiiRemoteInquiryComplete:NO];
}

@end
