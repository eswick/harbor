export ARCHS = armv7 arm64

export TARGET_CXX = /Users/eswick/Development/llvm_build/Debug+Asserts/bin/clang

TARGET=iphone:8.1

include theos/makefiles/common.mk

#INSTALL_LOCAL=1
#MAKE_SOURCE_DYLIB=1
#ENCRYPT=1

TWEAK_NAME = Harbor

export VERSION=1.0.0
Harbor_CFLAGS += -DVERSION=\"$(VERSION)\"

ifdef MAKE_SOURCE_DYLIB
Harbor_FILES += Tweak.m SBIconView.m CAKeyframeAnimation+dockBounce.m HBPreferences.m
Harbor_FILES += extensions/UIView+Origin.m

Harbor_CFLAGS += -Iinclude -Iextensions -fobjc-logos -Wno-objc-missing-super-calls -Wno-unused-function -mno-thumb

ifdef ENCRYPT
Harbor_CFLAGS += -DMACH_ENCRYPT -DMACH_VERIFY_UDID
endif

Harbor_FRAMEWORKS += CoreGraphics UIKit QuartzCore
Harbor_PRIVATE_FRAMEWORKS += SpringBoardFoundation
else
Harbor_FILES = Installer.xm
Harbor_CFLAGS += -Wno-deprecated-declarations
Harbor_FRAMEWORKS += UIKit
Harbor_LIBRARIES = MobileGestalt
endif


include $(THEOS_MAKE_PATH)/tweak.mk

ifdef INSTALL_LOCAL
ifdef ENCRYPT
after-Harbor-all::
	cp $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT) $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT).tmp
	rm $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)
	/Users/eswick/Development/mach_pwn/mach_pwn $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT).tmp -u edcc87b0f5f23ab5c8c45c2e78264b2a1007acfe -o $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)
	strip -u -r $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)
endif
endif

ifndef INSTALL_LOCAL
ifdef MAKE_SOURCE_DYLIB
after-Harbor-all::
	install_name_tool -id /var/mobile/Library/Preferences/com.eswick.harbor.license $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)
endif
endif

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += harborprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
