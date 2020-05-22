--GROUPS
CREATE ROLE Administracja LOGIN INHERIT;
CREATE ROLE Nauczyciele LOGIN INHERIT;
CREATE ROLE Uczniowie LOGIN INHERIT;

CREATE USER sekretariat;
GRANT Administracja TO sekretariat;

--SEQUENCES

CREATE SEQUENCE Lekcje_id_seq MINVALUE 0 START 0;

--ENUMS

CREATE TYPE TYTUL AS ENUM ('DOKTOR', 'MAGISTER', 'PROFESOR', 'DOKTOR HABILITOWANY');

--TABLES

CREATE TABLE Pracownicy(
    id INTEGER NOT NULL CONSTRAINT PK_PRAC PRIMARY KEY CHECK(id>=0),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    godzinyPracy NUMERIC(2),
    tytul TYTUL
);

CREATE TABLE Klasy(
    nr_klasy NUMERIC(1) NOT NULL,
    klasa VARCHAR(2) NOT NULL,
    wychowawca INTEGER NOT NULL REFERENCES Pracownicy(id),
    PRIMARY KEY (klasa),
    check(nr_klasy>0 AND nr_klasy<7)
);

CREATE TABLE Uczniowie(
    index INTEGER CONSTRAINT PK_UCZ PRIMARY KEY,
    klasa CHARACTER(2) REFERENCES Klasy(klasa),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    absolwent CHAR(1),
    CHECK (absolwent='T' OR absolwent='N')
);

CREATE TABLE Sale(
    nr INTEGER CONSTRAINT PK_SALE PRIMARY KEY,
    liczba_miejsc NUMERIC NOT NULL CHECK (liczba_miejsc>20)
);

CREATE TABLE Przedmioty(
    id INTEGER PRIMARY KEY,
    nazwa CHARACTER VARYING NOT NULL
);
CREATE TABLE Nauczyciele_powadzacy(
    id INTEGER PRIMARY KEY,
    id_przedmiot INTEGER references Przedmioty(id),
    nauczyciel INTEGER NOT NULL REFERENCES Pracownicy(id)
    --PRIMARY KEY (id_przedmiot,nauczyciel)
);

CREATE TABLE Lekcje(
    id INTEGER PRIMARY KEY DEFAULT nextval('Lekcje_id_seq'),
    przedmiot INTEGER NOT NULL REFERENCES Nauczyciele_powadzacy(id),
    sala INTEGER NOT NULL REFERENCES Sale(nr),
    klasa CHARACTER VARYING NOT NULL REFERENCES Klasy(klasa),
    czas TIME NOT NULL, CHECK (EXTRACT(hour FROM czas)>=8 AND EXTRACT(hour FROM czas)<=17 AND EXTRACT(minutes FROM czas)=0),
    dzien CHARACTER VARYING NOT NULL,
    CHECK(dzien='Poniedziałek' OR dzien='Wtorek' OR dzien='Środa' OR dzien='Czwartek' OR dzien='Piątek'),
    UNIQUE(sala,czas,dzien)
);

CREATE TABLE Oceny(
    index INTEGER REFERENCES uczniowie,
    przedmiot INTEGER REFERENCES przedmioty(id),
    ocena NUMERIC(3,2) CHECK (ocena in (1, 1.5, 1.75, 2, 2.5, 2.75, 3, 3.5, 3.75, 4, 4.5, 4.75, 5, 5.5, 5.75, 6)),
    komentarz VARCHAR,
    data DATE
);

CREATE TABLE Nieobecnosci(
    index INTEGER REFERENCES uczniowie,
    lekcja INTEGER REFERENCES Lekcje,
    typ CHAR(1) CHECK (typ in ('N', 'U', 'W', 'G')) DEFAULT 'N',
    data DATE,
    PRIMARY KEY (index, lekcja, data)
);

CREATE TABLE Terminarz(
    lekcja INTEGER REFERENCES lekcje,
    typ varchar CHECK (typ in ('sprawdzian', 'kartkowka', 'odpowiedz')),
    komentarz varchar,
    dzien DATE,
    PRIMARY KEY (lekcja,dzien)
);

CREATE TABLE Zastepstwa(
    lekcja INTEGER REFERENCES Lekcje,
    nauczyciel INTEGER NOT NULL REFERENCES Pracownicy(id),
    data DATE,
    PRIMARY KEY (lekcja,data)
);
CREATE TABLE oceny_okresowe(
    index INTEGER REFERENCES Uczniowie,
    przedmiot INTEGER REFERENCES Przedmioty(id),
    ocena_srodroczna INTEGER,
    ocena_koncoworoczna INTEGER,
    CHECK (ocena_srodroczna>0 AND ocena_srodroczna<7),
    CHECK (ocena_koncoworoczna>0 AND ocena_koncoworoczna<7),
    rok NUMERIC(4),
    PRIMARY KEY (index,przedmiot,rok)
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
        nazwa varchar;
    begin
        IF NEW.absolwent IS NULL THEN NEW.absolwent='N';END IF;
        IF NEW.absolwent='N' AND NEW.klasa IS NULL THEN RAISE EXCEPTION 'Do której chodzi klasy?';END IF;
        IF NEW.absolwent='T' AND NEW.klasa IS NOT NULL THEN RAISE EXCEPTION 'Absolwent nie może chodzić do klasy';END IF;
        dzieci=(SELECT COUNT(*) FROM Uczniowie WHERE klasa=NEW.klasa);
        IF TG_OP='UPDATE' AND OLD.klasa<>NEW.klasa THEN dzieci=dzieci+1;END IF;
        IF TG_OP='INSERT' THEN dzieci=dzieci+1;END IF;
        if dzieci>40 then RAISE EXCEPTION 'Za duzo dzieci w klasie';end if;
        for record in SELECT* FROM Lekcje loop
            if(record.klasa=NEW.klasa AND dzieci >(SELECT liczba_miejsc FROM sale WHERE sale.nr=record.sala))
                THEN RAISE EXCEPTION 'Klasa jest pełna';END IF;
         end loop;
        nazwa=CONCAT('u',cast(NEW.index AS varchar));
        IF TG_OP='INSERT' THEN EXECUTE('CREATE USER ' || quote_ident(nazwa) || ' PASSWORD ''1234'';');END IF;
        IF TG_OP='INSERT' THEN EXECUTE('GRANT Uczniowie TO ' || quote_ident(nazwa) || ';') ;END IF;
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
        nazwa varchar;
    BEGIN
        IF (NEW.id IS NOT NULL) THEN RETURN NEW; END IF;
        NEW.id=(SELECT COALESCE(MAX(id),-1) FROM pracownicy)+1;

        nazwa=CONCAT('n',cast(NEW.id AS varchar));
        IF TG_OP='INSERT' THEN EXECUTE('CREATE USER ' || quote_ident(nazwa) || ' PASSWORD ''1234'';') ;END IF;
        IF TG_OP='INSERT' THEN EXECUTE('GRANT Nauczyciele TO ' || quote_ident(nazwa) || ';') ;END IF;
        RETURN NEW;
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
    DELETE FROM Nauczyciele_powadzacy WHERE nauczyciel=OLD.id;
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

       DELETE FROM Lekcje WHERE (SELECT nauczyciel FROM Nauczyciele_powadzacy p WHERE p.id_przedmiot=Lekcje.przedmiot)=OLD.id;
       --nauczyciel=OLD.id;
       DELETE FROM Nauczyciele_powadzacy WHERE nauczyciel=OLD.id;

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
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3)
               OR (a='Czwartek' AND b=4) OR (a='Piątek' AND b=5)) THEN RETURN NEW;
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
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3)
               OR (a='Czwartek' AND b=4) OR (a='Piątek' AND b=5)) THEN RETURN NEW;
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
        if NEW.nauczyciel=(SELECT np.nauczyciel FROM Nauczyciele_powadzacy np JOIN Lekcje ON np.id=przedmiot
            WHERE Lekcje.id=NEW.lekcja) then raise EXCEPTION 'Nauczyciel nie może zastapić siebie samego';end if;

        if NEW.nauczyciel IN (SELECT nauczyciel FROM Nauczyciele_powadzacy np JOIN Lekcje l on np.id=l.przedmiot
            WHERE l.dzien=(SELECT dzien FROM Lekcje l2 WHERE l2.id=NEW.lekcja)
              AND l.czas=(SELECT czas FROM Lekcje l2 WHERE l2.id=NEW.lekcja)) THEN
            RAISE EXCEPTION 'Ten nauczyciel prowadzi juz wtedy lekcje';
        end if;

        if NEW.nauczyciel IN (SELECT nauczyciel FROM Zastepstwa z JOIN Lekcje l on z.lekcja=l.id
            WHERE l.dzien=(SELECT dzien FROM Lekcje l2 WHERE l2.id=NEW.lekcja)
              AND l.czas=(SELECT czas FROM Lekcje l2 WHERE l2.id=NEW.lekcja)) THEN
            RAISE EXCEPTION 'Ten nauczyciel prowadzi juz wtedy zastepstwo';
        end if;

        delete from zastepstwa WHERE lekcja=NEW.lekcja AND data=NEW.data;

        a = (SELECT dzien FROM lekcje WHERE id=NEW.lekcja);
        b = (EXTRACT(DOW FROM NEW.data::timestamp));
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3) OR (a='Czwartek' AND b=4)
               OR (a='Piątek' AND b=5)) THEN RETURN NEW;
        ELSE RAISE EXCEPTION 'Błędna data';
        END IF;

    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodajZastepstwo BEFORE INSERT OR UPDATE ON zastepstwa FOR EACH ROW EXECUTE PROCEDURE dodajZastepstwo();

----------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_klase()
RETURNS TRIGGER AS
$$
BEGIN
    IF NOT(NEW.klasa ~ '^[1-6][a-z]$')AND NOT (NEW.klasa ~ '^[1-6][A-Z]$') THEN RETURN NULL;END IF;
    RETURN NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_klase BEFORE INSERT OR UPDATE ON Klasy FOR EACH ROW EXECUTE PROCEDURE dodaj_klase();

-----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION dodaj_ocene_okresowa()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.rok IS NULL THEN NEW.rok=EXTRACT(year FROM current_timestamp);END IF;

    IF TG_OP='INSERT' AND (NEW.index,NEW.przedmiot,NEW.rok) IN (SELECT index,przedmiot,rok FROM oceny_okresowe)
        AND NEW.ocena_koncoworoczna IS NOT NULL
    THEN
        UPDATE oceny_okresowe SET ocena_koncoworoczna=NEW.ocena_koncoworoczna
        WHERE index=NEW.index AND przedmiot=NEW.przedmiot AND rok=NEW.rok;
    END IF;

    IF TG_OP='INSERT' AND (NEW.index,NEW.przedmiot,NEW.rok) IN (SELECT index,przedmiot,rok FROM oceny_okresowe)
        AND NEW.ocena_srodroczna IS NOT NULL
    THEN
        UPDATE oceny_okresowe SET ocena_srodroczna=NEW.ocena_srodroczna
        WHERE index=NEW.index AND przedmiot=NEW.przedmiot AND rok=NEW.rok;
    END IF;

    IF TG_OP='INSERT' AND (NEW.index,NEW.przedmiot,NEW.rok) IN (SELECT index,przedmiot,rok FROM oceny_okresowe)
    THEN RETURN NULL;END IF;

    RETURN NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_ocene_okresowa BEFORE INSERT OR UPDATE ON oceny_okresowe FOR EACH ROW EXECUTE PROCEDURE dodaj_ocene_okresowa();

--FUNCTIONS
create or replace function mojPlanLekcji(idDziecka NUMERIC)
    returns TABLE(przedmiot varchar,czas text ,dzien VARCHAR,sala INTEGER,nauczyciel varchar) as
$$
declare
    klasaDziecka VARCHAR;
begin
    klasaDziecka=(SELECT u.klasa FROM Uczniowie u WHERE u.index=idDziecka);

    return QUERY SELECT (SELECT p.nazwa FROM przedmioty p WHERE p.id=l.przedmiot) AS przedmiot,
    to_char(l.czas, 'HH:MI'), l.dzien, l.sala,
    (SELECT nazwisko FROM Pracownicy
    WHERE id=(SELECT p.nauczyciel FROM Nauczyciele_powadzacy p WHERE p.id_przedmiot=l.przedmiot)) AS nauczyciel
    FROM Lekcje l WHERE l.klasa=klasaDziecka ORDER BY l.dzien, l.czas;

end;
$$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION terminarzKlasy(kl varchar(2))
RETURNS TABLE (lekcja INTEGER, typ varchar, komentarz varchar, dzien DATE) AS
    $$
    BEGIN
        RETURN QUERY SELECT * FROM terminarz WHERE terminarz.lekcja IN (SELECT id FROM lekcje WHERE lekcje.klasa=kl);
    end;
    $$
language plpgsql;

--VIEWS
CREATE or replace VIEW "srednie_ocen" AS
    SELECT u.index,imie,nazwisko,
           (SELECT p.nazwa FROM przedmioty p WHERE p.id= o.przedmiot) AS "przedmiot",
           SUM(o.ocena)/COUNT(*) AS "ocena"
    FROM uczniowie u JOIN oceny o ON u.index=o.index
    GROUP BY o.przedmiot, u.index;

SELECT * FROM srednie_ocen;
--INSERTS


INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('A', 'Bananowski', 40,  'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('C', 'Drozd', 40,  'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('E', 'Figowa', 30, 'DOKTOR');
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('G', 'Haber', 40,  null);
INSERT INTO Pracownicy (imie, nazwisko, godzinyPracy, tytul) VALUES ('A', 'Borówka', 12,  null);


INSERT INTO Klasy  VALUES (1,'1E', 2);
INSERT INTO Klasy  VALUES (4,'4E', 1);
INSERT INTO Klasy  VALUES (2,'2E', 3);

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

INSERT INTO Przedmioty (id, nazwa) VALUES (0, 'Matematyka');
INSERT INTO Przedmioty (id, nazwa) VALUES (1, 'Polski');
INSERT INTO Przedmioty (id, nazwa) VALUES (2, 'Chemia');
INSERT INTO Przedmioty (id, nazwa) VALUES (3, 'Biologia');

INSERT INTO Nauczyciele_powadzacy VALUES (0,0,0);
INSERT INTO Nauczyciele_powadzacy VALUES (1,0,1);
INSERT INTO Nauczyciele_powadzacy VALUES (2,2,2);
INSERT INTO Nauczyciele_powadzacy VALUES (3,3,2);


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
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 1, '2E', '10:00', 'Piątek');



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

INSERT INTO zastepstwa (lekcja, nauczyciel, data) VALUES (1, 3, '18.05.2020');

INSERT INTO oceny_okresowe VALUES (401,0,3,4);
INSERT INTO oceny_okresowe VALUES (401,1,4,4);
INSERT INTO oceny_okresowe VALUES (101,0,4,5,2019);
INSERT INTO oceny_okresowe VALUES (101,0,5,5);


