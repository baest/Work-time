edit:
	$(EDITOR) server.p6 client.p6 lib/*.pm6 t/*.p6

test:
	prove --exec perl6 -v -r t/*.p6
