# Binary / SwiftPM target (no spaces) vs. user-facing app bundle name.
APP = VillainCaster
APP_NAME = Villain Caster
BUNDLE = build/$(APP_NAME).app
# Stable identity keeps TCC grants (Screen Recording, Accessibility) valid
# across rebuilds; ad-hoc ("-") re-prompts after every install.
SIGN_IDENTITY = $(shell security find-identity -v -p codesigning 2>/dev/null | grep -q "VillainCaster Dev" && echo "VillainCaster Dev" || echo -)

.PHONY: build run app icon install release clean

build:
	swift build -c release

run: build
	./.build/release/$(APP)

app: build
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	cp .build/release/$(APP) "$(BUNDLE)/Contents/MacOS/"
	mkdir -p "$(BUNDLE)/Contents/Resources"
	cp Resources/Info.plist "$(BUNDLE)/Contents/"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/"
	codesign --force --sign "$(SIGN_IDENTITY)" "$(BUNDLE)"
	@echo "Built $(BUNDLE)"

# Re-render Resources/AppIcon.icns from Resources/AppIcon.svg (committed, so
# only needed after editing the SVG). Each size is rendered, not downscaled.
ICONSET = build/AppIcon.iconset
RENDER = build/render-svg
icon:
	rm -rf $(ICONSET)
	mkdir -p $(ICONSET)
	swiftc -O -o $(RENDER) scripts/render-svg.swift
	for s in 16 32 128 256 512; do \
		$(RENDER) Resources/AppIcon.svg $(ICONSET)/icon_$${s}x$${s}.png $$s && \
		$(RENDER) Resources/AppIcon.svg $(ICONSET)/icon_$${s}x$${s}@2x.png $$((s * 2)) || exit 1; \
	done
	iconutil -c icns $(ICONSET) -o Resources/AppIcon.icns
	@echo "Wrote Resources/AppIcon.icns"

# Also removes the bundle name used before the "Villain Caster" rename.
install: app
	-pkill -x $(APP)
	rm -rf "/Applications/$(APP).app"
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(BUNDLE)" /Applications/
	open "/Applications/$(APP_NAME).app"
	@echo "Installed and started /Applications/$(APP_NAME).app"

# Developer ID signing + notarization for a GitHub release (see README →
# Releasing). Override DEVELOPER_ID / NOTARY_PROFILE on the command line.
DEVELOPER_ID ?= $(shell security find-identity -v -p codesigning 2>/dev/null | grep -o '"Developer ID Application: [^"]*"' | head -1 | tr -d '"')
NOTARY_PROFILE ?= villain-notary
VERSION = $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
ZIP = build/Villain-Caster-$(VERSION).zip

release: app
	@test -n "$(DEVELOPER_ID)" || { echo "No 'Developer ID Application' certificate in the keychain — see README → Releasing."; exit 1; }
	codesign --force --options runtime --timestamp \
		--entitlements Resources/VillainCaster.entitlements \
		--sign "$(DEVELOPER_ID)" "$(BUNDLE)"
	codesign --verify --strict --verbose=2 "$(BUNDLE)"
	rm -f "$(ZIP)"
	ditto -c -k --keepParent "$(BUNDLE)" "$(ZIP)"
	xcrun notarytool submit "$(ZIP)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(BUNDLE)"
	# Re-zip so the download carries the stapled ticket (works offline).
	rm -f "$(ZIP)"
	ditto -c -k --keepParent "$(BUNDLE)" "$(ZIP)"
	spctl --assess --type execute --verbose=2 "$(BUNDLE)"
	@echo "Notarized $(ZIP)"

clean:
	rm -rf .build build
