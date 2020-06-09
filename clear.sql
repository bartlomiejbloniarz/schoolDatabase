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
DROP FUNCTION if EXISTS dodaj_przedmiot() CASCADE;
DROP FUNCTION if EXISTS dodaj_nauczyciela_prowadzacego() CASCADE;
DROP FUNCTION if EXISTS terminarz_klasy(kl varchar) CASCADE;
DROP FUNCTION IF EXISTS plan_lekcji(kl varchar) CASCADE;
DROP FUNCTION IF EXISTS plan_lekcji_ucznia(indexUcznia integer) CASCADE;
DROP FUNCTION IF EXISTS plan_lekcji_nauczyciela(a integer) CASCADE;
DROP FUNCTION IF EXISTS dodaj_zastepstwo() CASCADE;
DROP FUNCTION IF EXISTS dodaj_nieobecnosc() CASCADE;
DROP FUNCTION IF EXISTS dodaj_terminarz() CASCADE;
DROP FUNCTION IF EXISTS zamien_nauczyciela() CASCADE;
DROP FUNCTION IF EXISTS usun_nauczyciela() CASCADE;
DROP FUNCTION IF EXISTS usun_ucznia() CASCADE;
DROP FUNCTION IF EXISTS dodaj_pracownika() CASCADE;
DROP FUNCTION IF EXISTS dodaj_lekcje() CASCADE;
DROP FUNCTION IF EXISTS usun_lekcje() CASCADE;
DROP FUNCTION IF EXISTS dodaj_dziecko() CASCADE;
DROP FUNCTION IF EXISTS nieobecnosc() CASCADE;
DROP FUNCTION IF EXISTS ocena_z_lekcji() CASCADE;
DROP FUNCTION IF EXISTS dodaj_ocene_okresowa() CASCADE;
DROP FUNCTION IF EXISTS dodaj_klase() CASCADE;
DROP FUNCTION IF EXISTS usun_uzytkownikow() CASCADE;
drop function if exists czy_dziecko_ma_klase() cascade;
drop function if exists dodaj_ocene() cascade;
drop function if exists plan_lekcji(kl integer) CASCADE;
drop function if exists terminarz_klasy(integer);
drop function if exists swiadectwa_srednie(integer);
drop function if exists koniec_roku();
drop function if exists generuj_swiadectwo(integer, integer);
drop function if exists koniec_roku_czyszczenie();
drop function if exists niezdajacy_uczniowie();
drop function if exists przedmiot(integer);
drop function if exists przedmiot(varchar);
drop function if exists koniec_roku_braki();
drop function if exists klasa(kl integer) CASCADE;
drop function if exists klasa(kl char(2)) CASCADE;
drop function if exists rok(rk char) CASCADE;
drop function if exists rok(rk integer) CASCADE;
drop function if exists rok_szkolny() CASCADE;
DROP TABLE if EXISTS Nauczyciele_prowadzacy CASCADE;
DROP TABLE if EXISTS zastepstwa;
DROP TABLE if EXISTS Terminarz;
DROP TABLE if EXISTS nieobecnosci;
DROP TABLE if EXISTS Oceny;
DROP TABLE if EXISTS Lekcje;
DROP TABLE if EXISTS oceny_okresowe;
DROP TABLE if EXISTS Przedmioty CASCADE;
DROP TABLE if EXISTS Sale;
DROP TABLE if EXISTS Uczniowie;
DROP TABLE if EXISTS Klasy;
DROP TABLE if EXISTS Zastepstwa;
DROP TABLE if EXISTS Pracownicy CASCADE;
DROP TABLE if EXISTS lata_szkolne;

DROP SEQUENCE IF EXISTS aktualny_rok_szkolny;
DROP TYPE if EXISTS TYTUL;
DROP TYPE if EXISTS DZIEN;
DROP TYPE if EXISTS absolwent;
DROP TYPE if EXISTS sprawdziany;
DROP TYPE if EXISTS obecnosc;


DROP ROLE Administracja;
DROP ROLE Nauczyciele;
DROP ROLE Uczniowie;
