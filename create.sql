--SEQUENCES

CREATE SEQUENCE Lekcje_id_seq MINVALUE 0 START 0;

--TABLES


CREATE TABLE Pracownicy(
    id NUMERIC(2) NOT NULL CONSTRAINT PK_PRAC PRIMARY KEY CHECK(id>=0),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    godzinyPracy NUMERIC(2),
    tytul VARCHAR  CHECK(tytul='DOKTOR' OR tytul='MAGISTER' OR tytul='PROFESOR' OR tytul='DOKTOR HABILITOWANY' OR tytul='BRAK')
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

CREATE TABLE Sale(
    nr NUMERIC CONSTRAINT PK_SALE PRIMARY KEY,
    liczba_miejsc NUMERIC NOT NULL CHECK (liczba_miejsc>20)
);

CREATE TABLE Przedmioty(
    id NUMERIC(2) PRIMARY KEY,
    nazwa CHARACTER VARYING NOT NULL,
    nauczyciel NUMERIC(2) NOT NULL REFERENCES Pracownicy(id)
);

CREATE TABLE Lekcje(
    id NUMERIC(3) PRIMARY KEY DEFAULT nextval('Lekcje_id_seq'),
    przedmiot NUMERIC(2) NOT NULL REFERENCES Przedmioty(id),
    sala NUMERIC(2) NOT NULL REFERENCES Sale(nr),
    klasa VARCHAR(2) NOT NULL REFERENCES Klasy(klasa),
    czas TIME NOT NULL, CHECK (EXTRACT(hour FROM czas)>=8 AND EXTRACT(hour FROM czas)<=17 AND EXTRACT(minutes FROM czas)=0),
    dzien CHARACTER VARYING NOT NULL,
    CHECK(dzien='Poniedziałek' OR dzien='Wtorek' OR dzien='Środa' OR dzien='Czwartek' OR dzien='Piątek'),
    UNIQUE(sala,czas,dzien)
);

CREATE TABLE Oceny(
    index NUMERIC(3) REFERENCES uczniowie,
    przedmiot NUMERIC(2) REFERENCES przedmioty(id),
    ocena NUMERIC(3,2) CHECK (ocena in (1, 1.5, 1.75, 2, 2.5, 2.75, 3, 3.5, 3.75, 4, 4.5, 4.75, 5, 5.5, 5.75, 6)),
    komentarz VARCHAR,
    data DATE
);

CREATE TABLE Nieobecnosci(
    index NUMERIC(3) REFERENCES uczniowie,
    lekcja NUMERIC(3) REFERENCES Lekcje,
    typ CHAR(1) CHECK (typ in ('N', 'U', 'W', 'G')) DEFAULT 'N',
    data DATE,
    PRIMARY KEY (index, lekcja, data)
);

CREATE TABLE Terminarz(
    lekcja numeric(3) REFERENCES lekcje,
    typ varchar CHECK (typ in ('sprawdzian', 'kartkowka', 'odpowiedz')),
    komentarz varchar,
    dzien DATE,
    PRIMARY KEY (lekcja,dzien)
);

CREATE TABLE Zastepstwa(
    lekcja NUMERIC(3) REFERENCES Lekcje,
    nauczyciel NUMERIC(2) REFERENCES Pracownicy(id),
    data DATE,
    PRIMARY KEY (lekcja,data)
);

--TRIGGERS

create or replace function ocena_z_lekcji()
    returns TRIGGER AS
$$
DECLARE
       klasaUcznia varchar(2);
begin
        klasaUcznia=(SELECT u.klasa FROM uczniowie u WHERE u.index=NEW.index);

        IF (SELECT coalesce(COUNT(*),0)
        FROM lekcje l WHERE l.przedmiot=NEW.przedmiot AND
        l.klasa=klasaUcznia)=0 THEN RETURN NULL; END IF;

        if NEW.data IS NULL THEN NEW.data=current_timestamp;END IF;
        return NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER "ocena_z_lekcji" BEFORE INSERT OR UPDATE ON Oceny FOR EACH ROW EXECUTE PROCEDURE ocena_z_lekcji();
---------------------------------------------------------------------------------------
create or replace function nieobecnosc()
    returns TRIGGER AS
$$
DECLARE
       klasaUcznia varchar(2);
begin
        klasaUcznia=(SELECT u.klasa FROM uczniowie u WHERE u.index=NEW.index);

        IF (SELECT klasa FROM lekcje WHERE lekcje.id=NEW.lekcja)<>klasaUcznia THEN RETURN NULL;END IF;

        return NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER "nieobecnosc" BEFORE INSERT OR UPDATE ON Nieobecnosci FOR EACH ROW EXECUTE PROCEDURE nieobecnosc();
---------------------------------------------------------------------------------------

create or replace function dodajDziecko()
    returns TRIGGER AS
    $$
    declare
       record record;
        dzieci NUMERIC;
    begin
        dzieci=(SELECT COUNT(*) FROM Uczniowie WHERE klasa=NEW.klasa);
        IF TG_OP='UPDATE' AND OLD.klasa<>NEW.klasa THEN dzieci=dzieci+1;END IF;
        IF TG_OP='INSERT' THEN dzieci=dzieci+1;END IF;
        if dzieci>40 then RAISE EXCEPTION 'Za duzo dzieci w klasie';end if;
        for record in SELECT* FROM Lekcje loop
            if(record.klasa=NEW.klasa AND dzieci >(SELECT liczba_miejsc FROM sale WHERE sale.nr=record.sala))
                THEN RAISE EXCEPTION 'Klasa jest pełna';END IF;
         end loop;
        return NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER "liczbaDzieci" BEFORE INSERT OR UPDATE ON Uczniowie FOR EACH ROW EXECUTE PROCEDURE dodajDziecko();

--------------------------------------------------------------------------------------

create or replace function dodajLekcje()
    returns TRIGGER AS
    $$
    declare
       record record;
    begin

        for record in SELECT* FROM Lekcje loop
            if(record.klasa=NEW.klasa AND record.czas=NEW.czas AND record.dzien=NEW.dzien)THEN
                IF TG_OP='UPDATE' AND record IS NOT DISTINCT FROM OLD THEN CONTINUE;END IF;
                RAISE EXCEPTION 'Klasa ma już wtedy lekcje ';END IF;
         end loop;
        return NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER "jednaLekcjaNaRaz" BEFORE INSERT OR UPDATE ON Lekcje FOR EACH ROW EXECUTE PROCEDURE dodajLekcje();

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
        RETURN ((b+1)::numeric(2), NEW.imie, NEW.nazwisko, NEW.godzinyPracy, NEW.tytul);
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_pracownika BEFORE INSERT ON Pracownicy FOR EACH ROW EXECUTE PROCEDURE dodaj_pracownika();

---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION usun_nauczyciela()
RETURNS TRIGGER AS
    $$
    DECLARE a RECORD;
    BEGIN
    IF(SELECT coalesce(COUNT(*),0) FROM Klasy WHERE wychowawca=OLD.id)>0 THEN RAISE EXCEPTION 'Znajdz zastepstwo na wychowawstwo';END IF;
    FOR a IN SELECT * FROM Przedmioty WHERE id=OLD.id LOOP
        DELETE FROM Lekcje WHERE przedmiot=a.id;
        END LOOP;
    DELETE FROM przedmioty WHERE nauczyciel=OLD.id;
    RETURN OLD;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER usunNauczyciela BEFORE DELETE ON Pracownicy FOR EACH ROW EXECUTE PROCEDURE usun_nauczyciela();

---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION zamien_nauczyciela()
RETURNS TRIGGER AS
    $$
    DECLARE record RECORD;
    BEGIN
       UPDATE Klasy SET wychowawca=NEW.id WHERE wychowawca=OLD.id;

       DELETE FROM Lekcje WHERE (SELECT nauczyciel FROM Przedmioty p WHERE p.id=Lekcje.przedmiot)=OLD.id;
       --nauczyciel=OLD.id;
       DELETE FROM Przedmioty WHERE nauczyciel=OLD.id;

        RETURN NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER zamienNauczyciela BEFORE UPDATE ON Pracownicy FOR EACH ROW EXECUTE PROCEDURE zamien_nauczyciela();

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodajTerminarz()
RETURNS TRIGGER AS
    $$
    DECLARE a varchar;
    b NUMERIC;
    BEGIN
        a = (SELECT dzien FROM lekcje WHERE id=NEW.lekcja);
        b = (EXTRACT(DOW FROM NEW.dzien::timestamp));
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3) OR (a='Czwartek' AND b=4) OR (a='Piątek' AND b=5)) THEN RETURN NEW;
        ELSE RAISE EXCEPTION 'Błędna data';
        END IF;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodajTerminarz BEFORE INSERT OR UPDATE ON Terminarz FOR EACH ROW EXECUTE PROCEDURE dodajTerminarz();

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodajNieobecnosc()
RETURNS TRIGGER AS
    $$
    DECLARE a varchar;
    b NUMERIC;
    BEGIN
        a = (SELECT dzien FROM lekcje WHERE id=NEW.lekcja);
        b = (EXTRACT(DOW FROM NEW.data::timestamp));
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3) OR (a='Czwartek' AND b=4) OR (a='Piątek' AND b=5)) THEN RETURN NEW;
        ELSE RAISE EXCEPTION 'Błędna data';
        END IF;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodajNieobecnosc BEFORE INSERT OR UPDATE ON nieobecnosci FOR EACH ROW EXECUTE PROCEDURE dodajNieobecnosc();

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodajZastepstwo()
RETURNS TRIGGER AS
    $$
    DECLARE a varchar;
    b NUMERIC;
    BEGIN
        a = (SELECT dzien FROM lekcje WHERE id=NEW.lekcja);
        b = (EXTRACT(DOW FROM NEW.data::timestamp));
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3) OR (a='Czwartek' AND b=4) OR (a='Piątek' AND b=5)) THEN RETURN NEW;
        ELSE RAISE EXCEPTION 'Błędna data';
        END IF;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodajZastepstwo BEFORE INSERT OR UPDATE ON zastepstwa FOR EACH ROW EXECUTE PROCEDURE dodajZastepstwo();

--FUNCTIONS

create or replace function mojPlanLekcji(idDziecka NUMERIC)
    returns TABLE(nauczyciel NUMERIC(2),sala NUMERIC(2),klasa VARCHAR(2),czas TIME ,dzien VARCHAR) as
$$
declare
    klasaDziecka VARCHAR;
begin
    klasaDziecka=(SELECT u.klasa FROM Uczniowie u WHERE u.index=idDziecka);

    return QUERY SELECT * FROM Lekcje WHERE Lekcje.klasa=klasaDziecka ORDER BY Lekcje.dzien, Lekcje.czas;

end;
$$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION terminarzKlasy(kl varchar(2))
RETURNS TABLE (lekcja numeric(3), typ varchar, komentarz varchar, dzien DATE) AS
    $$
    BEGIN
        RETURN QUERY SELECT * FROM terminarz WHERE terminarz.lekcja IN (SELECT id FROM lekcje WHERE lekcje.klasa=kl);
    end;
    $$
language plpgsql;

--VIEWS


--INSERTS

INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('A', 'B', 40,  'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('C', 'D', 40,  'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('E', 'F', 30, 'DOKTOR');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('G', 'H', 40,  'BRAK');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('A', 'B', 12,  'BRAK');

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
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (407, '4E', 'A', 'B');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (408, '4E', 'B', 'C');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (409, '4E', 'C', 'D');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (410, '4E', 'D', 'E');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (411, '4E', 'E', 'F');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (412, '4E', 'F', 'G');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (104, '1E', 'G', 'H');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (105, '1E', 'H', 'I');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (106, '1E', 'H', 'J');


INSERT INTO Sale (nr, liczba_miejsc) VALUES (1, 35);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (2, 37);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (3, 25);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (4, 28);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (12, 25);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (11, 45);

INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (0, 'Matematyka', 0);
INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (1, 'Matematyka', 1);
INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (2, 'Chemia', 2);
INSERT INTO Przedmioty (id, nazwa, nauczyciel) VALUES (3, 'Biologia', 2);

INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (0, 1, '4E', '12:00', 'Poniedziałek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 2, '1E', '12:00', 'Poniedziałek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 3, '4E', '12:00', 'Środa');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 11, '4E', '11:00', 'Piątek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (0, 11, '1E', '8:00', 'Czwartek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 3, '4E', '10:00', 'Środa');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 3, '4E', '11:00', 'Środa');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (0, 11, '4E', '9:00', 'Czwartek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (0, 11, '4E', '10:00', 'Czwartek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 11, '4E', '10:00', 'Piątek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (0, 12, '1E', '10:00', 'Piątek');

INSERT INTO Terminarz (lekcja, typ, komentarz, dzien) VALUES (0, 'sprawdzian', '', '11.05.2020');
INSERT INTO Terminarz (lekcja, typ, komentarz, dzien) VALUES (1, 'sprawdzian', '', '11.05.2020');

INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (401, 0, 5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (402, 0, 5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (403, 1, 5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (404, 0, 4, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (101, 2, 5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (102, 0, 3, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (103, 0, 3.5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (401, 3, 5.5, '');

INSERT INTO nieobecnosci (index, lekcja, data) VALUES (401, 0, '11.05.2020');
INSERT INTO nieobecnosci (index, lekcja, data) VALUES (402, 0, '11.05.2020');

INSERT INTO zastepstwa (lekcja, nauczyciel, data) VALUES (0, 0, '18.05.2020');


