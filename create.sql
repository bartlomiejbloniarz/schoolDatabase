--GROUPS

CREATE ROLE Administracja LOGIN INHERIT;
CREATE ROLE Nauczyciele LOGIN INHERIT;
CREATE ROLE Uczniowie LOGIN INHERIT;


CREATE USER sekretariat PASSWORD 'sekretariat';
ALTER USER sekretariat WITH SUPERUSER;
GRANT Administracja TO sekretariat;

--ENUMS

CREATE TYPE TYTUL AS ENUM ('DOKTOR', 'MAGISTER', 'PROFESOR', 'DOKTOR HABILITOWANY');

CREATE TYPE DZIEN AS ENUM ('Poniedziałek', 'Wtorek', 'Środa','Czwartek', 'Piątek');

CREATE TYPE ABSOLWENT AS ENUM ('T', 'N');

CREATE TYPE SPRAWDZIANY AS ENUM ('sprawdzian', 'kartkowka', 'odpowiedz');

CREATE TYPE OBECNOSC AS ENUM ('N', 'U', 'W', 'G');

--SEQUENCES

CREATE SEQUENCE aktualny_rok_szkolny;
GRANT ALL ON SEQUENCE aktualny_rok_szkolny TO nauczyciele;
SELECT setval('aktualny_rok_szkolny', 1);

--TABLES

CREATE TABLE lata_szkolne(
    id integer PRIMARY KEY,
    nazwa char(9) NOT NULL UNIQUE
);

CREATE TABLE Pracownicy(
    id INTEGER NOT NULL CONSTRAINT PK_PRAC PRIMARY KEY CHECK(id>=0),
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    tytul TYTUL
);

CREATE TABLE Klasy(
    nr_klasy NUMERIC(1) NOT NULL,
    nazwa_klasy CHAR(1) NOT NULL,
    klasa integer NOT NULL,
    wychowawca INTEGER NOT NULL REFERENCES Pracownicy(id),
    PRIMARY KEY (klasa),
    UNIQUE (nr_klasy, nazwa_klasy),
    check(nr_klasy>0 AND nr_klasy<9)
);

CREATE TABLE Uczniowie(
    index INTEGER CONSTRAINT PK_UCZ PRIMARY KEY,
    klasa integer,
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    absolwent ABSOLWENT NOT NULL DEFAULT 'N',
    CONSTRAINT uczniowie_klasa_fkey foreign key (klasa) REFERENCES klasy(klasa)
);

CREATE TABLE Sale(
    nr INTEGER CONSTRAINT PK_SALE PRIMARY KEY,
    liczba_miejsc NUMERIC NOT NULL CHECK (liczba_miejsc>20)
);

CREATE TABLE Przedmioty(
    id INTEGER PRIMARY KEY,
    nazwa CHARACTER VARYING NOT NULL UNIQUE
);
CREATE TABLE Nauczyciele_prowadzacy(
    id INTEGER PRIMARY KEY,
    id_przedmiot INTEGER NOT NULL REFERENCES Przedmioty(id),
    nauczyciel INTEGER NOT NULL REFERENCES Pracownicy(id)
);

CREATE TABLE Lekcje(
    id INTEGER PRIMARY KEY,
    przedmiot INTEGER NOT NULL REFERENCES Nauczyciele_prowadzacy(id),
    sala INTEGER NOT NULL REFERENCES Sale(nr),
    klasa integer NOT NULL REFERENCES Klasy(klasa),
    czas TIME NOT NULL, CHECK (EXTRACT(hour FROM czas)>=8 AND EXTRACT(hour FROM czas)<=17 AND EXTRACT(minutes FROM czas)=0),
    dzien DZIEN NOT NULL,
    UNIQUE(sala,czas,dzien)
);

CREATE TABLE Oceny(
    index INTEGER NOT NULL REFERENCES uczniowie,
    przedmiot INTEGER NOT NULL REFERENCES przedmioty(id),
    ocena NUMERIC(3,2) NOT NULL CHECK (ocena in (1, 1.5, 1.75, 2, 2.5, 2.75, 3, 3.5, 3.75, 4, 4.5, 4.75, 5, 5.5, 5.75, 6)),
    komentarz VARCHAR,
    data DATE
);

CREATE TABLE Nieobecnosci(
    index INTEGER NOT NULL REFERENCES uczniowie,
    lekcja INTEGER NOT NULL REFERENCES Lekcje,
    typ OBECNOSC NOT NULL DEFAULT 'N',
    data DATE NOT NULL,
    PRIMARY KEY (index, lekcja, data)
);

CREATE TABLE Terminarz(
    lekcja INTEGER NOT NULL REFERENCES lekcje,
    typ SPRAWDZIANY NOT NULL,
    komentarz varchar,
    dzien DATE NOT NULL,
    PRIMARY KEY (lekcja,dzien)
);

CREATE TABLE Zastepstwa(
    lekcja INTEGER NOT NULL REFERENCES Lekcje,
    nauczyciel INTEGER NOT NULL REFERENCES Pracownicy(id),
    data DATE NOT NULL,
   PRIMARY KEY (lekcja,data)
);
CREATE TABLE oceny_okresowe(
    index INTEGER NOT NULL REFERENCES Uczniowie,
    przedmiot INTEGER NOT NULL REFERENCES Przedmioty(id),
    ocena_srodroczna INTEGER,
    ocena_koncoworoczna INTEGER,
    CHECK (ocena_srodroczna>0 AND ocena_srodroczna<7),
    CHECK (ocena_koncoworoczna>0 AND ocena_koncoworoczna<7),
    rok INTEGER NOT NULL REFERENCES lata_szkolne(id),
    PRIMARY KEY (index,przedmiot,rok)
);
--TRIGGERS

CREATE OR REPLACE FUNCTION rok_szkolny()
RETURNS TRIGGER AS
    $$
    begin
        IF substring(NEW.nazwa, 1, 4)::integer+1<>substring(NEW.nazwa, 6, 4)::integer THEN RAISE EXCEPTION 'Niepoprawna nazwa roku'; END IF;
        IF NOT(NEW.nazwa ~ '^[0-9]{4}\/[0-9]{4}$') THEN RAISE EXCEPTION 'Niepoprawna nazwa roku';END IF;
        IF NEW.id IS NULL THEN NEW.id = COALESCE((SELECT max(id) FROM lata_szkolne), 0)+1; END IF;
        RETURN NEW;
    end;
    $$
language plpgsql;

CREATE TRIGGER rok_szkolny BEFORE INSERT OR UPDATE ON lata_szkolne FOR EACH ROW EXECUTE PROCEDURE rok_szkolny();

create or replace function ocena_z_lekcji()
    returns TRIGGER AS
$$
DECLARE
       klasaUcznia integer;
begin
        klasaUcznia=(SELECT u.klasa FROM uczniowie u WHERE u.index=NEW.index);

        IF (SELECT coalesce(COUNT(*),0)FROM lekcje l WHERE
           (SELECT id_przedmiot FROM nauczyciele_prowadzacy WHERE id=l.przedmiot)=NEW.przedmiot AND
        l.klasa=klasaUcznia)=0 THEN RAISE EXCEPTION 'Uczen nie ma takiej lekcji'; END IF;

        if NEW.komentarz IS NULL THEN NEW.komentarz='';END IF;

        if NEW.data IS NULL THEN NEW.data=current_timestamp;END IF;
        return NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER "ocena_z_lekcji" BEFORE INSERT OR UPDATE ON Oceny FOR EACH ROW EXECUTE PROCEDURE ocena_z_lekcji();
---------------------------------------------------------------------------------------

create or replace function dodaj_dziecko()
    returns TRIGGER AS
    $$
    declare
        record record;
        dzieci NUMERIC;
        nazwa varchar;
    begin
        IF TG_OP='INSERT' AND NEW.index IS NOT NULL AND NEW.index IN (SELECT index FROM uczniowie)
            THEN RAISE EXCEPTION 'Index zajęty';END IF;
        IF TG_OP='INSERT' AND NEW.imie IS NULL OR NEW.nazwisko IS NULL THEN RAISE EXCEPTION 'Brak imienia lub nazwiska';END IF;
        IF TG_OP='INSERT' AND NEW.index IS NULL THEN NEW.index=(SELECT COALESCE(MAX(index),0) FROM uczniowie)+1;END IF;
        IF TG_OP='UPDATE' THEN NEW.index=OLD.index;END IF;
        IF TG_OP='INSERT' AND NEW.absolwent IS NULL THEN NEW.absolwent='N';END IF;
        --IF NEW.absolwent='N' AND NEW.klasa IS NULL THEN RAISE EXCEPTION 'Do której chodzi klasy?';END IF;
        --to robi inny trigger
        --IF NEW.absolwent='T' THEN NEW.klasa=null;END IF;
        --AND NEW.klasa IS NOT NULL THEN RAISE EXCEPTION 'Absolwent nie może chodzić do klasy';END IF;

        dzieci=(SELECT COUNT(*) FROM Uczniowie WHERE klasa=NEW.klasa);

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

CREATE TRIGGER dodaj_dziecko BEFORE INSERT OR UPDATE ON Uczniowie FOR EACH ROW EXECUTE PROCEDURE dodaj_dziecko();
-------------------------------------------------------------------------------------
create or replace function czy_dziecko_ma_klase()
RETURNS trigger AS $$
BEGIN
    IF TG_OP='INSERT' AND NEW.absolwent='N' AND NEW.klasa IS NULL THEN RAISE EXCEPTION 'Do której chodzi klasy w takim razie?';END IF;
    IF TG_OP='UPDATE' AND NEW.absolwent='N' AND (OLD.klasa IS null AND NEW.klasa IS NULL) THEN RAISE EXCEPTION 'To do której chodzi klasy?';END IF;
   -- IF NEW.absolwent='T' AND NEW.klasa IS NOT NULL THEN RAISE EXCEPTION 'Absolwent nie może chodzić do klasy';END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER czy_dziecko_ma_klase AFTER INSERT OR UPDATE ON Uczniowie INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE czy_dziecko_ma_klase();
--------------------------------------------------------------------------------------

create or replace function dodaj_lekcje()
    returns TRIGGER AS
    $$
    declare
       record record;
    begin
        IF TG_OP='INSERT' THEN NEW.id=(SELECT COALESCE(MAX(id),0) FROM Lekcje)+1;END IF;
        IF TG_OP='UPDATE' THEN NEW.id=OLD.id;END IF;
        for record in SELECT* FROM Lekcje loop
            if(record.klasa=NEW.klasa AND record.czas=NEW.czas AND record.dzien=NEW.dzien)THEN
                IF TG_OP='UPDATE' AND record IS NOT DISTINCT FROM OLD THEN CONTINUE;END IF;
                RAISE EXCEPTION 'Klasa ma już wtedy lekcje ';END IF;
         end loop;
        IF (SELECT COUNT(*) FROM uczniowie WHERE klasa=NEW.klasa)>(SELECT liczba_miejsc FROM Sale WHERE Sale.nr=NEW.sala)
        THEN RAISE EXCEPTION 'Sala nie pomieści tylu osób';END IF;
        return NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_lekcje BEFORE INSERT OR UPDATE ON Lekcje FOR EACH ROW EXECUTE PROCEDURE dodaj_lekcje();

---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_pracownika()
RETURNS TRIGGER AS
    $$
    DECLARE a RECORD;
        nazwa varchar;
    BEGIN
        IF NEW.imie IS NULL OR NEW.nazwisko IS NULL THEN RAISE EXCEPTION 'Brak imienia lub nazwiska';END IF;
        NEW.id=(SELECT COALESCE(MAX(id),0) FROM pracownicy)+1;

        nazwa=CONCAT('n',cast(NEW.id AS varchar));
        EXECUTE('CREATE USER ' || quote_ident(nazwa) || ' PASSWORD ''1234'';') ;--to jest rigger tylko na insert anw
        EXECUTE('GRANT Nauczyciele TO ' || quote_ident(nazwa) || ';') ;
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
        nazwa varchar;
    BEGIN
    IF(SELECT coalesce(COUNT(*),0) FROM Klasy WHERE wychowawca=OLD.id)>0 THEN RAISE EXCEPTION 'Znajdz zastepstwo na wychowawstwo';END IF;
    FOR a IN SELECT * FROM nauczyciele_prowadzacy WHERE nauczyciel=OLD.id LOOP
        DELETE FROM Lekcje WHERE przedmiot=a.id;
        END LOOP;
    DELETE FROM nauczyciele_prowadzacy WHERE nauczyciel=OLD.id;
    nazwa=CONCAT('n',cast(OLD.id AS varchar));
    EXECUTE('DROP USER ' || quote_ident(nazwa) || ';') ;
    RETURN OLD;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER usunNauczyciela BEFORE DELETE ON Pracownicy FOR EACH ROW EXECUTE PROCEDURE usun_nauczyciela();
---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION usun_ucznia()
RETURNS TRIGGER AS
    $$
    DECLARE
        nazwa varchar;
    BEGIN
    nazwa=CONCAT('u',cast(OLD.index AS varchar));
    EXECUTE('DROP USER ' || quote_ident(nazwa) || ';') ;
    DELETE FROM Oceny WHERE Oceny.index=OLD.index;
    DELETE FROM oceny_okresowe WHERE oceny_okresowe.index=OLD.index;
    DELETE FROM Nieobecnosci WHERE Nieobecnosci.index=OLD.index;
    RETURN OLD;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER usun_ucznia BEFORE DELETE ON Uczniowie FOR EACH ROW EXECUTE PROCEDURE usun_ucznia();
---------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION zamien_nauczyciela()
RETURNS TRIGGER AS
    $$
    DECLARE nazwa varchar;

    BEGIN
       IF NEW.id IS NOT NULL AND NEW.id<>OLD.id THEN RAISE EXCEPTION 'Nie mozna zmienic id';END IF;

        RETURN NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER zamienNauczyciela BEFORE UPDATE ON Pracownicy FOR EACH ROW EXECUTE PROCEDURE zamien_nauczyciela();

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_terminarz()
RETURNS TRIGGER AS
    $$
    DECLARE a varchar;
    b NUMERIC;
    BEGIN
        if NEW.komentarz is null THEN NEW.komentarz='';END IF;
        a = (SELECT dzien FROM lekcje WHERE id=NEW.lekcja);
        b = (EXTRACT(DOW FROM NEW.dzien::timestamp));
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3)
               OR (a='Czwartek' AND b=4) OR (a='Piątek' AND b=5)) THEN RETURN NEW;
        ELSE RAISE EXCEPTION 'Błędna data';
        END IF;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_terminarz BEFORE INSERT OR UPDATE ON Terminarz FOR EACH ROW EXECUTE PROCEDURE dodaj_terminarz();

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_nieobecnosc()
RETURNS TRIGGER AS
    $$
    DECLARE a varchar;
            b NUMERIC;
         klasaUcznia integer;
    BEGIN
        IF TG_OP='INSERT' AND NEW.typ IS NULL THEN NEW.typ='N';END IF;
        klasaUcznia=(SELECT u.klasa FROM uczniowie u WHERE u.index=NEW.index);
        IF (SELECT klasa FROM lekcje WHERE lekcje.id=NEW.lekcja)<>klasaUcznia THEN RAISE EXCEPTION 'Uczen nie ma wtedy lekcji';
        END IF;

        a = (SELECT dzien FROM lekcje WHERE id=NEW.lekcja);
        b = (EXTRACT(DOW FROM NEW.data::timestamp));
        IF((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3)
               OR (a='Czwartek' AND b=4) OR (a='Piątek' AND b=5)) THEN RETURN NEW;
        ELSE RAISE EXCEPTION 'Błędna data';
        END IF;
    end;
    $$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_nieobecnosc BEFORE INSERT OR UPDATE ON nieobecnosci
    FOR EACH ROW EXECUTE PROCEDURE dodaj_nieobecnosc();

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_zastepstwo()
RETURNS TRIGGER AS
    $$
    DECLARE a varchar;
    b NUMERIC;
    BEGIN
        if NEW.nauczyciel=(SELECT np.nauczyciel FROM Nauczyciele_prowadzacy np JOIN Lekcje ON np.id=przedmiot
            WHERE Lekcje.id=NEW.lekcja) then raise EXCEPTION 'Nauczyciel nie może zastapić siebie samego';end if;

        if NEW.nauczyciel IN (SELECT nauczyciel FROM Nauczyciele_prowadzacy np JOIN Lekcje l on np.id=l.przedmiot
            WHERE l.dzien=(SELECT dzien FROM Lekcje l2 WHERE l2.id=NEW.lekcja)
              AND l.czas=(SELECT czas FROM Lekcje l2 WHERE l2.id=NEW.lekcja)) THEN
            RAISE EXCEPTION 'Ten nauczyciel prowadzi juz wtedy lekcje';
        end if;

        if NEW.nauczyciel IN (SELECT nauczyciel FROM Zastepstwa z JOIN Lekcje l on z.lekcja=l.id
            WHERE l.dzien=(SELECT dzien FROM Lekcje l2 WHERE l2.id=NEW.lekcja)
              AND l.czas=(SELECT czas FROM Lekcje l2 WHERE l2.id=NEW.lekcja)
            AND NEW.data=z.data AND NEW.ctid<>z.ctid) THEN
            RAISE EXCEPTION 'Ten nauczyciel prowadzi juz wtedy zastepstwo';
        end if;

        a = (SELECT dzien FROM lekcje WHERE id=NEW.lekcja);
        b = (EXTRACT(DOW FROM NEW.data::timestamp));
        IF ((a='Poniedziałek' AND b=1) OR (a='Wtorek' AND b=2) OR (a='Środa' AND b=3) OR (a='Czwartek' AND b=4)
               OR (a='Piątek' AND b=5))=false THEN RAISE EXCEPTION 'Błędna data';
        END IF;

        IF (NEW.lekcja,NEW.data) IN (SELECT lekcja,data FROM Zastepstwa z WHERE z.ctid<>NEW.ctid) THEN
            RAISE EXCEPTION 'Blad klucza podstawowego-lekcja,data';
        END IF;

        RETURN NEW;
    end;
    $$
LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER dodaj_zastepstwo AFTER INSERT OR UPDATE ON zastepstwa INITIALLY DEFERRED
    FOR EACH ROW EXECUTE PROCEDURE dodaj_zastepstwo();

----------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION dodaj_klase()
RETURNS TRIGGER AS
$$
BEGIN
    IF (NEW.klasa IS NULL) THEN NEW.klasa = COALESCE((SELECT MAX(klasa) FROM klasy), 0)+1; END IF;
    IF NOT(NEW.nazwa_klasy ~ '^[a-z]$')AND NOT (NEW.nazwa_klasy ~ '^[A-Z]$') THEN RAISE EXCEPTION 'Niepoprawna nazwa klasy';END IF;
    RETURN NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_klase BEFORE INSERT OR UPDATE ON Klasy FOR EACH ROW EXECUTE PROCEDURE dodaj_klase();

----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION dodaj_przedmiot()
RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP='INSERT' THEN NEW.id=(SELECT COALESCE(MAX(id),0) FROM przedmioty)+1;END IF;
    IF TG_OP='UPDATE' THEN NEW.id=OLD.id;END IF;
    RETURN NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_przedmiot BEFORE INSERT OR UPDATE ON przedmioty FOR EACH ROW EXECUTE PROCEDURE dodaj_przedmiot();
----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION dodaj_nauczyciela_prowadzacego()
RETURNS TRIGGER AS
$$
BEGIN
    IF TG_OP='INSERT' THEN NEW.id=(SELECT COALESCE(MAX(id),0) FROM nauczyciele_prowadzacy)+1;END IF;
        IF TG_OP='UPDATE' THEN NEW.id=OLD.id;END IF;
    RETURN NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_nauczyciela_prowadzacego BEFORE INSERT OR UPDATE ON nauczyciele_prowadzacy
    FOR EACH ROW EXECUTE PROCEDURE dodaj_nauczyciela_prowadzacego();

-----------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION dodaj_ocene_okresowa()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.rok IS NULL THEN NEW.rok = pg_sequence_last_value('aktualny_rok_szkolny'); END IF;

    IF NEW.przedmiot not in (SELECT id_przedmiot FROM nauczyciele_prowadzacy np JOIN Lekcje L on np.id = L.przedmiot WHERE L.klasa in (SELECT klasa FROM uczniowie WHERE index=NEW.index))
    THEN RAISE EXCEPTION 'Uczeń nie ma takiej lekcji'; END IF;

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
    THEN RETURN NULL;END IF;--bo juz to wyzej wszystko zrobilismy

    RETURN NEW;
end;
$$
LANGUAGE plpgsql;

CREATE TRIGGER dodaj_ocene_okresowa BEFORE INSERT OR UPDATE ON oceny_okresowe FOR EACH ROW EXECUTE PROCEDURE dodaj_ocene_okresowa();

--FUNCTIONS

CREATE OR REPLACE FUNCTION przedmiot (p integer) RETURNS varchar AS
    $$
    begin
        RETURN (SELECT nazwa FROM przedmioty WHERE id=p);
    end;
    $$
language plpgsql;

------------------------

CREATE OR REPLACE FUNCTION przedmiot (p varchar) RETURNS int AS
    $$
    begin
        RETURN (SELECT id FROM przedmioty WHERE nazwa=p);
    end;
    $$
language plpgsql;

------------------------

CREATE OR REPLACE FUNCTION klasa (kl integer) RETURNS char(2) AS
    $$
    begin
        RETURN (SELECT CONCAT(nr_klasy,nazwa_klasy) FROM klasy WHERE klasa=kl);
    end;
    $$
language plpgsql;

------------------------

CREATE OR REPLACE FUNCTION klasa (kl char(2)) RETURNS int AS
    $$
    begin
        RETURN (SELECT klasa FROM klasy WHERE nr_klasy = substring(kl,1,1)::int AND nazwa_klasy = substring(kl,2,2));
    end;
    $$
language plpgsql;

------------------------

CREATE OR REPLACE FUNCTION rok (rk integer) RETURNS char(9) AS
    $$
    begin
        RETURN (SELECT nazwa FROM lata_szkolne WHERE id=rk);
    end;
    $$
language plpgsql;

------------------------

CREATE OR REPLACE FUNCTION rok (rk char(9)) RETURNS int AS
    $$
    begin
        RETURN (SELECT id FROM lata_szkolne WHERE nazwa = rk);
    end;
    $$
language plpgsql;

------------------------

create or replace function plan_lekcji(kl int)
    returns TABLE(przedmiot varchar,czas text ,dzien DZIEN,sala INTEGER,nauczyciel varchar,id_lekcji integer) as
$$
begin
    IF kl NOT IN (SELECT klasa FROM klasy) THEN RAISE EXCEPTION 'Nie ma takiej klasy';END IF;
    return QUERY SELECT (SELECT p.nazwa FROM przedmioty p JOIN nauczyciele_prowadzacy np ON p.id=np.id_przedmiot
                       WHERE np.id=l.przedmiot) AS przedmiot,
    to_char(l.czas, 'HH:MI'), l.dzien, l.sala,
    (SELECT nazwisko FROM Pracownicy
    WHERE id=(SELECT p.nauczyciel FROM Nauczyciele_prowadzacy p WHERE p.id=l.przedmiot)) AS nauczyciel,l.id
    FROM Lekcje l WHERE l.klasa=kl ORDER BY l.dzien, l.czas;

end;
$$
language plpgsql;

------------------------
create or replace function plan_lekcji_ucznia(indexUcznia integer)
returns TABLE(przedmiot varchar,czas text ,dzien DZIEN,sala INTEGER,nauczyciel varchar,id_lekcji integer) as
$$
begin
    RETURN QUERY SELECT * FROM plan_Lekcji((SELECT klasa FROM uczniowie u WHERE u.index=indexUcznia));
end;
$$
language plpgsql;

------------------------

create or replace function plan_lekcji_nauczyciela(idn int)
    returns TABLE(przedmiot varchar,czas text ,dzien DZIEN,sala INTEGER,klasa CHAR(2),id_lekcji integer) as
$$
begin
    IF idn NOT IN (SELECT id FROM pracownicy) THEN RAISE EXCEPTION 'Nie ma takiego nauczyciela';END IF;
    return QUERY SELECT przedmiot(np.id_przedmiot), to_char(l.czas, 'HH:MI'), l.dzien, l.sala, klasa(l.klasa), l.id FROM lekcje l JOIN nauczyciele_prowadzacy np ON l.przedmiot=np.id WHERE
        l.przedmiot IN (SELECT id FROM nauczyciele_prowadzacy WHERE nauczyciel=idn) ORDER BY l.dzien, l.czas;
end;
$$
language plpgsql;

-----------------------------------------------------------------------------------------
--drop function terminarz_klasy(kl integer)
CREATE OR REPLACE FUNCTION terminarz_klasy(kl integer)
RETURNS TABLE (klasa_ char(2),nr_lekcji INTEGER,lekcja VARCHAR, dzien DATE, typ sprawdziany, komentarz varchar) AS
    $$
    BEGIN
        RETURN QUERY SELECT klasa(l.klasa) ,t.lekcja,
        (SELECT nazwa FROM przedmioty JOIN nauczyciele_prowadzacy np ON Przedmioty.id = np.id_przedmiot
            WHERE np.id=l.przedmiot)
        ,t.dzien,t.typ,t.komentarz FROM terminarz t LEFT JOIN lekcje l ON l.id=t.lekcja
        WHERE l.klasa=kl;
    end;
    $$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION swiadectwa_srednie(rokid int)
RETURNS TABLE (index int, srednia numeric(3,2)) AS
    $$
    BEGIN
        RETURN QUERY
        SELECT u.index, ROUND(AVG(ocena_koncoworoczna),2) FROM uczniowie u JOIN oceny_okresowe oo on u.index = oo.index WHERE u.absolwent='N' AND oo.rok=rokid GROUP BY u.index;
    end;
    $$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION koniec_roku_braki(rokid int)
RETURNS TABLE (index_ucznia int, przedmiot_brak varchar) AS
    $$
    declare
        i int;
        j int;
    begin
        CREATE TEMP TABLE tab(ind int, p varchar) ON COMMIT DROP;
        FOR i in (SELECT u.index FROM uczniowie u WHERE absolwent='N') LOOP
            FOR j in (SELECT id_przedmiot FROM nauczyciele_prowadzacy np JOIN Lekcje L on np.id = L.przedmiot WHERE L.klasa = (SELECT klasa FROM Uczniowie WHERE index = i)) LOOP
                if ((SELECT ocena_koncoworoczna FROM oceny_okresowe WHERE przedmiot=j AND index=i AND rok=rokid) IS NULL) THEN
                INSERT INTO tab VALUES (i,przedmiot(j));
                END IF;
                end loop;
            end loop;
        RETURN QUERY SELECT * FROM tab GROUP BY 1,2 ORDER BY 1,2;
    end;
    $$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION koniec_roku(rokid int)
RETURNS VOID AS
    $$
    declare
        i int;
        j int;
    begin
        FOR i in (SELECT index FROM uczniowie WHERE absolwent='N') LOOP
            FOR j in (SELECT id_przedmiot FROM nauczyciele_prowadzacy np JOIN Lekcje L on np.id = L.przedmiot WHERE L.klasa = (SELECT klasa FROM Uczniowie WHERE index = i)) LOOP
                if ((SELECT ocena_koncoworoczna FROM oceny_okresowe WHERE przedmiot=j AND index=i AND rok=rokid) IS NULL) THEN RAISE EXCEPTION 'Brak części ocen końcowych'; END IF;
                end loop;
            end loop;
    end;
    $$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generuj_swiadectwo(ind int, rokid int)
RETURNS TABLE (index int, Przedmiot varchar, ocena int) AS
    $$
    begin
        RETURN QUERY SELECT oo.index, p.nazwa, ocena_koncoworoczna FROM oceny_okresowe oo JOIN Przedmioty P on oo.przedmiot = P.id WHERE oo.index = ind AND rok=rokid;
    end;
    $$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION niezdajacy_uczniowie(rokid int)
RETURNS TABLE (index_ucznia int) AS
    $$
    DECLARE i int;
    begin
        CREATE TEMP TABLE tab (index int) ON COMMIT DROP;
        FOR i in (SELECT index FROM nieobecnosci WHERE typ='N' GROUP BY index HAVING COUNT(*)>10) LOOP
                INSERT INTO tab VALUES (i);
            end loop;
        FOR i in (SELECT distinct index FROM oceny_okresowe WHERE ocena_koncoworoczna=1 AND rok=rokid) LOOP
                INSERT INTO tab VALUES (i);
            end loop;
        RETURN QUERY SELECT * FROM tab;
    end;
    $$
language plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION koniec_roku_czyszczenie(rokid int)
RETURNS TABLE (index_ucznia int) AS
    $$
    DECLARE
        i int;
        a record;
    begin
        PERFORM koniec_roku(rokid);
        CREATE TEMP TABLE tab (index int) ON COMMIT DROP;
        FOR i in (SELECT index FROM nieobecnosci WHERE typ='N' GROUP BY index HAVING COUNT(*)>10) LOOP
                INSERT INTO tab VALUES (i);
            end loop;
        FOR i in (SELECT distinct index FROM oceny_okresowe WHERE ocena_koncoworoczna=1 AND rok=rokid) LOOP
                INSERT INTO tab VALUES (i);
            end loop;
        DELETE FROM oceny WHERE TRUE;
        DELETE FROM nieobecnosci WHERE TRUE;
        DELETE FROM terminarz WHERE TRUE;
        DELETE FROM zastepstwa WHERE TRUE;
        DELETE FROM lekcje WHERE TRUE;
        FOR i in (SELECT index FROM uczniowie WHERE klasa in (SELECT klasa FROM klasy WHERE nr_klasy=8)) LOOP
                UPDATE uczniowie SET klasa=null, absolwent='T' WHERE Uczniowie.index=i;
            end loop;
        FOR a in (SELECT * FROM klasy ORDER BY klasa DESC) LOOP
            if (a.nr_klasy=8) THEN DELETE FROM klasy WHERE klasa = a.klasa;
            ELSE UPDATE klasy SET nr_klasy = a.nr_klasy+1 WHERE klasa = a.klasa;
            END IF;
            end loop;
        IF (SELECT id FROM lata_szkolne WHERE nazwa = CONCAT(substring(rok(int4(pg_sequence_last_value('aktualny_rok_szkolny'))), 1, 4)::int+1,'/',substring(rok(int4(pg_sequence_last_value('aktualny_rok_szkolny'))), 1, 4)::int+2)) IS NULL THEN
        INSERT INTO lata_szkolne (nazwa) VALUES (CONCAT(substring(rok(int4(pg_sequence_last_value('aktualny_rok_szkolny'))), 1, 4)::int+1,'/',substring(rok(int4(pg_sequence_last_value('aktualny_rok_szkolny'))), 1, 4)::int+2));
        END IF;
        PERFORM setval('aktualny_rok_szkolny', rok(CONCAT(substring(rok(int4(pg_sequence_last_value('aktualny_rok_szkolny'))), 1, 4)::int+1,'/',substring(rok(int4(pg_sequence_last_value('aktualny_rok_szkolny'))), 1, 4)::int+2)));
        RETURN QUERY SELECT * FROM tab;
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

INSERT INTO Pracownicy (imie, nazwisko, tytul) VALUES ('A', 'Bananowski',   'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko,  tytul) VALUES ('C', 'Drozd',   'MAGISTER');
INSERT INTO Pracownicy (imie, nazwisko,  tytul) VALUES ('E', 'Figowa',  'DOKTOR');
INSERT INTO Pracownicy (imie, nazwisko,  tytul) VALUES ('G', 'Haber',   null);
INSERT INTO Pracownicy (imie, nazwisko,  tytul) VALUES ('A', 'Borówka',   null);

INSERT INTO Klasy (nr_klasy, nazwa_klasy, klasa, wychowawca) VALUES (1,'E', 1, 2);
INSERT INTO Klasy  VALUES (4,'E',2, 1);
INSERT INTO Klasy  VALUES (2,'E',3, 3);

INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (401, 2, 'Alivia','Goss');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (402, 2, 'Elijah','Pina');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (403, 2, 'Aditi','Mathews');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (404, 2, 'Haley','Shelton');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (405, 2, 'Kolt','Holcomb');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (406, 2, 'Aliyah','Suggs');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (407, 2, 'Layla','Varner');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (408, 2, 'Millicent','Olson');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (409, 2, 'Kennedy','Rushing');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (410, 2, 'Lilyanna','Pritchard');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (411, 2, 'Hugh','Scruggs');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (412, 2, 'Jamar','Peacock');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (101, 1, 'Braydan','Saunders');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (102, 1, 'Kai','Downey');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (103, 1, 'Hallie','Platt');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (104, 1, 'Jarvis','Childress');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (105, 1, 'Ally','Zimmerman');
INSERT INTO Uczniowie (index, klasa, imie, nazwisko) VALUES (106, 1, 'Bentley','Draper');

INSERT INTO Sale (nr, liczba_miejsc) VALUES (1, 35);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (2, 37);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (3, 25);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (4, 28);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (12, 25);
INSERT INTO Sale (nr, liczba_miejsc) VALUES (11, 45);

INSERT INTO Przedmioty (id, nazwa) VALUES (1, 'Matematyka');
INSERT INTO Przedmioty (id, nazwa) VALUES (2, 'Polski');
INSERT INTO Przedmioty (id, nazwa) VALUES (3, 'Chemia');
INSERT INTO Przedmioty (id, nazwa) VALUES (4, 'Biologia');

INSERT INTO Nauczyciele_prowadzacy VALUES (0,1,1);
INSERT INTO Nauczyciele_prowadzacy VALUES (1,4,1);
INSERT INTO Nauczyciele_prowadzacy VALUES (2,2,2);
INSERT INTO Nauczyciele_prowadzacy VALUES (3,3,2);

INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 1, 2, '12:00', 'Poniedziałek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 2, 1, '12:00', 'Poniedziałek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (3, 3, 2, '12:00', 'Środa');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 11, 2, '11:00', 'Piątek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 11, 1, '8:00', 'Czwartek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (3, 3, 2, '10:00', 'Środa');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 3, 2, '11:00', 'Środa');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 11, 2, '9:00', 'Czwartek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (1, 11, 2, '10:00', 'Czwartek');
INSERT INTO Lekcje (przedmiot, sala, klasa, czas, dzien) VALUES (2, 11, 2, '10:00', 'Piątek');

INSERT INTO Terminarz (lekcja, typ, komentarz, dzien) VALUES (1, 'sprawdzian', '', '11.05.2020');
INSERT INTO Terminarz (lekcja, typ, komentarz, dzien) VALUES (1, 'sprawdzian', '', '18.05.2020');

INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (401, 1, 5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (402, 1, 3, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (403, 2, 5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (404, 4, 4, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (101, 4, 5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (102, 4, 3, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (103, 4, 3.5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (401, 2, 5.5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (105, 1, 5.5, '');
INSERT INTO Oceny (index, przedmiot, ocena, komentarz) VALUES (105, 1, 5.5, '');

INSERT INTO nieobecnosci (index, lekcja, data) VALUES (401, 1, '11.05.2020');
INSERT INTO nieobecnosci (index, lekcja, data) VALUES (402, 1, '11.05.2020');

INSERT INTO zastepstwa (lekcja, nauczyciel, data) VALUES (1, 3, '18.05.2020');
INSERT INTO zastepstwa (lekcja, nauczyciel, data) VALUES (10, 3, '05.06.2020');
INSERT INTO zastepstwa (lekcja, nauczyciel, data) VALUES (4, 2, '05.06.2020');

INSERT INTO lata_szkolne (id, nazwa) VALUES (0, '2018/2019');
INSERT INTO lata_szkolne (id, nazwa) VALUES (1, '2019/2020');

INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (401,1,3,1,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (401,2,2,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (401,4,4,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (402,1,3,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (402,2,3,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (402,4,5,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (403,1,3,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (403,2,4,2,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (403,4,5,6,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (404,1,3,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (404,2,4,2,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (404,4,5,6,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (405,1,3,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (405,2,4,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (405,4,5,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (406,1,3,2,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (406,2,4,2,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (406,4,5,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (407,1,3,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (407,2,4,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (407,4,5,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (408,1,3,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (408,2,4,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (408,4,5,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (409,1,3,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (409,2,4,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (409,4,5,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (410,1,3,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (410,2,4,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (410,4,5,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (411,1,3,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (411,2,4,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (411,4,5,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (412,1,3,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (412,2,4,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (412,4,5,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (101,1,4,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (101,4,5,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (102,1,4,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (102,4,5,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (103,1,4,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (103,4,5,4,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (104,1,4,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (104,4,5,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (105,1,4,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (105,4,5,5,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (106,1,4,3,1);
INSERT INTO oceny_okresowe (index, przedmiot, ocena_srodroczna, ocena_koncoworoczna, rok) VALUES (106,4,5,4,1);

--GRANTS

GRANT SELECT ON ALL TABLES IN SCHEMA public TO Nauczyciele;
GRANT INSERT ON ALL TABLES IN SCHEMA public TO Nauczyciele;
GRANT UPDATE ON ALL TABLES IN SCHEMA public TO Nauczyciele;
GRANT DELETE ON ALL TABLES IN SCHEMA public TO Nauczyciele;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO Uczniowie;



UPDATE Terminarz SET typ='kartkowka'
 WHERE lekcja=4 AND dzien='2020-06-12';

SELECT * FROM terminarz;