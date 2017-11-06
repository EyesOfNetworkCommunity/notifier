# Files permissions

This is the default EyesOfNetwork installation files permissions could be set for notifier correct usage :
```bash
├── bin                                            # root:root 755
│   └── notifier.pl                                # root:root 755
├── docs                                           # root:root 755
│   ├── db                                         # root:root 755
│   │   ├── create_database.sh                     # root:root 644 - Needed for installation
│   │   ├── create_user.txt                        # root:root 644 - Production useless
│   │   └── notifier.sql                           # root:root 644 - Needed for installation
│   ├── notifier.cfg.md                            # root:root 644 - Production useless
│   ├── notifier_rules.log.md                      # root:root 644 - Production useless
│   ├── notifier.rules.md                          # root:root 644 - Production useless
│   ├── notifier_send.log.md                       # root:root 644 - Production useless
│   ├── platform.xsd.md                            # root:root 644 - Production useless
│   └── updates_scripts.md                         # root:root 644 - Production useless
├── etc                                            # root:root 755
│   ├── logrotate                                  # root:root 755
│   │   └── notifier                               # root:root 644
│   ├── messages                                   # root:root 644
│   │   ├── sms-app-critical                       # root:root 644
│   │   ├── sms-app-ok                             # root:root 644
│   │   └── sms-app-warning                        # root:root 644
│   ├── notifier.cfg                               # root:root 644
│   └── notifier.rules                             # nagios:eyesofnetwork 664
├── log                                            # nagios:eyesofnetwork 755
│   ├── notifier_rules.log                         # nagios:eyesofnetwork 644
│   └── notifier_send.log                          # nagios:eyesofnetwork 644
├── README.md                                      # root:root 644 - Production useless
├── scripts                                        # root:root 755
│   ├── createxml2sms.sh                           # root:root 755
│   └── updates                                    # root:root 755
│       ├── check_config_file.sh                   # root:root 755 - No prod run script
│       └── v2.1_to_v2.1-1.sh                      # root:root 755 - Upgrade script
└── var                                            # root:root 644
    └── www                                        # root:root 644
        └── index.html                             # root:root 644
```
