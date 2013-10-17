use strict;
use warnings;
use Test::More tests => 11;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Zabbix::Senrigan;

my $snrgn = Zabbix::Senrigan->new(
    username    => "senrigun",
    password    => "senrigun",
    zabbix_url  => "http://localhost/zabbix",
    data_source => "DBI:mysql:zabbix",
    db_username => "zabbix",
    db_password => "zabbix",
    graph_name_list => ["CPU utilization", "Swap usage"],
    period      => 86400,
    time        => "120000",
    create_dir  => "../hoge",
);

my @array = ("CPU utilization", "Swap usage");

isa_ok($snrgn, 'Zabbix::Senrigan');
is($snrgn->username,    'senrigun');
is($snrgn->password,    'senrigun');
is($snrgn->zabbix_url,  'http://localhost/zabbix');
is($snrgn->data_source, 'DBI:mysql:zabbix');
is($snrgn->db_username, 'zabbix');
is($snrgn->db_password, 'zabbix');
is($snrgn->period,      86400);
is($snrgn->time,        "120000");
is($snrgn->create_dir,  "../hoge");
cmp_ok(@{$snrgn->graph_name_list}, 'eq', @array);

done_testing;
