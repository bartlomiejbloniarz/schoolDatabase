DROP TABLE if EXISTS Przedmioty;
DROP TABLE if EXISTS Lekcje;
DROP TABLE if EXISTS Sale CASCADE;
DROP TABLE if EXISTS Uczeniowie;
DROP TABLE if EXISTS Uczniowie;
DROP TABLE if EXISTS Klasy CASCADE;
DROP TABLE if EXISTS Nauczyciele;
DROP TABLE if EXISTS Pracownicy CASCADE;
DROP TABLE if EXISTS Place;
DROP TABLE if EXISTS Obiekty CASCADE;
DROP TABLE if EXISTS Inwentaz;
DROP TABLE if EXISTS Drogi_ewakuacyjne;

--SEQUENCES

DROP SEQUENCE IF EXISTS Pracownicy_id_seq;
CREATE SEQUENCE Pracownicy_id_seq MINVALUE 0 START 0;

--TABLES

CREATE TABLE Place(
    stanowisko CHARACTER VARYING NOT NULL,
    CHECK (stanowisko='NAUCZYCIEL' OR stanowisko='DYREKTOR' OR stanowisko='SEKRETARZ' OR stanowisko='OSOBA SPRZĄTAJĄCA'
               OR stanowisko='OPIEKA MEDYCZNA' OR stanowisko='SPRZEDAWCA' OR stanowisko='PSYCHOLOG'),
    tytul VARCHAR CHECK(tytul='DOKTOR' OR tytul='MAGISTER' OR tytul='PROFESOR' OR tytul='DOKTOR HABILITOWANY' OR tytul='BRAK'),
    PRIMARY KEY (stanowisko,tytul),
    placa NUMERIC(6,2) NOT NULL
);

CREATE TABLE Pracownicy(
    id NUMERIC(2) NOT NULL CONSTRAINT PK_PRAC PRIMARY KEY DEFAULT(nextval('Pracownicy_id_seq')) CHECK(id>=0),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    godzinyPracy NUMERIC(2),
    stanowisko CHARACTER VARYING NOT NULL,
    tytul VARCHAR  CHECK(tytul='DOKTOR' OR tytul='MAGISTER' OR tytul='PROFESOR' OR tytul='DOKTOR HABILITOWANY' OR tytul='BRAK'),
    CHECK (stanowisko='NAUCZYCIEL' OR stanowisko='DYREKTOR' OR stanowisko='SEKRETARZ' OR stanowisko='OSOBA SPRZĄTAJĄCA'
               OR stanowisko='OPIEKA MEDYCZNA' OR stanowisko='SPRZEDAWCA' OR stanowisko='PSYCHOLOG'),
    FOREIGN KEY (stanowisko, tytul) REFERENCES Place
);

CREATE TABLE Klasy(
    klasa CHARACTER(2) NOT NULL,
    PRIMARY KEY (klasa),
    wychowawca NUMERIC(2) NOT NULL REFERENCES Pracownicy(id)
);

CREATE TABLE Uczniowie(
    index NUMERIC(3) CONSTRAINT PK_UCZ PRIMARY KEY,
    klasa CHARACTER(2) NOT NULL REFERENCES Klasy(klasa),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL
);

CREATE TABLE Drogi_ewakuacyjne(
    id NUMERIC(2) PRIMARY KEY,
    nr_klatki NUMERIC(2),
    nr_wyjscia NUMERIC(2) NOT NULL,
    miejsce_zbiorki VARCHAR NOT NULL
);
CREATE TABLE Sale(
    nr NUMERIC CONSTRAINT PK_SALE PRIMARY KEY,
    droga_ewakuacyjna NUMERIC(2) NOT NULL REFERENCES Drogi_ewakuacyjne(id),
    liczba_miejsc NUMERIC NOT NULL CHECK (liczba_miejsc>20)
);

CREATE TABLE Lekcje(
    nauczyciel NUMERIC(2) NOT NULL REFERENCES Pracownicy(id),
    sala NUMERIC(2) NOT NULL REFERENCES Sale(nr),
    klasa CHARACTER(2) NOT NULL REFERENCES Klasy(klasa),
    czas TIME NOT NULL, CHECK (EXTRACT(hour FROM czas)>=8 AND EXTRACT(hour FROM czas)<=17 AND EXTRACT(minutes FROM czas)=0),
    dzien CHARACTER VARYING NOT NULL,
    CHECK(dzien='Poniedzialek' OR dzien='Wtorek' OR dzien='Środa' OR dzien='Czwartek' OR dzien='Piątek')
);

CREATE TABLE Przedmioty(
    nazwa CHARACTER VARYING NOT NULL,
    nauczyciel NUMERIC(2) NOT NULL REFERENCES Pracownicy(id),
    PRIMARY KEY(nazwa,nauczyciel)
);

CREATE TABLE Obiekty(
    id NUMERIC(2) PRIMARY KEY,
    nazwa VARCHAR NOT NULL UNIQUE,
    wartosc NUMERIC NOT NULL
);

CREATE TABLE Inwentaz(
    obiekt NUMERIC(2) REFERENCES Obiekty(id),
    sala NUMERIC(2) REFERENCES Sale(nr),
    PRIMARY KEY (obiekt, sala),
    ilosc NUMERIC(2)
);

--TRIGGERS

create or replace function addKid()
    returns TRIGGER AS
    $$
    declare
       record record;
        dzieci NUMERIC;
    begin
        dzieci=(SELECT COUNT(*) FROM Uczniowie WHERE klasa=NEW.klasa)+1;
        for record in SELECT* FROM Lekcje loop
            if(record.klasa=NEW.klasa AND dzieci >(SELECT liczba_miejsc FROM sale WHERE sale.nr=record.sala))
                THEN RAISE EXCEPTION 'Klasa jest pełna';END IF;
         end loop;
        return NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER "liczbaDzieci" BEFORE INSERT ON Uczniowie FOR EACH ROW EXECUTE PROCEDURE addKid();

create or replace function addLesson()
    returns TRIGGER AS
    $$
    declare
       record record;
    begin

        for record in SELECT* FROM Lekcje loop
            if(record.klasa=NEW.klasa AND record.czas=NEW.czas AND record.dzien=NEW.dzien)
                THEN RAISE EXCEPTION 'Klasa ma już wtedy lekcje ';END IF;
         end loop;
        return NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER "jednaLekcjaNaRaz" BEFORE INSERT ON Lekcje FOR EACH ROW EXECUTE PROCEDURE addLesson();

CREATE OR REPLACE FUNCTION dodaj_place()
RETURNS TRIGGER AS
    $$
    BEGIN
        IF (NEW.stanowisko!='NAUCZYCIEL' AND NEW.tytul!='BRAK') THEN RETURN NULL;
        END IF;
        RETURN NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_place BEFORE INSERT ON Place FOR EACH ROW EXECUTE PROCEDURE dodaj_place();

--VIEWS

CREATE OR REPLACE VIEW Pracownicy_wyplaty AS
    SELECT imie, nazwisko, placa
FROM pracownicy pr LEFT JOIN place pl ON (pr.tytul=pl.tytul AND pr.stanowisko=pl.stanowisko);

--INSERTS

