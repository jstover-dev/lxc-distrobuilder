UPLOAD_HOST ?=	

SOURCES		:=	$(wildcard *.yml)

TARGETS		:=	$(addprefix distrobuilder-,$(SOURCES:.yml=.tar.xz))


UPLOAD_HOST ?=
UPLOAD_PATH ?= template/cache

DISTROBUILDER_OUTPUTS	:= meta.tar.xz rootfs.tar.xz


.PHONY: all upload

all: $(TARGETS)

upload: $(TARGETS)
ifeq ($(UPLOAD_HOST),)
	$(error Unable to upload. UPLOAD_HOST variable is not set)
else
	scp $(TARGETS) $(UPLOAD_HOST):$(UPLOAD_PATH)
endif


distrobuilder-%.tar.xz: %.yml
	@echo ""
	@echo "========== BUILDING IMAGE: $@ =========="
	sudo sh -c "( distrobuilder build-lxc $< ; chown ${USER}: $(DISTROBUILDER_OUTPUTS) )"
	@rm -f meta.tar.xz
	@mv -fv rootfs.tar.xz $@
