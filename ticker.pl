#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use LWP::UserAgent;
use JSON::XS;
use Try::Tiny;

my ($coins, $to_satoshi, $swisscex_key, $market, $preferred_exchange);
GetOptions(
	'coins=s'	=> \$coins,
	'to_satoshi' => \$to_satoshi,
	'swisscex_key=s' => \$swisscex_key,
	'market=s' => \$market,
	'preferred_exchange=s' => \$preferred_exchange,
);

die "List of coins is required!"
	unless $coins;

$preferred_exchange ||= 'mintpal';
$market = $market ? uc $market : 'BTC';

$coins = [ 
	map { 
		uc (/\// ? $_ : $_.'/'.$market)
	} (split /\s*,\s*/, $coins) 
];


my $market_data = get_market_data(
	$preferred_exchange =~ /mint/i ? 'mintpal' : 'swisscex'
);
my $count;
for my $available (@$market_data){
	++$count if grep {
		$available->{code} eq $_
	} @$coins;
}
if ($count != scalar @$coins){
	push @$market_data, @{get_market_data($preferred_exchange =~ /mint/i ? 'swisscex' : 'mintpal')};
}


my $btc_usd = get_btc_usd();

my %stats;
my ($btc_high,$btc_low,$btc_last) = map {
	$btc_usd->{$_}
} qw {
	high low last
};

my $output = <<BTC;
BTC/USD Market Data
High: \$$btc_high  Low: \$$btc_low  Last: \$$btc_last
BTC

for my $coin (@$coins){
	$stats{$coin} = fetch_coin($coin);
	my ($ex_name,$vol,$high,$low,$last) = map {
		to_satoshi($_, $stats{$coin}{$_})
	} qw {
		ex_name
		24hvol
		24hhigh
		24hlow
		last_price
	};
	$output = <<STATS;
$output
$coin - ${vol}BTC $ex_name
High: $high  Low: $low  Last: $last
STATS
}

system("notify-send 'Recent Coin Stats' '$output' -t 7500");

exit;

sub fetch_coin {
	my $coin = shift;
	return (sort {
		$b->{pref} <=> $a->{pref}
	} grep {
		$_->{code} eq $coin
	} @$market_data)[0];
}


sub get_market_data {
	my $exchange = shift;
	return [] if $exchange eq 'swisscex' && !$swisscex_key;
	my $web = LWP::UserAgent->new;
	my %urls = (
		mintpal => "https://api.mintpal.com/market/summary",
		swisscex => "http://api.swisscex.com/quotes?apiKey=$swisscex_key"
	);
	my $response = $web->get(
		$urls{$exchange}
	);

	return [] 
		unless $response->is_success;

	try {
		my $json = decode_json($response->decoded_content);
		if ($exchange eq 'swisscex'){
			my %map = (
				volume24 => '24hvol',
				low24 => '24hlow',
				high24 => '24hhigh',
				lastPrice => 'last_price',
				to => 'exchange',
				from => 'name'
			);
			for my $k (keys %map){
				for my $key (%$json){
					my $coin = $json->{$key};
					$coin->{code} = $key;
					$coin->{ex_name} = 'SwissCEX';
					$coin->{pref} = $preferred_exchange =~ /swiss/i;
					$coin->{$map{$k}} = delete $coin->{$k};
				}
			}
			return [
				values %$json
			];
		} elsif ($exchange eq 'mintpal') {
			for my $coin (@$json) {
				$coin->{name} = $coin->{code};
				$coin->{ex_name} = 'MintPal';
				$coin->{pref} = $preferred_exchange =~ /mint/i;
				$coin->{code} = uc $coin->{name}.'/'.$coin->{exchange};
			}
		}
		return $json;
	} catch {
		return [];
	}
}

sub get_btc_usd {
	my $web = LWP::UserAgent->new;
	my $response = $web->get(
		"https://www.bitstamp.net/api/ticker/"
	);

	return {}
		unless $response->is_success;

	my $market_data = {};
	try {
		return decode_json($response->decoded_content);
	} catch {
		return {};
	}
}

sub to_satoshi {
	my ($key,$num) = @_;
	return $num unless $to_satoshi;
	if ($key eq '24hvol'){
		$num = sprintf "%.2f", $num;
		return $num;
	}
	return $num unless grep {
		$key eq $_
	} qw(last_price 24hlow 24hhigh);
	$num *= 100000000;
	return $num.'s';
}
