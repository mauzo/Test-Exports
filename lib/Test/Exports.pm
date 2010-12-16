package Test::Exports;

use warnings;
use strict;

use B;

use parent "Test::Builder::Module";

our @EXPORT = qw/
    new_import_pkg 
    import_ok import_nok
    is_import cant_ok
/;

our $VERSION = "1";

my $CLASS = __PACKAGE__;
my $counter = "AAAAA";
my $PKG;

sub new_import_pkg { $counter++; $PKG = "$CLASS\::Test$counter" }
new_import_pkg;

sub import_ok {
    my ($mod, $args, $msg) = @_;
    my $tb  = $CLASS->builder;

    local $" = ", ";
    $args   ||= [];
    $msg    ||= "$mod->import(@$args) succeeds";

    my $code = "package $PKG; $mod->import(\@\$args); 1";

    #$tb->diag($code);

    my $eval = eval $code;

    $tb->ok($eval, $msg) or $tb->diag(<<DIAG);
$mod->import(@$args) failed:
$@
DIAG
}

sub import_nok {
    my ($mod, $args, $msg) = @_;
    my $tb  = $CLASS->builder;

    local $" = ", ";
    $args   ||= [];
    $msg    ||= "$mod->import(@$args) fails";

    my $eval = eval "package $PKG; $mod->import(\@\$args); 1";

    $tb->ok(!$eval, $msg) or $tb->diag(<<DIAG);
$mod->import(@$args) succeeded where it should have failed.
DIAG
}

sub is_import {
    my $msg  = pop;
    my $from = pop;
    my $tb = $CLASS->builder;

    my @nok;

    for (@_) {
        my $to = "$PKG\::$_";

        no strict 'refs';
        unless (defined &$to) {
            push @nok, <<DIAG;
  \&$to is not defined
DIAG
            next;
        }

        \&$to == \&{"$from\::$_"} or push @nok, <<DIAG;
  \&$to is not imported correctly
DIAG
    }

    my $ok = $tb->ok(!@nok, $msg) or $tb->diag(<<DIAG);
Expected subs to be imported from $from:
DIAG
    $tb->diag($_) for @nok;
    return $ok;
}

sub cant_ok {
    my $msg = pop;
    my $tb  = $CLASS->builder;

    my @nok;

    for (@_) {
        my $can = $PKG->can($_);
        $can and push @nok, $_;
    }

    my $ok = $tb->ok(!@nok, $msg);
    
    for (@nok) {
        my $from = B::svref_2object($PKG->can($_))->GV->STASH->NAME;
        $tb->diag(<<DIAG);
    \&$PKG\::$_ is imported from $from
DIAG
    }

    return $ok;
}

1;
