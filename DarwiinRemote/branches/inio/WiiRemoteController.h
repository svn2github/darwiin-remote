/* WiiRemoteController */

#import <Cocoa/Cocoa.h>
#import "WiiRemote.h"

@interface WiiRemoteController : NSWindowController
{
    IBOutlet NSTextField *nameLabel;
	
	IBOutlet NSButton *button1;
    IBOutlet NSButton *button2;
    IBOutlet NSButton *buttonA;
    IBOutlet NSButton *buttonB;
	
    IBOutlet NSButton *buttonDown;
    IBOutlet NSButton *buttonHome;
    IBOutlet NSButton *buttonLeft;
    IBOutlet NSButton *buttonMinus;
    IBOutlet NSButton *buttonPlus;
    IBOutlet NSButton *buttonRight;
    IBOutlet NSButton *buttonUp;
	
    IBOutlet NSButton *led1;
    IBOutlet NSButton *led2;
    IBOutlet NSButton *led3;
    IBOutlet NSButton *led4;
	
    IBOutlet NSLevelIndicator *batteryStatus;
	
    IBOutlet NSPopUpButton *showMenu;
	
    IBOutlet NSTabView *detailView;
	
	IBOutlet NSMenuItem *viewMenuNone;
	IBOutlet NSMenuItem *viewMenuSettings;
	IBOutlet NSMenuItem *viewMenuXLR;
	IBOutlet NSMenuItem *viewMenuIR;
	IBOutlet NSMenuItem *viewMenuRaw;
	
	WiiRemote *wii;
}
+ (WiiRemoteController*)createForWiiRemote:(WiiRemote*) wii;
- (IBAction)changeView:(id)sender;
- (IBAction)setButtonAction:(id)sender;
- (IBAction)setLED:(id)sender;
- (IBAction)showWindow:(id)sender;
- (void)setWii:(WiiRemote *)wii;

// internal:
- (void)saveSettings;
- (void)loadSettings;
- (void)markView:(NSMenuItem*) item;

@end
