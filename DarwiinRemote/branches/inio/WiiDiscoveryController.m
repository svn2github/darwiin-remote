#import "WiiDiscoveryController.h"
#import "WiiRemoteController.h"

@implementation WiiDiscoveryController


- (void)awakeFromNib {
	idle = YES;
	wiimoteDiscovery =  [WiiRemoteDiscovery discoveryWithDelegate:self];
	[statusText setStringValue:@"Idle"];
	[activityIndicator setDisplayedWhenStopped:false];
	[activityIndicator stopAnimation:self];
	
	[self doConnectDisconnect:actionButton];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	return NSTerminateNow;
}

- (IBAction)doConnectDisconnect:(id)sender
{
	if (idle) {
		idle = NO;
		[wiimoteDiscovery start];
		[activityIndicator startAnimation:self];
		[statusText setStringValue:@"Searching..."];
		[actionButton setTitle:@"Stop"];
	} else {
		idle = YES;
		[wiimoteDiscovery stop];
		[activityIndicator stopAnimation:self];
		[statusText setStringValue:@"Idle"];
		[actionButton setTitle:@"Start"];
	}
}

- (void) WiiRemoteDiscovered:(WiiRemote*)w {
//	[statusText setStringValue:[NSString stringWithFormat:@"found %@", [w getAddress]]];
	[WiiRemoteController createForWiiRemote:w];
}

- (void) WiiRemoteDiscoveryError:(int)code {
	[statusText setStringValue:[NSString stringWithFormat:@"Error: %08X", code]];
	[wiimoteDiscovery stop];
	[activityIndicator stopAnimation:self];
	[actionButton setTitle:@"Error"];
	[actionButton setEnabled:NO];
}

@end
