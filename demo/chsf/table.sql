CREATE TABLE document
(
	id	PRIMARY KEY
	root	text
	xml	text
);

CREATE TABLE trace
(
	id		PRIMARY KEY,
	docid		int REFERENCES xmldoc(id),
	type		varchar(1),
	name		text,
	content	text
);
