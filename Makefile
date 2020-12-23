CC              ?= cc
STRIP           ?= strip
LDID            ?= ldid
SED             ?= gsed
INSTALL         ?= ginstall
FAKEROOT        ?= fakeroot
CFLAGS          ?= -arch arm64 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -miphoneos-version-min=13.0
PREFIX          ?= /usr
DESTDIR         ?= 

DEB_MAINTAINER  ?= absidue <apt@absidue.me>
DEB_ARCH        ?= iphoneos-arm
MEDIA_VERSION   := 1.2
DEB_MEDIA_V     := $(MEDIA_VERSION)

all: build/media build/media.1

build/media: main.m ent.plist
	mkdir -p build
	$(CC) $(CFLAGS) -o build/media main.m -Iinclude -FPrivateFrameworks -framework Foundation -framework CoreFoundation -framework MediaRemote -framework Celestial -fobjc-arc
	$(STRIP) build/media
	$(LDID) -Sent.plist build/media

build/media.1: media.1.in
	$(INSTALL) -Dm755 media.1.in build/media.1
	$(SED) -i 's/@MEDIA_VERSION@/$(MEDIA_VERSION)/g' build/media.1

install: build/media build/media.1
	$(INSTALL) -Dm755 build/media $(DESTDIR)$(PREFIX)/bin/media
	$(INSTALL) -Dm755 build/media.1 $(DESTDIR)$(PREFIX)/share/man/man1/media.1
	$(INSTALL) -Dm644 COPYING $(DESTDIR)$(PREFIX)/share/mediacli/COPYING

package: build/media build/media.1
	rm -rf staging
	$(INSTALL) -Dm755 build/media staging$(PREFIX)/bin/media
	$(INSTALL) -Dm755 build/media.1 staging$(PREFIX)/share/man/man1/media.1
	$(INSTALL) -Dm644 COPYING staging$(PREFIX)/share/media/COPYING
	SIZE=$$(du -s staging | cut -f 1); \
	$(INSTALL) -Dm755 control.in staging/DEBIAN/control; \
	$(SED) -i 's/@DEB_MEDIA_V@/$(DEB_MEDIA_V)/g' staging/DEBIAN/control; \
	$(SED) -i 's/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g' staging/DEBIAN/control; \
	$(SED) -i 's/@DEB_ARCH@/$(DEB_ARCH)/g' staging/DEBIAN/control; \
	cd staging && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' | xargs md5sum > DEBIAN/md5sum; \
	cd ..; \
	echo "Installed-Size: $$SIZE" >> staging/DEBIAN/control
	$(FAKEROOT) dpkg-deb -z9 -b staging build
	rm -rf staging

clean: 
	rm -f build/media build/media.1
