# Countdown Screensaver Makefile

SCREENSAVER_NAME = CountdownScreensaver
BUNDLE_NAME = ../Build/$(SCREENSAVER_NAME).saver
BUNDLE_DIR = $(BUNDLE_NAME)/Contents
EXECUTABLE = $(BUNDLE_DIR)/MacOS/$(SCREENSAVER_NAME)

# Swift compiler settings
SWIFT = swiftc
TARGET = x86_64-apple-macos14.0

# Source files - choose version to build
# Options: appkit-beautiful, swiftui, appkit-simple
VERSION ?= appkit-beautiful

ifeq ($(VERSION), swiftui)
    SOURCES = ../Sources/CountdownScreensaverView_SwiftUI.swift ../Sources/SharedModelsComplete.swift
    SWIFT_FLAGS = -framework ScreenSaver -framework SwiftUI -framework AppKit -framework Foundation -O -whole-module-optimization
else ifeq ($(VERSION), appkit-simple)
    SOURCES = ../Legacy/CountdownScreensaverView_AppKit.swift
    SWIFT_FLAGS = -framework ScreenSaver -framework AppKit -framework Foundation -O -whole-module-optimization
else
    # Default: beautiful AppKit version (needs SwiftUI for Color/Font types)
    SOURCES = ../Legacy/CountdownScreensaverView_AppKit_Beautiful.swift ../Sources/SharedModelsComplete.swift
    SWIFT_FLAGS = -framework ScreenSaver -framework SwiftUI -framework AppKit -framework Foundation -O -whole-module-optimization
endif

# Installation directories
USER_SCREENSAVER_DIR = ~/Library/Screen\ Savers
SYSTEM_SCREENSAVER_DIR = /Library/Screen\ Savers

.PHONY: all clean install install-user install-system uninstall force-reload

all: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCES)
	@echo "Building $(SCREENSAVER_NAME)..."
	$(SWIFT) $(SWIFT_FLAGS) -target $(TARGET) -emit-library -o $(EXECUTABLE) $(SOURCES)
	@echo "Build complete!"

clean:
	@echo "Cleaning..."
	rm -f $(EXECUTABLE)
	@echo "Clean complete!"

install: install-user

install-user: $(EXECUTABLE)
	@echo "Installing to user directory..."
	@mkdir -p $(USER_SCREENSAVER_DIR)
	@rm -rf $(USER_SCREENSAVER_DIR)/$(BUNDLE_NAME)
	@cp -R $(BUNDLE_NAME) $(USER_SCREENSAVER_DIR)/
	@echo "Installation complete! The screensaver is now available in System Preferences."

install-system: $(EXECUTABLE)
	@echo "Installing to system directory (requires sudo)..."
	@sudo rm -rf $(SYSTEM_SCREENSAVER_DIR)/$(BUNDLE_NAME)
	@sudo cp -R $(BUNDLE_NAME) $(SYSTEM_SCREENSAVER_DIR)/
	@echo "System installation complete!"

uninstall:
	@echo "Uninstalling screensaver..."
	@rm -rf $(USER_SCREENSAVER_DIR)/$(BUNDLE_NAME)
	@sudo rm -rf $(SYSTEM_SCREENSAVER_DIR)/$(BUNDLE_NAME) 2>/dev/null || true
	@echo "Uninstall complete!"

force-reload: $(EXECUTABLE)
	@echo "Force reloading screensaver (clears caches)..."
	@./force_reload.sh

# Development helpers
test: $(EXECUTABLE)
	@echo "Opening System Settings to test screensaver..."
	@open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension"

info:
	@echo "Screensaver Info:"
	@echo "  Name: $(SCREENSAVER_NAME)"
	@echo "  Bundle: $(BUNDLE_NAME)"
	@echo "  User Install Path: $(USER_SCREENSAVER_DIR)/$(BUNDLE_NAME)"
	@echo "  System Install Path: $(SYSTEM_SCREENSAVER_DIR)/$(BUNDLE_NAME)"
	@echo "  Current Version: $(VERSION)"
	@echo "  Sources: $(SOURCES)"

# Convenience targets for different versions
appkit-beautiful:
	$(MAKE) clean
	$(MAKE) all VERSION=appkit-beautiful
	$(MAKE) install

swiftui:
	$(MAKE) clean
	$(MAKE) all VERSION=swiftui
	$(MAKE) install

appkit-simple:
	$(MAKE) clean
	$(MAKE) all VERSION=appkit-simple
	$(MAKE) install

# Force reload with version selection
force-reload-beautiful:
	$(MAKE) force-reload VERSION=appkit-beautiful

force-reload-swiftui:
	$(MAKE) force-reload VERSION=swiftui

force-reload-simple:
	$(MAKE) force-reload VERSION=appkit-simple

.PHONY: all clean install uninstall test force-reload info
.PHONY: appkit-beautiful swiftui appkit-simple
.PHONY: force-reload-beautiful force-reload-swiftui force-reload-simple
