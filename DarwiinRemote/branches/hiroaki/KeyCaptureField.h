/* KeyCaptureField */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>


@interface KeyCaptureField : NSTextField
{
	NSDictionary* keyCodes;
	CGKeyCode keyCode;
	NSString* character;
}

- (NSString*)characterName;
- (CGKeyCode)keyCode;



@end
