export ARCHS = armv7 arm64

export TARGET_CXX = /Users/eswick/Development/llvm_build/Debug+Asserts/bin/clang

TARGET=iphone:8.1

include theos/makefiles/common.mk

TWEAK_NAME = Harbor

export VERSION=1.0.0
Harbor_CFLAGS += -DVERSION=\"$(VERSION)\"

Harbor_FILES += Tweak.m SBIconView.m CAKeyframeAnimation+dockBounce.m HBPreferences.m
Harbor_FILES += extensions/UIView+Origin.m

Harbor_CFLAGS += -Iinclude -Iextensions -fobjc-logos -Wno-objc-missing-super-calls

Harbor_FRAMEWORKS += CoreGraphics UIKit QuartzCore
Harbor_PRIVATE_FRAMEWORKS += SpringBoardFoundation


include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += harborprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
