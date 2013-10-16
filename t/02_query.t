use strict;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Zabbix::Senrigan;

use DBI;

my $snrgn = Zabbix::Senrigan->new(
    data_source => "DBI:mysql:zabbix",
    db_username => "zabbix",
    db_password => "zabbix",
);

my @ids;
my $graph_name = "CPU utilization";

my $dbh = DBI->connect($snrgn->data_source, $snrgn->db_username, $snrgn->db_password,
        {RaiseError => 1, PrintError => 0});

my $sth = $dbh->prepare('SELECT graphid FROM graphs WHERE name = ?');
$sth->execute($graph_name);

while (my $id= $sth->fetchrow_arrayref) {
         push(@ids, $id->[0]);
}

$sth->finish;
$dbh->disconnect;

ok($dbh);
ok($sth);
isa_ok($dbh, 'DBI::db');

done_testing;
