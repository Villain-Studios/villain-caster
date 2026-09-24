# Binary / SwiftPM target (no spaces) vs. user-facing app bundle name.
APP = VillainCaster
APP_NAME = Villain Caster
BUNDLE = build/$(APP_NAME).app
# Stable identity keeps TCC grants (Screen Recording, Accessibility) valid
# across rebuilds; ad-hoc ("-") re-prompts after every install.
SIGN_IDENTITY = $(shell security find-identity -v -p codesigning 2>/dev/null | grep -q "VillainCaster Dev" && echo "VillainCaster Dev" || echo -)

.PHONY: build run app install clean

build:
	swift build -c release

run: build
	./.build/release/$(APP)

app: build
	rm -rf "$(BUNDLE)"
	mkdir -p "$(BUNDLE)/Contents/MacOS"
	cp .build/release/$(APP) "$(BUNDLE)/Contents/MacOS/"
	cp Resources/Info.plist "$(BUNDLE)/Contents/"
	codesign --force --sign "$(SIGN_IDENTITY)" "$(BUNDLE)"
	@echo "Built $(BUNDLE)"

install: app
	-pkill -x $(APP)
	# Pre-rename bundle name.
	rm -rf "/Applications/$(APP).app"
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(BUNDLE)" /Applications/
	open "/Applications/$(APP_NAME).app"
	@echo "Installed and started /Applications/$(APP_NAME).app"

clean:
	rm -rf .build build
