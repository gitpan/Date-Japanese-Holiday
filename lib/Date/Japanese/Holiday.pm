package Date::Japanese::Holiday;

use strict;
use Time::JulianDay ();
use Date::Calc ();
require Exporter;
use vars qw($VERSION @EXPORT_OK);
use base qw(Date::Simple Exporter);
@EXPORT_OK = qw(is_japanese_holiday);

$VERSION = '0.04';

# Too many magic numbers..
use vars qw(%FIXED_HOLIDAY_TABLE);
use constant FIRST_DAY => 2432753;
%FIXED_HOLIDAY_TABLE = (
    '01-01' => [FIRST_DAY, 0],
    '01-15' => [FIRST_DAY, 2451544],
    '02-11' => [2439469, 0],
    '04-29' => [FIRST_DAY, 0],
    '05-03' => [FIRST_DAY, 0],
    '05-05' => [FIRST_DAY, 0],
    '07-20' => [2450084, 2452640],
    '09-15' => [2439302, 2452640],
    '10-10' => [2439302, 2451544],
    '11-03' => [FIRST_DAY, 0],
    '11-23' => [FIRST_DAY, 0],
    '12-23' => [2447575, 0],
);

sub is_holiday {
    my $self = shift;
    return 
	$self->day_of_week == 7 || $self->is_basic_holiday || 
	    $self->is_change_holiday || $self->is_between_holiday || 
		$self->is_special_holiday;
}

sub is_basic_holiday {
    my $self = shift;
    return $self->is_fixed_holiday || $self->is_float_holiday || undef;
}

sub is_change_holiday {
    my $self = shift;
    my $prev = $self->prev;
    return $self->julian_day >= 2441785 && 
	$prev->is_basic_holiday && $prev->day_of_week == 7;
}

sub is_between_holiday {
    my $self = shift;
    my $next = $self->next;
    my $prev = $self->prev;
    $self->julian_day >= 2446427 &&
	$self->day_of_week != 7 &&
	    !$self->is_change_holiday &&
		$prev->is_basic_holiday && $next->is_basic_holiday;
}

sub is_special_holiday {
    my $self = shift;
    my $jd = $self->julian_day;
    my $str = sprintf("%04d-%02d-%02d", $self->year, $self->month, $self->day);
    return $str eq "1989-02-24" || $str eq "1990-11-12" || 
	$str eq "1993-06-09";
}

sub is_fixed_holiday {
    my $self = shift;
    my $dstr = sprintf("%02d-%02d", $self->month, $self->day);
    return 1 if $self->julian_day == $self->vernal_equinox;
    return 1 if $self->julian_day == $self->autumnal_equinox;
    return undef unless $FIXED_HOLIDAY_TABLE{$dstr};
    my $jd = $self->julian_day;
    my @range = @{$FIXED_HOLIDAY_TABLE{$dstr}};
    if ($jd > $range[0] && (!$range[1] || $jd < $range[1])) {
	return 1;
    }
    return undef;
}

sub is_float_holiday {
    my $self = shift;
    my $jd = $self->julian_day;
    return 
    ($self->month == 1 && 
	 $self->is_nth_wday(2, 1) && $jd >= 2451545) ||
    ($self->month == 7 && 
	 $self->is_nth_wday(3, 1) && $jd >= 2452641) ||
    ($self->month == 9 && 
	 $self->is_nth_wday(3, 1) && $jd >= 2452641) ||
    ($self->month == 10 && 
	 $self->is_nth_wday(2, 1) && $jd >= 2451545);
}

sub day_of_week {
    my $self = shift;
    return Date::Calc::Day_of_Week($self->year, $self->month, $self->day);
}

sub is_nth_wday {
    my($self, $n, $dow) = @_;
    my($y, $m, $d) = 
	Date::Calc::Nth_Weekday_of_Month_Year($self->year, $self->month, $dow, $n);
    return $self->year == $y && $self->month == $m && $self->day == $d;
}

sub julian_day {
    my $self = shift;
    return Time::JulianDay::julian_day($self->year, $self->month, $self->day);
}

sub _deq {
    my($self, $a, $b) = @_;
    my $y = $self->year;
    my $d = int($a + 0.242194 * ($y - 1980) - int(($y - $b) / 4));
    return $d;
}

sub vernal_equinox {
    my $self = shift;
    my $y = $self->year;
    my($a, $b);
    if ($y >= 1900 && $y <= 1979) {
	$a = 20.8357; $b = 1983.0;
    }
    if ($y >= 1980 && $y <= 2099) {
	$a = 20.8431; $b = 1980.0;
    }
    if ($y >= 2100 && $y <= 2150) {
	$a = 21.8510; $b = 1980.0;
    }
    return Time::JulianDay::julian_day($y, 3, $self->_deq($a, $b));
}

sub autumnal_equinox {
    my $self = shift;
    my $y = $self->year;
    if ($y >= 1900 && $y <= 1979) {
	$a = 23.2588; $b = 1983.0;
    }
    if ($y >= 1980 && $y <= 2099) {
	$a = 23.2488; $b = 1980.0;
    }
    if ($y >= 2100 && $y <= 2150) {
	$a = 24.2488; $b = 1980.0;
    }
    return Time::JulianDay::julian_day($y, 9, $self->_deq($a, $b));
}

# functional interface
sub is_japanese_holiday {
    my($y, $m, $d) = @_;
    my $obj = __PACKAGE__->new($y, $m, $d);
    return $obj->is_holiday ? $obj : undef;
}

1;
__END__

=head1 NAME

Date::Japanese::Holiday - Calculate Japanese Holiday.

=head1 SYNOPSIS

  # OO interface
  use Date::Japanese::Holiday;

  if(Date::Japanese::Holiday->new(2002, 2, 11)->is_holiday) {
       # ...
  }

  # functional interface
  use Date::Japanese::Holiday qw(is_japanese_holiday);

  # return Date::Japanese::Holiday object or undef.
  if(is_japanese_holiday(2002, 11, 23)) {
      # ...
  }

=head1 DESCRIPTION

Date::Japanese::Holiday is-a L<Date::Simple>, and calculates Japanese Holiday.
this module supports from 1948-04-20 to now.

is_holiday method return true value when the day is Holiday.

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Date::Simple> L<Date::Calc> L<Time::JulianDay> L<Date::Japanese::Era>

=cut
