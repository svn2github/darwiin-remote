/* AppController */

#import <Cocoa/Cocoa.h>
#import "WiiRemote.h"
#import "WiiRemoteDiscovery.h"
#import "GraphView.h"

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
	
	WiiRemoteDiscovery *discovery;
	WiiRemote* wii;
	CGPoint point;
	BOOL sendMouseEvent;
	BOOL isPressedBButton, isPressedAButton, isPressedHomeButton, isPressedUpButton, isPressedDownButton, isPressedLeftButton, isPressedRightButton, isPressedOneButton, isPressedTwoButton, isPressedPlusButton, isPressedMinusButton;
	
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
@end
