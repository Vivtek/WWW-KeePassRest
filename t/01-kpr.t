#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use WWW::KeePassRest;

my $kpr = WWW::KeePassRest->new();
eval { my $test_connection = $kpr->get("this is not a UUID"); };
if ($@ =~ /^KeePass not running/) {
   plan( skip_all => "KeePass and KeePassRest aren't running. Can't test anything." );
}

plan tests => 10;

eval { $kpr = WWW::KeePassRest->new(cert_file => 't/01-kpr.t'); };
like ($@, qr/^Must provide both cert and key file/);

$kpr = WWW::KeePassRest->new();

my $newkey = $kpr->create_and_return ({ Title => 'wwwkpr test',
                                        Password => 'test',
                                        URL => 'http://test.cpan.org/wwwkpr' });
                                        
my $list = $kpr->get_all('wwwkpr test', 'SearchInTitles');
my @k = keys %$list;
ok (@k >= 1);  # There must be at least one key with this title now.
is ($list->{$k[0]}->{Title}, 'wwwkpr test');


# Check it, modify it, delete it.
my $entry = $kpr->get ($newkey);
is (ref($entry), 'HASH');
is ($entry->{'Password'}, 'test');
$entry->{'test-string'} = 'this is a test value';
is ($kpr->update ($newkey, $entry), 1);

my ($password, $test) = $kpr->get_by_url ('http://test.cpan.org/wwwkpr', 'Password', 'test-string');
is ($password, 'test');
is ($test, 'this is a test value');
is ($kpr->delete ($newkey), 1);

eval { $kpr->get($newkey); };
like ($@, qr/^UUID not found/);
