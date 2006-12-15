#import "KeyCaptureField.h"

@implementation KeyCaptureField





- (void)awakeFromNib{
	
	keyCodes = [[NSDictionary alloc] initWithObjectsAndKeys:
		@"Space", [NSNumber numberWithInt:49],
		@"Return", [NSNumber numberWithInt:36],
		@"Enter", [NSNumber numberWithInt:76],
		@"Delete", [NSNumber numberWithInt:117],
		@"Tab", [NSNumber numberWithInt:48],
		@"Escape", [NSNumber numberWithInt:53],
		@"Num Lock", [NSNumber numberWithInt:71],
		@"Scroll Lock", [NSNumber numberWithInt:107],
		@"Print Screen", [NSNumber numberWithInt:105],
		@"Pause", [NSNumber numberWithInt:113],
		@"Back Space", [NSNumber numberWithInt:51],
		@"Insert", [NSNumber numberWithInt:114],

		@"Up", [NSNumber numberWithInt:126],
		@"Down", [NSNumber numberWithInt:125],
		@"Left", [NSNumber numberWithInt:123],
		@"Right", [NSNumber numberWithInt:124],
		@"Page Up", [NSNumber numberWithInt:116],
		@"Page Down", [NSNumber numberWithInt:121],
		@"Home", [NSNumber numberWithInt:115],
		@"End", [NSNumber numberWithInt:119],
		
		@"F1", [NSNumber numberWithInt:122],
		@"F2", [NSNumber numberWithInt:120],
		@"F3", [NSNumber numberWithInt:99],
		@"F4", [NSNumber numberWithInt:118],
		@"F5", [NSNumber numberWithInt:96],
		@"F6", [NSNumber numberWithInt:97],
		@"F7", [NSNumber numberWithInt:98],
		@"F8", [NSNumber numberWithInt:100],
		@"F9", [NSNumber numberWithInt:101],
		@"F10", [NSNumber numberWithInt:109],
		@"F11", [NSNumber numberWithInt:103],
		@"F12", [NSNumber numberWithInt:111],
		
		nil];

	[self setNextResponder:nil];	
}

- (BOOL)acceptsFirstResponder{
	return YES;
}
- (BOOL)becomeFirstResponder{
	return YES;
}
- (BOOL)resignFirstResponder{
	return YES;
}


- (void)keyDown:(NSEvent*)event{
}

- (void)keyUp:(NSEvent*)event{
	[super keyUp:event];
	
	
	if (![keyCodes objectForKey:[NSNumber numberWithInt:[event keyCode]]]){
		[self setStringValue:@""];
		
		CFRelease(CGEventCreate(NULL));		
		// this is Tiger's bug.
		//see also: http://www.cocoabuilder.com/archive/message/cocoa/2006/10/4/172206
		
		
		CGEventRef event2 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)[event keyCode], true);
		CGEventPost(kCGHIDEventTap, event2);
		CFRelease(event2);
		
		event2 = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)[event keyCode], false);
		CGEventPost(kCGHIDEventTap, event2);
		CFRelease(event2);
		
		
	}else{
		[self setStringValue:[keyCodes objectForKey:[NSNumber numberWithInt:[event keyCode]]]];
	}
	
	keyCode = [event keyCode];
	character = [self stringValue];
}

- (CGKeyCode)keyCode{
	return keyCode;
}

- (NSString*)characterName{
	return character;
}

@end
