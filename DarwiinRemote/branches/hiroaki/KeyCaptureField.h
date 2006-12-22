/* KeyCaptureField */

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>


@interface KeyCaptureField : NSTextField
{
	NSDictionary* keyCodes;
	NSNumber* keyCode;
	IBOutlet id observer;
}





@end
