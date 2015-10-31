export ARCHS = armv7 arm64

TARGET=iphone:9.0

include theos/makefiles/common.mk

TWEAK_NAME = Harbor

Harbor_FILES += Tweak.xm SBIconView.xm CAKeyframeAnimation+dockBounce.m HBPreferences.m
Harbor_FILES += extensions/UIView+Origin.m

Harbor_CFLAGS += -Iinclude -Iextensions

Harbor_FRAMEWORKS += CoreGraphics UIKit QuartzCore
Harbor_PRIVATE_FRAMEWORKS += SpringBoardFoundation


include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += harborprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
