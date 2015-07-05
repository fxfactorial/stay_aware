#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#include "osx_notifier.h"
#include "values"


static NSString *fake_bundle_identifier;

@implementation NSBundle(swizzle)
-(NSString *)__bundleIdentifier
{
	if (self == [NSBundle mainBundle]) {
		return fake_bundle_identifier ? fake_bundle_identifier :
			@"com.apple.finder";
	} else
		return [self __bundleIdentifier];
}
@end

BOOL install_bundle_hook()
{
	Class b_class = objc_getClass("NSBundle");
	if (b_class) {
		SEL current = @selector(bundleIdentifier);
		Method m1 = class_getInstanceMethod(b_class, current);
		current = @selector(__bundleIdentifier);
		Method m2 = class_getInstanceMethod(b_class, current);
		method_exchangeImplementations(m1, m2);
		return YES;
	}
	return NO;
}

@interface OCamlNotifier ()
{
	NSString *_the_message;
}

@end

@implementation OCamlNotifier

-(instancetype)init_with_message:(NSString*)msg
{
	self = [super init];
	if (self) {
		_the_message = msg;
	}
	return self;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self do_notification:_the_message];
}

-(NSImage*)load_image
{
	NSData *pngData = [NSData dataWithBytesNoCopy:robot_jpg
										   length:robot_jpg_len
									 freeWhenDone:NO];
	return [[NSImage alloc] initWithData:pngData];
}


-(void)do_notification : (NSString*)message
{
	NSUserNotification *notification = [[NSUserNotification alloc] init];
	// [notification addObserver:self
	// 			   forKeyPath:@"presented"
	// 				  options:0
	// 				  context:NULL];
	[notification setTitle:message];
	[notification setContentImage:[self load_image]];
	[notification setInformativeText:@"I love PandaBar!"];
	[notification setSoundName:NSUserNotificationDefaultSoundName];
	NSUserNotificationCenter *center =
		[NSUserNotificationCenter defaultUserNotificationCenter];
	center.delegate = self;
	[center deliverNotification:notification];
	[[NSSound soundNamed:@"Hero"] play];
}

// -(void)observeValueForKeyPath:(NSString *)keyPath
// 					 ofObject:(id)object
// 					   change:(NSDictionary *)change
// 					  context:(void *)context
// {
// 	NSLog(@"Value changed!");
// }

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification
{
	NSLog(@"Something clicked?");
	// [[NSWorkspace sharedWorkspace]
	// 	openURL:[NSURL URLWithString:@"http://google.com"]];
	exit(1);
}

@end

void notify_start(char *message)
{
	// if (install_bundle_hook()) {
	// 	OCamlNotifier *carrier = [OCamlNotifier new];
	// 	NSString *wrapped = [NSString stringWithCString:message
	// 										   encoding:NSUTF8StringEncoding];
	// 	[carrier do_notification:wrapped];
	// }
	// else
	// 	NSLog(@"Error, wasn't able to do the bundle hook");
	install_bundle_hook();
	NSApplication *app = [NSApplication sharedApplication];
	// So Weird that if you don't have a handle on an object, then you get
	// this warning:  assigning retained object to unsafe property;
	// object will be released after assignment [-Warc-unsafe-retained-assign]
	// and it will seg fault
	NSString *wrapped = [NSString stringWithCString:message
										   encoding:NSUTF8StringEncoding];
	OCamlNotifier *app_delegate = [[OCamlNotifier alloc]
									  init_with_message:wrapped];
	app.delegate = app_delegate;
	[app run];
}
