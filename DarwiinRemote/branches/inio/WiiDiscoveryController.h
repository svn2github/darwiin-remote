/* WiiDiscoveryController */

#import <Cocoa/Cocoa.h>
#import "WiiRemoteDiscovery.h"

@interface WiiDiscoveryController : NSObject
{
    BOOL idle;
	
	IBOutlet NSButton *actionButton;
    IBOutlet NSProgressIndicator *activityIndicator;
    IBOutlet NSTextField *statusText;
	WiiRemoteDiscovery* wiimoteDiscovery;
}

- (IBAction)doConnectDisconnect:(id)sender;
@end
