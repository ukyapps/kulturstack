SIM ?= iPhone 17 Pro
SCHEME := Kulturstack
DEST := platform=iOS Simulator,name=$(SIM)
RESULT := build/Test.xcresult

.PHONY: secrets generate build test device coverage hooks clean

secrets:
	@./scripts/secrets.sh

generate: secrets
	@xcodegen generate --quiet

build: generate
	xcodebuild -project Kulturstack.xcodeproj -scheme $(SCHEME) -destination "$(DEST)" -quiet build

test: generate
	@rm -rf $(RESULT)
	xcodebuild -project Kulturstack.xcodeproj -scheme $(SCHEME) -destination "$(DEST)" -resultBundlePath $(RESULT) -enableCodeCoverage YES -quiet test

# Installe sur l'iPhone branché (déverrouillé, mode développeur activé).
device: generate
	@DEVICE=$$(xcrun devicectl list devices 2>/dev/null | grep -E '[[:space:]]connected' \
		| grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | head -1); \
	if [ -z "$$DEVICE" ]; then echo "Aucun iPhone connecté, déverrouillé et en mode développeur."; exit 1; fi; \
	xcodebuild -project Kulturstack.xcodeproj -scheme $(SCHEME) -destination "generic/platform=iOS" \
		-derivedDataPath build/DerivedDataDevice -allowProvisioningUpdates -quiet build && \
	xcrun devicectl device install app --device $$DEVICE \
		build/DerivedDataDevice/Build/Products/Debug-iphoneos/Kulturstack.app

coverage:
	@xcrun xccov view --report --only-targets $(RESULT) | grep -E "Kulturstack(\.app)?\b" || xcrun xccov view --report --only-targets $(RESULT)

hooks:
	@ln -sf ../../scripts/pre-commit .git/hooks/pre-commit && echo "Hook pre-commit installé."

clean:
	@rm -rf build DerivedData Kulturstack.xcodeproj
