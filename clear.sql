create or replace function usun_uzytkownikow()
    returns void AS
    $$
    declare
       record record;
        nazwa varchar;
    begin

        for record in SELECT* FROM pracownicy loop
        nazwa=CONCAT('n',cast(record.id AS varchar));
        EXECUTE('DROP USER ' || quote_ident(nazwa) || ';') ;
        end loop;

        for record in SELECT* FROM uczniowie loop
        nazwa=CONCAT('u',cast(record.index AS varchar));
        EXECUTE('DROP USER ' || quote_ident(nazwa) || ';') ;
        end loop;

       DROP USER sekretariat;

    end;
    $$
LANGUAGE plpgsql;

SELECT usun_uzytkownikow();


DROP VIEW if exists srednie_ocen;
DROP FUNCTION if EXISTS terminarzklasy(kl varchar);
DROP FUNCTION IF EXISTS mojplanlekcji(iddziecka numeric);
DROP FUNCTION IF EXISTS dodajZastepstwo() CASCADE;
DROP FUNCTION IF EXISTS dodajnieobecnosc() CASCADE;
DROP FUNCTION IF EXISTS dodajterminarz() CASCADE;
DROP FUNCTION IF EXISTS wiecej_niz_zero(a numeric);
DROP FUNCTION IF EXISTS zamien_nauczyciela() CASCADE;
DROP FUNCTION IF EXISTS usun_nauczyciela() CASCADE;
DROP FUNCTION IF EXISTS dodaj_pracownika() CASCADE;
DROP FUNCTION IF EXISTS dodajlekcje() CASCADE;
DROP FUNCTION IF EXISTS dodajdziecko() CASCADE;
DROP FUNCTION IF EXISTS nieobecnosc() CASCADE;
DROP FUNCTION IF EXISTS ocena_z_lekcji() CASCADE;
DROP FUNCTION IF EXISTS dodaj_ocene_okresowa() CASCADE;
DROP FUNCTION IF EXISTS dodaj_klase() CASCADE;
DROP TABLE if EXISTS Nauczyciele_prowadzacy;
DROP TABLE if EXISTS zastepstwa;
DROP TABLE if EXISTS Terminarz;
DROP TABLE if EXISTS nieobecnosci;
DROP TABLE if EXISTS Oceny;
DROP TABLE if EXISTS Lekcje;
DROP TABLE if EXISTS nauczyciele_powadzacy;
DROP TABLE if EXISTS oceny_okresowe;
DROP TABLE if EXISTS Przedmioty;
DROP TABLE if EXISTS Sale;
DROP TABLE if EXISTS Uczniowie;
DROP TABLE if EXISTS Klasy;
DROP TABLE if EXISTS Zastepstwa;
DROP TABLE if EXISTS Pracownicy;

DROP SEQUENCE IF EXISTS Lekcje_id_seq;
DROP TYPE if EXISTS TYTUL;

DROP ROLE Administracja;
DROP ROLE Nauczyciele;
DROP ROLE Uczniowie;
