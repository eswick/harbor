#import <objc/objc.h>
#import <objc/message.h>
#import "SBIconView.h"
#import "SBIconController.h"
#import "SBApplication.h"
#import "SBApplicationIcon.h"
#import "SBIconModel.h"
#import "SBDockIconListView.h"
#import "SBIconViewMap.h"
#import "SBIconLabelView.h"
#import "SBApplicationController.h"
#import "CAKeyframeAnimation+dockBounce.h"
#import "BBServer.h"
#import "BBBulletin.h"

#import "HBPreferences.h"

@interface SBIconView ()

@property (nonatomic, retain) UIView *indicatorView;
@property (nonatomic, retain) NSTimer *bounceTimer;
@property (nonatomic, assign) int bouncesRemaining;

@new
- (void)updateIndicatorVisibility;

- (void)bounce;
- (void)bounceTimerFired:(NSTimer*)timer;
- (void)startBouncing;
- (void)stopBouncing;
- (void)updateBouncingState;

@end

@interface SBApplication ()

@property (nonatomic, retain) NSDate *lastNotificationDate;
@property (nonatomic, retain) NSDate *lastLaunchDate;

@end

@interface SBIconController ()

/* TODO: Fix
 * This method does not actually exist, but is defined to avoid a compiler bug.
 * clang-logos is mistaking SBApplicationController for SBIconController.
 */
- (id)applicationWithBundleIdentifier:(id)id;

@end

@hook SBIconView
@synthesize indicatorView;
@synthesize bounceTimer;
@synthesize bouncesRemaining;

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
	if (![[prefs getenabled] boolValue])
		return @orig(point, event);

	if ([self isInDock])
		return nil;

	return @orig(point, event);
}

- (id)initWithDefaultSize {
	self = @orig();
	if (self && [[prefs getenabled] boolValue]) {

		self.indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
		self.indicatorView.backgroundColor = [UIColor blackColor];
		self.indicatorView.clipsToBounds = true;
		self.indicatorView.layer.cornerRadius = self.indicatorView.bounds.size.width / 2;
		self.indicatorView.hidden = true;

		CGSize defaultSize = [objc_getClass("SBIconView") defaultIconImageSize];
		self.indicatorView.center = CGPointMake(defaultSize.width / 2, defaultSize.height + self.indicatorView.bounds.size.height);

		[self addSubview:self.indicatorView];
	}
	return self;
}

- (void)bounce {
	CAKeyframeAnimation *animation = [CAKeyframeAnimation dockBounceAnimationWithIconHeight:[objc_getClass("SBIconView") defaultVisibleIconImageSize].height];
	[self.layer addAnimation:animation forKey:@"jumping"];
}

- (void)bounceTimerFired:(NSTimer*)timer {

	if (self.bouncesRemaining == 0) {
		[self stopBouncing];
		return;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		if ([self isInDock]) {
			[self bounce];
		}
	});

	if (self.bouncesRemaining != -1)
		self.bouncesRemaining--;
}

- (void)startBouncing {

	if (self.bounceTimer)
		[self stopBouncing];

	double bounceInterval = [[prefs getbounceInterval] floatValue];

	if (bounceInterval == 0) {
		return;
	} else if (bounceInterval < 0) {
		self.bouncesRemaining = (int)floor(-bounceInterval);
		bounceInterval = 2.0;
	} else {
		self.bouncesRemaining = -1.0;
	}

	self.bounceTimer = [NSTimer scheduledTimerWithTimeInterval:bounceInterval target:self selector:@selector(bounceTimerFired:) userInfo:nil repeats:true];

	[self.bounceTimer fire];

}

- (void)stopBouncing {
	if (self.bounceTimer) {
		[self.bounceTimer invalidate];
		self.bounceTimer = nil;
	}
}

- (void)updateBouncingState {

	if ([self.icon isKindOfClass:objc_getClass("SBApplicationIcon")]) {
		SBApplicationIcon *appIcon = (SBApplicationIcon*)self.icon;

		SBApplication *app = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:appIcon.applicationBundleID];

		if (!app.lastLaunchDate && app.lastNotificationDate) {
			[self startBouncing];
		} else if ([app.lastLaunchDate laterDate:app.lastNotificationDate] == app.lastNotificationDate) {
			[self startBouncing];
		} else {
			[self stopBouncing];
		}

	}
}

- (void)_updateCloseBoxAnimated:(BOOL)arg1 {
	if (![[prefs getenabled] boolValue]) {
		@orig(arg1);
		return;
	}

	if ([self isInDock] && [self isEditing])
		return;

	@orig(arg1);
}

- (void)updateIndicatorVisibility {

	if (![[prefs getenabled] boolValue])
		return;

	if (![[prefs getshowStateIndicator] boolValue]) {
		self.indicatorView.hidden = true;
		return;
	}

	BOOL applicationRunning = false;

	if ([self.icon isKindOfClass:objc_getClass("SBApplicationIcon")]) {
		SBApplicationIcon *icon = (SBApplicationIcon*)self.icon;
		if ([icon.application activationState] >= SBActivationStateActivated) {
			applicationRunning = true;
		}
	}

	self.indicatorView.hidden = (![self isInDock] || !applicationRunning);
}

- (void)layoutSubviews {
	if (![[prefs getenabled] boolValue]) {
		@orig();
		_labelView.hidden = false;
		self.indicatorView.hidden = true;
		return;
	}

	@orig();
	[self updateIndicatorVisibility];

	if ([self isInDock]) {
		_labelView.hidden = true;
	}else{
		_labelView.hidden = false;
	}
}

#pragma mark Touch Handling

#define super(...) ({ struct objc_super superInfo = { self, objc_getClass("UIView") }; ((void(*)(struct objc_super*,SEL,id,id))objc_msgSendSuper)(&superInfo, _cmd, __VA_ARGS__); })

- (void)touchesEnded:(id)arg1 withEvent:(id)arg2{
	if (![[prefs getenabled] boolValue]) {
		@orig(arg1, arg2);
		return;
	}

	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		@orig(arg1, arg2);
}

- (void)touchesMoved:(id)arg1 withEvent:(id)arg2{
	if (![[prefs getenabled] boolValue]) {
		@orig(arg1, arg2);
		return;
	}

	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		@orig(arg1, arg2);
}

- (void)touchesBegan:(id)arg1 withEvent:(id)arg2{
	if (![[prefs getenabled] boolValue]) {
		@orig(arg1, arg2);
		return;
	}

	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		@orig(arg1, arg2);
}

- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2{
	if (![[prefs getenabled] boolValue]) {
		@orig(arg1, arg2);
		return;
	}

	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		@orig(arg1, arg2);
}

@end

@hook BBServer

- (void)publishBulletin:(BBBulletin*)arg1 destinations:(unsigned int)arg2 alwaysToLockScreen:(BOOL)arg3 {

	SBApplicationIcon *icon = [[[objc_getClass("SBIconController") sharedInstance] model] applicationIconForBundleIdentifier:[arg1 sectionID]];
	SBIconView *iconView = [[[[objc_getClass("SBIconController") sharedInstance] dockListView] viewMap] mappedIconViewForIcon:icon];

	SBApplication *app = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:[arg1 sectionID]];

	app.lastNotificationDate = [NSDate date];

	if (iconView) {
		if ([iconView isInDock]) {

			dispatch_async(dispatch_get_main_queue(), ^{
				[iconView updateBouncingState];
			});

		}
	}

	@orig(arg1, arg2, arg3);
}

@end

@hook SBApplication
@synthesize lastNotificationDate;
@synthesize lastLaunchDate;

- (void)_setActivationState:(int)arg1 {
	@orig(arg1);

	SBIcon *icon = [[[objc_getClass("SBIconController") sharedInstance] model] applicationIconForBundleIdentifier:self.bundleIdentifier];
	SBIconView *iconView = [[[[objc_getClass("SBIconController") sharedInstance] dockListView] viewMap] mappedIconViewForIcon:icon];

	[iconView updateIndicatorVisibility];

	if (arg1 == SBActivationStateActivated) {
		self.lastLaunchDate = [NSDate date];
		[iconView updateBouncingState];
	}

}

@end
