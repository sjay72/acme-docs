QPID_UPSTREAM_DIR := $(shell readlink -f upstreams/qpid-books)
ACTIVEMQ_UPSTREAM_DIR := $(shell readlink -f upstreams/activemq-books)
ASCIIDOCTOR_OPTIONS := -a QpidUpstreamDir="${QPID_UPSTREAM_DIR}" -a ActiveMqUpstreamDir="${ACTIVEMQ_UPSTREAM_DIR}"

BUILD_DIR := build

DOC_SOURCES := $(shell find docs -type f -name master.adoc)
DOC_TARGETS := \
	${DOC_SOURCES:docs/%/master.adoc=${BUILD_DIR}/%/index.html} \
	${DOC_SOURCES:docs/%/master.adoc=${BUILD_DIR}/%/images}

IMAGE_SOURCES := $(shell find images -type f)
IMAGE_TARGETS := ${IMAGE_SOURCES:images/%=${BUILD_DIR}/images/%}

EXTRA_SOURCES := docs/index.adoc
EXTRA_TARGETS := ${EXTRA_SOURCES:docs/%.adoc=${BUILD_DIR}/%.html}

.PHONY: default
default: build

.PHONY: help
help:
	@echo "[default]      Equivalent to 'make build'"
	@echo "build          Renders the site to ${BUILD_DIR}/"
	@echo "clean          Removes ${BUILD_DIR}/ and other build artifacts"

.PHONY: build
build: ${DOC_TARGETS} ${IMAGE_TARGETS} ${EXTRA_TARGETS}
	@echo "See the output in your browser at file://${PWD}/${BUILD_DIR}/index.html"

.PHONY: publish
publish: build
publish:
	rsync -av ${BUILD_DIR}/ home.apache.org:public_html/qpid-books

.PHONY: clean
clean:
	rm -rf ${BUILD_DIR}

define DOC_TEMPLATE =
$${BUILD_DIR}/${1}/index.html: $$(shell find -L docs/${1} -type f -name \*.adoc)
	@mkdir -p $${@D}
	asciidoctor ${ASCIIDOCTOR_OPTIONS} -o $$@ docs/${1}/master.adoc

$${BUILD_DIR}/${1}/images:
	@mkdir -p $${@D}
	ln -s --force --no-target-directory ../images $$@
endef

$(foreach dir,${DOC_SOURCES:docs/%/master.adoc=%},$(eval $(call DOC_TEMPLATE,${dir})))

${BUILD_DIR}/%.html: docs/%.adoc
	@mkdir -p ${@D}
	asciidoctor ${ASCIIDOCTOR_OPTIONS} -o $@ $<

${BUILD_DIR}/images/%: images/%
	@mkdir -p ${@D}
	cp $< $@
