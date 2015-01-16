include theos/makefiles/common.mk


BUNDLE_NAME = harborprefs

export VERSION=0.8.2
harborprefs_CFLAGS += -DVERSION=\"$(VERSION)\"

harborprefs_FILES += harborprefs.m ../HBPreferences.m ../Installer.xm
harborprefs_INSTALL_PATH = /Library/PreferenceBundles
harborprefs_FRAMEWORKS += UIKit
harborprefs_PRIVATE_FRAMEWORKS += Preferences
harborprefs_CFLAGS += -I.. -fobjc-logos -Wno-deprecated-declarations
harborprefs_LIBRARIES += substrate

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/harborprefs.plist$(ECHO_END)
