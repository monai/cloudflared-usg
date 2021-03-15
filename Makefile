arch = $(shell uname -m)
version = 2021.2.5
name = cloudflared
source_dir = $(name)-$(version)
package = $(name)_$(version)_$(arch).deb
work_dir = work_dir
date = $(shell date -u '+%Y-%m-%d-%H%M UTC')

ifeq ($(arch), x86_64)
  goarch = amd64
else ifeq ($(arch), i686)
  goarch = amd64
else
  goarch = $(arch)
endif

$(source_dir):
	wget https://github.com/cloudflare/cloudflared/archive/$(version).zip
	unzip $(version).zip
	rm $(version).zip

$(source_dir)/$(name): $(source_dir)
	cd $(source_dir) && \
		PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$(PATH)" \
		GOOS=linux \
		$(MAKE) cloudflared GOARCH=$(goarch) VERSION=$(version)

$(package): $(source_dir)/$(name)
	mkdir -p $(work_dir)/DEBIAN
	cat debian/control | sed -e 's/\$${VERSION}/$(version)/; s/\$${ARCH}/$(arch)/' > $(work_dir)/DEBIAN/control

	mkdir -p $(work_dir)/etc/init.d
	cp init.sh $(work_dir)/etc/init.d/$(name)
	chmod +x $(work_dir)/etc/init.d/$(name)

	mkdir -p $(work_dir)/etc/$(name)
	cp config.yml $(work_dir)/etc/$(name)

	mkdir -p $(work_dir)/usr/share/doc/$(name)
	cp config.gateway.json $(work_dir)/usr/share/doc/$(name)

	mkdir -p $(work_dir)/usr/sbin
	cp $(source_dir)/$(name) $(work_dir)/usr/sbin

	mkdir -p $(work_dir)/usr/share/man/man1
	cat $(source_dir)/cloudflared_man_template | sed -e 's/\$${VERSION}/$(version)/; s/\$${DATE}/$(date)/' > $(work_dir)/usr/share/man/man1/cloudflared.1

	dpkg-deb --root-owner-group --build -Zgzip $(work_dir) $(package)

clean-source:
	rm -rf $(source_dir)/$(name)
	rm -rf $(source_dir)/*.deb

clean-work:
	rm -rf $(work_dir)
	rm -rf *.deb

clean: clean-source clean-work

build: $(package)
	@exit

.DEFAULT_GOAL := build
