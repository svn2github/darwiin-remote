#import "AppController.h"


@implementation AppController



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

-(void)awakeFromNib{

	InitAscii2KeyCodeTable(&table);
	
	
	mouseEventMode = 0;
	discovery = [[WiiRemoteDiscovery alloc] init];
	[discovery setDelegate:self];
	[discovery start];
	[drawer open];
	[textView setString:@"Please press 1 button and 2 button simultaneously"];
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
	

	
	[[NSNotificationCenter defaultCenter] addObserver:self
														selector:@selector(expansionPortChanged:)
														name:@"WiiRemoteExpansionPortChangedNotification"
														object:nil];
	
	


}

- (void)expansionPortChanged:(NSNotification *)nc{
	WiiRemote* tmpWii = (WiiRemote*)[nc object];
	if (![[tmpWii address] isEqualToString:[wii address]]){
		return;
	}
	
	if ([tmpWii isExpansionPortAttached]){
		[tmpWii setExpansionPortEnabled:YES];

	}else{
		[tmpWii setExpansionPortEnabled:NO];

	}
	
}


//delegats implementation

- (void) WiiRemoteDiscovered:(WiiRemote*)wiimote {
	wii = wiimote;
	[wiimote setDelegate:self];
	[textView setString:[NSString stringWithFormat:@"%@\n===== Connected to WiiRemote =====", [textView string]]];
	[wiimote setLEDEnabled1:YES enabled2:NO enabled3:NO enabled4:NO];
	[wiimote setMotionSensorEnabled:YES];
//	[wiimote setIRSensorEnabled:YES];
	[discovery stop];
	[graphView startTimer];
	[graphView2 startTimer];

	
	
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[mappingController setSelectionIndex:[[defaults objectForKey:@"selection"] intValue]];
	


}

- (void) WiiRemoteDiscoveryError:(int)code {
	[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemoteDiscovery error (%d) =====", [textView string], code]];
}

- (void) wiiRemoteDisconnected:(IOBluetoothDevice*)device {
	[textView setString:[NSString stringWithFormat:@"%@\n===== lost connection with WiiRemote =====", [textView string]]];
	[wii release];
	wii = nil;

	[discovery start];
	[textView setString:[NSString stringWithFormat:@"%@\nPlease press the synchronize button", [textView string]]];
}

- (void) irPointMovedX:(float)px Y:(float)py wiiRemote:(WiiRemote*)wiiRemote{
	
	NSLog(@"x: %f, y: %f", py, py);
	
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
	
	float newx = (px*sens2)*dispWidth + dispWidth/2;
	float newy = -(py*sens2)*dispWidth + dispHeight/2;
	
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
	
	
	NSLog(@"x: %f  y: %f", point.x, point.y);
	
	
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



- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)isPressed wiiRemote:(WiiRemote*)wiiRemote{
	
	
	id mappings = [mappingController selection];
	id map = nil;
	if (type == WiiRemoteAButton){
		map = [mappings valueForKeyPath:@"wiimote.a"];
		[aButton setEnabled:isPressed];
		
	}else if (type == WiiRemoteBButton){
		map = [mappings valueForKeyPath:@"wiimote.b"];
		[bButton setEnabled:isPressed];

	}else if (type == WiiRemoteUpButton){
		map = [mappings valueForKeyPath:@"wiimote.up"];
		[upButton setEnabled:isPressed];

	}else if (type == WiiRemoteDownButton){
		map = [mappings valueForKeyPath:@"wiimote.down"];
		[downButton setEnabled:isPressed];

	}else if (type == WiiRemoteLeftButton){
		map = [mappings valueForKeyPath:@"wiimote.left"];
		[leftButton setEnabled:isPressed];

	}else if (type == WiiRemoteRightButton){
		map = [mappings valueForKeyPath:@"wiimote.right"];
		[rightButton setEnabled:isPressed];

	}else if (type == WiiRemoteMinusButton){
		map = [mappings valueForKeyPath:@"wiimote.minus"];
		[minusButton setEnabled:isPressed];

	}else if (type == WiiRemotePlusButton){
		map = [mappings valueForKeyPath:@"wiimote.plus"];
		[plusButton setEnabled:isPressed];

	}else if (type == WiiRemoteHomeButton){
		map = [mappings valueForKeyPath:@"wiimote.home"];
		[homeButton setEnabled:isPressed];

	}else if (type == WiiRemoteOneButton){
		map = [mappings valueForKeyPath:@"wiimote.one"];
		[oneButton setEnabled:isPressed];

	}else if (type == WiiRemoteTwoButton){
		map = [mappings valueForKeyPath:@"wiimote.two"];
		[twoButton setEnabled:isPressed];

	}else if (type == WiiNunchukCButton){
		map = [mappings valueForKeyPath:@"nunchuk.c"];
	}else if (type == WiiNunchukZButton){
		map = [mappings valueForKeyPath:@"nunchuk.z"];
	}else if (type == WiiClassicControllerXButton){
		map = [mappings valueForKeyPath:@"classiccontroller.x"];
	}else if (type == WiiClassicControllerYButton){
		map = [mappings valueForKeyPath:@"classiccontroller.y"];
	}else if (type == WiiClassicControllerAButton){
		NSLog(@"changed! %d", isPressed);

		map = [mappings valueForKeyPath:@"classiccontroller.a"];
	}else if (type == WiiClassicControllerBButton){
		map = [mappings valueForKeyPath:@"classiccontroller.b"];
	}else if (type == WiiClassicControllerLButton){
		map = [mappings valueForKeyPath:@"classiccontroller.l"];
	}else if (type == WiiClassicControllerRButton){
		map = [mappings valueForKeyPath:@"classiccontroller.r"];
	}else if (type == WiiClassicControllerZLButton){
		map = [mappings valueForKeyPath:@"classiccontroller.zl"];
	}else if (type == WiiClassicControllerZRButton){
		map = [mappings valueForKeyPath:@"classiccontroller.zr"];
	}else if (type == WiiClassicControllerUpButton){
		map = [mappings valueForKeyPath:@"classiccontroller.up"];
	}else if (type == WiiClassicControllerDownButton){
		map = [mappings valueForKeyPath:@"classiccontroller.down"];
	}else if (type == WiiClassicControllerLeftButton){
		map = [mappings valueForKeyPath:@"classiccontroller.left"];
	}else if (type == WiiClassicControllerRightButton){
		map = [mappings valueForKeyPath:@"classiccontroller.right"];
	}else if (type == WiiClassicControllerMinusButton){
		map = [mappings valueForKeyPath:@"classiccontroller.minus"];
	}else if (type == WiiClassicControllerHomeButton){
		map = [mappings valueForKeyPath:@"classiccontroller.home"];
	}else if (type == WiiClassicControllerPlusButton){
		map = [mappings valueForKeyPath:@"classiccontroller.plus"];
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
		
	}else if ([modeName isEqualToString:@"\tF1"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:122 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF2"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:120 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF3"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:99 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF4"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:118 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF5"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:96 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF6"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:97 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF7"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:98 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF8"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:100 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF9"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:101 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF10"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:109 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF11"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:103 keyDown:isPressed];
		
	}else if ([modeName isEqualToString:@"\tF12"]){
		[self sendModifierKeys:map isPressed:isPressed]; 
		
		[self sendKeyboardEvent:111 keyDown:isPressed];
		
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

- (void) sendModifierKeys:(id)map isPressed:(BOOL)isPressed{
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


- (void) joyStickChanged:(WiiJoyStickType)type tiltX:(unsigned char)tiltX tiltY:(unsigned char)tiltY wiiRemote:(WiiRemote*)wiiRemote{
	if (type == WiiNunchukJoyStick){
		
	}
}

- (void) analogButtonChanged:(WiiButtonType)type amount:(unsigned char)pressure wiiRemote:(WiiRemote*)wiiRemote{
	
}

- (void) accelerationChanged:(WiiAccelerationSensorType)type accX:(unsigned char)accX accY:(unsigned char)accY accZ:(unsigned char)accZ wiiRemote:(WiiRemote*)wiiRemote{
	
	if (type == WiiNunchukAccelerationSensor){
		[graphView2 setData:accX y:accY z:accZ];
		return;
	}
	
	[graphView setData:accX y:accY z:accZ];
	[batteryLevel setDoubleValue:(double)[wii batteryLevel]];
	
	
	tmpAccX = accX;
	tmpAccY = accY;
	tmpAccZ = accZ;
	
	if (mouseEventMode != 1)
		return;
	

	
	
	id config = [mappingController selection];
	if ([[config valueForKey:@"manualCalibration"] boolValue]){
		x0 = [[config valueForKeyPath:@"wiimote.accX_zero"] intValue] ;
		x3 = [[config valueForKeyPath:@"wiimote.accX_1g"] intValue];
		y0 = [[config valueForKeyPath:@"wiimote.accY_zero"] intValue];
		y2 = [[config valueForKeyPath:@"wiimote.accY_1g"] intValue];
		
	}else{ 
		WiiAccCalibData data = [wii accCalibData:WiiRemoteAccelerationSensor];
		x0 = data.accX_zero;
		x3 = data.accX_1g;
		y0 = data.accY_zero;
		y2 = data.accY_1g;
	}
	
	

	double ax = (double)(accX - x0) / (x3 - x0);
	double ay = (double)(accY - y0) / (y2 - y0);
	
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

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
	
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
	
	
	if ([results count] == 0){
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
		[config setValue:[[NSNumber alloc] initWithInt:24] forKeyPath:@"wiimote.a.mode"];
		
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
		[config setValue:[[NSNumber alloc] initWithInt:28] forKeyPath:@"wiimote.one.mode"];
		
		[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.command"];
		[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.control"];
		[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.option"];
		[config setValue:[[NSNumber alloc] initWithBool:NO] forKeyPath:@"wiimote.two.shift"];
		[config setValue:[[NSNumber alloc] initWithInt:29] forKeyPath:@"wiimote.two.mode"];
	}
	
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
	NSManagedObject* ccontroller = [NSEntityDescription insertNewObjectForEntityForName:@"ClassicController" inManagedObjectContext: context];			
	
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"one"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"two"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"a"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"b"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"minus"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"home"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"plus"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"up"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"down"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"left"];
	[wiimote setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"right"];

	[nunchuk setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"c"];
	[nunchuk setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"z"];
	[nunchuk setValue:[NSEntityDescription insertNewObjectForEntityForName:@"JoyStickMapping" inManagedObjectContext: context] forKey:@"joystick"];

	
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"l"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"r"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"a"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"b"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"minus"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"plus"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"home"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"up"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"down"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"left"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"right"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"zl"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"KeyMapping" inManagedObjectContext: context] forKey:@"zr"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"JoyStickMapping" inManagedObjectContext: context] forKey:@"joystickL"];
	[ccontroller setValue:[NSEntityDescription insertNewObjectForEntityForName:@"JoyStickMapping" inManagedObjectContext: context] forKey:@"joystickR"];
	
	[config setValue:wiimote forKey:@"wiimote"];
	[config setValue:nunchuk forKey:@"nunchuk"];
	[config setValue:ccontroller forKey:@"classiccontroller"];
	[config setValue:name forKey:@"name"];
	[config setValue:[NSNumber numberWithFloat:[[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"] floatValue]] forKey:@"version"];
	
	
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

@end
