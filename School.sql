DROP TABLE if EXISTS Przedmioty;
DROP TABLE if EXISTS Lekcje;
DROP TABLE if EXISTS Sale CASCADE;
DROP TABLE if EXISTS Uczeniowie;
DROP TABLE if EXISTS Uczniowie;
DROP TABLE if EXISTS Klasy CASCADE;
DROP TABLE if EXISTS Nauczyciele;
DROP TABLE if EXISTS Pracownicy;
DROP TABLE if EXISTS Place;
DROP TABLE if EXISTS Obiekty CASCADE;
DROP TABLE if EXISTS Inwentaz;
DROP TABLE if EXISTS Drogi_ewakuacyjne;

CREATE TABLE Place(
    stanowisko CHARACTER VARYING NOT NULL,
    CHECK (stanowisko='NAUCZYCIEL' OR stanowisko='DYREKTOR' OR stanowisko='SEKRETARZ' OR stanowisko='OSOBA SPRZĄTAJĄCA'
               OR stanowisko='OPIEKA MEDYCZNA' OR stanowisko='SPRZEDAWCA' OR stanowisko='PSYCHOLOG'),
    tytul VARCHAR CHECK(tytul='DOKTOR' OR tytul='MAGISTER' OR tytul='PROFESOR' OR tytul='DOKTOR HABILITOWANY'),
    PRIMARY KEY (stanowisko,tytul),
    placa NUMERIC(5,2) NOT NULL
);
CREATE TABLE Pracownicy(
    id NUMERIC(2) NOT NULL CONSTRAINT PK_PRAC PRIMARY KEY,
    imie CHARACTER VARYING NOT NULL,
    nazwisko CHARACTER VARYING NOT NULL,
    godzinyPracy NUMERIC(2),
    stanowisko CHARACTER VARYING NOT NULL,
    tytul VARCHAR  CHECK(tytul='DOKTOR' OR tytul='MAGISTER' OR tytul='PROFESOR' OR tytul='DOKTOR HABILITOWANY'),
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
