#import "AppController.h"


@implementation AppController

- (IBAction)setForceFeedbackEnabled:(id)sender
{
	[wii setForceFeedbackEnabled:[sender state]];
}

- (IBAction)setIRSensorEnabled:(id)sender
{
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

-(void)awakeFromNib{
	sendMouseEvent = NO;
	wii = [[WiiRemote alloc] init];
	[wii setDelegate:self];
	[drawer open];
	[textView setString:@"Please press 1 button and 2 button simultaneously"];
	point.x = 0;
	point.y = 0;
}



//delegats implementation

- (void) wiiRemoteInquiryComplete:(BOOL)isFound{
	if (isFound){
		[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemote is found! =====", [textView string]]];
		if (![wii connect]){
			[textView setString:[NSString stringWithFormat:@"%@\n===== could not connect to the WiiRemote...... =====", [textView string]]];
			[wii release];
			wii = [[WiiRemote alloc] init];
			[wii setDelegate:self];
			return;
		}
		[graphView startTimer];
	}else{
		[textView setString:[NSString stringWithFormat:@"%@\n===== WiiRemote could not be found. Retrying... =====", [textView string]]];
		[wii release];
		wii = [[WiiRemote alloc] init];
		[wii setDelegate:self];
	}
}



- (void) dataChanged:(short)buttonData accX:(unsigned char)accX accY:(unsigned char)accY accZ:(unsigned char)accZ{

	[graphView setData:accX y:accY z:accZ];
	
	//calibration...
	double x0 = (126 + 127) / 2.0;
	double y0 = (128 + 128) / 2.0;
	double z0 = (128 + 129) / 2.0;
	double ax = (double)(accX - x0) / (154 - x0);
	double ay = (double)(accY - y0) / (154 - y0);
	//double az = (double)(accZ - z0) / (154 - z0);

	
	double roll = atan(ax) * 180.0 / 3.14 * 2;
	double pitch = atan(ay) * 180.0 / 3.14 * 2;
	
	

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

	
	int dispWidth = CGDisplayPixelsWide(kCGDirectMainDisplay);
	if (point.x > dispWidth)
		point.x = dispWidth - 1;
	
	int dispHeight = CGDisplayPixelsHigh(kCGDirectMainDisplay);
	if (point.y > dispHeight)
		point.y = dispHeight - 1;
		
	
	if ((buttonData & kWiiRemoteAButton)){
		[aButton setEnabled:YES];
		
		if (!isPressedAButton){
			isPressedAButton = YES;
			if (sendMouseEvent)
				CGPostMouseEvent(point, TRUE, 1, TRUE);
		}else{
			if (sendMouseEvent)	//dragging...
				CGPostMouseEvent(point, TRUE, 1, TRUE);
		}
	}else{
		
		[aButton setEnabled:NO];
		if (sendMouseEvent)
			CGPostMouseEvent(point, TRUE, 1, FALSE);
		
		if (isPressedAButton){
			isPressedAButton = NO;
		}
	}

	
	if ((buttonData & kWiiRemoteBButton)){
		[bButton setEnabled:YES];
		if (!isPressedBButton){
			isPressedBButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)36, true);
		}
	}else{
		[bButton setEnabled:NO];
		
		if (isPressedBButton){
			isPressedBButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)36, false);
		}
	}
	
	if ((buttonData & kWiiRemoteUpButton)){
		[upButton setEnabled:YES];
		
		if (!isPressedUpButton){
			isPressedUpButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)126, true);
		}
		
	}else{
		[upButton setEnabled:NO];
		
		if (isPressedUpButton){
			isPressedUpButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)126, false);
		}
	}
	
	if ((buttonData & kWiiRemoteDownButton)){
		[downButton setEnabled:YES];
		
		if (!isPressedDownButton){
			isPressedDownButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)125, true);
		}
		
	}else{
		[downButton setEnabled:NO];
		
		if (isPressedDownButton){
			isPressedDownButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)125, false);
		}
	}
	
	if ((buttonData & kWiiRemoteLeftButton)){
		[leftButton setEnabled:YES];
		
		if (!isPressedLeftButton){
			isPressedLeftButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)123, true);
		}
		
	}else{
		[leftButton setEnabled:NO];
		
		if (isPressedLeftButton){
			isPressedLeftButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)123, false);
		}
	}
	
	if ((buttonData & kWiiRemoteRightButton)){
		[rightButton setEnabled:YES];
		
		if (!isPressedRightButton){
			isPressedRightButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)124, true);
		}
		
	}else{
		[rightButton setEnabled:NO];
		
		if (isPressedRightButton){
			isPressedRightButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)124, false);
		}
		
	}
	
	if ((buttonData & kWiiRemoteMinusButton)){
		[minusButton setEnabled:YES];
		
		if (!isPressedMinusButton){
			isPressedMinusButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, true);
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)125, true);
		}
	}else{
		[minusButton setEnabled:NO];
		
		if (isPressedMinusButton){
			isPressedMinusButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, false);
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)125, false);
		}
	}
	
	if ((buttonData & kWiiRemotePlusButton)){
		[plusButton setEnabled:YES];
		
		if (!isPressedPlusButton){
			isPressedPlusButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, true);
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)126, true);
		}
		
	}else{
		[plusButton setEnabled:NO];
		
		if (isPressedPlusButton){
			isPressedPlusButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)56, false);
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)126, false);
		}
		
	}
	
	if ((buttonData & kWiiRemoteHomeButton)){
		[homeButton setEnabled:YES];
		
		if (!isPressedHomeButton){
			isPressedHomeButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)55, true);
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)53, true);
		}
		
	}else{
		[homeButton setEnabled:NO];
		
		if (isPressedHomeButton){
			isPressedHomeButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)53, false);
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)55, false);
		}
	}
	
	if ((buttonData & kWiiRemoteOneButton)){
		[oneButton setEnabled:YES];
		
		if (!isPressedOneButton){
			isPressedOneButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)116, true);
		}
		
	}else{
		[oneButton setEnabled:NO];
		
		if (isPressedOneButton){
			isPressedOneButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)116, false);

		}
	}
	
	if ((buttonData & kWiiRemoteTwoButton)){
		[twoButton setEnabled:YES];
		
		
		if (!isPressedTwoButton){
			isPressedTwoButton = YES;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)121, true);
		}
	}else{
		[twoButton setEnabled:NO];
		
		if (isPressedTwoButton){
			isPressedTwoButton = NO;
			CGPostKeyboardEvent((CGCharCode)0, (CGKeyCode)121, false);
		}
	}
	
}





- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
	[graphView stopTimer];
	[wii close];
	return NSTerminateNow;
}


@end
