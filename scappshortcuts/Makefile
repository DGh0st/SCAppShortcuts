export ARCHS = armv7 arm64
export TARGET = iphone:clang:8.1:latest

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SCAppShortcuts
SCAppShortcuts_FILES = SCARootListController.m
SCAppShortcuts_INSTALL_PATH = /Library/PreferenceBundles
SCAppShortcuts_FRAMEWORKS = UIKit MessageUI
SCAppShortcuts_PRIVATE_FRAMEWORKS = Preferences
SCAppShortcuts_LIBRARIES = applist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SCAppShortcuts.plist$(ECHO_END)
