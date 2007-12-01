#import "AppController.h"
#import <sys/time.h>

@implementation AppController

- (IBAction)doDiscovery:(id)sender
{
//	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.5, NO);

	[discovery start];
	[textView setString:@"Please press 1 button and 2 button simultaneously"];
	[discoverySpinner startAnimation:self];
}


- (IBAction)showHideIRWindow:(id)sender
{
	if ([irWindow isVisible]) {
		[sender setTitle:@"Show IR Info"];
		[irWindow orderOut:self];
	} else {
		[sender setTitle:@"Hide IR Info"];
		[irWindow makeKeyAndOrderFront:self];
	}
}

- (IBAction)setForceFeedbackEnabled:(id)sender
{
	[wii setForceFeedbackEnabled:[sender state]];
}

- (IBAction)setIRSensorEnabled:(id)sender
{
	[wii setIRSensorEnabled:[sender state]];
}

- (IBAction)setLEDEnabled:(id)sender
{

	[wii setLEDEnabled1:[led1 state] enabled2:[led2 state] enabled3:[led3 state] enabled4:[led4 state]];

	[wiimoteQCView setValue:[NSNumber numberWithBool:[led1 state] ] forInputKey:[NSString stringWithString:@"LED_1"]];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led2 state] ] forInputKey:[NSString stringWithString:@"LED_2"]];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led3 state] ] forInputKey:[NSString stringWithString:@"LED_3"]];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led4 state] ] forInputKey:[NSString stringWithString:@"LED_4"]];

}

/**
- (IBAction)setMouseModeEnabled:(id)sender{

	
	if ([sender state]){
		sendMouseEvent = YES;
	}else{
		CGPostMouseEvent(point, TRUE, 1, FALSE);
		isPressedAButton = NO;
		sendMouseEvent = NO;
	}
}
**/

- (IBAction)setMotionSensorsEnabled:(id)sender
{
	[wii setMotionSensorEnabled:[sender state]];
}


- (IBAction)doCalibration:(id)sender{
	
	id config = [mappingController selection];
	
	
	if ([sender tag] == 0){
		x1 = tmpAccX;
		y1 = tmpAccY;
		z1 = tmpAccZ;
	}
	
	if ([sender tag] == 1){
		x2 = tmpAccX;
		y2 = tmpAccY;
		z2 = tmpAccZ;
	}
	if ([sender tag] == 2){
		x3 = tmpAccX;
		y3 = tmpAccY;
		z3 = tmpAccZ;
	}
	x0 = (x1 + x2) / 2.0;
	y0 = (y1 + y3) / 2.0;
	z0 = (z2 + z3) / 2.0;
	
	[config setValue:[NSNumber numberWithInt:(int)x0] forKeyPath:@"wiimote.accX_zero"];
	[config setValue:[NSNumber numberWithInt:(int)y0] forKeyPath:@"wiimote.accY_zero"];
	[config setValue:[NSNumber numberWithInt:(int)z0] forKeyPath:@"wiimote.accZ_zero"];

	[config setValue:[NSNumber numberWithInt:(int)x3] forKeyPath:@"wiimote.accX_1g"];
	[config setValue:[NSNumber numberWithInt:(int)y2] forKeyPath:@"wiimote.accY_1g"];
	[config setValue:[NSNumber numberWithInt:(int)z1] forKeyPath:@"wiimote.accZ_1g"];

	
	[textView setString:[NSString stringWithFormat:@"%@\n===== x: %d  y: %d  z: %d =====", [textView string], tmpAccX, tmpAccY, tmpAccZ]];

}

- (IBAction)saveFile:(id)sender
{
	if ([[sender title] isEqualToString:@"Start"]){
		[sender setTitle:@"Stop"];
//		state = YES;
		if ([recordData length] > 0){
			savePanel = [NSSavePanel savePanel];
			[savePanel setDirectory:NSHomeDirectory()];
			int ret = [savePanel runModal];

			NSString * columnHeaders =@"time,AccX,AccY,AccZ\n";
			[recordData insertString:columnHeaders atIndex:0];
				
			if (ret){
				[recordData writeToFile:[savePanel filename] atomically:YES];				
			}
		}
	
		[recordData release];
		recordData = [[NSMutableString string] retain];

	}else{
		[sender setTitle:@"Start"];
//		state = NO;

	}
}



- (id)init{
	
	modes = [[NSArray arrayWithObjects:@"Nothing", @"Key", @"\tReturn", @"\tTab", @"\tEsc", @"\tBackspace", @"\tUp", @"\tDown", @"\tLeft",@"\tRight", @"\tPage Up", @"\tPage Down", @"\tF1", @"\tF2", @"\tF3", @"\tF4", @"\tF5", @"\tF6", @"\tF7", @"\tF8", @"\tF9", @"\tF10", @"\tF11", @"\tF12", @"Left Click", @"Left Click2", @"Right Click", @"Right Click2", @"Toggle Mouse (Motion)", @"Toggle Mouse (IR)",nil] retain];

	
	id transformer = [[[WidgetsEnableTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"WidgetsEnableTransformer"];
	/**
	id transformer2 = [[[KeyCodeTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer2 forName:@"KeyCodeTransformer"];
	**/
	id transformer3 = [[[WidgetsEnableTransformer2 alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer3 forName:@"WidgetsEnableTransformer2"];

	NSSortDescriptor* descriptor = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
	configSortDescriptors = [[NSArray arrayWithObjects:descriptor, nil] retain];
	return self;
}

- (void) dealloc
{
	[wii release];
	[discovery release];
	[configSortDescriptors release];
	[super dealloc];
}

-(void)awakeFromNib{

	[[NSNotificationCenter defaultCenter] addObserver:self
											selector:@selector(expansionPortChanged:)
											name:@"WiiRemoteExpansionPortChangedNotification"
											object:nil];

	InitAscii2KeyCodeTable(&table);
	
	/**	
		Interface Builder doesn't allow vertical level meters.
		So the battery level is put in an NSView and then the view is rotated.
	**/
	[batteryLevelView setFrameRotation: 90.0];

	
	mouseEventMode = 0;
	discovery = [[WiiRemoteDiscovery alloc] init];
	[discovery setDelegate:self];
//	[discovery start];
//	[discoverySpinner startAnimation:self];
	[logDrawer open];
//	[textView setString:@"Please press 1 button and 2 button simultaneously"];
    [textView setString:@"Please press Find Wiimote.  Waiting about 15s on non-Intel systems _may_ prevent having to refind the wiimote"];
	
	state = NO;
	recordData = [[NSMutableString string] retain];
	
	point.x = 0;
	point.y = 0;
	
	
	/**
	{
        NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		NSNumber* num = [[NSNumber alloc] initWithDouble:128.0];
		NSNumber* num2 = [[NSNumber alloc] initWithDouble:154.0];


		[defaultValues setObject:num forKey:@"x1"];
		[defaultValues setObject:num forKey:@"y1"];
		[defaultValues setObject:num2 forKey:@"z1"];

		[defaultValues setObject:num forKey:@"x2"];
		[defaultValues setObject:num2 forKey:@"y2"];
		[defaultValues setObject:num forKey:@"z2"];
		
		[defaultValues setObject:num2 forKey:@"x3"];
		[defaultValues setObject:num forKey:@"y3"];
		[defaultValues setObject:num forKey:@"z3"];
		
		[defaultValues setObject:[NSNumber numberWithInt:0] forKey:@"selection"];

        [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
    }
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	x1 = [[defaults objectForKey:@"x1"] doubleValue];
	y1 = [[defaults objectForKey:@"y1"] doubleValue];
	z1 = [[defaults objectForKey:@"z1"] doubleValue];

	x2 = [[defaults objectForKey:@"x2"] doubleValue];
	y2 = [[defaults objectForKey:@"y2"] doubleValue];
	z2 = [[defaults objectForKey:@"z2"] doubleValue];
	
	x3 = [[defaults objectForKey:@"x3"] doubleValue];
	y3 = [[defaults objectForKey:@"y3"] doubleValue];
	z3 = [[defaults objectForKey:@"z3"] doubleValue];


	x0 = (x1 + x2) / 2.0;
	y0 = (y1 + y3) / 2.0;
	z0 = (z2 + z3) / 2.0;
	**/
	
	
	[self setupInitialKeyMappings];
		
}

- (void)expansionPortChanged:(NSNotification *)nc{

	[textView setString:[NSString stringWithFormat:@"%@\n===== Expansion port status changed. =====", [textView string]]];
	
	WiiRemote* tmpWii = (WiiRemote*)[nc object];
	
	if (![[tmpWii address] isEqualToString:[wii address]]){
		return;
	}
	
	if ([tmpWii isExpansionPortAttached]){
		[wii setExpansionPortEnabled:YES];
		[epDrawer open];
		NSLog(@"** Expansion Port Enabled");
	}else{
		[wii setExpansionPortEnabled:NO];
		[epDrawer close];
		NSLog(@"** Expansion Port Disabled");
	}	
}



- (void) wiiRemoteDisconnected:(IOBluetoothDevice*)device {
	[wii release];
	wii = nil;

	[textView setString:[NSString stringWithFormat:@"%@\n===== lost connection with WiiRemote =====", [textView string]]];
}

- (void) irPointMovedX:(float)px Y:(float)py{
	
	if (mouseEventMode != 2)
		return;
	
	BOOL haveMouse = (px > -2)?YES:NO;
	
	if (!haveMouse) {
		[graphView setIRPointX:-2 Y:-2];
		return;
	} else {
		[graphView setIRPointX:px Y:py];

	}
	
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	
	id config = [mappingController selection];
	float sens2 = [[config valueForKey:@"sensitivity2"] floatValue] * [[config valueForKey:@"sensitivity2"] floatValue];
	
	float newx = (px*1*sens2)*dispWidth + dispWidth/2;
	float newy = -(py*1*sens2)*dispWidth + dispHeight/2;
	
	if (newx < 0) newx = 0;
	if (newy < 0) newy = 0;
	if (newx >= dispWidth) newx = dispWidth-1;
	if (newy >= dispHeight) newy = dispHeight-1;
	
	float dx = newx - point.x;
	float dy = newy - point.y;
	
	float d = sqrt(dx*dx+dy*dy);

	
	
	// mouse filtering
	if (d < 20) {
		point.x = point.x * 0.9 + newx*0.1;
		point.y = point.y * 0.9 + newy*0.1;
	} else if (d < 50) {
		point.x = point.x * 0.7 + newx*0.3;
		point.y = point.y * 0.7 + newy*0.3;
	} else {
		point.x = newx;
		point.y = newy;
	}
	
	if (point.x > dispWidth)
		point.x = dispWidth - 1;
	
	if (point.y > dispHeight)
		point.y = dispHeight - 1;
	
	if (point.x < 0)
		point.x = 0;
	if (point.y < 0)
		point.y = 0;
	
	
	
	if (!isLeftButtonDown && !isRightButtonDown){
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventMouseMoved);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
	}else{		
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDragged, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventLeftMouseDragged);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);	
	}
	
} // irPointMoved

- (void) rawIRData:(IRData[4])irData {
		[irPoint1X setStringValue: [NSString stringWithFormat:@"%00X", irData[0].x]];		
		[irPoint1Y setStringValue: [NSString stringWithFormat:@"%00X", irData[0].y]];		
		[irPoint1Size setStringValue: [NSString stringWithFormat:@"%00X", irData[0].s]];		

		[irPoint2X setStringValue: [NSString stringWithFormat:@"%00X", irData[1].x]];		
		[irPoint2Y setStringValue: [NSString stringWithFormat:@"%00X", irData[1].y]];		
		[irPoint2Size setStringValue: [NSString stringWithFormat:@"%00X", irData[1].s]];		

		[irPoint3X setStringValue: [NSString stringWithFormat:@"%00X", irData[2].x]];		
		[irPoint3Y setStringValue: [NSString stringWithFormat:@"%00X", irData[2].y]];		
		[irPoint3Size setStringValue: [NSString stringWithFormat:@"%00X", irData[2].s]];		
	
		[irPoint4X setStringValue: [NSString stringWithFormat:@"%00X", irData[3].x]];		
		[irPoint4Y setStringValue: [NSString stringWithFormat:@"%00X", irData[3].y]];		
		[irPoint4Size setStringValue: [NSString stringWithFormat:@"%00X", irData[3].s]];
		
		if (irData[0].s != 0xF) {
			float scaledX = ((irData[0].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[0].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[0].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point1X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point1Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point1Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point1Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point1Enable"]];		
		}

		if (irData[1].s != 0xF) {
			float scaledX = ((irData[1].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[1].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[1].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point2X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point2Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point2Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point2Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point2Enable"]];		
		}

		if (irData[2].s != 0xF) {
			float scaledX = ((irData[2].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[2].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[2].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point3X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point3Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point3Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point3Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point3Enable"]];		
		}
		if (irData[3].s != 0xF) {
			float scaledX = ((irData[3].x / 1024.0) * 2.0) - 1.0;
			float scaledY = ((irData[3].y / 768.0) * 1.5) - 0.75;
			float scaledSize = irData[3].s / 16.0;
			
			[irQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"Point4X"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Point4Y"]];
			[irQCView setValue:[NSNumber numberWithFloat: scaledSize] forInputKey:[NSString stringWithString:@"Point4Size"]];

			[irQCView setValue:[NSNumber numberWithBool: YES] forInputKey:[NSString stringWithString:@"Point4Enable"]];		
		} else {
			[irQCView setValue:[NSNumber numberWithBool: NO] forInputKey:[NSString stringWithString:@"Point4Enable"]];		
		}
}


- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)isPressed{
		 
	id mappings = [mappingController selection];
	id map = nil;
	if (type == WiiRemoteAButton){
		map = [mappings valueForKeyPath:@"wiimote.a"];
		[aButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"A_Button"]];
		
	}else if (type == WiiRemoteBButton){
		map = [mappings valueForKeyPath:@"wiimote.b"];
		[bButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"B_Button"]];

	}else if (type == WiiRemoteUpButton){
		map = [mappings valueForKeyPath:@"wiimote.up"];
		[upButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Up"]];

	}else if (type == WiiRemoteDownButton){
		map = [mappings valueForKeyPath:@"wiimote.down"];
		[downButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Down"]];

	}else if (type == WiiRemoteLeftButton){
		map = [mappings valueForKeyPath:@"wiimote.left"];
		[leftButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Left"]];

	}else if (type == WiiRemoteRightButton){
		map = [mappings valueForKeyPath:@"wiimote.right"];
		[rightButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Right"]];

	}else if (type == WiiRemoteMinusButton){
		map = [mappings valueForKeyPath:@"wiimote.minus"];
		[minusButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Minus"]];

	}else if (type == WiiRemotePlusButton){
		map = [mappings valueForKeyPath:@"wiimote.plus"];
		[plusButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Plus"]];

	}else if (type == WiiRemoteHomeButton){
		map = [mappings valueForKeyPath:@"wiimote.home"];
		[homeButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Home"]];

	}else if (type == WiiRemoteOneButton){
		map = [mappings valueForKeyPath:@"wiimote.one"];
		[oneButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"One"]];

	}else if (type == WiiRemoteTwoButton){
		map = [mappings valueForKeyPath:@"wiimote.two"];
		[twoButton setEnabled:isPressed];
		[wiimoteQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"Two"]];

	}else if (type == WiiNunchukCButton){
		map = [mappings valueForKeyPath:@"nunchuk.c"];
		[joystickQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"CEnable"]];

	}else if (type == WiiNunchukZButton){
		map = [mappings valueForKeyPath:@"nunchuk.z"];
		[joystickQCView setValue:[NSNumber numberWithBool: isPressed] forInputKey:[NSString stringWithString:@"ZEnable"]];
	}
	
	
	NSString* modeName = [modes objectAtIndex:[[map valueForKey:@"mode"] intValue] ];
	//NSLog(@"modeName: %@", modeName);
	if ([modeName isEqualToString:@"Key"]){

		[self sendModifierKeys:map isPressed:isPressed]; 
		
		char c = (char)[[map valueForKey:@"character"] characterAtIndex:0];
		short keycode = AsciiToKeyCode(&table, c);
		[self sendKeyboardEvent:keycode keyDown:isPressed];
	}else if ([modeName isEqualToString:@"\tReturn"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:36 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tTab"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:48 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tEsc"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:53 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tBackspace"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:51 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tUp"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:126 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tDown"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:125 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tLeft"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:123 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tRight"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:124 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tPage Up"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:116 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tPage Down"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:121 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"Left Click"]){
		[self sendModifierKeys:map isPressed:isPressed];
		
		
		
		if (!isLeftButtonDown && isPressed){	//start dragging...
			isLeftButtonDown = YES;
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
			
			
			CGEventSetType(event, kCGEventLeftMouseDown);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);	
		}else if (isLeftButtonDown && !isPressed){	//end dragging...

			isLeftButtonDown = NO;

			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
		}
				
	}else if ([modeName isEqualToString:@"Left Click2"]){
		
		if (!isPressed)
			return;
		
		[self sendModifierKeys:map isPressed:YES];
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
		
		
		CGEventSetType(event, kCGEventLeftMouseDown);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventLeftMouseUp);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		[self sendModifierKeys:map isPressed:NO];

				
	}else if ([modeName isEqualToString:@"Right Click"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		
		[self sendModifierKeys:map isPressed:isPressed];
		
		
		
		if (!isRightButtonDown && isPressed){	//start dragging...
			isRightButtonDown = YES;
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, point, kCGMouseButtonRight);
			
			
			CGEventSetType(event, kCGEventRightMouseDown);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);	
		}else if (isRightButtonDown && !isPressed){	//end dragging...
			
			isRightButtonDown = NO;
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
		}
		
	}else if ([modeName isEqualToString:@"Right Click2"]){
		if (!isPressed)
			return;
		
		[self sendModifierKeys:map isPressed:YES];
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, point, kCGMouseButtonRight);
		
		
		CGEventSetType(event, kCGEventRightMouseDown);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
		
		CGEventSetType(event, kCGEventRightMouseUp);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
		
		[self sendModifierKeys:map isPressed:NO];
		
		
	}else if ([modeName isEqualToString:@"Toggle Mouse (Motion)"]){
		
		if (isPressed)
			return;
		
		if (mouseEventMode != 1){	//Mouse mode on
			mouseEventMode = 1;
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (Motion Sensors) =====", [textView string]]];

		}else{						//Mouse mode off
			mouseEventMode = 0;
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			[self sendKeyboardEvent:58 keyDown:NO];
			[self sendKeyboardEvent:56 keyDown:NO];
			[self sendKeyboardEvent:55 keyDown:NO];
			[self sendKeyboardEvent:59 keyDown:NO];
			
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode Off =====", [textView string]]];


		}
		[mouseMode selectItemAtIndex:mouseEventMode];
		
	}else if ([modeName isEqualToString:@"Toggle Mouse (IR)"]){
		
		
		if (isPressed)
			return;
		
		if (mouseEventMode != 2){	//Mouse mode on
			mouseEventMode = 2;
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (IR) =====", [textView string]]];

		}else{						//Mouse mode off
			mouseEventMode = 0;
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			[self sendKeyboardEvent:58 keyDown:NO];
			[self sendKeyboardEvent:56 keyDown:NO];
			[self sendKeyboardEvent:55 keyDown:NO];
			[self sendKeyboardEvent:59 keyDown:NO];
			
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode Off =====", [textView string]]];

		}
		[mouseMode selectItemAtIndex:mouseEventMode];
	}
	
	
}

- (void) sendModifierKeys:(id)map isPressed:(BOOL)isPressed {
	if ([[map valueForKey:@"shift"] boolValue]){
		[self sendKeyboardEvent:56 keyDown:isPressed];
	}
	
	if ([[map valueForKey:@"command"] boolValue]){
		[self sendKeyboardEvent:55 keyDown:isPressed];
	}
	
	if ([[map valueForKey:@"control"] boolValue]){
		[self sendKeyboardEvent:59 keyDown:isPressed];
	}
	
	if ([[map valueForKey:@"option"] boolValue]){
		[self sendKeyboardEvent:58 keyDown:isPressed];
	}
}


/* 
	My nunchuk reports joystick values from ~0x20 to ~0xE0 +/- ~5 in each axis.
	There may be calibration that can/should be performed and other nunchuks may 
	report different values and the scaling should be done using the calibrated
	values.  See http://www.wiili.org/index.php/Nunchuk#Calibration_data for more
	details.
*/
- (void) joyStickChanged:(WiiJoyStickType)type tiltX:(unsigned short)tiltX tiltY:(unsigned short)tiltY{
	if (type == WiiNunchukJoyStick){
		unsigned short max = 0xE0;
		unsigned short center = 0x80;
		
		float shiftedX = (tiltX * 1.0) - (center * 1.0);
		float shiftedY = (tiltY * 1.0) - (center * 1.0);
		
		float scaledX = (shiftedX * 1.0) / ((max - center) * 1.0);
		float scaledY = (shiftedY * 1.0) / ((max - center) * 1.0);
		
		// NSLog(@"Joystick X = %f  Y= %f", scaledX, scaledY);
		[joystickQCView setValue:[NSNumber numberWithFloat: scaledX] forInputKey:[NSString stringWithString:@"X_Position"]];
		[joystickQCView setValue:[NSNumber numberWithFloat: scaledY] forInputKey:[NSString stringWithString:@"Y_Position"]];
		
		[joystickX setStringValue: [NSString stringWithFormat:@"%00X", tiltX]];		
		[joystickY setStringValue: [NSString stringWithFormat:@"%00X", tiltY]];		
				
	}
}

- (void) accelerationChanged:(WiiAccelerationSensorType)type accX:(unsigned short)accX accY:(unsigned short)accY accZ:(unsigned short)accZ{
	
	if (type == WiiNunchukAccelerationSensor){
		// Get calibration data
		WiiAccCalibData data = [wii accCalibData:WiiNunchukAccelerationSensor];

		x0 = data.accX_zero;
		x3 = data.accX_1g;
		y0 = data.accY_zero;
		y2 = data.accY_1g;
		z0 = data.accZ_zero;
		z1 = data.accZ_1g;

		double ax = (double)(accX - x0) / (x3 - x0);
		double ay = (double)(accY - y0) / (y2 - y0);
		double az = (double)(accZ - z0) / (z1 - z0) * (-1.0);

		[graphView2 setData:ax y:ay z:az];
		[NunchukX setStringValue: [NSString stringWithFormat:@"%f", ax]];	
		[NunchukY setStringValue: [NSString stringWithFormat:@"%f", ay]];	
		[NunchukZ setStringValue: [NSString stringWithFormat:@"%f", az]];	
		
		return;
	}
	
	[batteryLevel setDoubleValue:(double)[wii batteryLevel]];
	
	
	tmpAccX = accX;
	tmpAccY = accY;
	tmpAccZ = accZ;
	
	id config = [mappingController selection];
	if ([[config valueForKey:@"manualCalibration"] boolValue]){
		x0 = [[config valueForKeyPath:@"wiimote.accX_zero"] intValue] ;
		x3 = [[config valueForKeyPath:@"wiimote.accX_1g"] intValue];
		y0 = [[config valueForKeyPath:@"wiimote.accY_zero"] intValue];
		y2 = [[config valueForKeyPath:@"wiimote.accY_1g"] intValue];
		z0 = [[config valueForKeyPath:@"wiimote.accZ_zero"] intValue];
		z1 = [[config valueForKeyPath:@"wiimote.accZ_1g"] intValue];
		
	}else{ 
		WiiAccCalibData data = [wii accCalibData:WiiRemoteAccelerationSensor];
		x0 = data.accX_zero;
		x3 = data.accX_1g;
		y0 = data.accY_zero;
		y2 = data.accY_1g;
		z0 = data.accZ_zero;
		z1 = data.accZ_1g;
	}

	double ax = (double)(accX - x0) / (x3 - x0);
	double ay = (double)(accY - y0) / (y2 - y0);
	double az = (double)(accZ - z0) / (z1 - z0) * (-1.0);
	
//This part is for writing data to a file.  Data is scaled to local gravitational acceleration and contains absolute local times.
	
	struct tm *t;
	struct timeval tval;
	struct timezone tzone;
	
	
	gettimeofday(&tval, &tzone);
	t = localtime(&(tval.tv_sec));
	
	[recordData appendFormat:@"%d:%d:%d.%06d,%f,%f,%f\n", t->tm_hour, t->tm_min, t->tm_sec, tval.tv_usec, ax, ay, az];

//End of part for writing data to file.
//Send same data to graphing window for live viewing and to text box to see values.
	
	[graphView setData:ax y:ay z:az];
	[WiimoteX setStringValue: [NSString stringWithFormat:@"%f", ax]];		
	[WiimoteY setStringValue: [NSString stringWithFormat:@"%f", ay]];		
	[WiimoteZ setStringValue: [NSString stringWithFormat:@"%f", az]];		
	
//End sending to live view.

	
	if (mouseEventMode != 1)	//Must be after graph and file data or they don't happen if Wii doesn't control mouse.
	return;
	
	
	double roll = atan(ax) * 180.0 / 3.14 * 2;
	double pitch = atan(ay) * 180.0 / 3.14 * 2;
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	
	NSPoint p = [mainWindow mouseLocationOutsideOfEventStream];
	NSRect p2 = [mainWindow frame];
	
	point.x = p.x + p2.origin.x;
	point.y = dispHeight - p.y - p2.origin.y;
	
	float sens1 = [[config valueForKey:@"sensitivity1"] floatValue] * [[config valueForKey:@"sensitivity1"] floatValue];
	
	if (roll < -15)
		point.x -= 2 * sens1;
	if (roll < -45)
		point.x -= 4 * sens1;
	if (roll < -75)
		point.x -= 6 * sens1;
	
	if (roll > 15)
		point.x += 2 * sens1;
	if (roll > 45)
		point.x += 4 * sens1;
	if (roll > 75)
		point.x += 6 * sens1;
	
	// pitch -	-90 = vertical, IR port up
	//			  0 = horizontal, A-button up.
	//			 90 = vertical, IR port down
	
	// The "natural" hand position for the wiimote is ~ -40 up. 
	
	if (pitch < -50)
		point.y -= 2 * sens1;
	if (pitch < -60)
		point.y -= 4 * sens1;
	if (pitch < -80)
		point.y -= 6 * sens1;
	
	if (pitch > -15)
		point.y += 2 * sens1;
	if (pitch > -5)
		point.y += 4 * sens1;
	if (pitch > 15)
		point.y += 6 * sens1; 
	
	
	if (point.x < 0)
		point.x = 0;
	if (point.y < 0)
		point.y = 0;
	
	if (point.x > dispWidth)
		point.x = dispWidth - 1;
	
	if (point.y > dispHeight)
		point.y = dispHeight - 1;
	
	
	
	if (!isLeftButtonDown && !isRightButtonDown){
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventMouseMoved);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);
	}else{		
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDragged, point, kCGMouseButtonLeft);
		
		CGEventSetType(event, kCGEventLeftMouseDragged);
		// this is Tiger's bug.
		// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
		
		CGEventPost(kCGHIDEventTap, event);
		CFRelease(event);	
	}
	
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:[[NSNumber alloc] initWithDouble:x1] forKey:@"x1"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:y1] forKey:@"y1"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:z1] forKey:@"z1"];
	
	[defaults setObject:[[NSNumber alloc] initWithDouble:x2] forKey:@"x2"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:y2] forKey:@"y2"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:z2] forKey:@"z2"];
	
	[defaults setObject:[[NSNumber alloc] initWithDouble:x3] forKey:@"x3"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:y3] forKey:@"y3"];
	[defaults setObject:[[NSNumber alloc] initWithDouble:z3] forKey:@"z3"];
	
	
	[defaults setObject:[[NSNumber alloc] initWithInt:[mappingController selectionIndex]] forKey:@"selection"];

	
	[graphView stopTimer];
	[graphView2 stopTimer];
	[wii closeConnection];
	
	[appDelegate saveAction:nil];
	
	return NSTerminateNow;
}


- (void)sendKeyboardEvent:(CGKeyCode)keyCode keyDown:(BOOL)keyDown{
	CFRelease(CGEventCreate(NULL));		
	// this is Tiger's bug.
	//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
	
	
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, keyCode, keyDown);
	CGEventPost(kCGHIDEventTap, event);
	CFRelease(event);
	usleep(10000);
}


- (IBAction)openKeyConfiguration:(id)sender{
	//[keyConfigWindow setKeyTitle:[sender title]];

	NSManagedObjectContext * context  = [appDelegate managedObjectContext];

	[context commitEditing];



	[NSApp beginSheet:preferenceWindow
	   modalForWindow:mainWindow
        modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
	
}


- (void)setupInitialKeyMappings{
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];
	NSManagedObjectModel   * model    = [appDelegate managedObjectModel];
	NSDictionary           * entities = [model entitiesByName];
	NSEntityDescription    * entity   = [entities valueForKey:@"KeyMapping"];
	
	NSFetchRequest* fetch = [[NSFetchRequest alloc] init];
	NSError* error;
	
	[fetch setEntity:entity];
	
	NSArray* results = [context executeFetchRequest:fetch error:&error];
	if ([results count] > 0){
		return;
	}
	
	
	NSManagedObject* config = [self createNewConfigration:@"Apple Remote"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.up.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:6] forKeyPath:@"wiimote.up.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.down.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:7] forKeyPath:@"wiimote.down.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.left.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:8] forKeyPath:@"wiimote.left.mode"];

	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.right.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:9] forKeyPath:@"wiimote.right.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.a.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:12] forKeyPath:@"wiimote.a.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.b.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:2] forKeyPath:@"wiimote.b.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:YES] forKeyPath:@"wiimote.plus.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.plus.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.plus.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.plus.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:9] forKeyPath:@"wiimote.plus.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:YES] forKeyPath:@"wiimote.minus.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.minus.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.minus.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.minus.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:8] forKeyPath:@"wiimote.minus.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:YES] forKeyPath:@"wiimote.home.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.home.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.home.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.home.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:4] forKeyPath:@"wiimote.home.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.one.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:16] forKeyPath:@"wiimote.one.mode"];
	
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.command"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.control"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.option"];
	[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.shift"];
	[config setValue:[[NSNumber alloc] initWithInt:17] forKeyPath:@"wiimote.two.mode"];
	


	[appDelegate saveAction:nil];
	
}

- (void)sheetDidEnd:(NSWindow *)sheetWin returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];

	if (returnCode == 1){
		[context commitEditing];
		[appDelegate saveAction:nil];
	}else{
		//[context discardEditing];
		[context rollback];
	}
	
	
	[sheetWin close];
}


- (IBAction)addConfiguration:(id)sender{
	int result = [NSApp runModalForWindow:enterNameWindow];
	[enterNameWindow close];
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];

	if (result == 1){
		id config = [self createNewConfigration:[newNameField stringValue]];
		[mappingController setSelectsInsertedObjects:YES];
		[mappingController addObject:config];
		
		//[context insertObject:config];
		
		[context commitEditing];
	}

}

- (NSManagedObject*)createNewConfigration:(NSString*)name{
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];
	NSManagedObject* config = [NSEntityDescription insertNewObjectForEntityForName:@"KeyConfiguration" inManagedObjectContext: context];
	NSManagedObject* wiimote = [NSEntityDescription insertNewObjectForEntityForName:@"Wiimote" inManagedObjectContext: context];
	NSManagedObject* nunchuk = [NSEntityDescription insertNewObjectForEntityForName:@"Nunchuk" inManagedObjectContext: context];

	
	NSManagedObject* one = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* two = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* a = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* b = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* minus = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* plus = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* home = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* up = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* down = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* left = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* right = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	
	[wiimote setValue:one forKey:@"one"];
	[wiimote setValue:two forKey:@"two"];
	[wiimote setValue:a forKey:@"a"];
	[wiimote setValue:b forKey:@"b"];
	[wiimote setValue:minus forKey:@"minus"];
	[wiimote setValue:home forKey:@"home"];
	[wiimote setValue:plus forKey:@"plus"];
	[wiimote setValue:up forKey:@"up"];
	[wiimote setValue:down forKey:@"down"];
	[wiimote setValue:left forKey:@"left"];
	[wiimote setValue:right forKey:@"right"];
	
	
	NSManagedObject* c = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];
	NSManagedObject* z = [NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context];

	[nunchuk setValue:c forKey:@"c"];
	[nunchuk setValue:z forKey:@"z"];
	
	
	[config setValue:wiimote forKey:@"wiimote"];
	[config setValue:nunchuk forKey:@"nunchuk"];
	[config setValue:name forKey:@"name"];
	
	
	return config;
}


- (IBAction)enterSaveName:(id)sender{
    // OK button is pushed
	
	if ([[newNameField stringValue] length] == 0){
		return;
	}
	
    [NSApp stopModalWithCode:1];
}

- (IBAction)cancelEnterSaveName:(id)sender{
	// Cancel button is pushed
    [NSApp stopModalWithCode:0];

}

- (IBAction)deleteConfiguration:(id)sender{
	if ([[mappingController arrangedObjects] count] <= 1){
		return;
	}
	
	NSManagedObjectContext * context  = [appDelegate managedObjectContext];
	[mappingController removeObjectAtArrangedObjectIndex:[mappingController selectionIndex]];
	[context commitEditing];

}

- (IBAction)setMouseModeEnabled:(id)sender{
	mouseEventMode = [sender indexOfSelectedItem];
	
	switch(mouseEventMode){
		case 0:
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, point, kCGMouseButtonRight);
			
			CGEventSetType(event, kCGEventRightMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			[self sendKeyboardEvent:58 keyDown:NO];
			[self sendKeyboardEvent:56 keyDown:NO];
			[self sendKeyboardEvent:55 keyDown:NO];
			[self sendKeyboardEvent:59 keyDown:NO];
			
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode Off =====", [textView string]]];
			break;
		case 1:
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (Motion Sensors) =====", [textView string]]];
			break;
		case 2:
			[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode On (IR Sensor) =====", [textView string]]];
			
	}
}

/*
- (IBAction)getMii: (id)sender
{
       NSLog(@"Requesting Mii...");
       [wii getMii:0];
}

- (void)gotMiiData: (Mii*)m at:(int)slot
{
       Mii mii = *m;

       NSLog(@"Got Mii named %@ ", mii.creatorName);
       NSLog(@" at %@",slot);

       // save Mii binary file
       NSData* miiData = [NSData dataWithBytes:(void*)m length: MII_DATA_SIZE];
       NSSavePanel* theSavePanel = [NSSavePanel new];
       [theSavePanel setPrompt:NSLocalizedString(@"Save", @"Save")];
       if (NSFileHandlingPanelOKButton == [theSavePanel runModalForDirectory:NULL file:@"Untitled.mii"]) {
               NSURL *selectedFileURL = [theSavePanel URL];
               [miiData writeToURL:selectedFileURL atomically:NO];
       }
}
*/

#pragma mark -
#pragma mark WiiRemoteDiscovery delegates

- (void) WiiRemoteDiscoveryError:(int)code {
	[discoverySpinner stopAnimation:self];
	[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemoteDiscovery error.  If clicking Find Wiimote gives this error, try System Preferences > Bluetooth > Devices, delete Nintendo. (%d) =====", [textView string], code]];
}

- (void) willStartWiimoteConnections {
	[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemote discovered.  Opening connection. =====", [textView string]]];
}

- (void) WiiRemoteDiscovered:(WiiRemote*)wiimote {
	
	//	[discovery stop];
	
	// the wiimote must be retained because the discovery provides us with an autoreleased object
	wii = [wiimote retain];
	[wiimote setDelegate:self];
	
	[textView setString:[NSString stringWithFormat:@"%@\n===== Connected to WiiRemote =====", [textView string]]];
	[discoverySpinner stopAnimation:self];
	
	[wiimote setLEDEnabled1:YES enabled2:NO enabled3:NO enabled4:NO];
	[wiimoteQCView setValue:[NSNumber numberWithBool:[led1 state] ] forInputKey:[NSString stringWithString:@"LED_1"]];

	[wiimote setMotionSensorEnabled:YES];
//	[wiimote setIRSensorEnabled:YES];

	[graphView startTimer];
	[graphView2 startTimer];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[mappingController setSelectionIndex:[[defaults objectForKey:@"selection"] intValue]];
}

@end
