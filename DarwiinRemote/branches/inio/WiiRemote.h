//
//  WiiRemote.h
//  DarwiinRemote
//
//  Created by KIMURA Hiroaki on 06/12/04.
//  Copyright 2006 KIMURA Hiroaki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothL2CAPChannel.h>


typedef struct {
	BOOL set;
	int x, y, s;
} WiiRemoteIRData;

typedef struct {
	float x, y;
} WiiFloatVector2;

typedef struct {
	float x, y, z;
} WiiFloatVector3;

typedef UInt16 WiiButtonData;
enum {
	kWiiRemoteButtonTwo		= 0x0001,
	kWiiRemoteButtonOne		= 0x0002,
	kWiiRemoteButtonB		= 0x0004,
	kWiiRemoteButtonA		= 0x0008,
	kWiiRemoteButtonMinus	= 0x0010,
	kWiiRemoteButtonHome	= 0x0080,
	kWiiRemoteButtonLeft	= 0x0100,
	kWiiRemoteButtonRight	= 0x0200,
	kWiiRemoteButtonDown	= 0x0400,
	kWiiRemoteButtonUp		= 0x0800,
	kWiiRemoteButtonPlus	= 0x1000,
	
	kWiiRemoteLED1          = 0x01;
	kWiiRemoteLED2          = 0x02;
	kWiiRemoteLED3          = 0x04;
	kWiiRemoteLED4          = 0x08;
	
	kWiiRemoteIRModeSimple   = 1;
	kWiiRemoteIRModeExtended = 2;
	
	kWiiRemoteHaveButtons      = 0x01;
	kWiiRemoteHaveAcelleration = 0x02;
	kWiiRemoteHaveIRSimple     = 0x04;
	kWiiRemoteHaveIRComplex    = 0x08;
	kWiiRemoteHaveExtension    = 0x01;
	
	// for future use
	kWiiExtensionNone       = 0x00,
	kWiiExtensionNunchaku   = 0x00,
	kWiiExtensionClassic    = 0x00,
	kWiiExtensionZapper     = 0x00,
	
	kWiiNunchakuButtonC     = 0x00,
	kWiiNunchakuButtonZ     = 0x00,
	
	kWiiClassicButtonA      = 0x0000,
	kWiiClassicButtonB      = 0x0000,
	kWiiClassicButtonX      = 0x0000,
	kWiiClassicButtonY      = 0x0000,
	kWiiClassicButtonZL     = 0x0000,
	kWiiClassicButtonZR     = 0x0000,
	kWiiClassicButtonLeft   = 0x0000,
	kWiiClassicButtonRight  = 0x0000,
	kWiiClassicButtonUp     = 0x0000,
	kWiiClassicButtonDown   = 0x0000,
	kWiiClassicButtonPlus   = 0x0000,
	kWiiClassicButtonMinus  = 0x0000,
	kWiiClassicButtonHome   = 0x0000,
};


@interface WiiRemote : NSObject {
	
	private IOBluetoothDevice* wiiDevice;
	private IOBluetoothL2CAPChannel *ichan;
	private IOBluetoothL2CAPChannel *cchan;
	private IOBluetoothUserNotification *disconnectNotification;
	private NSString *address;
	private NSTimer forceFeedbackDisableTimer;
	
	private id _delegate;
	private id _rawDelegate;

	private BOOL isMotionSensorEnabled, isVibrationEnabled;
	private int irSensorMode; //  0 = off, 1 = simple,  2 = extended?
	
	WiiRemoteButtonData    buttons; // bitwise or of kWiiRemoteButton codes above
	WiiRemoteFloatVector3  acelleration; // measured in m/s^2.  +x right, +y backwards, +z up
	WiiRemoteIRData        irPoints[4];
	int                    extension;
	
	// for future use
	union {
		struct {
			WiiButtonData     buttons; // bitwise or of kWiiNunchakuButton codes above
			WiiFloatVector3   acelleration; // measured in m/s^2.  mapping unknown
			WiiFloatVector2   stick; // typical range for each axis is -1 .. 1.  ?? on diagonals
		} nunchaku;
		struct {
			WiiButtonData     buttons; // bitwise or of kWiiClassicButton codes above
			WiiFloatVector2   leftStick, rightStick; // typical range for each axis is -1 .. 1.  ?? on diagonals
			float             l, r; // typical range is 0..??, then pops to ?? or more
		} classic;
		struct {
			WiiButtonData     buttons; // bitwise or of kWiiZapperButton codes above
			WiiFloatVector2   stick; // typical range for each axis is -1 .. 1.  ?? on diagonals
		} zapper;
	} extension;
			
			
}

- (IOReturn)connectTo:(IOBluetoothDevice*)device;

- (BOOL)available;
- (IOReturn)close;
- (NSString*)getAddress; // unique identifier for each wiimote made

// High-level interfaces
- (void)setDelegate:(id)delegate;
- (IOReturn)setIRSensor:(BOOL)enabled withMode:(int)mode
- (IOReturn)setIRSensitivity:(float)sensitivity;
// sensitivity currently unimplemented.  0 = least sensitive, 1 = most sensitive.
- (IOReturn)setForceFeedback:(BOOL)enabled forInterval:(NSTimeInterval)interval;
- (IOReturn)setMotionSensor:(BOOL)enabled;
- (IOReturn)setLEDs:(unsigned int)leds; // bitwise or of kWiiRemoteLED codes above

// low-level interfaces
- (void)setRawDelegate:(id)delegate;
- (IOReturn)writeData:(const unsigned char*)data at:(unsigned long)address length:(size_t)length;
- (IOReturn)sendCommand:(const unsigned char*)data length:(size_t)length;


@end


@interface NSObject( WiiRemoteDelegate )

- (void) wiiRemoteUpdate:(WiiRemote*)wiimote withChanges:(unsigned int) mask;
    // changes encoded per kWiiRemoteHave codes above
- (void) wiiRemoteExtensionChanged:(WiiRemote*)
- (void) wiiRemoteDisconnected:(IOReturn)errorCode;

@end

@interface NSObject( WiiRemoteRawDelegate )

- (void) receivedPacket:(unsigned char *)data withLength:(unsigned int)len;

@end