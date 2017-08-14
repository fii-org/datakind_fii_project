CREATE TABLE fii_anomalies (
	FamilyID integer NOT NULL,
	MonthsInFII integer,
	Value numeric NOT NULL,
	Mean numeric NOT NULL,
	STD numeric NOT NULL,
	JournalDate date,
	Measure varchar(40),
	Status varchar(40),
	AuthorID varchar(50),
	InsertDate timestamp DEFAULT current_timestamp
	)


CREATE VIEW fii_anomalies_current AS
SELECT "FamilyID","MonthsInFII", "Value", "Mean","STD","JournalDate","Measure","Status", "AuthorID","InsertDate" FROM (
SELECT *,
ROW_NUMBER() OVER (PARTITION BY "FamilyID", "JournalDate", "Measure" ORDER BY "InsertDate" desc) from fii_anomalies) a 
where row_number=1

CREATE TABLE films (
    code        char(5) CONSTRAINT firstkey PRIMARY KEY,
    title       varchar(40) NOT NULL,
    did         integer NOT NULL,
    date_prod   date,
    kind        varchar(10),
    len         interval hour to minute
);
