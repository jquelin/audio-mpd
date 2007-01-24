
use strict;
use Test;


# use a BEGIN block so we print our plan before Audio::MPD is loaded
BEGIN { plan tests => 1 }

# load Audio::MPD
use Audio::MPD;


# Helpful notes.  All note-lines must start with a "#".
print "# I'm testing Audio::MPD version $Audio::MPD::VERSION\n";

# Module has loaded sucessfully 
ok(1);


exit;

