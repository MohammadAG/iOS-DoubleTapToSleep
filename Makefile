include theos/makefiles/common.mk

TWEAK_NAME = DoubleTapToSleep
DoubleTapToSleep_FILES = Tweak.xm
DoubleTapToSleep_FRAMEWORKS = UIKit
DoubleTapToSleep_PRIVATE_FRAMEWORKS = GraphicsServices
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
