#import "OSCController.h"

#import <BBOSC/BBOSCMessage.h>
#import <BBOSC/BBOSCSender.h>
#import <BBOSC/BBOSCArgument.h>
#import <BBOSC/BBOSCAddress.h>

@implementation OSCController

- (id) init
{
    self = [super init];
    if (self != nil) {

        oscSender = [[BBOSCSender senderWithDestinationHostName:@"localhost" portNumber:4556] retain];

    }
    return self;
}

- (void) dealloc
{
	[oscSender release];

	[super dealloc];
}

- (void) accelerationChanged:(WiiAccelerationSensorType)type aX:(double)accX aY:(double)accY aZ:(double)accZ
{
    if(type != WiiRemoteAccelerationSensor)
        return;

    BBOSCMessage * newMessage = [BBOSCMessage messageWithBBOSCAddress:[BBOSCAddress addressWithString:@"/accelerometer"]];
	[newMessage attachArgument:[BBOSCArgument argumentWithInt:[idField intValue]]];
	[newMessage attachArgument:[BBOSCArgument argumentWithFloat:(float)accX]];
	[newMessage attachArgument:[BBOSCArgument argumentWithFloat:(float)accY]];
	[newMessage attachArgument:[BBOSCArgument argumentWithFloat:(float)accZ]];
    
    [oscSender sendOSCPacket:newMessage];
}

- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)pressed
{
    if(type > WiiRemoteRightButton)
        return;

    BBOSCMessage * newMessage = [BBOSCMessage messageWithBBOSCAddress:[BBOSCAddress addressWithString:@"/button"]];
	[newMessage attachArgument:[BBOSCArgument argumentWithInt:[idField intValue]]];
	[newMessage attachArgument:[BBOSCArgument argumentWithInt:type]];
	[newMessage attachArgument:[BBOSCArgument argumentWithInt:pressed]];
    
    [oscSender sendOSCPacket:newMessage];
}


@end
