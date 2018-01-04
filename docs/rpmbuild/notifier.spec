Summary: EON Advanced Notifier
Name:notifier
Version:2.1.2
Release:1.eon
Source:%{name}-%{version}.tar.gz
Source1:%{name}
BuildRoot:/root/rpmbuild
Group:Applications/Base
License:GPLv2
URL: http://www.eyesofnetwork.com
Packager: Vincent FRICOU <vincent@fricouv.eu>

Requires: perl
Requires: perl-XML-Simple
Requires: logrotate
Requires: mariadb-server
Requires: mariadb
Requires: perl-DBI
Requires: perl-DBD-MySQL
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
	install -m 775  scripts/updates/v2.1_to_v2.1-1.sh ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/scripts/updates/v2.1_to_v2.1.1.sh
	install -m 664  var/www/index.html ${RPM_BUILD_ROOT}/srv/eyesofnetwork/%{name}-%{version}/var/www/index.html

%post
	sh /srv/eyesofnetwork/%{name}-%{version}/docs/db/create_database.sh
	cp -pr /srv/eyesofnetwork/%{name}/etc/* /srv/eyesofnetwork/%{name}-%{version}/etc
	cp -pr /srv/eyesofnetwork/%{name}/log/* /srv/eyesofnetwork/%{name}-%{version}/log
	cp -pr /srv/eyesofnetwork/%{name}/scripts/* /srv/eyesofnetwork/%{name}-%{version}/scripts
	printf "\nBe carefull : If you've change mysql root password, is possible to have error on SQL database creation and table injection. \n If is the only error, modify /srv/eyesofnetwork/notifier/docs/db/create_database.sh and re-run it. \n"

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
%attr (664,nagios,eyesofnetwork) /srv/eyesofnetwork/%{name}-%{version}/etc/notifier.rules
%attr (775,nagios,eyesofnetwork) /srv/eyesofnetwork/%{name}-%{version}/log/
%attr (775,nagios,eyesofnetwork) /srv/eyesofnetwork/%{name}-%{version}/var/www/

%changelog
* Thu Nov 2 2017 Vincent Fricou <vincent@fricouv.eu> - 2.1.1
(Refer to Git release : https://github.com/EyesOfNetworkCommunity/notifier/releases/tag/2.1-1)
- Now username was checked instead of email into notification rules
- Updated documentation
- Added script to update from previous version (2.1)
- Added script to check notifier.rules fields configuration
- Added log line to print contact name
