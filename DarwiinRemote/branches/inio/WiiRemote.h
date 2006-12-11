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
#import <Foundation/NSTimer.h>

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
	
	kWiiRemoteLED1          = 0x01,
	kWiiRemoteLED2          = 0x02,
	kWiiRemoteLED3          = 0x04,
	kWiiRemoteLED4          = 0x08,
	
	kWiiRemoteIRModeOff      = 0,
	kWiiRemoteIRModeSimple   = 1,
	kWiiRemoteIRModeExtended = 2,
	
	kWiiRemoteHaveButtons      = 0x01,
	kWiiRemoteHaveAcceleration = 0x02,
	kWiiRemoteHaveIRSimple     = 0x04,
	kWiiRemoteHaveIRComplex    = 0x08,
	kWiiRemoteHaveExtension    = 0x10,
	
	// for future use
	kWiiExtensionNone       = 0x00,
	kWiiExtensionNunchaku   = 0x01,
	kWiiExtensionClassic    = 0x02,
	kWiiExtensionZapper     = 0x03,
	
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
	IOBluetoothDevice* wiiDevice;
	IOBluetoothL2CAPChannel *ichan;
	IOBluetoothL2CAPChannel *cchan;
	IOBluetoothUserNotification *disconnectNotification;
	
	NSString *btaddress;
	NSTimer *forceFeedbackDisableTimer;
	struct MemoryReadCallback *readList;
	
	id delegate;
	id rawDelegate;

	BOOL isAccelerometerEnabled, isVibrationEnabled;
	int irSensorMode; //  0 = off, 1 = simple,  2 = extended?
	
	unsigned char xlrZero[3];

@public
	WiiButtonData       buttons; // bitwise or of kWiiRemoteButton codes above
	WiiFloatVector3     acceleration; // measured in m/s^2.  +x right, +y backwards, +z up
	WiiRemoteIRData     irPoints[4];
	unsigned char       accelerationRaw[3]; // raw data
	
	int                 extensionType;
	
	// for future use
	union {
		struct {
			WiiButtonData     buttons; // bitwise or of kWiiNunchakuButton codes above
			WiiFloatVector3   acceleration; // measured in m/s^2.  mapping unknown
			WiiFloatVector2   stick; // typical range for each axis is -1 .. 1.  ?? on diagonals
			unsigned char     accelerationRaw[3], stickRaw[2];
		} nunchaku;
		struct {
			WiiButtonData     buttons; // bitwise or of kWiiClassicButton codes above
			WiiFloatVector2   leftStick, rightStick; // typical range for each axis is -1 .. 1.  ?? on diagonals
			float             l, r; // typical range is 0..??, then pops to ?? or more
			unsigned char     leftStickRaw[2], rightStickRaw[2], lRaw, rRaw;
		} classic;
		struct {
			WiiButtonData     buttons; // bitwise or of kWiiZapperButton codes above
			WiiFloatVector2   stick; // typical range for each axis is -1 .. 1.  ?? on diagonals
			unsigned char     stickRaw[2];
		} zapper;
	} extension;
			
			
}

- (WiiRemote*)initWith:(IOBluetoothDevice*)device;

- (IOReturn)  startConnection;
- (BOOL)      connected;
- (void)      disconnect;
- (NSString*) getAddress; // unique identifier for each wiimote made

// High-level interfaces
- (void)      setDelegate:(id)inDelegate;
- (IOReturn)  setIRSensorMode:(int)mode;
- (IOReturn)  setIRSensitivity:(float)sensitivity; // currently unimplemented.  0 = least sensitive, 1 = most sensitive.
- (IOReturn)  setForceFeedbackEnabled:(BOOL)active;
- (IOReturn)  pulseForceFeedbackForInterval:(NSTimeInterval)interval;
- (IOReturn)  setAccelerometerEnabled:(BOOL)enabled;
- (void)      setAccelerometerZeroPoint:(unsigned char[3])zero;
- (IOReturn)  setLEDs:(unsigned int)leds; // bitwise or of kWiiRemoteLED codes above

// low-level interfaces
- (void)setRawDelegate:(id)delegate;
- (IOReturn)writeMemory:(const unsigned char*)data at:(unsigned long)address length:(size_t)length;
- (IOReturn)sendCommand:(const unsigned char*)data length:(size_t)length;
- (IOReturn)readMemory:(unsigned long)address withLength:(size_t)length withDelegate:(id)delegate;


@end


@interface NSObject( WiiRemoteDelegate )

- (void) wiiRemoteConnected:(WiiRemote*)wiimote;
- (void) wiiRemoteDisconnected:(WiiRemote*)wiimote withError:(IOReturn)errorCode;
- (void) wiiRemoteUpdate:(WiiRemote*)wiimote withChanges:(unsigned int) mask; // see kWiiRemoteHave<foo>
- (void) wiiRemoteExtensionChanged:(WiiRemote*)wiimote;

- (void) wiiRemoteReadComplete:(unsigned long)address dataReturned:(unsigned char*)data dataLength:(size_t)length;
- (void) wiiRemoteReadError:(unsigned long)address;

- (void) wiiRemoteWroteData:(WiiRemote*)wiimote withData:(unsigned char *)data withLength:(unsigned int)len;
- (void) wiiRemoteReadData:(WiiRemote*)wiimote withData:(unsigned char *)data withLength:(unsigned int)len;

@end