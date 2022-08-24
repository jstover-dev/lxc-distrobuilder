MO                  := sh ./bin/mo -u

TEMPLATES_DIR       := templates
IMAGES_DIR          := images
BUILDS_DIR          := builds

ALPINE_LATEST       := $(shell $(PWD)/bin/alpine_releases.py --supported)
ALPINE_VERSIONS     ?= $(ALPINE_LATEST)
DEBIAN_VERSIONS     ?= 11

ALPINE_CONFIGS      := $(foreach v,$(ALPINE_VERSIONS),$(TEMPLATES_DIR)/alpine-$(v).yml)
ALPINE_IMAGES       := $(foreach v,$(ALPINE_VERSIONS),$(IMAGES_DIR)/distrobuilder-alpine-$(v).tar.xz)

DEBIAN_CONFIGS      := $(foreach v,$(DEBIAN_VERSIONS),$(TEMPLATES_DIR)/debian-$(v).yml)
DEBIAN_IMAGES       := $(foreach v,$(DEBIAN_VERSIONS),$(IMAGES_DIR)/distrobuilder-debian-$(v).tar.xz)

ALL_CONFIGS         := $(ALPINE_CONFIGS) $(DEBIAN_CONFIGS)
ALL_IMAGES          := $(ALPINE_IMAGES) $(DEBIAN_IMAGES)

EXISTING_IMAGES		:= $(wildcard $(ALL_IMAGES))

UPLOAD_HOST         ?=
UPLOAD_PATH         ?= template/cache


.PHONY: default images templates alpine debian upload clean _unlock_sudo

default: images

images: alpine debian

templates: $(ALL_CONFIGS)

alpine: $(ALPINE_IMAGES)

debian: $(DEBIAN_IMAGES)

upload:
ifeq ($(UPLOAD_HOST),)
	$(error Unable to upload. UPLOAD_HOST variable is not set)
else ifeq ($(EXISTING_IMAGES),)
	$(error There are no images to upload)
else
	scp $(EXISTING_IMAGES) $(UPLOAD_HOST):$(UPLOAD_PATH)
endif

clean:
	[ ! -d $(BUILDS_DIR) ] || sudo chown -R $(USER): $(BUILDS_DIR)
	rm -rf $(TEMPLATES_DIR) $(IMAGES_DIR) $(BUILDS_DIR)


templates/alpine-%.yml: alpine.yml.mo
	@[ -d $(TEMPLATES_DIR) ] || mkdir -p $(TEMPLATES_DIR)
	ALPINE_RELEASE=$* $(MO) "$<" > "$@"


templates/debian-%.yml: debian-%.yml
	@[ -d $(TEMPLATES_DIR) ] || mkdir -p $(TEMPLATES_DIR)
	cp -v "$<" "$@"


$(IMAGES_DIR)/distrobuilder-%.tar.xz: $(TEMPLATES_DIR)/%.yml | _unlock_sudo
	@[ -d $(IMAGES_DIR) ] || mkdir $(IMAGES_DIR)
	@[ -d $(BUILDS_DIR) ] || mkdir $(BUILDS_DIR)
	@echo ""
	@echo "========== BUILDING IMAGE: $@ =========="
	@( \
		BUILD_DIR="$(BUILDS_DIR)/build-$*" ;\
		sudo sh -c "( \
			distrobuilder build-lxc $< $$BUILD_DIR ;\
			chown -R ${USER}: $$BUILD_DIR ;\
			mv -fv $$BUILD_DIR/rootfs.tar.xz $@ ;\
			rm -rf $$BUILD_DIR ;\
			chown ${USER}: $@ ;\
		)" ;\
	)

#mv -fv $$BUILD_DIR/rootfs.tar.xz $@ ;\
#rm -rf $$BUILD_DIR ;\
_unlock_sudo:
	@sudo whoami >/dev/null
