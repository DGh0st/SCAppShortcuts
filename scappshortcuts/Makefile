include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SCAppShortcuts
SCAppShortcuts_FILES = SCARootListController.m
SCAppShortcuts_INSTALL_PATH = /Library/PreferenceBundles
SCAppShortcuts_FRAMEWORKS = UIKit MessageUI
SCAppShortcuts_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SCAppShortcuts.plist$(ECHO_END)
