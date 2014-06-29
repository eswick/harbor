export ARCHS = armv7 arm64
DEBUG = 1
TARGET=iphone:7.1

include theos/makefiles/common.mk

TWEAK_NAME = BubbleDock
BubbleDock_FILES += Tweak.xm SBIconView.xm
BubbleDock_FILES += extensions/UIView+Origin.m

ADDITIONAL_LDFLAGS += -Wl,-map,$@.map -g -x c /dev/null -x none

BubbleDock_CFLAGS += -Iinclude -Iextensions
BubbleDock_FRAMEWORKS += CoreGraphics UIKit
BubbleDock_PRIVATE_FRAMEWORKS += SpringBoardFoundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
