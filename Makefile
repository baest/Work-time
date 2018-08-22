edit:
	$(EDITOR) server.p6 lib/*.pm6 t/*.p6

test:
	prove --exec perl6 -v -r t/*.p6

depends:
	zef install DateTime::Parse
	zef install DBIish
	zef install --/test cro
	zef install Cro::HTTP::Test

