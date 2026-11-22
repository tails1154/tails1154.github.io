THEOS ?= $(CURDIR)/../theos

TARGET = iphone:clang:5.1:5.1
ARCHS = armv7

TWEAK_NAME = BlueSkyNotify
BlueSkyNotify_FILES = Tweak.xm
BlueSkyNotify_FRAMEWORKS = Foundation UIKit
BlueSkyNotify_PRIVATE_FRAMEWORKS = BulletinBoard

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
