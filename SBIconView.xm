#import "SBIconView.h"
#import "SBIconController.h"
#import "SBApplication.h"
#import "SBApplicationIcon.h"
#import "SBIconModel.h"
#import "SBDockIconListView.h"
#import "SBIconViewMap.h"

@interface SBIconView ()

@property (nonatomic, retain) UIView *indicatorView;
- (void)updateIndicatorVisibility;

@end

%hook SBIconView

%property (nonatomic, retain) UIView *indicatorView;

- (id)initWithDefaultSize {
	self = %orig;
	if (self) {
		self.indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 5)];
		self.indicatorView.backgroundColor = [UIColor blackColor];
		self.indicatorView.clipsToBounds = true;
		self.indicatorView.layer.cornerRadius = self.indicatorView.bounds.size.width / 2;
		self.indicatorView.hidden = true;

		CGSize defaultSize = [%c(SBIconView) defaultIconImageSize];
		self.indicatorView.center = CGPointMake(defaultSize.width / 2, defaultSize.height + self.indicatorView.bounds.size.height);

		[self addSubview:self.indicatorView];
	}
	return self;
}

%new
- (void)updateIndicatorVisibility {
	BOOL applicationRunning = false;

	if ([self.icon isKindOfClass:%c(SBApplicationIcon)]) {
		SBApplicationIcon *icon = (SBApplicationIcon*)self.icon;
		if ([icon.application activationState] >= SBActivationStateActivated) {
			applicationRunning = true;
		}
	}

	self.indicatorView.hidden = (![self isInDock] || !applicationRunning);
}

- (void)layoutSubviews {
	%orig;
	[self updateIndicatorVisibility];
}

#pragma mark Touch Handling

#define super(...) ({ struct objc_super superInfo = { self, [UIView class] }; objc_msgSendSuper(&superInfo, _cmd, __VA_ARGS__); })

- (void)touchesEnded:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}
- (void)touchesMoved:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}
- (void)touchesBegan:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}
- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		%orig;
}

- (void)dealloc {
	[self.indicatorView release];
	%orig;
}

%end

// Status indicator

%hook SBApplication

- (void)_setActivationState:(int)arg1 {
	%orig;

	SBIcon *icon = [[[%c(SBIconController) sharedInstance] model] applicationIconForDisplayIdentifier:self.displayIdentifier];
	SBIconView *iconView = [[[[%c(SBIconController) sharedInstance] dockListView] viewMap] mappedIconViewForIcon:icon];

	[iconView updateIndicatorVisibility];

}

%end
