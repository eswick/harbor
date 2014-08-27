#import <Preferences/Preferences.h>
#import "HBPreferences.h"

NSArray* SpecifiersFromPlist (
        NSDictionary*     plist,      // r0
        PSSpecifier*      prevSpec,   // r1
        id                target,     // r2
        NSString*         plistName,  // r3
        NSBundle*         curBundle,           // sp[0x124]
        NSString**        pTitle,              // sp[0x128]
        NSString**        pSpecifierID,        // sp[0x12C]
        PSListController* callerList,          // sp[0x130]
        NSMutableArray**  pBundleControllers   // sp[0x134]
);

#define RESPRING_ALERT 1

@interface HPListController: PSListController

@end

@implementation HPListController

#define PREF(TYPE, NAME, DEFAULT, LABEL, CELL_TYPE, ...) \
- (TYPE)get##NAME:(PSSpecifier*)specifier { \
	return [[HBPreferences sharedInstance] get##NAME]; \
} \
- (void)set##NAME:(TYPE)newValue forSpecifier:(PSSpecifier*)specifier { \
	[[HBPreferences sharedInstance] set##NAME:newValue]; \
}

#include "Preferences.def"

- (id)specifiers {

	if (_specifiers == nil) {

		NSDictionary *plist = @{
      @"title" : @"Harbor",
			@"items" : @[

				#define GROUP(TITLE, FOOTER) @{ \
					@"cell" : @"PSGroupCell", \
					@"label" : @(TITLE), \
					@"footerText" : @(FOOTER) \
				},

				#define PREF(TYPE, NAME, DEFAULT, LABEL, CELL_TYPE, ...) @{ \
					@"cell" : @#CELL_TYPE, \
					@"label" : LABEL, \
					@"get" : @("get" #NAME ":"), \
					@"set" : @("set" #NAME ":forSpecifier:"), \
					__VA_ARGS__ \
				},

				#include "Preferences.def"
			]
		};

		NSString *specifierID = nil;
		NSString *title = nil;
		_specifiers = [SpecifiersFromPlist(plist, _specifier, self, @"harborprefs", [self bundle], &title, &specifierID, self, &_bundleControllers) retain];

		if (title)
			[self setTitle:title];

		if (specifierID)
			[self setSpecifierID:specifierID];
	}

	return _specifiers;
}

- (void)showRespringPrompt{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Respring" message:@"The device will now respring." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	alert.tag = RESPRING_ALERT;
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == RESPRING_ALERT) {
		if (buttonIndex == 1) {
			[[HBPreferences sharedInstance] setenabled:@(![[self getenabled:nil] boolValue])];
			system("killall -9 backboardd");
		} else {
			[self reloadSpecifiers];
		}
	}
}

@end

@hook HPListController


- (void)setenabled:(NSNumber*)newValue forSpecifier:(PSSpecifier*)specifier {
	[self showRespringPrompt];
}

@end

// vim:ft=objc
