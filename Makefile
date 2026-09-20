SIM ?= iPhone 17 Pro
SCHEME := Kulturstack
DEST := platform=iOS Simulator,name=$(SIM)
RESULT := build/Test.xcresult

.PHONY: secrets generate build test coverage hooks clean

secrets:
	@./scripts/secrets.sh

generate: secrets
	@xcodegen generate --quiet

build: generate
	xcodebuild -project Kulturstack.xcodeproj -scheme $(SCHEME) -destination "$(DEST)" -quiet build

test: generate
	@rm -rf $(RESULT)
	xcodebuild -project Kulturstack.xcodeproj -scheme $(SCHEME) -destination "$(DEST)" -resultBundlePath $(RESULT) -enableCodeCoverage YES -quiet test

coverage:
	@xcrun xccov view --report --only-targets $(RESULT) | grep -E "Kulturstack(\.app)?\b" || xcrun xccov view --report --only-targets $(RESULT)

hooks:
	@ln -sf ../../scripts/pre-commit .git/hooks/pre-commit && echo "Hook pre-commit installé."

clean:
	@rm -rf build DerivedData Kulturstack.xcodeproj
