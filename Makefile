SIM ?= iPhone 17 Pro
SCHEME := Kulturstack
DEST := platform=iOS Simulator,name=$(SIM)
RESULT := build/Test.xcresult

.PHONY: secrets generate build test device coverage hooks clean sauvegarde sauvegardes sauvegarde-auto sauvegarde-stop test-sauvegarde

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

# --- Sauvegarde de la base de l'iPhone -------------------------------------------------
# Née du 18/10 : l'app avait disparu de l'iPhone avec sa base, et la dernière sauvegarde
# datait de trois semaines. Dix jours de logs perdus.
AGENT := $(HOME)/Library/LaunchAgents/com.ukyapps.kulturstack.sauvegarde.plist
# macOS interdit à un agent launchd de lire ~/Documents : le script et les sauvegardes
# vivent donc dans Application Support, que l'agent a le droit d'ouvrir.
SAUV_DIR := $(HOME)/Library/Application Support/Kulturstack
AGENT_SCRIPT := $(SAUV_DIR)/sauvegarder-base.sh

sauvegarde:
	@./scripts/sauvegarder-base.sh && echo "Sauvegarde faite." || echo "Rien sauvegardé (voir ci-dessus)."

test-sauvegarde:
	@./scripts/test-sauvegarde.sh

sauvegarde-auto:
	@mkdir -p $(HOME)/Library/LaunchAgents "$(SAUV_DIR)/sauvegardes"
	@cp scripts/sauvegarder-base.sh "$(AGENT_SCRIPT)" && chmod +x "$(AGENT_SCRIPT)"
	@sed -e "s#__SCRIPT__#$(AGENT_SCRIPT)#" \
	     -e "s#__LOG__#$(SAUV_DIR)/launchd.log#" \
	     -e "s#__SAUVEGARDES__#$(SAUV_DIR)/sauvegardes#" \
	     scripts/launchd/com.ukyapps.kulturstack.sauvegarde.plist > $(AGENT)
	@launchctl unload $(AGENT) 2>/dev/null || true
	@launchctl load $(AGENT)
	@echo "Sauvegarde automatique active : toutes les 30 minutes, dès que l'iPhone est branché."
	@echo "Sauvegardes dans ~/Library/Application Support/Kulturstack/sauvegardes/"
	@echo "Les lister : make sauvegardes · arrêter : make sauvegarde-stop"

sauvegardes:
	@ls -1 "$(SAUV_DIR)/sauvegardes" 2>/dev/null | grep -v journal.log || echo "Aucune sauvegarde."
	@echo "---"
	@cat "$(SAUV_DIR)/sauvegardes/derniere/manifeste.txt" 2>/dev/null || true
	@open "$(SAUV_DIR)/sauvegardes" 2>/dev/null || true

sauvegarde-stop:
	@launchctl unload $(AGENT) 2>/dev/null || true
	@rm -f $(AGENT)
	@echo "Sauvegarde automatique arrêtée. Les sauvegardes déjà faites sont conservées."
