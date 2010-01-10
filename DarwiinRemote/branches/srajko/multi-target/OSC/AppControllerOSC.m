#import "AppController.h"
#import "OSCController.h"

@implementation AppController (OSC)

- (void) loadPlugins
{
	OSCController *OSC = [[OSCController alloc] init];

	NSAssert([NSBundle loadNibNamed:@"OSC" owner:OSC], @"Cannot load OSC.xib file!");

	[pluginArray addObject:OSC];

	[OSC release];
}

@end
