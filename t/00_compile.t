use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok $_ for qw(
    Zabbix::Senrigan
);

done_testing;

