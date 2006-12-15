#import "KeyConfigWindow.h"

@implementation KeyConfigWindow

- (IBAction)cancel:(id)sender
{
	[NSApp endSheet:self returnCode:0];

}

- (IBAction)ok:(id)sender
{
	[NSApp endSheet:self returnCode:1];

}

- (void)setKeyTitle:(NSString*)title{
	[box setTitle:[NSString stringWithFormat:@"Button: \"%@\"", title]];
}


@end
