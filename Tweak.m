#import <objc/runtime.h>

#import "UIView+Origin.h"

#import "SBIconListModel.h"
#import "SBDockIconListView.h"
#import "SBIconView.h"
#import "SBIconViewMap.h"
#import "SBIconController.h"
#import "SBIcon.h"
#import "SBScaleIconZoomAnimator.h"
#import "SBWallpaperEffectView.h"
#import "SBUIAnimationZoomUpAppFromHome.h"
#import "SBIconFadeAnimator.h"
#import "SBDockView.h"
#import "SBRootFolderView.h"
#import "SBRootFolderController.h"
#import "CDStructures.h"

#import "HBPreferences.h"

#import <mach_verify/mach_verify.h>

#pragma mark Declarations

#define UIApp ([UIApplication sharedApplication])

#define cur_orientation ([UIApp statusBarOrientation])
#define in_landscape (UIInterfaceOrientationIsLandscape(cur_orientation))

#define icon_animation_duration 0.5

@interface SBRootFolderView ()

@new
- (void)orientationChanged:(NSNotification*)arg1;

@end

@interface SBDockIconListView ()

@property (nonatomic, assign) CGFloat focusPoint;
@property (nonatomic, assign) BOOL trackingTouch;
@property (nonatomic, assign) BOOL appLaunching;
@property (nonatomic, assign) SBIconView *activatingIcon;

@property (nonatomic, assign) CGFloat maxTranslationX;
@property (nonatomic, assign) CGFloat xTranslationDamper;

@property (nonatomic, retain) UIView *indicatorView;
@property (nonatomic, assign) UILabel *indicatorLabel;
@property (nonatomic, assign) SBIconView *focusedIconView;

@new
- (CGFloat)horizontalIconBounds;
- (CGFloat)collapsedIconScale;
- (CGFloat)collapsedIconWidth;
- (CGFloat)scaleForOffsetFromFocusPoint:(CGFloat)offset;
- (CGFloat)yTranslationForOffsetFromFocusPoint:(CGFloat)offset;
- (CGFloat)xTranslationForOffsetFromFocusPoint:(CGFloat)offset;
- (CGFloat)iconCenterY;
- (NSUInteger)columnAtX:(CGFloat)x;

- (void)updateIconTransforms;
- (void)collapseAnimated:(BOOL)animated;
- (void)updateIndicatorForIconView:(SBIconView*)iconView animated:(BOOL)animated;

@end

@interface SBDockView ()

@new
- (void)layoutBackgroundView;

@end

#pragma mark Constants

static const CGFloat kCancelGestureRange = 10.0;

static const CGFloat kMaxScale = 1.0;

#pragma mark -

@hook SBDockIconListView

@synthesize focusPoint;
@synthesize trackingTouch;
@synthesize appLaunching;
@synthesize activatingIcon;

@synthesize maxTranslationX;
@synthesize xTranslationDamper;

@synthesize indicatorView;
@synthesize indicatorLabel;
@synthesize focusedIconView;

+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1{
	if (![[prefs getenabled] boolValue])
		return @orig(arg1);
	return 100;
}

- (id)initWithModel:(id)arg1 orientation:(NSInteger)arg2 viewMap:(id)arg3 {
	VERIFY_START(initWithModel_orientation_viewMap);
	self = @orig(arg1, arg2, arg3);
	if (self) {

		self.trackingTouch = false;

		// Set up indicator view
		self.indicatorView = [[UIView alloc] init];

		self.indicatorView.clipsToBounds = true;
		self.indicatorView.layer.cornerRadius = 5;

		// Add background view
		SBWallpaperEffectView *indicatorBackgroundView = [[objc_getClass("SBWallpaperEffectView") alloc] initWithWallpaperVariant:1];
		indicatorBackgroundView.style = 11;
		indicatorBackgroundView.translatesAutoresizingMaskIntoConstraints = false;

		[self.indicatorView addSubview:indicatorBackgroundView];
		[indicatorBackgroundView release];

		// Set up label
		UILabel *indicatorLabel = [[UILabel alloc] init];
		indicatorLabel.font = [UIFont systemFontOfSize:14];
		indicatorLabel.textColor = [UIColor whiteColor];
		indicatorLabel.textAlignment = NSTextAlignmentCenter;
		[self.indicatorView addSubview:indicatorLabel];
		self.indicatorLabel = indicatorLabel;

		[indicatorLabel release];

		// Setup constraints
		NSMutableArray *constraints = [NSMutableArray new];

		[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[v]-0-|" options:0 metrics:nil views: @{ @"v" : indicatorBackgroundView }]];
		[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[v]-0-|" options:0 metrics:nil views: @{ @"v" : indicatorBackgroundView }]];
		[self.indicatorView addConstraints:constraints];

		[constraints release];

		// -

		[self addSubview:self.indicatorView];
		[self.indicatorView release];

	}

	VERIFY_STOP(initWithModel_orientation_viewMap);

	return self;
}

#pragma mark Layout


- (CGFloat)horizontalIconBounds {
	return (in_landscape ? self.bounds.size.height : self.bounds.size.width) - [[prefs geticonInset] floatValue] * 2;
}


- (CGFloat)collapsedIconScale {
	CGFloat normalIconSize = [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;

	CGFloat newIconSize = [self horizontalIconBounds] / self.model.numberOfIcons;

	if (self.model.numberOfIcons == 0) {
		return 1;
	}

	return MIN(newIconSize / normalIconSize, 1);
}


- (CGFloat)collapsedIconWidth {
	return [self collapsedIconScale] * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;
}


- (CGFloat)scaleForOffsetFromFocusPoint:(CGFloat)offset {

	if (fabs(offset) > [[prefs geteffectiveRange] doubleValue])
		return [self collapsedIconScale];

	return MAX((cos(offset / (([[prefs geteffectiveRange] doubleValue]) / M_PI)) + 1.0) / (1.0 / ((kMaxScale - [self collapsedIconScale]) / 2.0)) + [self collapsedIconScale], [self collapsedIconScale]);
}


- (CGFloat)xTranslationForOffsetFromFocusPoint:(CGFloat)offset {

	if (self.xTranslationDamper == 0)
		self.xTranslationDamper = 1;

	return -(atan(offset / (self.xTranslationDamper * (M_PI / 4))) * ((self.maxTranslationX) / (M_PI / 2)));
}


- (CGFloat)yTranslationForOffsetFromFocusPoint:(CGFloat)offset {

	if (fabs(offset) > [[prefs geteffectiveRange] doubleValue])
		return 0;

	return -((cos(offset / (([[prefs geteffectiveRange] doubleValue]) / M_PI)) + 1.0) / (1.0 / ([[prefs getevasionDistance] doubleValue] / 2.0)));
}

- (void)updateEditingStateAnimated:(BOOL)arg1 {
	VERIFY_START(updateEditingStateAnimated);
	@orig(arg1);
	if (![[prefs getenabled] boolValue])
		return;
	[self layoutIconsIfNeeded:0.0 domino:false];
	VERIFY_STOP(updateEditingStateAnimated);
}

- (CGFloat)iconCenterY {

	if ([[prefs getflushWithBottom] boolValue]) {
		return (in_landscape ? self.bounds.size.width : self.bounds.size.height) - [self collapsedIconWidth] / 2 - 10.0;
	} else {
		return (in_landscape ? self.bounds.size.width : self.bounds.size.height) / 2;
	}

}

- (void)layoutIconsIfNeeded:(NSTimeInterval)animationDuration domino:(BOOL)arg2 {

	if (self.appLaunching)
		return;

	if (![[prefs getenabled] boolValue]) {
		@orig(animationDuration, arg2);
		return;
	}

	CGFloat defaultWidth = [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;

	self.xTranslationDamper = acos(([[prefs geteffectiveRange] doubleValue] * [self collapsedIconScale]) / ([[prefs geteffectiveRange] doubleValue] / 2) - 1) * ([[prefs geteffectiveRange] doubleValue] / M_PI);
	self.maxTranslationX = 0;

	// Calculate total X translation

	int iconsInRange = (int)floor([[prefs geteffectiveRange] doubleValue] / [self collapsedIconWidth]);
	float offset = 0;

	for (int i = 0; i < 2; i++) {
		// Run twice, once for left side of focus, and one for right side of focus

		for (int i = 0; i < iconsInRange; i++) {
			self.maxTranslationX += ([self scaleForOffsetFromFocusPoint:offset] * defaultWidth) - [self collapsedIconWidth];
			offset += [self collapsedIconWidth];
		}

		offset = [self collapsedIconWidth]; // Set to collapsed icon width, so we skip the center icon on the second run
	}

	CGFloat xOffset = MAX(([self horizontalIconBounds] - self.model.numberOfIcons * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width) / 2, 0);

	[UIView animateWithDuration:animationDuration animations:^{

		for (int i = 0; i < self.model.numberOfIcons; i++) {

			SBIcon *icon = self.model.icons[i];
			SBIconView *iconView = [self.viewMap mappedIconViewForIcon:icon];

			[self sendSubviewToBack:iconView];

			iconView.location = [self iconLocation];

			CGPoint center = CGPointZero;

			if (!in_landscape) {
				center.x = xOffset + ([self collapsedIconWidth] * i) + ([self collapsedIconWidth] / 2) + (self.bounds.size.width - [self horizontalIconBounds]) / 2;
				center.y = [self iconCenterY];
			} else {
				center.x = [self iconCenterY];
				center.y = xOffset + ([self collapsedIconWidth] * i) + ([self collapsedIconWidth] / 2) + (self.bounds.size.height - [self horizontalIconBounds]) / 2;
			}

			iconView.center = center;
		}

		if (self.activatingIcon) {
			self.focusPoint = in_landscape ? self.activatingIcon.center.y : self.activatingIcon.center.x;
		}

		[self updateIconTransforms];

		if ([self.superview isKindOfClass:objc_getClass("SBDockView")]) {
			[(SBDockView*)self.superview layoutBackgroundView];
		}
	}];

	if (self.activatingIcon) {
		[self bringSubviewToFront:self.activatingIcon];
	}

}


- (void)updateIconTransforms {

	for (int i = 0; i < self.model.numberOfIcons; i++) {
		SBIcon *icon = self.model.icons[i];
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:icon];

		const CGFloat offsetFromFocusPoint = self.focusPoint - (in_landscape ? iconView.center.y : iconView.center.x);


		CGFloat scale = [self collapsedIconScale];

		CGFloat tx = 0;
		CGFloat ty = 0;

		if (self.trackingTouch) {
			scale = [self scaleForOffsetFromFocusPoint:offsetFromFocusPoint];
			ty = [self yTranslationForOffsetFromFocusPoint:offsetFromFocusPoint];
			tx = [self xTranslationForOffsetFromFocusPoint:offsetFromFocusPoint];
		}

		CGPoint center = iconView.center;

		if (!in_landscape) {
			center.x += tx;
			center.y += ty;
		} else {
			center.x += ty;
			center.y += tx;
		}

		iconView.center = center;

		iconView.transform = CGAffineTransformMakeScale(scale, scale);

	}

}


- (void)updateIndicatorForIconView:(SBIconView*)iconView animated:(BOOL)animated {

	VERIFY_START(updateIndicatorForIconView_animated);

	if (![[prefs getshowIndicator] boolValue]) {
		self.indicatorView.hidden = true;
		return;
	}

	if (!iconView) {

		if (animated) {
			[UIView animateWithDuration:0.2 animations:^{
				self.indicatorView.alpha = 0;
			} completion:^(BOOL finished) {
				self.indicatorView.hidden = true;
				self.indicatorView.alpha = 1;
			}];
		}else{
			self.indicatorView.hidden = true;
		}

		return;
	}else{
		if (animated && self.indicatorView.hidden) {
			self.indicatorView.alpha = 0;
			self.indicatorView.hidden = false;

			[UIView animateWithDuration:0.2 animations:^{
				self.indicatorView.alpha = 1;
			} completion:nil];
		}else{
			self.indicatorView.hidden = false;
		}
	}

	void (^animations) (void) = ^{

		NSString *text = iconView.icon.displayName;
		CGRect textRect = [text boundingRectWithSize:[objc_getClass("SBIconView") maxLabelSize] options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14]} context:nil];

		self.indicatorView.bounds = CGRectMake(0, 0, textRect.size.width + 30, textRect.size.height + 30);

		if (!in_landscape) {
			self.indicatorView.center = CGPointMake(MAX(MIN(self.focusPoint, self.bounds.size.width - self.indicatorView.bounds.size.width / 2), self.indicatorView.bounds.size.width / 2), (self.bounds.size.height / 2) - [[prefs getevasionDistance] doubleValue] - self.indicatorView.bounds.size.height - 20.0);
		} else {
			self.indicatorView.center = CGPointMake((self.bounds.size.width / 2) - [[prefs getevasionDistance] doubleValue] - self.indicatorView.bounds.size.width, MAX(MIN(self.focusPoint, self.bounds.size.height - self.indicatorView.bounds.size.height / 2), self.indicatorView.bounds.size.height / 2));
		}

		self.indicatorLabel.text = text;
		self.indicatorLabel.bounds = textRect;
		self.indicatorLabel.center = CGPointMake(self.indicatorView.bounds.size.width / 2, self.indicatorView.bounds.size.height / 2);

	};

	if (animated)
		[UIView animateWithDuration:0.1 animations:animations completion:nil];
	else
		animations();

	VERIFY_STOP(updateIndicatorForIconView_animated);
}

#pragma mark Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

	VERIFY_START(touchesBegan_withEvent);

	self.trackingTouch = true;
	self.focusPoint = in_landscape ? [[touches anyObject] locationInView:self].y : [[touches anyObject] locationInView:self].x;
	self.activatingIcon = nil;

	[self layoutIconsIfNeeded:icon_animation_duration domino:false];

	// Update indicator
	SBIconView *focusedIcon = nil;

	@try {
		focusedIcon = [self.viewMap mappedIconViewForIcon:self.model.icons[[self columnAtX:self.focusPoint]]];
	}@catch (NSException *exception) { }

	[self updateIndicatorForIconView:focusedIcon animated:false];

	VERIFY_STOP(touchesBegan_withEvent);
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	SBIconView *iconView = nil;

	@try {
		iconView = [self.viewMap mappedIconViewForIcon:self.model.icons[[self columnAtX:self.focusPoint]]];
	} @catch (NSException *e) { }

	if ((in_landscape ? [[touches anyObject] locationInView:self].x : [[touches anyObject] locationInView:self].y) < 0 && ![[objc_getClass("SBIconController") sharedInstance] grabbedIcon] && iconView) {

		// get origin, remove transform, restore origin
		CGPoint origin = iconView.origin;
		iconView.transform = CGAffineTransformIdentity;
		iconView.origin = origin;

		// fix frame (somewhere along the way, the size gets set to zero. not exactly sure where)
		CGRect frame = iconView.frame;
		frame.size = [objc_getClass("SBIconView") defaultIconSize];
		iconView.frame = frame;

		// set grabbed and begin forwarding touches to icon
		[[objc_getClass("SBIconController") sharedInstance] setGrabbedIcon:iconView.icon];
		[iconView touchesBegan:touches withEvent:nil];
		[iconView longPressTimerFired];

		[[objc_getClass("SBIconController") sharedInstance] setIsEditing:true];

		[self updateIndicatorForIconView:nil animated:true];

		return;
	}

	if ([[objc_getClass("SBIconController") sharedInstance] grabbedIcon]) {
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:[[objc_getClass("SBIconController") sharedInstance] grabbedIcon]];
		[iconView touchesMoved:touches withEvent:nil];
		return;
	}

	self.focusPoint = in_landscape ? [[touches anyObject] locationInView:self].y : [[touches anyObject] locationInView:self].x;
	[self layoutIconsIfNeeded:0 domino:false];

	// Update indicator
	SBIconView *focusedIcon = nil;

	@try {
		focusedIcon = [self.viewMap mappedIconViewForIcon:self.model.icons[[self columnAtX:self.focusPoint]]];
	}@catch (NSException *exception) { }

	[self updateIndicatorForIconView:focusedIcon animated:true];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

	VERIFY_START(touchesEnded_withEvent);

	if ([[objc_getClass("SBIconController") sharedInstance] grabbedIcon]) {
		SBIconView *iconView = [self.viewMap mappedIconViewForIcon:[[objc_getClass("SBIconController") sharedInstance] grabbedIcon]];
		[iconView touchesEnded:touches withEvent:nil];
		return;
	}

	[self updateIndicatorForIconView:nil animated:true];


	if (in_landscape ?
		 ( [[touches anyObject] locationInView:self].x > self.bounds.size.width - kCancelGestureRange) :
		 ( [[touches anyObject] locationInView:self].y > self.bounds.size.height - kCancelGestureRange)) {
		// User swiped off to the bottom edge of the screen; collapse and do nothing
		[self collapseAnimated:true];
		return;
	}

	NSInteger index = [self columnAtX:self.focusPoint];

	SBIconView *iconView = nil;

	@try {
		iconView = [self.viewMap mappedIconViewForIcon:self.model.icons[index]];
	}@catch (NSException *e) {
		[self collapseAnimated:true];
		return;
	}

	[self bringSubviewToFront:iconView];

	self.activatingIcon = iconView;

	[self layoutIconsIfNeeded:icon_animation_duration domino:false];

	[[objc_getClass("SBIconController") sharedInstance] iconTapped:iconView];

	VERIFY_STOP(touchesEnded_withEvent);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {

	VERIFY_START(touchesCancelled_withEvent);

	self.trackingTouch = false;
	[self layoutIconsIfNeeded:0 domino:false];

	VERIFY_STOP(touchesCancelled_withEvent);
}

#pragma mark -


- (void)collapseAnimated:(BOOL)animated {

	VERIFY_START(collapseAnimated);

	self.trackingTouch = false;
	self.activatingIcon = nil;
	[self layoutIconsIfNeeded:animated ? icon_animation_duration : 0.0 domino:false];

	VERIFY_STOP(collapseAnimated);
}


- (NSUInteger)columnAtX:(CGFloat)x {
	return in_landscape ? [self rowAtPoint:CGPointMake(0, x)] : [self columnAtPoint:CGPointMake(x, 0)];
}

- (NSUInteger)columnAtPoint:(struct CGPoint)arg1 {
	if (in_landscape) {
		return 0;
	}

	CGFloat collapsedItemWidth = [self collapsedIconScale] * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;
	CGFloat xOffset = MAX(([self horizontalIconBounds] - self.model.numberOfIcons * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width) / 2, 0);

	NSUInteger index = floorf((arg1.x - (self.bounds.size.width - [self horizontalIconBounds]) / 2 - xOffset) / collapsedItemWidth);

	return index;
}

- (NSUInteger)rowAtPoint:(struct CGPoint)arg1 {
	if (!in_landscape) {
		return 0;
	}

	CGFloat collapsedItemWidth = [self collapsedIconScale] * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width;
	CGFloat xOffset = MAX(([self horizontalIconBounds] - self.model.numberOfIcons * [objc_getClass("SBIconView") defaultVisibleIconImageSize].width) / 2, 0);

	NSUInteger index = floorf((arg1.y - (self.bounds.size.height - [self horizontalIconBounds]) / 2 - xOffset) / collapsedItemWidth);

	return index;
}

- (void)removeIconAtIndex:(NSUInteger)arg1 {

	VERIFY_START(removeIconAtIndex);

	@orig(arg1);
	[self collapseAnimated:true];

	VERIFY_STOP(removeIconAtIndex);
}

@end

#pragma mark Animators

@hook SBIconFadeAnimator

- (void)_cleanupAnimation {

	VERIFY_START(_cleanupAnimation);

	@orig();
	if (![[prefs getenabled] boolValue])
		return;
	[[[objc_getClass("SBIconController") sharedInstance] dockListView] collapseAnimated:true];

	VERIFY_STOP(_cleanupAnimation);
}

@end

@hook SBUIAnimationZoomUpAppFromHome

- (void)prepareZoom {
	[[[objc_getClass("SBIconController") sharedInstance] dockListView] setAppLaunching:true];
	@orig();
}

- (void)cleanupZoom {
	[[[objc_getClass("SBIconController") sharedInstance] dockListView] setAppLaunching:false];
	@orig();
}

@end

@hook SBScaleIconZoomAnimator

- (void)enumerateIconsAndIconViewsWithHandler:(void (^) (id animator, SBIconView *iconView, BOOL inDock))arg1 {

	VERIFY_START(enumerateIconsAndIconViewsWithHandler);

	if (![[prefs getenabled] boolValue]) {
		@orig(arg1);
		return;
	}

	// Prevent this method from changing the origins and transforms of the dock icons

	NSMapTable *mapHolder = _dockIconToViewMap;
	_dockIconToViewMap = nil;

	@orig(arg1);

	_dockIconToViewMap = mapHolder;

	VERIFY_STOP(enumerateIconsAndIconViewsWithHandler);
}

- (void)_prepareAnimation {
	VERIFY_START(_prepareAnimation);

	if (![[prefs getenabled] boolValue]) {
		@orig();
		return;
	}

	// Focus dock on animation target icon

	SBDockIconListView *dockListView = [[objc_getClass("SBIconController") sharedInstance] dockListView];
	SBIconView *targetIconView = [dockListView.viewMap mappedIconViewForIcon:self.targetIcon];

	if ([targetIconView isInDock]) {
		dockListView.activatingIcon = targetIconView;
		dockListView.focusPoint = in_landscape ? targetIconView.center.y : targetIconView.center.x;
		dockListView.trackingTouch = true;
		[dockListView layoutIconsIfNeeded:0.0 domino:false];
	}

	@orig();

	VERIFY_STOP(_prepareAnimation);
}

- (void)_cleanupAnimation {
	VERIFY_START(_cleanupAnimation);

	@orig();
	if (![[prefs getenabled] boolValue])
		return;
	[self.dockListView collapseAnimated:true];

	VERIFY_STOP(_cleanupAnimation);
}

@end

@hook SBDockView

- (void)layoutSubviews {
	@orig();
	_highlightView.hidden = true;
	[self layoutBackgroundView];
}

- (void)layoutBackgroundView {

	UIView *firstIcon = [_iconListView.viewMap mappedIconViewForIcon:[_iconListView.model.icons firstObject]];
	UIView *lastIcon = [_iconListView.viewMap mappedIconViewForIcon:[_iconListView.model.icons lastObject]];

	if ([[_iconListView.model.icons lastObject] isKindOfClass:objc_getClass("SBPlaceholderIcon")]) {
		lastIcon = [_iconListView.viewMap mappedIconViewForIcon:_iconListView.model.icons[([_iconListView.model.icons count]) - 2]];
	}

	CGFloat backgroundMargin = 25.0;

	CGRect frame = CGRectZero;

	if (!in_landscape) {

		frame.size.width = (CGRectGetMaxX(lastIcon.frame) - CGRectGetMinX(firstIcon.frame)) + backgroundMargin;
		frame.size.height = [_iconListView collapsedIconWidth] + backgroundMargin;
		frame.origin.x = CGRectGetMinX(firstIcon.frame) - backgroundMargin / 2;
		frame.origin.y = ([_iconListView iconCenterY]) - (backgroundMargin / 2) - ([_iconListView collapsedIconWidth] / 2);

	} else {

		frame.size.width = [_iconListView collapsedIconWidth] + backgroundMargin;
		frame.size.height = (CGRectGetMaxY(lastIcon.frame) - CGRectGetMinY(firstIcon.frame)) + backgroundMargin;
		frame.origin.x = ([_iconListView iconCenterY]) - (backgroundMargin / 2) - ([_iconListView collapsedIconWidth] / 2);
		frame.origin.y = CGRectGetMinY(firstIcon.frame) - backgroundMargin / 2;

	}

	_backgroundView.layer.cornerRadius = 5.0;
	_backgroundView.frame = frame;

}

@end

@hook SBRootFolderView

- (id)initWithFolder:(id)arg1 orientation:(UIInterfaceOrientation)arg2 viewMap:(id)arg3 forSnapshot:(BOOL)arg4 {
	self = @orig(arg1, arg2, arg3, arg4);
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
	}
	return self;
}

- (void)orientationChanged:(NSNotification*)arg1 {
	for (UIView *view in [[[objc_getClass("SBIconController") sharedInstance] _rootFolderController] iconListViews]) {
		view.alpha = 1;
	}

	CGPoint contentOffset = [self.scrollView contentOffset];

	[self iconScrollView:self.scrollView willSetContentOffset:&contentOffset];
}

- (void)iconScrollView:(UIScrollView*)arg1 willSetContentOffset:(inout struct CGPoint *)arg2 {

	@orig(arg1, arg2);

	if (in_landscape) {
		int page = floor(arg2->x / arg1.frame.size.width);

		CGFloat opacity = (arg2->x / arg1.frame.size.width) - (CGFloat)page;

		UIView *nextPage = [[[objc_getClass("SBIconController") sharedInstance] _rootFolderController] iconListViewAtIndex:page + 1];

		nextPage.alpha = opacity;
	}
}


@end

@hook SBRootFolderController

- (BOOL)_shouldSlideDockOutDuringRotationFromOrientation:(UIInterfaceOrientation)arg1 toOrientation:(UIInterfaceOrientation)arg2 {
	return true; // Hides animation glitch. TODO: Make a proper fix for the glitch
}

@end
