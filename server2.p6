use v6;

use lib 'lib';
use Server;

multi sub MAIN() { Server.new.start; }
multi sub MAIN(Bool :$verbose) {
	Server.new(:$verbose).start;
}
