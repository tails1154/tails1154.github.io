THEOS ?= $(CURDIR)/../theos

TARGET = iphone:clang:5.1:5.1
ARCHS = armv7

TWEAK_NAME = BlueSkyNotify
BlueSkyNotify_FILES = Tweak.xm
BlueSkyNotify_FRAMEWORKS = Foundation UIKit
BlueSkyNotify_PRIVATE_FRAMEWORKS = BulletinBoard

BUNDLE_NAME = BlueSkyNotifyPrefs
BlueSkyNotifyPrefs_BUNDLE_NAME = BlueSkyNotify
BlueSkyNotifyPrefs_FILES = Preferences/BlueSkyNotifyRootListController.m
BlueSkyNotifyPrefs_FRAMEWORKS = UIKit
BlueSkyNotifyPrefs_PRIVATE_FRAMEWORKS = Preferences
BlueSkyNotifyPrefs_RESOURCE_DIRS = Preferences/Resources
BlueSkyNotifyPrefs_INSTALL_PATH = /Library/PreferenceBundles

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
include $(THEOS)/makefiles/bundle.mk
