#import <Cocoa/Cocoa.h>
#import "Plugin.h"

@class BBOSCSender;

@interface OSCController : NSObject<Plugin> {

	IBOutlet NSTextField *idField;

	BBOSCSender * oscSender;

}


@end
