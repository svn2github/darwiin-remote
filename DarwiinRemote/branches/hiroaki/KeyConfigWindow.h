/* KeyConfigWindow */

#import <Cocoa/Cocoa.h>
#import "KeyCaptureField.h"
@interface KeyConfigWindow : NSWindow
{
    IBOutlet NSBox *box;
    IBOutlet NSButton *command;
    IBOutlet NSButton *control;
    IBOutlet KeyCaptureField *keyField;
    IBOutlet NSButton *option;
    IBOutlet NSButton *shift;
    IBOutlet NSPopUpButton *type;
}
- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;

- (void)setKeyTitle:(NSString*)title;
@end
