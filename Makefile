include theos/makefiles/common.mk

TWEAK_NAME = batterybar
batterybar_FILES = Tweak.xm
batterybar_FRAMEWORKS = UIKit
batterybar_LIBRARIES = IOKit.A

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
#SUBPROJECTS += batterybarsettings
#include $(THEOS_MAKE_PATH)/aggregate.mk
