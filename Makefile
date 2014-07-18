export ARCHS = armv7

export TARGET_CXX = /Users/eswick/Development/clang-logos/build/bin/clang
export TARGET_STRIP = echo

TARGET=iphone:7.1

include theos/makefiles/common.mk

TWEAK_NAME = BubbleDock
BubbleDock_FILES += Tweak.m SBIconView.m
BubbleDock_FILES += extensions/UIView+Origin.m

BubbleDock_CFLAGS += -Iinclude -Iextensions -fobjc-logos -Wno-objc-missing-super-calls
BubbleDock_FRAMEWORKS += CoreGraphics UIKit
BubbleDock_PRIVATE_FRAMEWORKS += SpringBoardFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
