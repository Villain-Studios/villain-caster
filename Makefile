# Binary / SwiftPM target (no spaces) vs. user-facing app bundle name.
APP = VillainCaster
APP_NAME = Villain Caster
BUNDLE = build/$(APP_NAME).app
# Stable identity keeps TCC grants (Screen Recording, Accessibility) valid
# across rebuilds; ad-hoc ("-") re-prompts after every install.
SIGN_IDENTITY = $(shell security find-identity -v -p codesigning 2>/dev/null | grep -q "VillainCaster Dev" && echo "VillainCaster Dev" || echo -)

.PHONY: build run app icon install clean

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

install: app
	-pkill -x $(APP)
	# Bundle name before the "Villain Caster" rename.
	rm -rf "/Applications/$(APP).app"
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(BUNDLE)" /Applications/
	open "/Applications/$(APP_NAME).app"
	@echo "Installed and started /Applications/$(APP_NAME).app"

clean:
	rm -rf .build build
