/* AppController */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QuartzComposer/QCView.h>
#import <WiiRemote/WiiRemote.h>
#import <WiiRemote/WiiRemoteDiscovery.h>
#import "GraphView.h"
#import "PreferenceWindow.h"
#import "WidgetsEnableTransformer.h"
#import "WidgetsEnableTransformer2.h"

#import "KeyConfiguration_AppDelegate.h"

#import "iGetKeys.h"

@class PreferenceWindow;

@interface AppController : NSObject
{
	IBOutlet KeyConfiguration_AppDelegate* appDelegate;
	IBOutlet NSArrayController* mappingController;
	NSArray* modes;
	NSArray* configSortDescriptors;
	
    IBOutlet NSDrawer *drawer;
    IBOutlet GraphView *graphView;
	IBOutlet GraphView *graphView2;
    IBOutlet NSTextView *textView;
	IBOutlet NSButton* led1;
	IBOutlet NSButton* led2;
	IBOutlet NSButton* led3;
	IBOutlet NSButton* led4;
	IBOutlet NSWindow* mainWindow;
	IBOutlet PreferenceWindow* preferenceWindow;
	IBOutlet NSWindow* enterNameWindow;
	IBOutlet NSWindow* irWindow;
	
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
	IBOutlet NSPopUpButton* mouseMode;
	
	IBOutlet NSView* batteryLevelView;
	IBOutlet NSLevelIndicator* batteryLevel;
	
	IBOutlet QCView* wiimoteQCView;
	IBOutlet QCView* joystickQCView;
	IBOutlet QCView* irQCView;

	IBOutlet NSTextField* newNameField;
	
	IBOutlet NSTextField* WiimoteX;
	IBOutlet NSTextField* WiimoteY;
	IBOutlet NSTextField* WiimoteZ;
	
	IBOutlet NSTextField* NunchukX;
	IBOutlet NSTextField* NunchukY;
	IBOutlet NSTextField* NunchukZ;
	
	IBOutlet NSTextField* joystickX;
	IBOutlet NSTextField* joystickY;
	
	IBOutlet NSTextField* irPoint1X;
	IBOutlet NSTextField* irPoint1Y;
	IBOutlet NSTextField* irPoint1Size;

	IBOutlet NSTextField* irPoint2X;
	IBOutlet NSTextField* irPoint2Y;
	IBOutlet NSTextField* irPoint2Size;

	IBOutlet NSTextField* irPoint3X;
	IBOutlet NSTextField* irPoint3Y;
	IBOutlet NSTextField* irPoint3Size;

	IBOutlet NSTextField* irPoint4X;
	IBOutlet NSTextField* irPoint4Y;
	IBOutlet NSTextField* irPoint4Size;
	
	WiiRemoteDiscovery *discovery;
	WiiRemote* wii;
	CGPoint point;
	//BOOL isPressedBButton, isPressedAButton, isPressedHomeButton, isPressedUpButton, isPressedDownButton, isPressedLeftButton, isPressedRightButton, isPressedOneButton, isPressedTwoButton, isPressedPlusButton, isPressedMinusButton;
	
	BOOL isLeftButtonDown, isRightButtonDown;
	
	int mouseEventMode;
	int x1, x2, x3, y1, y2, y3, z1, z2, z3;
	int x0, y0, z0;
	unsigned char tmpAccX, tmpAccY, tmpAccZ;
	
	WiiJoyStickCalibData nunchukJsCalib;
	WiiAccCalibData wiiAccCalib, nunchukAccCalib;
	
	Ascii2KeyCodeTable table;

}


- (IBAction)doCalibration:(id)sender;
- (IBAction)setForceFeedbackEnabled:(id)sender;
- (IBAction)setIRSensorEnabled:(id)sender;
- (IBAction)setLEDEnabled:(id)sender;
- (IBAction)setMotionSensorsEnabled:(id)sender;
- (IBAction)setMouseModeEnabled:(id)sender;
- (IBAction)doCalibration:(id)sender;
- (IBAction)openKeyConfiguration:(id)sender;
- (IBAction)addConfiguration:(id)sender;
- (IBAction)deleteConfiguration:(id)sender;
- (void)sendKeyboardEvent:(CGKeyCode)keyCode keyDown:(BOOL)keyDown;
- (IBAction)enterSaveName:(id)sender;
- (IBAction)cancelEnterSaveName:(id)sender;

- (IBAction)showHideIRWindow:(id)sender;

- (void) sendModifierKeys:(id)map isPressed:(BOOL)isPressed;
@end
