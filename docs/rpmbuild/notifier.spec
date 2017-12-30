Summary: EON Advanced Notifier
Name:notifier
Version:2.1.1
Release:2.eon
Source:%{name}-%{version}.tar.gz
Source1:%{name}
BuildRoot:/root/rpmbuild
Group:Applications/Base
License:GPLv2

Requires: perl
Requires: perl-XML-Simple
Requires: logrotate
Requires: mariadb-server
Requires: mariadb
Requires: perl-DBI
Requires: perl-DBI-MySQL
Requires: git


%description
EyesOfNetwork advanced notifier can provide a fine configuration for nagios notifications.

%prep
%define _unpackaged_files_terminate_build 0
%setup -q

%build

%install
	mkdir -p ${RPM_BUILD_ROOT}/srv/eyesofnetwork/
	tar -xf /root/rpmbuild/SOURCES/%{name}-%{version}.tar.gz -C ${RPM_BUILD_ROOT}/srv/eyesofnetwork/

	mkdir -p /srv/eyesofnetwork/%{name}-%{version}/{bin,docs,etc,log,scripts,var}
	mkdir -p /srv/eyesofnetwork/%{name}-%{version}/docs/db
	mkdir -p /srv/eyesofnetwork/%{name}-%{version}/etc/{logrotate,messages}
	mkdir -p /srv/eyesofnetwork/%{name}-%{version}/scripts/updates
	mkdir -p /srv/eyesofnetwork/%{name}-%{version}/var/www

	install -m 775  bin/notifier.pl ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/bin/
	install -m 664  etc/notifier.cfg ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/etc/
	install -m 664 -o nagios -g eyesofnetwork etc/notifier.rules ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/etc/
	install -m 664  etc/messages/sms-app-critical ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/etc/messages/
	install -m 664  etc/messages/sms-app-warning ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/etc/messages/
	install -m 664  etc/messages/sms-app-ok ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/etc/messages/
	install -m 664  etc/logrotate/%{name} ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/etc/logrotate/
	install -m 664  docs/notifier.cfg.md ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/
	install -m 664  docs/notifier.rules.md ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/
	install -m 664  docs/notifier_send.log.md ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/
	install -m 664  docs/notifier_rules.log.md ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/
	install -m 664  docs/platform.xsd.md ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/
	install -m 664  docs/updates_scripts.md ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/
	install -m 664  docs/db/notifier.sql ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/db/
	install -m 664  docs/db/create_database.sh ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/db/
	install -m 664  docs/db/create_user.txt ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/docs/db/
	install -m 775  scripts/createxml2sms.sh ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/scripts/createxml2sms.sh
	install -m 775  scripts/updates/check_config_file.sh ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/scripts/updates/check_config_file.sh
	install -m 775  scripts/updates/v2.1_to_v2.1-1.sh ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/scripts/updates/v2.1_to_v2.1-1.sh
	install -m 664  var/www/index.html ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/var/www/index.html

%post
	sh /srv/eyesofnetwork/%{name}-%{version}/docs/db/create_database.sh
	cp -pr /srv/eyesofnetwork/%{name}/etc/* /srv/eyesofnetwork/%{name}-%{version}/etc
	cp -pr /srv/eyesofnetwork/%{name}/log/* /srv/eyesofnetwork/%{name}-%{version}/log
	cp -pr /srv/eyesofnetwork/%{name}/scripts/* /srv/eyesofnetwork/%{name}-%{version}/scripts
	printf "\nIf you already have a notifier 2.*, is possible to have an error on database \"notifier\". Is normal because it already exist.\nBe carefull : If you've change mysql root password, is possible to have error on SQL database creation and table injection. \n If is the only error, modify /srv/eyesofnetwork/notifier/docs/db/create_database.sh and re-run it. \n"
	printf "\n\nNormaly, the rpm copy files/folder in folders /srv/eyesofnetwork/notifier-2.0/[etc,scripts,log]. If is done, execute following commands :\n rm /srv/eyesofnetwork/notifier \n ln -s /srv/eyesofnetwork/notifier-2.0 /srv/eyesofnetwork/notifier\n\nThanks."

%postun
	rm -rf /srv/eyesofnetwork/%{name}

%clean
	rm -rf ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}

%files
%defattr(-,root,root,-)
/srv/eyesofnetwork/%{name}-%{version}/bin/
/srv/eyesofnetwork/%{name}-%{version}/etc/
/srv/eyesofnetwork/%{name}-%{version}/docs/
/srv/eyesofnetwork/%{name}-%{version}/scripts/
/srv/eyesofnetwork/%{name}-%{version}/var/
%attr (775,nagios,eyesofnetwork) /srv/eyesofnetwork/%{name}-%{version}/log/
%attr (775,nagios,eyesofnetwork) /srv/eyesofnetwork/%{name}-%{version}/var/www/

%changelog
* Mon Mar 30 2014 Vincent Fricou <vincent@fricouv.eu> - 2.0-1
- Newer version with MySQL logging integration

* Mon Jan 20 2014 Vincent Fricou <vincent@fricouv.eu> - 1.4-6
- Bug correction on rules debug.

* Wed Aug 14 2013 Vincent Fricou <vincent@fricouv.eu> - 1.4-5
- Bug correction on notifications sent logging.
- Bug correction on sms notifications.

* Wed Jul 17 2013 Vincent Fricou <vincent@fricouv.eu> - 1.4-4
- Full debug by rules implementation.

* Mon Jul 15 2013 Vincent Fricou <vincent@fricouv.eu> - 1.4-3
- Sms notification implementation.
- Adding xml2sms converter.

* Wed Jun 26 2013 Vincent Fricou <vincent@fricouv.eu> - 1.4-2
- Logrotate Integration.

* Wed Jun 26 2013 Vincent Fricou <vincent@fricouv.eu> - 1.4-1
- Initial release.
