package Zabbix::Senrigan;

use 5.010;
use strict;
use warnings;
use utf8;

our $VERSION = "0.01";

use autodie qw(open close);

use POSIX;
use Encode;
use Text::Xslate;
use File::Spec;
use FindBin;
use lib "$FindBin::Bin/tmpl";
use Data::Section::Simple;
use WWW::Mechanize;
use Date::Simple::D8;
use Parallel::ForkManager;
use Carp;
use DBI;
use Moo;

use File::Spec;
use File::Basename qw(dirname);
use File::Copy::Recursive qw(rcopy);


### Zabbix Settings ###
has username   => (is => 'rw');
has password   => (is => 'rw');
has zabbix_url => (is => 'rw');

### MySQL settings ###
has data_source => (is => 'rw', default => sub {"DBI:mysql:zabbix"});
has db_username => (is => 'rw');
has db_password => (is => 'rw');

### Graph
has graph_name_list => (is => 'rw', default => sub { ["CPU utilization", "Swap usage"] });
has graphiid_list   => (is => 'rw');
has view_graph_num  => (is => 'rw', default => sub { 3 });
has period          => (is => 'rw', default => sub { 1209600 }); # 86400 => 1day. 1209600 => 2week.
has time            => (is => 'rw', default => sub { "090000" }); # set graph time. 09:00:00
has create_dir      => (is => 'rw', default => sub { "senrigun" });

sub run {
    my $self = shift;
    my @graphids;
    my $create_dir = $self->create_dir;

    my $basedir  = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__)));
    my $tmpl_dir = File::Spec->catfile($basedir, '../../tmpl');
    my $css_dir  = File::Spec->catfile($basedir, '../../bootstrap');

    my $tx = Text::Xslate->new(path => $tmpl_dir);

    mkdir("./$create_dir", 0755) or die if (!-d "./$create_dir");

    my $graph_name_num = 0;
    for my $graph_name (@{$self->graph_name_list}) {

        @graphids = $self->_get_graphids_from_sql($graph_name);
        my @view_num = $self->_get_view_num_from_graph_name(@graphids);

        ### graph.png download  by Mechanize
        $self->_download_graph_images(@graphids);

        my $spliced_graphid_num = 0;
        while (my @spliced_graphids = splice @graphids, 0, $self->view_graph_num) {

            my $graph_data = $tx->render("template.tx",
                {
                    graph_name_num      => $graph_name_num,
                    graph_name          => $graph_name,
                    graph_name_list     => \@{$self->graph_name_list},
                    view_num            => \@view_num,
                    spliced_graphids    => \@spliced_graphids,
                }
            );

            open my $fh, '>', "./$create_dir/".$graph_name_num."_".$spliced_graphid_num.".html" or die $!; # open ex) $key(cpu)_$num(one).html
            print $fh encode_utf8($graph_data);
            close($fh);
            $spliced_graphid_num++;
        }
        $graph_name_num++;
    }

    my $index_graph_data = $tx->render("index.tx",
        {
            graph_name_list => \@{$self->graph_name_list},
        }
    );

    rcopy $css_dir, "$create_dir/bootstrap" or die $!;

    open my $fh, '>', "$create_dir/index.html" or die $!;
    print $fh encode_utf8($index_graph_data);
    close($fh);
}

sub _get_graphids_from_sql {
    my $self = shift;
    my $graph_name = shift;
    my @ids;

    eval {
       my $dbh = DBI->connect($self->data_source, $self->db_username, $self->db_password,
               {RaiseError => 1, PrintError => 0});

       my $sth = $dbh->prepare('SELECT graphid FROM graphs WHERE name = ?');
       $sth->execute($graph_name);

       while (my $id= $sth->fetchrow_arrayref) {
                push(@ids, $id->[0]);
       }

       $sth->finish;
       $dbh->disconnect;
   };

   croak "Error : $@\n" if ($@);
   return @ids;
}

sub _download_graph_images{
    my $self = shift;
    my @ids = @_;
    my $pm = new Parallel::ForkManager(2);
    my $url    = $self->zabbix_url;
    my $period = $self->period;
    my $time   = $self->time;
    my $create_dir = $self->create_dir;

    my $width  = 500;
    my $days   = Date::Simple::D8->new() - ( $period / 60 / 60 / 24); # 所作が合ってるのか謎
 
    # my $mech = WWW::Mechanize->new(ssl_opts => { verify_hostname => 0 }, timeout => 180);
    my $mech = WWW::Mechanize->new(timeout => 180);

    $mech->timeout(30);
    $mech->get($self->zabbix_url);
    $mech->field(name     => $self->username);
    $mech->field(password => $self->password);
    $mech->click('enter');

    mkdir("./$create_dir/png", 0755) or die if (!-d "./$create_dir/png");

    for my $graphid (@ids) {
        $pm->start and next;
        my $graphurl = "$url/chart2.php?graphid=$graphid&width=$width&period=$period&stime=$days$time";

        # main system get png image 
        $mech->get("$graphurl",":content_file" => "$create_dir/png/${graphid}.png"); 
        print "$graphurl\n";

        $pm->finish;
        $pm->wait_all_children;
    }
}

# Template内で while $n <= $m ; $n++ みたいなのできたらここいらない。
sub _get_view_num_from_graph_name {
    my $self = shift;
    my @ids = @_;
    my $view_page = ceil(scalar(@ids) / $self->view_graph_num);
    my @view_num;

    for (my $i = 0; ($view_page -1) >= $i ; $i++){
        push(@view_num, $i)
    };

    return @view_num;
}

1;

__END__

=encoding utf-8

=head1 NAME

Zabbix::Senrigan - It's new $module

=head1 SYNOPSIS

    use Zabbix::Senrigan;

=head1 DESCRIPTION

Zabbix::Senrigan is ...

=head1 LICENSE

Copyright (C) kenjiskywalker.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kenjiskywalker E<lt>git@kenjiskywalker.orgE<gt>

=cut

