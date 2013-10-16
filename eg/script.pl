#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Zabbix::Senrigan;

my $snrgn = Zabbix::Senrigan->new(
    username    => "zabbix_user",
    password    => "zabbix_password",
    zabbix_url  => "http://localhost/zabbix",
    data_source => "DBI:mysql:zabbix",
    db_username => "zabbix",
    db_password => "zabbinx",
    graph_name_list => ["CPU utilization", "Swap usage"],
    period      => 86400,
    time        => "120000",
    create_dir  => "../test_dir",
);

$snrgn->run;
