
prefix ?= /usr/local
bindir = $(prefix)/bin
datadir = $(prefix)/share/canfar
etcdir = /etc

INSTALL = install -c
INSTALL_SCRIPT = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
MKDIR_P = mkdir -p
RM = rm -f

SCRIPTS = \
	cadc_cert \
	cadc_dotnetrc \
	canfar_cloud_cleanup \
	canfar_condor_csv \
	canfar_condor_user_stats \
	canfar_create_batch_user \
	canfar_job_validate \
	canfar_openstack_stats \
	canfar_project_remove_prompt \
	canfar_project_restore_prompt \
	canfar_project_stats \
	canfar_share_vm \
	canfar_submit \
	canfar_translate_vm \
	canfar_update_default_image

WORKER_SCRIPTS = canfar_batch_cert canfar_batch_init

DATA = canfar_batch_rsa.pub

install: 
	@$(MKDIR_P) $(DESTDIR)$(bindir) ; \
	for script in $(SCRIPTS); do \
		echo " $(INSTALL_SCRIPT) bin/$$script $(DESTDIR)$(bindir)/$$script" ; \
		$(INSTALL_SCRIPT) bin/$$script $(DESTDIR)$(bindir)/$$script ; \
	done
	@$(MKDIR_P) $(DESTDIR)$(datadir) ; \
	for data in $(DATA); do \
		echo " $(INSTALL_DATA) share/$$data $(DESTDIR)$(datadir)/$$data" ; \
		$(INSTALL_DATA) share/$$data $(DESTDIR)$(datadir)/$$data ; \
	done; \
	for script in $(WORKER_SCRIPTS); do \
		echo " $(INSTALL_SCRIPT) share/$$script $(DESTDIR)$(datadir)/$$script" ; \
		$(INSTALL_SCRIPT) share/$$script $(DESTDIR)$(datadir)/$$script ; \
	done

uninstall:
	@for script in $(SCRIPTS); do \
		echo " $(RM) $(DESTDIR)$(bindir)/$$script" ; \
		$(RM) $(DESTDIR)$(bindir)/$$script ; \
	done
	@for data in $(DATA); do \
		echo " $(RM) $(DESTDIR)$(datadir)/$$data" ; \
		$(RM) $(DESTDIR)$(datadir)/$$data ; \
	done
