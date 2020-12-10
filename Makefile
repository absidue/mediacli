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
MEDIA_VERSION   := 1.1.1
DEB_MEDIA_V     := $(MEDIA_VERSION)

all: build/media

build/media: main.m ent.plist
	mkdir -p build
	$(CC) $(CFLAGS) -o build/media main.m -Iinclude -FPrivateFrameworks -framework Foundation -framework CoreFoundation -framework MediaRemote -framework Celestial -fobjc-arc
	$(STRIP) build/media
	$(LDID) -Sent.plist build/media

install: build/media
	$(INSTALL) -Dm755 build/media $(DESTDIR)$(PREFIX)/bin/media
	$(INSTALL) -Dm644 COPYING $(DESTDIR)$(PREFIX)/share/media/COPYING

package: build/media
	rm -rf staging
	$(INSTALL) -Dm755 build/media staging$(PREFIX)/bin/media
	$(INSTALL) -Dm644 COPYING staging$(PREFIX)/share/media/COPYING
	SIZE=$$(du -s staging | cut -f 1); \
	$(INSTALL) -Dm755 control.in staging/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_MEDIA_V@/$(DEB_MEDIA_V)/g; ta' staging/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_MAINTAINER@/$(DEB_MAINTAINER)/g; ta' staging/DEBIAN/control; \
	$(SED) -i ':a; s/@DEB_ARCH@/$(DEB_ARCH)/g; ta' staging/DEBIAN/control; \
	cd staging && find . -type f ! -regex '.*.hg.*' ! -regex '.*?debian-binary.*' ! -regex '.*?DEBIAN.*' | xargs md5sum > DEBIAN/md5sum; \
	cd ..; \
	echo "Installed-Size: $$SIZE" >> staging/DEBIAN/control
	$(FAKEROOT) dpkg-deb -z9 -b staging build
	rm -rf staging

clean: 
	rm -f build/media
