package Utility::KLPDB;

use strict;
use warnings;

require Exporter;
use DBI;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
        connect
        db_get_value
        last_inserted_key
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

sub connect {
    return (DBI->connect_cached('dbi:Oracle:' . $ENV{KLP_DB}, 
                                $ENV{KLP_USER}, 
                                $ENV{KLP_PASSWD}, 
                                { AutoCommit => 0 ,
                                  RaiseError => 1,
                                  FetchHashKeyName => "NAME_lc" }) 
                or die "Could not connect to the database\n");
}
