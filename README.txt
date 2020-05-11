
Baza danych przedstawiająca schemat szkoły. 
Zawiera informacje o 
przedmiotach tj. typach prowadzonych zajęć połączonych z prowadzącymi je nauczycielami (tabela Przedmioty), 
lekcjach tj. konkretnych zajęciach odbywających się w danych godzinach i dniach(tablea Lekcje),
salach tj. pomieszczeniach (tabela Sale), 
uczniach uczęszczających do szkoły (tabela Uczniowie), 
klasach tj. grupach ucznów (np.6a)(tabela Klasy), 
pracownikach tj. nauczycielach (tabela pracownicy),
Obecnościach uczniów na lekcjach  (tabela Nieobecności),
Ocenach uczniów z konkretnych przedmiotów (Tabela Oceny),
Formach sprawdzania wiedzy np. sprawdzianach, kartkówkach (tabela Terminarz)


Zachodzą następujące zależności między tablami: 
ponież stosowane będą następujące oznaczenia na typy relacji:
O oznacza obowiązkowe, N oznacza nieobowiązkowe, W oznacza wiele, J odnzacza jeden.

Tabela Uczniowie jest w relacji OW:NJ z Klasy na zasadzie: klasa moze posiadać w inwentarzu wiele obiektów.
Tabela Klasy jest w relacji OW:NJ z Pracownicy na zasadzie bycia wychowawcą. 
Tabela Przedmioty jest w relacji OW:NJ z Pracownicy na zasadzie prowadzenia przedmiotu, przedmiot musi ktoś prowadzić, jednak nie każdy musi prowadzić przedmiot.
Tabela Lekcje jest w relacji OW:NJ z Sale na zasadzie każda lekcja musi się odbywać w dokłądnie jednym pomieszczeniu, jednak nie w każdym pomieszczeniu muszą odbywać lekcje. 
Tabela Lekcje jest w relacji OW:NJ z Przedmioty na zasadzie każda lekcja musi dotyczyć jakiegoś przedmiotu jednak nie z każdego przedmiotu lekcje muszą się odbywać. 
Tabela Lekcje jest w relacji OW:NJ z Klasy na zasadzie w każda klasa musi odbywać się z jakąś klasą.
Tabela Termiarz jest w relacji OW:NJ z Lekcje na zasadzie każda forma sprawdzania wiedzy musi odbywać się podaczas jakiejś lekcji, jednak mogą odbywać się lekcje na któych wiedza uczniów nie jest sprawdzana.
Tabela Nieobecności jest w relacji OW:NJ z Uczniowie na zasadzie każda nieobecność dotyczy konkretnego ucznia, jednak nie jest wymagane, by każdy jakąś posiadał.
Tabela Nieobecności jest w relacji OW:NJ z Lekcje na zasadzie każda nieobecność dotyczy konkretnej lekcji, jednak nie jest wymagane, by na każdej lekcji ktoś miał nieobecność.
Tabela Oceny jest w relacji OW:NJ z Uczniowie na zasadzie jedna ocena dotyczy jednego ucznia, jednak nie każdy musi jakąś posiadać.
Tabela Oceny jest w relacji OW:NJ z Przedmioty na zasadzie każda ocena dotyczy konkretnego przedmiotu, jednak nie z każdego przedmiotu muszą być jakieś oceny.


Dodatkowo zawarte są:
funkcja przedstawiająca spis zajęć dla podanego ucznia,


Wkład pracy:

Bartłomiej Błoniarz: 
Stworzone tabele:
Nieobecnosci, Oceny, Termiarz, Przedmioty. Oraz korekta pozostałych tabel.
Stworzone triggery(oraz konieczne do nich funkcje):
dodaj_pracownika, usunNauczyciela, dodajTerminarz, dodajNieobecnosci, dodajZastepstwo
Stworzone funkcje:
terminarzKlasy
Przykładowe dane
Clear.sql

Inka Sokołowska:
Stworzone tabele:
Lekcje, Sale, Uczniowie, Klasy, Pracownicy, Zastepstwa.
Stworzone triggery(oraz konieczne do nich funkcje): 
liczbaDzieci, jednaLekcjaNaRaz, usunSale, zamienNauczyciela, nieobecnosc, ocena_z_lekcji
Stworzone funkcje:
mojPlanLekcji.
Readme

Plany:
dopracowanie wyświetlania planu lekcji


