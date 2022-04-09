MO                 := sh ./bin/mo -u

TEMPLATES_DIR      := templates

IMAGES_DIR         := images


ALPINE_VERSIONS    ?= 3.12.12 \
					  3.13.10 \
					  3.14.6  \
					  3.15.4  \

ALPINE_CONFIGS     := $(foreach v,$(ALPINE_VERSIONS),$(TEMPLATES_DIR)/alpine-$(v).yml)

ALPINE_IMAGES      := $(foreach v,$(ALPINE_VERSIONS),$(IMAGES_DIR)/distrobuilder-alpine-$(v).tar.xz)


DEBIAN_VERSIONS    := 11

DEBIAN_CONFIGS     := $(foreach v,$(DEBIAN_VERSIONS),$(TEMPLATES_DIR)/debian-$(v).yml)

DEBIAN_IMAGES      := $(foreach v,$(DEBIAN_VERSIONS),$(IMAGES_DIR)/distrobuilder-debian-$(v).tar.xz)


ALL_CONFIGS        := $(ALPINE_CONFIGS) $(DEBIAN_CONFIGS)

ALL_IMAGES         := $(ALPINE_IMAGES) $(DEBIAN_IMAGES)

UPLOAD_HOST        ?=

UPLOAD_PATH        ?= template/cache


.PHONY: default images configs upload clean

default: images

images: $(ALL_IMAGES)

configs: $(ALL_CONFIGS)

upload: $(ALL_IMAGES)
ifeq ($(UPLOAD_HOST),)
	$(error Unable to upload. UPLOAD_HOST variable is not set)
else
	scp $(ALL_IMAGES) $(UPLOAD_HOST):$(UPLOAD_PATH)
endif

clean:
	rm -f $(TEMPLATES_DIR)/* $(IMAGES_DIR)/*


templates/alpine-%.yml: alpine.tpl.yml
	@[ -d templates ] || mkdir -p templates
	ALPINE_RELEASE=$* $(MO) "$<" > "$@"

templates/debian-%.yml: debian-%.yml
	@[ -d templates ] || mkdir -p templates
	cp -v "$<" "$@"

images/distrobuilder-%.tar.xz: templates/%.yml
	@[ -d images ] || mkdir images
	@echo ""
	@echo "========== BUILDING IMAGE: $@ =========="
	( \
		BUILD_DIR="build-$*" ;\
		sudo sh -c "( \
			distrobuilder build-lxc $< $$BUILD_DIR ;\
			chown -R ${USER}: $$BUILD_DIR ;\
		)" ;\
		mv -fv $$BUILD_DIR/rootfs.tar.xz $@ ;\
		rm -rf $$BUILD_DIR ;\
	)

