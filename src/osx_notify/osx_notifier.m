#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

#include "osx_notifier.h"
#include "values.h"

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

-(NSImage*)load_image:(ImageChoice)image_choice
{
	NSData *pngData;
	switch(image_choice) {
	case Machine:
		pngData = [NSData dataWithBytesNoCopy:machine_png
									   length:machine_png_len
								 freeWhenDone:NO];
		break;
	case Internet:
		pngData = [NSData dataWithBytesNoCopy:internet_png
									   length:internet_png_len
								 freeWhenDone:NO];
		break;
	}
	return [[NSImage alloc] initWithData:pngData];
}

-(void)do_notification : (NSString*)message
{
	NSUserNotification *notification = [[NSUserNotification alloc] init];
	[notification setTitle:@"Your Title!"];
	[notification setContentImage:[self load_image:Machine]];
	[notification setInformativeText:message];
	[notification setSoundName:NSUserNotificationDefaultSoundName];
	NSUserNotificationCenter *center =
		[NSUserNotificationCenter defaultUserNotificationCenter];
	[notification setValue:[self load_image:Internet]
					forKey:@"_identityImage"];
	center.delegate = self;
	[center deliverNotification:notification];
	[[NSSound soundNamed:@"Hero"] play];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
        didDeliverNotification:(NSUserNotification *)notification
{
	sleep(3);
	exit(SUCCESS);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification
{
	exit(CLICKED);
}

@end

void notify_start(char *message)
{
	if (install_bundle_hook()) {
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
	exit(BUNDLE_HOOK_FAILED);
}
