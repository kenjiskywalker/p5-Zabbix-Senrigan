use strict;
use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Zabbix::Senrigan;

my $snrgn = Zabbix::Senrigan->new(
    username    => "senrigun",
    password    => "senrigun",
    zabbix_url  => "http://localhost/zabbix",
);

my $mech = WWW::Mechanize->new(timeout => 180);

$mech->get($snrgn->zabbix_url);
$mech->field(name     => $snrgn->username);
$mech->field(password => $snrgn->password);
$mech->click('enter');

ok($mech->success);
is($mech->status, 200);
 
done_testing;
