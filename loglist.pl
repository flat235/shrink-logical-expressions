#!/usr/bin/perl

use strict;

my $list = new loglist(undef);
$list->makelist('A & A | B & ( B & ( F | C ) ) & ( C | D ) & E');
print $list->print;
print "\n";
$list->ease;
print $list->print;
print "\n";
package loglist;

sub new{
  my ($class, $left) = @_;
	my $self = bless{
		left => $left,
		right => undef,
		type => undef,
		child => undef
	}, $class;
	return $self;
}

sub print{

	my $self = shift;
	my $string = "";
	if($self->{type} eq 'ATOM'){
		$string = '(' . $self->{child}->print() . ')';
	}
	elsif($self->{type} eq 'STRING'){
		$string = $self->{child};
	}
	elsif($self->{type} eq 'NOT'){
		$string = '^(' . $self->{child}->print . ')';
	}
	else{
		$string = ' ' . $self->{type} . ' ';
	}
	if($self->{right}){
		$string .= $self->{right}->print;
	}
	$string =~ s/\((\w*)\)/$1/g;
	$string =~ s/AND/&/g;
	$string =~ s/OR/|/g;
	$string =~ s/(\w)\s*\)/$1)/g;
	$string =~ s/\)\s+\)/))/g;
	return $string;
}

sub makelist{
	my ($self, $string) = @_;
	$string =~ s/\s//g;
	if($string =~ s/^\^//){
		#conf self
		$self->{type} = 'NOT';
		$self->{child} = new loglist(undef);
		#ATOM or ()
		my $substring;
		if($string =~ /^\(/){
			my @par = split /(\(|\))/, $string;
			$substring = shift( @par ) . shift( @par );
			$substring .= shift @par while ($substring =~ tr/(/(/) ne ($substring =~ tr/)/)/);
			$substring =~ s/^\(|\)$//g;
			$self->{child}->makelist($substring);
			$self->{right} = new loglist($self);
			$self->{right}->makelist(join("",@par));
		}
		else{
			#ATOM
			$string =~ s/^(\w*)//;
			$substring = $1;
			$self->{child}->{type} = 'ATOM';
			$self->{child}->{child} = new loglist(undef);
			$self->{child}->{child}->{type} = 'STRING';
			$self->{child}->{child}->{child} = $substring;
			$self->{right} = new loglist($self);
			$self->{right}->makelist($string);
		}
		

	}
	elsif($string =~ s/^(\w+)//){
		my $substring = $1;
		$self->{type} = 'ATOM';
		$self->{child} = new loglist;
		$self->{child}->{type} = 'STRING';
		$self->{child}->{child} = $substring;
		$self->{right} = new loglist($self);
		$self->{right}->makelist($string);
	}
	elsif($string =~ s/^&//){
		$self->{type} = 'AND';
		$self->{right} = new loglist($self);
		$self->{right}->makelist($string);
	}
	elsif($string =~ s/^\|//){
		$self->{type} = 'OR';
		$self->{right} = new loglist($self);
		$self->{right}->makelist($string);
	}
	elsif($string =~ /^\(/){
		$self->{type} = 'ATOM';
		my @par = split /(\(|\))/, $string;
		my $substring = shift( @par ) . shift( @par );
		$substring .= shift @par while ($substring =~ tr/(/(/) ne ($substring =~ tr/)/)/);
		$substring =~ s/^\(|\)$//g;
		$self->{child} = new loglist(undef);
		$self->{child}->makelist($substring);
		$self->{right} = new loglist($self);
		$self->{right}->makelist(join("",@par));	
	}
}

sub compare{
	my ($bla, $blub) = @_;
	my $ret = 1;
	$ret &= ($bla->{type} eq $blub->{type});
	if($bla->{child} =~ /(\w*)/){
		$ret &= ($bla->{child} eq $blub->{child});
	}
	if($bla->{right}){
		$ret &= compare($bla->{right}, $blub->{right});
	}
	return $ret;
}

sub ease{
	my $self = shift;
	# a & a|b = a
	# a | a&b = a
	if(($self->{type} eq 'AND') and
			($self->{right}->{type} eq $self->{left}->{type}) and
			compare($self->{left}->{child}, $self->{right}->{child})){
		$self->{left}->{right} = $self->{right}->{right};
		$self->{left}->{right}->ease;
		if($self->{left}->{right}->{child}){
			$self->{left}->{right}->{child}->ease;
		}
	}
	else{
		if($self->{right}){
			$self->{right}->ease;
		}
	}
	
}
