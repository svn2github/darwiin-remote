#import "WiiRemoteController.h"


static NSMutableDictionary *openWindows = nil;

@implementation WiiRemoteController

+ (WiiRemoteController*)createForWiiRemote:(WiiRemote*) wii {
	
	if (nil == openWindows)
		openWindows = [[NSMutableDictionary alloc] init];
	
	WiiRemoteController *out = [openWindows objectForKey:[wii getAddress]];
	
	if (nil != out) {
		[out setWii:wii];
		return out;
	} else {
		out = [[WiiRemoteController alloc] initWithWindowNibName:@"WiiWindow"]; 
		[openWindows setObject:out forKey:[wii getAddress]];
		[out setWii:wii];
		[out showWindow:self];
	}
	
	return out;
}

- (WiiRemoteController*)init {
	[super init];
	wii = nil;
	return self;
}

- (IBAction)showWindow:(id)sender {
	//NSWindow *win = [self window];
	[[self window] setBackgroundColor: [NSColor colorWithDeviceWhite:.93 alpha:1]];
	[[self window] setDelegate:self];
	[[self window] setContentSize:[[self window] minSize]];
	[detailView setHidden:YES];
	[self markView:viewMenuNone];
	
	
	[self loadSettings];
	
	[nameLabel setStringValue:[wii getAddress]];
		
	[super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification {
	[openWindows removeObjectForKey:[wii getAddress]];
	[wii disconnect];
	[self saveSettings];
	[self release];
	wii = nil;
}

- (void)setWii:(WiiRemote *)inWii {
	if ([wii isEqual:inWii]) return;
	if (nil != wii) {
		[wii disconnect];
	}
	wii = inWii;
	[wii setDelegate:self];
	[wii startConnection];
}

- (void) wiiRemoteConnected:(WiiRemote*)w {
	
	[self setLED:self];
	
	[w setAccelerometerEnabled:YES];
}

- (void) wiiRemoteError:(WiiRemote*)wiimote withDescription:(NSString *)error withCode:(int)code {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:@"Wii Remote Communications Error"];
	[alert setInformativeText:[NSString stringWithFormat:@"%@\n\nError Code: 0x%08X", error, code]];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self
		didEndSelector:@selector(disconnectAlertDone:returnCode:contextInfo:) contextInfo:nil];
}

- (void)disconnectAlertDone:(NSAlert *)alert returnCode:(int)returnCode
    contextInfo:(void *)contextInfo {
	[wii disconnect];
	[[self window] close];
}

- (void) wiiRemoteDisconnected:(WiiRemote*)wiimote {
	[[self window] close];
}

- (void) wiiRemoteUpdate:(WiiRemote*)wiimote withChanges:(unsigned int) mask {
	if (mask & kWiiRemoteHaveButtons) {
		[buttonA setEnabled:!(wiimote->buttons & kWiiRemoteButtonA)];
		[buttonB setEnabled:!(wiimote->buttons & kWiiRemoteButtonB)];
		[button1 setEnabled:!(wiimote->buttons & kWiiRemoteButton1)];
		[button2 setEnabled:!(wiimote->buttons & kWiiRemoteButton2)];
		[buttonLeft setEnabled:!(wiimote->buttons & kWiiRemoteButtonLeft)];
		[buttonRight setEnabled:!(wiimote->buttons & kWiiRemoteButtonRight)];
		[buttonUp setEnabled:!(wiimote->buttons & kWiiRemoteButtonUp)];
		[buttonDown setEnabled:!(wiimote->buttons & kWiiRemoteButtonDown)];
		[buttonMinus setEnabled:!(wiimote->buttons & kWiiRemoteButtonMinus)];
		[buttonPlus setEnabled:!(wiimote->buttons & kWiiRemoteButtonPlus)];
		[buttonHome setEnabled:!(wiimote->buttons & kWiiRemoteButtonHome)];
	}
}

- (void)markView:(NSMenuItem*) item {
	[viewMenuNone setState:NSOffState];
	[viewMenuSettings setState:NSOffState];
	[viewMenuXLR setState:NSOffState];
	[viewMenuIR setState:NSOffState];
	[viewMenuRaw setState:NSOffState];
	[item setState:NSOnState];
}

- (IBAction)changeView:(id)sender
{
}

- (IBAction)setButtonAction:(id)sender
{
	[keyBindHeader setStringValue:[NSString stringWithFormat:@"Binding For %@", [sender title]]];
	[NSApp beginSheet: keyBindSheet
            modalForWindow: [self window]
            modalDelegate: self
            didEndSelector: @selector(keyBindDone:returnCode:contextInfo:)
            contextInfo: nil];
}

- (IBAction)keyBindChangeAction:(id)sender {
	NSMenuItem *item = sender;
	
	[keyBindOptions selectTabViewItemAtIndex:[item tag]];
}

- (IBAction)keyBindDismiss:(id)sender {
	[NSApp endSheet: keyBindSheet];
}

- (void)keyBindDone:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
}

- (IBAction)setLED:(id)sender
{
	[wii setLEDs: ([led1 state]?kWiiRemoteLED1:0)|
	              ([led2 state]?kWiiRemoteLED2:0)|
				  ([led3 state]?kWiiRemoteLED3:0)|
				  ([led4 state]?kWiiRemoteLED4:0)];
}

- (void)saveSettings {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	
	[dict setObject:[NSNumber numberWithInt: [led1 state]] forKey:@"led1"];
	[dict setObject:[NSNumber numberWithInt: [led2 state]] forKey:@"led2"];
	[dict setObject:[NSNumber numberWithInt: [led3 state]] forKey:@"led3"];
	[dict setObject:[NSNumber numberWithInt: [led4 state]] forKey:@"led4"];
	
	[[NSUserDefaults standardUserDefaults] setObject: dict forKey:[wii getAddress]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadSettings {
	NSDictionary *dict = (NSDictionary*)[[NSUserDefaults standardUserDefaults] objectForKey:[wii getAddress]];
	
	[[self window]setFrameAutosaveName: [wii getAddress]];
	
	if (nil == dict) {
		// set up defaults
		[led1 setState:NSOnState];
		[led2 setState:NSOffState];
		[led3 setState:NSOffState];
		[led4 setState:NSOffState];
	} else {		
		[led1 setState:[[dict objectForKey:@"led1"] intValue]];
		[led2 setState:[[dict objectForKey:@"led2"] intValue]];
		[led3 setState:[[dict objectForKey:@"led3"] intValue]];
		[led4 setState:[[dict objectForKey:@"led4"] intValue]];
	}
}

@end
