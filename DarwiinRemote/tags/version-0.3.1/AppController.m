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


- (IBAction)setMouseModeEnabled:(id)sender{

	
	if ([sender state]){
		sendMouseEvent = YES;
	}else{
		CGPostMouseEvent(point, TRUE, 1, FALSE);
		isPressedAButton = NO;
		sendMouseEvent = NO;
	}
}


- (IBAction)setMotionSensorsEnabled:(id)sender
{
	[wii setMotionSensorEnabled:[sender state]];
}


- (IBAction)doCalibration:(id)sender{
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
	
	[textView setString:[NSString stringWithFormat:@"%@\n===== x: %d  y: %d  z: %d =====", [textView string], tmpAccX, tmpAccY, tmpAccZ]];

}

-(void)awakeFromNib{
	sendMouseEvent = NO;
	discovery = [[WiiRemoteDiscovery alloc] init];
	[discovery setDelegate:self];
	[discovery start];
	[drawer open];
	[textView setString:@"Please press 1 button and 2 button simultaneously"];
	point.x = 0;
	point.y = 0;
	
	//User defaults settings...
	{
        NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
		
		NSNumber* num = [[NSNumber alloc] initWithDouble:128.0];
		NSNumber* num2 = [[NSNumber alloc] initWithDouble:154.0];

        //NSData *num = [NSArchiver archivedDataWithRootObject:[[NSNumber alloc]initWithInt:0]];
        //NSData *check = [NSArchiver archivedDataWithRootObject:[[NSNumber alloc]initWithInt:NSOffState]];
		[defaultValues setObject:num forKey:@"x1"];
		[defaultValues setObject:num forKey:@"y1"];
		[defaultValues setObject:num2 forKey:@"z1"];

		[defaultValues setObject:num forKey:@"x2"];
		[defaultValues setObject:num2 forKey:@"y2"];
		[defaultValues setObject:num forKey:@"z2"];
		
		[defaultValues setObject:num2 forKey:@"x3"];
		[defaultValues setObject:num forKey:@"y3"];
		[defaultValues setObject:num forKey:@"z3"];

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


	NSLog(@"%f, %f, %f, %f, %f, %f, %f, %f, %f", x1, y1, z1, x2, y2, z2, x3, y3, z3);

	x0 = (x1 + x2) / 2.0;
	y0 = (y1 + y3) / 2.0;
	z0 = (z2 + z3) / 2.0;
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
}

- (void) WiiRemoteDiscoveryError:(int)code {
	[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemoteDiscovery error (%d) =====", [textView string], code]];
}

- (void) wiiRemoteDisconnected {
	[textView setString:[NSString stringWithFormat:@"%@\n===== lost connection with WiiRemote =====", [textView string]]];
	[wii release];
	wii = nil;
	[discovery start];
	[textView setString:[NSString stringWithFormat:@"%@\nPlease press the synchronize button", [textView string]]];
}


//- (void) dataChanged:(short)buttonData accX:(unsigned char)accX accY:(unsigned char)accY accZ:(unsigned char)accZ{
- (void) dataChanged:(unsigned short)buttonData accX:(unsigned char)accX accY:(unsigned char)accY accZ:(unsigned char)accZ mouseX:(float)mx mouseY:(float)my{
	[graphView setData:accX y:accY z:accZ];
	[batteryLevel setDoubleValue:(double)[wii batteryLevel]];
	tmpAccX = accX;
	tmpAccY = accY;
	tmpAccZ = accZ;
	
	
	double ax = (double)(accX - x0) / (x3 - x0);
	double ay = (double)(accY - y0) / (y2 - y0);
//	double az = (double)(accZ - z0) / (z1 - z0);

	
	double roll = atan(ax) * 180.0 / 3.14 * 2;
	double pitch = atan(ay) * 180.0 / 3.14 * 2;
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	
	
	NSPoint p = [mainWindow mouseLocationOutsideOfEventStream];
	NSRect p2 = [mainWindow frame];
	
	point.x = p.x + p2.origin.x;
	point.y = dispHeight - p.y - p2.origin.y;
	//NSLog(@"width: %d, height: %d,  point.y: %f p.y: %f p2.origin.y: %f p2.size.height: %f", dispWidth, dispHeight, point.y, p.y, p2.origin.y, p2.size.height);

	// Set the mouse pointer position delta for different angles - in degrees.
	// roll - 0 = level
	// roll < 0 = left side down.
	// roll > 0 = right side down.
	
	if (mouseEventMode == 1){
		if (roll < -15)
			point.x -= 2;
		if (roll < -45)
			point.x -= 4;
		if (roll < -75)
			point.x -= 6;
		
		if (roll > 15)
			point.x += 2;
		if (roll > 45)
			point.x += 4;
		if (roll > 75)
			point.x += 6;
		
		// pitch -	-90 = vertical, IR port up
		//			  0 = horizontal, A-button up.
		//			 90 = vertical, IR port down
		
		// The "natural" hand position for the wiimote is ~ -40 up. 
		
		if (pitch < -50)
			point.y -= 2;
		if (pitch < -60)
			point.y -= 4;
		if (pitch < -80)
			point.y -= 6;
		
		if (pitch > -15)
			point.y += 2;
		if (pitch > -5)
			point.y += 4;
		if (pitch > 15)
			point.y += 6; 
		
		
		if (point.x < 0)
			point.x = 0;
		if (point.y < 0)
			point.y = 0;
	}

	
	BOOL haveMouse = (mx > -2)?YES:NO;
	
	if (haveMouse) {
		[graphView setIRPointX:mx Y:my];
	} else {
		[graphView setIRPointX:-2 Y:-2];
	}
	
	if (mouseEventMode == 2 && haveMouse) {
		// the 1 in the next two lines is the screen scaling factor.  1 seems to work
		// pretty good.  smaller values will result in wider movement, but not as much
		// give at the edges or be able to get to the corners of the screen when rotated
		float newx = (mx*1)*dispWidth + dispWidth/2;
		float newy = -(my*1)*dispWidth + dispHeight/2;
		
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
		
		//	printf("%4d %4d    %4d %4d\n", (int)newx, (int)newy, (int)point.x, (int)point.y);
	}
	
	
	if (point.x < 0)
		point.x = 0;
	if (point.y < 0)
		point.y = 0;
	
	if (point.x > dispWidth)
		point.x = dispWidth - 1;
	
	if (point.y > dispHeight)
		point.y = dispHeight - 1;
		
	
	if ((buttonData & kWiiRemoteAButton)){
		[aButton setEnabled:YES];
		
		if (!isPressedAButton){
			isPressedAButton = YES;
			if (mouseEventMode != 0){
				
				CFRelease(CGEventCreate(NULL));		
				// this is Tiger's bug.
				//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
				
				
				CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
				
				
				CGEventSetType(event, kCGEventLeftMouseDown);
				// this is Tiger's bug.
				// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
				
				
				CGEventPost(kCGHIDEventTap, event);
				CFRelease(event);
				

			}
		}else{
			if (mouseEventMode != 0){				//dragging...
				
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
	}else{
		
		[aButton setEnabled:NO];
		if (mouseEventMode != 0){
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventMouseMoved);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html

			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			

		}
		
		if (isPressedAButton){
			
			CFRelease(CGEventCreate(NULL));		
			// this is Tiger's bug.
			// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
			
			
			CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
			
			CGEventSetType(event, kCGEventLeftMouseUp);
			// this is Tiger's bug.
			// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
			
			
			CGEventPost(kCGHIDEventTap, event);
			CFRelease(event);
			
			isPressedAButton = NO;
		}
	}

	
	if ((buttonData & kWiiRemoteBButton)){
		[bButton setEnabled:YES];
		if (!isPressedBButton){
			isPressedBButton = YES;
			

			[self sendKeyboardEvent:(CGKeyCode)36 keyDown:YES];
		}
	}else{
		[bButton setEnabled:NO];
		
		if (isPressedBButton){
			isPressedBButton = NO;
			
			[self sendKeyboardEvent:(CGKeyCode)36 keyDown:NO];
		}
	}
	
	if ((buttonData & kWiiRemoteUpButton)){
		[upButton setEnabled:YES];
		
		if (!isPressedUpButton){
			isPressedUpButton = YES;
			
			[self sendKeyboardEvent:(CGKeyCode)126 keyDown:YES];
		}
		
	}else{
		[upButton setEnabled:NO];
		
		if (isPressedUpButton){
			isPressedUpButton = NO;
			[self sendKeyboardEvent:(CGKeyCode)126 keyDown:NO];

		}
	}
	
	if ((buttonData & kWiiRemoteDownButton)){
		[downButton setEnabled:YES];
		
		if (!isPressedDownButton){
			isPressedDownButton = YES;
			[self sendKeyboardEvent:(CGKeyCode)125 keyDown:YES];

		}
		
	}else{
		[downButton setEnabled:NO];
		
		if (isPressedDownButton){
			isPressedDownButton = NO;
			[self sendKeyboardEvent:(CGKeyCode)125 keyDown:NO];

		}
	}
	
	if ((buttonData & kWiiRemoteLeftButton)){
		[leftButton setEnabled:YES];
		
		if (!isPressedLeftButton){
			isPressedLeftButton = YES;
			[self sendKeyboardEvent:(CGKeyCode)123 keyDown:YES];

		}
		
	}else{
		[leftButton setEnabled:NO];
		
		if (isPressedLeftButton){
			isPressedLeftButton = NO;
			[self sendKeyboardEvent:(CGKeyCode)123 keyDown:NO];

		}
	}
	
	if ((buttonData & kWiiRemoteRightButton)){
		[rightButton setEnabled:YES];
		
		if (!isPressedRightButton){
			isPressedRightButton = YES;
			
			[self sendKeyboardEvent:(CGKeyCode)124 keyDown:YES];

		}
		
	}else{
		[rightButton setEnabled:NO];
		
		if (isPressedRightButton){
			isPressedRightButton = NO;
			[self sendKeyboardEvent:(CGKeyCode)124 keyDown:NO];

		}
		
	}
	
	if ((buttonData & kWiiRemoteMinusButton)){
		[minusButton setEnabled:YES];
		
		if (!isPressedMinusButton){
			isPressedMinusButton = YES;
			
			[self sendKeyboardEvent:(CGKeyCode)56 keyDown:YES];
			[self sendKeyboardEvent:(CGKeyCode)125 keyDown:YES];

			
		}
	}else{
		[minusButton setEnabled:NO];
		
		if (isPressedMinusButton){
			isPressedMinusButton = NO;
			
			[self sendKeyboardEvent:(CGKeyCode)56 keyDown:NO];
			[self sendKeyboardEvent:(CGKeyCode)125 keyDown:NO];

			
		}
	}
	
	if ((buttonData & kWiiRemotePlusButton)){
		[plusButton setEnabled:YES];
		
		if (!isPressedPlusButton){
			isPressedPlusButton = YES;
			
			[self sendKeyboardEvent:(CGKeyCode)56 keyDown:YES];
			[self sendKeyboardEvent:(CGKeyCode)126 keyDown:YES];

			
		}
		
	}else{
		[plusButton setEnabled:NO];
		
		if (isPressedPlusButton){
			isPressedPlusButton = NO;
			
			[self sendKeyboardEvent:(CGKeyCode)56 keyDown:NO];
			[self sendKeyboardEvent:(CGKeyCode)126 keyDown:NO];

		}
		
	}
	
	if ((buttonData & kWiiRemoteHomeButton)){
		[homeButton setEnabled:YES];
		
		if (!isPressedHomeButton){
			isPressedHomeButton = YES;
			
			
			[self sendKeyboardEvent:(CGKeyCode)55 keyDown:YES];
			[self sendKeyboardEvent:(CGKeyCode)53 keyDown:YES];

		}
		
	}else{
		[homeButton setEnabled:NO];
		
		if (isPressedHomeButton){
			isPressedHomeButton = NO;
			
			[self sendKeyboardEvent:(CGKeyCode)53 keyDown:NO];
			[self sendKeyboardEvent:(CGKeyCode)55 keyDown:NO];

			
		}
	}
	
	if ((buttonData & kWiiRemoteOneButton)){
		[oneButton setEnabled:YES];
		
		if (!isPressedOneButton){
			isPressedOneButton = YES;
			
		}
		
	}else{
		[oneButton setEnabled:NO];
		
		if (isPressedOneButton){
			isPressedOneButton = NO;
			if (mouseEventMode != 1){
				mouseEventMode = 1;
				[textView setString:[NSString stringWithFormat:@"%@\n===== Acceleration Sensor Mouse Mode =====", [textView string]]];
			}else{
				mouseEventMode = 0;
				
				CFRelease(CGEventCreate(NULL));		
				// this is Tiger's bug.
				// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
				
				
				CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
				
				CGEventSetType(event, kCGEventLeftMouseUp);
				// this is Tiger's bug.
				// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
				
				
				CGEventPost(kCGHIDEventTap, event);
				CFRelease(event);
				
				
				isPressedAButton = NO;
				[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode off =====", [textView string]]];
			}
			
		}
	}
	
	if ((buttonData & kWiiRemoteTwoButton)){
		[twoButton setEnabled:YES];
		
		
		if (!isPressedTwoButton){
			isPressedTwoButton = YES;
		}
	}else{
		[twoButton setEnabled:NO];
		
		if (isPressedTwoButton){
			isPressedTwoButton = NO;
			if (mouseEventMode != 2){
				mouseEventMode = 2;
				[textView setString:[NSString stringWithFormat:@"%@\n===== IR Sensor Mouse Mode =====", [textView string]]];
				
			}else{
				mouseEventMode = 0;
				
				CFRelease(CGEventCreate(NULL));		
				// this is Tiger's bug.
				// see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
				
				
				CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, point, kCGMouseButtonLeft);
				
				CGEventSetType(event, kCGEventLeftMouseUp);
				// this is Tiger's bug.
				// see also: http://lists.apple.com/archives/Quartz-dev/2005/Oct/msg00048.html
				
				
				CGEventPost(kCGHIDEventTap, event);
				CFRelease(event);
				
				
				isPressedAButton = NO;
				[textView setString:[NSString stringWithFormat:@"%@\n===== Mouse Mode Off =====", [textView string]]];
			}
		}
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
	
	
	[graphView stopTimer];
	[wii closeConnection];
	return NSTerminateNow;
}


- (void)sendKeyboardEvent:(CGKeyCode)keyCode keyDown:(BOOL)keyDown{
	CFRelease(CGEventCreate(NULL));		
	// this is Tiger's bug.
	//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
	
	
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, keyCode, keyDown);
	CGEventPost(kCGHIDEventTap, event);
	CFRelease(event);
}


@end
