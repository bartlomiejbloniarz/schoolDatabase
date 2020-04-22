DROP TABLE if EXISTS Przedmioty;
DROP TABLE if EXISTS Lekcje;
DROP TABLE if EXISTS Sale;
DROP TABLE if EXISTS Uczeniowie;
DROP TABLE if EXISTS Klasy;
DROP TABLE if EXISTS Nauczyciele;
DROP TABLE if EXISTS Pracownicy;

CREATE TABLE Pracownicy(
    id NUMERIC(2) NOT NULL CONSTRAINT PK_PRAC PRIMARY KEY,
    jestNauczycielem CHARACTER(1) NOT NULL, CHECK (jestNauczycielem='T' OR jestNauczycielem='N'),
    godzinyPracy NUMERIC(2),
    stanowisko CHARACTER VARYING NOT NULL,
    CHECK (stanowisko='NAUCZYCIEL' OR stanowisko='DYREKTOR' OR stanowisko='SEKRETARZ' OR stanowisko='OSOBA SPRZĄTAJĄCA'
               OR stanowisko='OPIEKA MEDYCZNA' OR stanowisko='SPRZEDAWCA' OR stanowisko='PSYCHOLOG')
);
CREATE TABLE Nauczyciele(
    wychowawca NUMERIC(1) NOT NULL REFERENCES Pracownicy(id),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    id NUMERIC(2) CONSTRAINT PK_NAUCZ PRIMARY KEY
);
CREATE TABLE Klasy(
    klasa CHARACTER(2) NOT NULL,
    PRIMARY KEY (klasa),
    wychowawca NUMERIC(2) NOT NULL REFERENCES Nauczyciele(id),
    liczba_uczniow NUMERIC(3) NOT NULL
);
CREATE TABLE Uczeniowie(
    index NUMERIC(3) CONSTRAINT PK_UCZ PRIMARY KEY,
    klasa CHARACTER(2) NOT NULL REFERENCES Klasy(klasa),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL
);
CREATE TABLE Sale(
    nr NUMERIC CONSTRAINT PK_SALE PRIMARY KEY,
    liczba_miejsc NUMERIC NOT NULL
);
CREATE TABLE Lekcje(
    nauczyciel NUMERIC(2) NOT NULL REFERENCES Nauczyciele(id),
    Sala NUMERIC(2) NOT NULL REFERENCES Sale(nr),
    klasa CHARACTER(2) NOT NULL REFERENCES Klasy(klasa),
    czas TIME NOT NULL, CHECK (EXTRACT(hour FROM czas)>=8 AND EXTRACT(hour FROM czas)<=17),
    dzien CHARACTER VARYING NOT NULL,
    CHECK(dzien='Poniedzialek' OR dzien='Wtorek' OR dzien='Środa' OR dzien='Czwartek' OR dzien='Piątek')
);
CREATE TABLE Przedmioty(
    nazwa CHARACTER VARYING NOT NULL,
    nauczyciel NUMERIC(2) NOT NULL REFERENCES Nauczyciele(id),
    PRIMARY KEY(nazwa,nauczyciel)
);
