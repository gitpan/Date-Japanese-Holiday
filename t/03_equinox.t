use strict;
use Test::More "no_plan";

use Date::Japanese::Holiday;

ok(Date::Japanese::Holiday->new(2003, 3, 21)->is_holiday);
ok(Date::Japanese::Holiday->new(2003, 9, 23)->is_holiday);


