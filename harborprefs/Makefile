include theos/makefiles/common.mk


BUNDLE_NAME = harborprefs

export VERSION=1.0.0
harborprefs_CFLAGS += -DVERSION=\"$(VERSION)\"

harborprefs_FILES += harborprefs.xm ../HBPreferences.m
harborprefs_INSTALL_PATH = /Library/PreferenceBundles
harborprefs_FRAMEWORKS += UIKit
harborprefs_CFLAGS += -I.. -Wno-deprecated-declarations
harborprefs_LIBRARIES += substrate MobileGestalt

ifndef SIMULATOR
harborprefs_PRIVATE_FRAMEWORKS += Preferences
else
harborprefs_LDFLAGS += -undefined dynamic_lookup
endif

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/harborprefs.plist$(ECHO_END)
