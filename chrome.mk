# external 'compile' target required

required := PKG PKG_FILES
$(foreach idx,$(required),$(if $($(idx)),,$(error $(idx) variable is empty)))

ZIP := zip
ZIP2CRX:= ./zip2crx.sh
PRIVATE_KEY := private.pem

zipArchive := $(PKG).zip
extension := $(PKG).crx

.PHONY: zip zip_clean crx_clean crx chrome_clean

zip_clean:
	rm -f $(zipArchive)

zip: zip_clean
	$(ZIP) $(zipArchive) $(PKG_FILES)

crx_clean:
	rm -f $(extension)

chrome_clean: zip_clean crx_clean

crx: crx_clean compile zip
	@if [ -r $(PRIVATE_KEY) ] ; then \
		$(ZIP2CRX) $(zipArchive) $(PRIVATE_KEY); \
	else \
		echo crx: $(PRIVATE_KEY) not found; \
		exit 1 ; \
	fi
