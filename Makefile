export ARCHS = armv7

export TARGET_CXX = /Users/eswick/Development/llvm_build/Debug+Asserts/bin/clang

TARGET=iphone:7.1

include theos/makefiles/common.mk

TWEAK_NAME = BubbleDock
BubbleDock_FILES += Tweak.m SBIconView.m HBPreferences.m
BubbleDock_FILES += extensions/UIView+Origin.m

BubbleDock_CFLAGS += -Iinclude -Iextensions -fobjc-logos -Wno-objc-missing-super-calls
BubbleDock_FRAMEWORKS += CoreGraphics UIKit
BubbleDock_PRIVATE_FRAMEWORKS += SpringBoardFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += harborprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
