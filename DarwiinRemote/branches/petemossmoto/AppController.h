/* AppController */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <WiiRemote/WiiRemote.h>
#import <WiiRemote/WiiRemoteDiscovery.h>
#import "GraphView.h"
#include "lo.h"

@interface AppController : NSObject
{
    IBOutlet NSDrawer *drawer;
    IBOutlet GraphView *graphView;
    IBOutlet NSTextView *textView;
	IBOutlet NSButton* led1;
	IBOutlet NSButton* led2;
	IBOutlet NSButton* led3;
	IBOutlet NSButton* led4;
	IBOutlet NSWindow* mainWindow;
	
	IBOutlet NSButton* upButton;
	IBOutlet NSButton* downButton;
	IBOutlet NSButton* leftButton;
	IBOutlet NSButton* rightButton;
	IBOutlet NSButton* aButton;
	IBOutlet NSButton* bButton;
	IBOutlet NSButton* minusButton;
	IBOutlet NSButton* plusButton;
	IBOutlet NSButton* homeButton;
	IBOutlet NSButton* oneButton;
	IBOutlet NSButton* twoButton;
	
	IBOutlet NSLevelIndicator* batteryLevel;
	
	WiiRemoteDiscovery *discovery;
	WiiRemote* wii;
	CGPoint point;
	lo_address remoteOSC;
	BOOL sendMouseEvent;
//	BOOL isPressedBButton, isPressedAButton, /*isPressedHomeButton, isPressedUpButton, isPressedDownButton, isPressedLeftButton, isPressedRightButton,*/ isPressedOneButton, isPressedTwoButton;
	unsigned short isPressedBButton, isPressedAButton, isPressedHomeButton, isPressedUpButton, isPressedDownButton, isPressedLeftButton, isPressedRightButton, isPressedPlusButton, isPressedMinusButton,  isPressedOneButton, isPressedTwoButton;
	int mouseEventMode;
	double x1, x2, x3, y1, y2, y3, z1, z2, z3;
	double x0, y0, z0;
	unsigned char tmpAccX, tmpAccY, tmpAccZ;

}
- (IBAction)doCalibration:(id)sender;
- (IBAction)setForceFeedbackEnabled:(id)sender;
- (IBAction)setIRSensorEnabled:(id)sender;
- (IBAction)setLEDEnabled:(id)sender;
- (IBAction)setMotionSensorsEnabled:(id)sender;
- (IBAction)setMouseModeEnabled:(id)sender;
- (IBAction)doCalibration:(id)sender;
//- (void)sendKeyboardEvent:(CGKeyCode)keyCode keyDown:(BOOL)keyDown;
- (void)sendKeyboardEvent:(CGKeyCode)keyCode keyDown:(BOOL)keyDown eventFlags:(CGEventFlags)flags;
- (void)sendKeyboardKey:(UniChar)key keyDown:(BOOL)keyDown eventFlags:(CGEventFlags)flags;
- (CGKeyCode)keyCodeFromKey:(UniChar)key;
-(void)handleButtonEvent:(NSUserDefaults*)defaults action:(BOOL)action tag:(NSString *)tag key:(NSString *)key shift:(NSString *)shift control:(NSString *)control option:(NSString *)option command:(NSString *)command;
-(void)toggleIRMouseMode;
-(void)toggleMotionMouseMode;
@end
