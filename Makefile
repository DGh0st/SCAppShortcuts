export ARCHS = armv7 arm64
export TARGET = iphone:clang:9.3:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SCAppShortcuts
SCAppShortcuts_FILES = Tweak.xm
SCAppShortcuts_FRAMEWORKS = UIKit QuartzCore CoreGraphics
SCAppShortcuts_PRIVATE_FRAMEWORKS = Preferences
SCAppShortcuts_LIBRARIES = applist SwitcherControls

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += scappshortcuts
include $(THEOS_MAKE_PATH)/aggregate.mk
