DROP VIEW IF EXISTS braki_wyposazenia;
DROP VIEW IF EXISTS tygodniowa_placa;
DROP FUNCTION IF EXISTS mojplanlekcji(iddziecka numeric);
DROP FUNCTION IF EXISTS braki_wyposazenia();
DROP FUNCTION IF EXISTS wiecej_niz_zero(a numeric);
DROP FUNCTION IF EXISTS zamien_nauczyciela() CASCADE;
DROP FUNCTION IF EXISTS czy_nauczyciel() CASCADE;
DROP FUNCTION IF EXISTS usun_nauczyciela() CASCADE;
DROP FUNCTION IF EXISTS dodaj_pracownika() CASCADE;
DROP FUNCTION IF EXISTS dodaj_place();
DROP FUNCTION IF EXISTS dodajlekcje() CASCADE;
DROP FUNCTION IF EXISTS dodajdziecko() CASCADE;
DROP FUNCTION IF EXISTS usun_sale();
DROP TABLE if EXISTS Terminarz;
DROP TABLE if EXISTS nieobecnosci;
DROP TABLE if EXISTS Oceny;
DROP TABLE if EXISTS Lekcje;
DROP TABLE if EXISTS Przedmioty;
DROP TABLE if EXISTS Sale;
DROP TABLE if EXISTS Drogi_ewakuacyjne;
DROP TABLE if EXISTS Uczniowie;
DROP TABLE if EXISTS Klasy;
DROP TABLE if EXISTS Pracownicy;
DROP TABLE if EXISTS Place;
DROP SEQUENCE IF EXISTS Lekcje_id_seq;
