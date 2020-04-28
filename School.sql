DROP TABLE if EXISTS Przedmioty CASCADE;
DROP TABLE if EXISTS Lekcje;
DROP TABLE if EXISTS Sale CASCADE;
DROP TABLE if EXISTS Uczniowie;
DROP TABLE if EXISTS Klasy CASCADE;
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
    id NUMERIC(2) NOT NULL CONSTRAINT PK_PRAC PRIMARY KEY CHECK(id>=0),
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
    klasa VARCHAR(2) NOT NULL,
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

CREATE TABLE Przedmioty(
    id NUMERIC(2) PRIMARY KEY,
    nazwa CHARACTER VARYING NOT NULL,
    nauczyciel NUMERIC(2) NOT NULL REFERENCES Pracownicy(id)
);

CREATE TABLE Lekcje(
    przedmiot NUMERIC(2) NOT NULL REFERENCES Przedmioty(id),
    sala NUMERIC(2) NOT NULL REFERENCES Sale(nr),
    klasa VARCHAR(2) NOT NULL REFERENCES Klasy(klasa),
    czas TIME NOT NULL, CHECK (EXTRACT(hour FROM czas)>=8 AND EXTRACT(hour FROM czas)<=17 AND EXTRACT(minutes FROM czas)=0),
    dzien CHARACTER VARYING NOT NULL,
    CHECK(dzien='Poniedziałek' OR dzien='Wtorek' OR dzien='Środa' OR dzien='Czwartek' OR dzien='Piątek'),
    PRIMARY KEY(sala,czas,dzien)
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

create or replace function dodajDziecko()
    returns TRIGGER AS
    $$
    declare
       record record;
        dzieci NUMERIC;
    begin
        dzieci=(SELECT COUNT(*) FROM Uczniowie WHERE klasa=NEW.klasa)+1;
        if dzieci>40 then RAISE EXCEPTION 'Za duzo dzieci w klasie';end if;
        for record in SELECT* FROM Lekcje loop
            if(record.klasa=NEW.klasa AND dzieci >(SELECT liczba_miejsc FROM sale WHERE sale.nr=record.sala))
                THEN RAISE EXCEPTION 'Klasa jest pełna';END IF;
         end loop;
        return NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER "liczbaDzieci" BEFORE INSERT ON Uczniowie FOR EACH ROW EXECUTE PROCEDURE dodajDziecko();

--------------------------------------------------------------------------------------

create or replace function dodajLekcje()
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

CREATE TRIGGER "jednaLekcjaNaRaz" BEFORE INSERT ON Lekcje FOR EACH ROW EXECUTE PROCEDURE dodajLekcje();

---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_place()
RETURNS TRIGGER AS
    $$
    BEGIN
        IF (NEW.stanowisko!='NAUCZYCIEL' AND NEW.tytul!='BRAK') THEN RAISE EXCEPTION 'Błąd';
        END IF;
        IF (NEW.placa<12) THEN RAISE EXCEPTION 'To jest wyzysk';
        END IF;
        RETURN NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_place BEFORE INSERT ON Place FOR EACH ROW EXECUTE PROCEDURE dodaj_place();

---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_pracownika()
RETURNS TRIGGER AS
    $$
    DECLARE a RECORD;
        b NUMERIC(2);
    BEGIN
        IF (NEW.id IS NOT NULL) THEN RETURN NEW; END IF;
        b=-1::numeric(2);
        FOR a IN SELECT * FROM Pracownicy LOOP
            IF (a.id>b) THEN b=a.id; END IF;
            end loop;
        RETURN ((b+1)::numeric(2), NEW.imie, NEW.nazwisko, NEW.godzinyPracy, NEW.stanowisko, NEW.tytul);
    end;
    $$
LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dodaj_place ON pracownicy;
CREATE TRIGGER dodaj_place BEFORE INSERT ON Pracownicy FOR EACH ROW EXECUTE PROCEDURE dodaj_pracownika();

---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION usun_nauczyciela()
RETURNS TRIGGER AS
    $$
    DECLARE a RECORD;
    BEGIN
    IF(SELECT COUNT(*) FROM Klasy WHERE wychowawca=OLD.id)>0 THEN RAISE EXCEPTION 'Znajdz zastepstwo na wychowawstwo';END IF;
    FOR a IN SELECT * FROM Przedmioty WHERE id=OLD.id LOOP
        DELETE FROM Lekcje WHERE przedmiot=a.id;
        END LOOP;
    DELETE FROM przedmioty WHERE nauczyciel=OLD.id;
    RETURN OLD;
    end;
    $$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS usunNauczyciela ON Pracownicy;
CREATE TRIGGER usunNauczyciela BEFORE DELETE ON Pracownicy FOR EACH ROW EXECUTE PROCEDURE usun_nauczyciela();

---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION czy_nauczyciel()
RETURNS TRIGGER AS
    $$
    BEGIN

   IF (SELECT stanowisko FROM Pracownicy WHERE id=NEW.nauczyciel)<>'NAUCZYCIEL' THEN
        RAISE EXCEPTION 'Ta osoba nie ma odpowiednich kwalifikacji';END IF;

    RETURN NEW;
    end;
    $$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS uczyNauczyciel ON Pracownicy;
CREATE TRIGGER uczyNauczyciel BEFORE INSERT ON Przedmioty FOR EACH ROW EXECUTE PROCEDURE czy_nauczyciel();

--VIEWS

CREATE OR REPLACE VIEW Pracownicy_wyplaty AS
    SELECT imie, nazwisko, placa
FROM pracownicy pr LEFT JOIN place pl ON (pr.tytul=pl.tytul AND pr.stanowisko=pl.stanowisko);

--FUNCTIONS

create or replace function mojPlanLekcji(idDziecka NUMERIC)
    returns TABLE(nauczyciel NUMERIC(2),sala NUMERIC(2),klasa VARCHAR(2),czas TIME ,dzien VARCHAR) as
$$
declare
    klasaDziecka VARCHAR;
begin
    klasaDziecka=(SELECT klasa FROM Uczniowie u WHERE u.index=idDziecka);

    return QUERY SELECT * FROM Lekcje WHERE Lekcje.klasa=klasaDziecka;

end;
$$
language plpgsql;

--INSERTS

INSERT INTO Place (stanowisko, tytul, placa) VALUES ('NAUCZYCIEL', 'MAGISTER', 18);
INSERT INTO Place (stanowisko, tytul, placa) VALUES ('NAUCZYCIEL', 'DOKTOR', 25);
INSERT INTO Place (stanowisko, tytul, placa) VALUES ('NAUCZYCIEL', 'PROFESOR', 30);
INSERT INTO Place (stanowisko, tytul, placa) VALUES ('OSOBA SPRZĄTAJĄCA', 'BRAK', 12);
INSERT INTO Place (stanowisko, tytul, placa) VALUES ('OPIEKA MEDYCZNA', 'BRAK', 12);

INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, stanowisko, tytul) VALUES ('A', 'B', 40, 'NAUCZYCIEL', 'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, stanowisko, tytul) VALUES ('C', 'D', 40, 'NAUCZYCIEL', 'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, stanowisko, tytul) VALUES ('E', 'F', 30, 'NAUCZYCIEL', 'DOKTOR');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, stanowisko, tytul) VALUES ('G', 'H', 40, 'OSOBA SPRZĄTAJĄCA', 'BRAK');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, stanowisko, tytul) VALUES ('A', 'B', 12, 'OPIEKA MEDYCZNA', 'BRAK');

INSERT INTO Klasy (klasa, wychowawca) VALUES ('1E', 0);
INSERT INTO Klasy (klasa, wychowawca) VALUES ('4E', 1);

INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (401, '4E', 'A', 'A');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (402, '4E', 'B', 'B');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (403, '4E', 'C', 'C');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (404, '4E', 'D', 'D');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (405, '4E', 'E', 'E');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (406, '4E', 'F', 'F');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (101, '1E', 'G', 'G');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (102, '1E', 'H', 'H');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (103, '1E', 'H', 'H');

INSERT INTO Drogi_ewakuacyjne (id, nr_klatki, nr_wyjscia, miejsce_zbiorki) VALUES (0, 0, 0, 'Plac Sikorskiego');
INSERT INTO Drogi_ewakuacyjne (id, nr_wyjscia, miejsce_zbiorki) VALUES (1, 0, 'Plac Sikorskiego');

INSERT INTO Sale (nr, droga_ewakuacyjna, liczba_miejsc) VALUES (1, 0, 35);
INSERT INTO Sale (nr, droga_ewakuacyjna, liczba_miejsc) VALUES (2, 0, 37);
INSERT INTO Sale (nr, droga_ewakuacyjna, liczba_miejsc) VALUES (3, 0, 25);
INSERT INTO Sale (nr, droga_ewakuacyjna, liczba_miejsc) VALUES (4, 0, 28);
INSERT INTO Sale (nr, droga_ewakuacyjna, liczba_miejsc) VALUES (12, 1, 25);
INSERT INTO Sale (nr, droga_ewakuacyjna, liczba_miejsc) VALUES (11, 1, 45);

INSERT INTO Obiekty (id, nazwa, wartosc) VALUES (0, 'krzeslo', 25);
INSERT INTO Obiekty (id, nazwa, wartosc) VALUES (1, 'lawka', 100);
INSERT INTO Obiekty (id, nazwa, wartosc) VALUES (2, 'laptop', 1200);
INSERT INTO Obiekty (id, nazwa, wartosc) VALUES (3, 'projektor', 300);
INSERT INTO Obiekty (id, nazwa, wartosc) VALUES (4, 'tablica', 150);
INSERT INTO Obiekty (id, nazwa, wartosc) VALUES (5, 'mapa', 50);
INSERT INTO Obiekty (id, nazwa, wartosc) VALUES (6, 'biurko', 100);

INSERT INTO Inwentaz (obiekt, sala, ilosc) VALUES (0, 1, 36);
INSERT INTO Inwentaz (obiekt, sala, ilosc) VALUES (1, 1, 18);
INSERT INTO Inwentaz (obiekt, sala, ilosc) VALUES (6, 1, 1);
INSERT INTO Inwentaz (obiekt, sala, ilosc) VALUES (2, 1, 1);
INSERT INTO Inwentaz (obiekt, sala, ilosc) VALUES (3, 1, 1);
INSERT INTO Inwentaz (obiekt, sala, ilosc) VALUES (0, 2, 50);
INSERT INTO Inwentaz (obiekt, sala, ilosc) VALUES (1, 2, 15);

INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (0, 'Matematyka', 0);
INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (1, 'Matematyka', 1);
INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (2, 'Chemia', 2);
INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (3, 'Biologia', 2);

INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (0, 1, '4E', '12:00', 'Poniedziałek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 2, '1E', '12:00', 'Poniedziałek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 3, '4E', '12:00', 'Środa');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 11, '4E', '11:00', 'Piątek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (0, 11, '1E', '8:00', 'Czwartek');

SELECT * FROM Place;
SELECT * FROM Pracownicy;
SELECT * FROM Pracownicy_wyplaty;
SELECT * FROM Klasy;
SELECT * FROM Uczniowie;
SELECT * FROM Lekcje;
--DELETE FROM Pracownicy WHERE id=2;


