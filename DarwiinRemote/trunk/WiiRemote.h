//
//  WiiRemote.h
//  WiiRemote
//
//  Created by KIMURA Hiroaki on 06/12/04.
//  Copyright 2006 Distributed and Ubiquitous Computing Lab.. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothL2CAPChannel.h>

#import <IOBluetooth/objc/IOBluetoothDeviceInquiry.h> 



@interface WiiRemote : NSObject {
	
	IOBluetoothDeviceInquiry* inquiry;
	IOBluetoothDevice* wiiDevice;
	IOBluetoothL2CAPChannel *ichan;
	IOBluetoothL2CAPChannel *cchan;
	
	id _delegate;
	
	
	unsigned char accX;
	unsigned char accY;
	unsigned char accZ;
	unsigned short buttonData;

}

- (void)setDelegate:(id)delegate;
- (BOOL)available;
- (BOOL)connect;
- (void)close;
- (void)setForceFeedbackEnabled:(BOOL)enabled;
- (void)setMotionSensorEnabled:(BOOL)enabled;
- (void)setLEDEnabled1:(BOOL)enabled1 enabled2:(BOOL)enabled2 enabled3:(BOOL)enabled3 enabled4:(BOOL)enabled4;
- (IOReturn)inquiry;

enum {
	kWiiRemoteTwoButton		= 0x0001,
	kWiiRemoteOneButton		= 0x0002,
	kWiiRemoteBButton		= 0x0004,
	kWiiRemoteAButton		= 0x0008,
	kWiiRemoteMinusButton	= 0x0010,
	kWiiRemoteHomeButton	= 0x0080,
	kWiiRemoteLeftButton	= 0x0100,
	kWiiRemoteRightButton	= 0x0200,
	kWiiRemoteDownButton	= 0x0400,
	kWiiRemoteUpButton		= 0x0800,
	kWiiRemotePlusButton	= 0x1000,
} WiiButtonType;


@end


@interface NSObject( WiiRemoteDelegate )

- (void) wiiRemoteInquiryComplete:(BOOL)isFound;
- (void) dataChanged:(unsigned short)buttonData accX:(unsigned char)accX accY:(unsigned char)accY accZ:(unsigned char)accZ;

@end