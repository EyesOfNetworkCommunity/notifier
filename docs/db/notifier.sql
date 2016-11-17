DROP TABLE IF EXISTS `sents_logs`;

CREATE TABLE `sents_logs` (
  `id` int(255) unsigned NOT NULL AUTO_INCREMENT,
  `nagios_date` varchar(255) DEFAULT NULL,
  `contact` longtext DEFAULT NULL,
  `host` longtext DEFAULT NULL,
  `service` longtext DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `notification_number` int(11) DEFAULT NULL,
  `method` varchar(255) DEFAULT NULL,
  `priority` tinyint(1) DEFAULT NULL,
  `matched_rule` longtext DEFAULT NULL,
  `exit_code` tinyint(1) DEFAULT NULL,
  `exit_command` longtext DEFAULT NULL,
  `epoch` int(255) unsigned DEFAULT NULL,
  `cmd_duration` int(255) unsigned DEFAULT NULL,
  `notifier_duration` int(255) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
