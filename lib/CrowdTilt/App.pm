package CrowdTilt::App;
use strict;
use warnings;

use Dancer ':syntax';
use Data::Dumper;
use Net::Twitter;
use Dancer::Plugin::Cache::CHI;

use Scalar::Util 'blessed';
use Array::Utils qw(:all);

our $VERSION = '0.1';

my $nt = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    consumer_key        => config->{consumer_key},
    consumer_secret     => config->{consumer_secret},
    access_token        => config->{token},
    access_token_secret => config->{token_secret},
		ssl                 => 1,
);

#--------------------------------------------------------
get '/' => sub {
    template 'index';
};

# Returns the most recent timeline for the user
#--------------------------------------------------------
get '/user/:screen_name/user_timeline' => sub {
		
	my @timeline;
	
	eval {
	    my $statuses = $nt->user_timeline({ screen_name=> params->{screen_name} });
	    for my $status ( @$statuses ) {
	       push( @timeline, $status->{text} );
	    }
	};
	
	if ( my $err = $@ ) {
	    die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

	    warn "HTTP Response Code: ", $err->code, "\n",
	         "HTTP Message......: ", $err->message, "\n",
	         "Twitter error.....: ", $err->error, "\n";
	};
	
	return { results => \@timeline }
	
};

# Returns the intersection of following users for 2 users.
#---------------------------------------------------------
get '/user/followers' => sub {
		
	my @first; my @second;
	
	eval {
		for ( my $cursor = -1, my $r; $cursor; $cursor = $r->{next_cursor} ) {
			$r = $nt->friends_ids({ cursor => $cursor, screen_name=> params->{u1} });
	 	 	push @first, @{ $r->{ids} };
		}
   
		for ( my $cursor = -1, my $r; $cursor; $cursor = $r->{next_cursor} ) {
			$r = $nt->friends_ids({ cursor => $cursor, screen_name=> params->{u2} });
	 	 	push @second, @{ $r->{ids} };
		}
	};
	
	if ( my $err = $@ ) {
	    die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

	    warn "HTTP Response Code: ", $err->code, "\n",
	         "HTTP Message......: ", $err->message, "\n",
	         "Twitter error.....: ", $err->error, "\n";
	};
	
	my @diff = intersect(@first, @second);
	
	my @ids;
	push @ids, [ splice @diff, 0, 100 ] while @diff;
	
	my @common;
	foreach my $id (@ids)
	{	
			debug($id );
	    my $users = $nt->lookup_users({ user_id => $id });
	    for my $user ( @{$users} ) {
					my @ua = $user;
					push( @common, $ua[0]->{screen_name});
	    }
	}
	
	return { results => \@common }
};

true;
