APP = VillainCaster
BUNDLE = build/$(APP).app

.PHONY: build run app install clean

build:
	swift build -c release

run: build
	./.build/release/$(APP)

app: build
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS
	cp .build/release/$(APP) $(BUNDLE)/Contents/MacOS/
	cp Resources/Info.plist $(BUNDLE)/Contents/
	codesign --force --sign - $(BUNDLE)
	@echo "Built $(BUNDLE)"

install: app
	rm -rf /Applications/$(APP).app
	cp -R $(BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP).app"

clean:
	rm -rf .build build
