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

@interface SBIconView ()

@property (nonatomic, retain) UIView *indicatorView;

@new
- (void)updateIndicatorVisibility;

@end

@hook SBIconView
@synthesize indicatorView;

- (id)initWithDefaultSize {
	self = @orig();
	if (self) {
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

- (void)updateIndicatorVisibility {
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
	@orig();
	[self updateIndicatorVisibility];

	if ([self isInDock]) {
		_labelView.hidden = true;
	}else{
		_labelView.hidden = false;
	}
}

#pragma mark Touch Handling

#define super(...) ({ struct objc_super superInfo = { self, [UIView class] }; objc_msgSendSuper(&superInfo, _cmd, __VA_ARGS__); })

- (void)touchesEnded:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		@orig(arg1, arg2);
}
- (void)touchesMoved:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		@orig(arg1, arg2);
}
- (void)touchesBegan:(id)arg1 withEvent:(id)arg2{
	if ([self isInDock] && !self.isGrabbed)
		super(arg1, arg2);
	else
		@orig(arg1, arg2);
}
- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2{
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

	SBIcon *icon = [[[objc_getClass("SBIconController") sharedInstance] model] applicationIconForDisplayIdentifier:self.displayIdentifier];
	SBIconView *iconView = [[[[objc_getClass("SBIconController") sharedInstance] dockListView] viewMap] mappedIconViewForIcon:icon];

	[iconView updateIndicatorVisibility];

}

@end
