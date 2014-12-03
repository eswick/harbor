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

#import "HBPreferences.h"

@interface SBIconView ()

@property (nonatomic, retain) UIView *indicatorView;

@new
- (void)updateIndicatorVisibility;

@end

@hook SBIconView
@synthesize indicatorView;

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

// Status indicator

@hook SBApplication

- (void)_setActivationState:(int)arg1 {
	@orig(arg1);

	SBIcon *icon = [[[objc_getClass("SBIconController") sharedInstance] model] applicationIconForBundleIdentifier:self.bundleIdentifier];
	SBIconView *iconView = [[[[objc_getClass("SBIconController") sharedInstance] dockListView] viewMap] mappedIconViewForIcon:icon];

	[iconView updateIndicatorVisibility];

}

@end
