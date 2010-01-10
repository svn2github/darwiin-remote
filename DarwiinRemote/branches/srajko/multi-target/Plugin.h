#import <WiiRemote/WiiRemote.h>


@protocol Plugin

- (void) accelerationChanged:(WiiAccelerationSensorType)type aX:(double)accX aY:(double)accY aZ:(double)accZ;
- (void) buttonChanged:(WiiButtonType)type isPressed:(BOOL)pressed;

@end
