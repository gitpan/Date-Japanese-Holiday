package Date::Japanese::Holiday;

use strict;
use Time::JulianDay qw(julian_day);
use Date::Calc ();
use vars qw($VERSION);
$VERSION = '0.01';

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

sub new {
    my($class, @args) = @_;
    if (@args == 1) {
	return $class->new_from_date(@args)
    }
    elsif (@args == 3) {
	return $class->new_from_ymd(@args)
    }
    else {
	_croak("odd number of arguments for ". __PACKAGE__. "->new");
    }
}

sub new_from_ymd {
    my($class, @ymd) = @_;
    my $self = bless {
	julian_day => 0,
	year => 0,
	month => 0, 
	mday => 0,
    }, $class;
    _croak("invalid date @ymd") unless eval { Date::Calc::check_date(@ymd) };
    $self->{year} = $ymd[0];
    $self->{month} = $ymd[1];
    $self->{day} = $ymd[2];
    my $jd = julian_day(@ymd);
    $self->{julian_day} = $jd;
    return $self;
}

sub new_from_date {
    my($class, $date) = @_;
    return $class->new_from_ymd(split(/-/, $date));
}

sub is_holiday {
    my $self = shift;
    return $self->is_fixed_holiday || $self->is_happy_monday_holiday || undef;
}

sub is_fixed_holiday {
    my $self = shift;
    my $dstr = sprintf("%02d-%02d", $self->{month}, $self->{day});
    return 1 if $dstr eq $self->vernal_equinox;
    return 1 if $dstr eq $self->autumnal_equinox;
    return undef unless $FIXED_HOLIDAY_TABLE{$dstr};
    my @range = @{$FIXED_HOLIDAY_TABLE{$dstr}};
    if ($self->{julian_day} > $range[0] && (!$range[1] || $self->{julian_day} < $range[1])) {
	return 1;
    }
    return undef;
}

sub is_happy_monday_holiday {
    my $self = shift;
    # the 2nd Monday of January
    return 1 if $self->ymd_equal(Date::Calc::Nth_Weekday_of_Month_Year($self->{year}, 1, 1, 2));
    # the 3rd Monday of July
    return 1 if $self->ymd_equal(Date::Calc::Nth_Weekday_of_Month_Year($self->{year}, 7, 1, 3));
    # the 3rd Monday of September
    return 1 if $self->ymd_equal(Date::Calc::Nth_Weekday_of_Month_Year($self->{year}, 9, 1, 3));
    # the 2nd Monday of October
    return 1 if $self->ymd_equal(Date::Calc::Nth_Weekday_of_Month_Year($self->{year}, 10, 1, 2));
    return undef;
}

sub ymd_equal {
    my($self, $y, $m, $d) = @_;
    return ($y == $self->{year} && $m == $self->{month} && $d == $self->{day});
}

sub _croak {
    require Carp;
    Carp::croak(@_);
}

sub vernal_equinox {
    my $self = shift;
    my $d = int( 20.8431 + 0.242194 * ($self->{year} - 1980) - int(($self->{year} - 1980) / 4) );
    return sprintf("%02d-%02d", 3, $d)
}

sub autumnal_equinox {
    my $self = shift;
    my $d = int(23.2488 + 0.242194 * ($self->{year} - 1980) - int(($self->{year} - 1980) / 4));
    return sprintf("%02d-%02d", 9, $d)
}

1;
__END__

=head1 NAME

Date::Japanese::Holiday - Calculate Japanese Holiday.

=head1 SYNOPSIS

  use Date::Japanese::Holiday;

  if(Date::Japanese::Holiday->new(2002, 2, 11)->is_holiday) {
       # ...
  }

=head1 DESCRIPTION

Date::Japanese::Holiday calculates Japanese Holiday.
this module supports from 1948-04-20 to now.

is_holiday method return true value when the day is Holiday.
the Holiday does not Include Sunday, Change Holiday.

=head1 AUTHOR

IKEBE Tomohiro E<lt>ikebe@edge.co.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Date::Calc> L<Time::JulianDay>

=cut
