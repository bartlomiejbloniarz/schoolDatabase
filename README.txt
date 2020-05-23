Baza danych przedstawiająca schemat szkoły, podobny do dziennika elektronicznego. 
Zawiera informacje o 
pracownikach tj. nauczycielach (tabela pracownicy),
przedmiotach tj. typach prowadzonych zajęć (tabela przedmioty), 
relacji między przedmiotami a prowadzących je nauczycielami(tabela nauczyciele_prowadzacy),
lekcjach tj. konkretnych zajęciach odbywających się w danych godzinach i dniach(tablea Lekcje),
salach tj. pomieszczeniach (tabela sale), 
uczniach uczęszczających do szkoły (tabela uczniowie), 
klasach tj. grupach ucznów (np.6a)(tabela klasy), 
obecnościach uczniów na lekcjach  (tabela nieobecności),
ocenach uczniów z konkretnych przedmiotów (Tabela oceny),
formach sprawdzania wiedzy np. sprawdzianach, kartkówkach (tabela terminarz),
zastępstwach (tabla zastepstwa),
ocenach okresowych-śródrocznych i koncoworocznych (tabela oceny_okresowe).


Zachodzą następujące zależności między tablami: 
ponież stosowane będą następujące oznaczenia na typy relacji:
O oznacza obowiązkowe, N oznacza nieobowiązkowe, W oznacza wiele, J odnzacza jeden.

Tabela Uczniowie jest w relacji OW:NJ z Klasy na zasadzie: klasa moze posiadać w inwentarzu wiele obiektów.
Tabela Klasy jest w relacji OW:NJ z Pracownicy na zasadzie bycia wychowawcą. 
Tabela Lekcje jest w relacji OW:NJ z Sale na zasadzie każda lekcja musi się odbywać w dokładnie jednym pomieszczeniu, jednak nie w każdym pomieszczeniu muszą odbywać lekcje. 
Tabela Lekcje jest w relacji OW:NJ z Przedmioty na zasadzie każda lekcja musi dotyczyć jakiegoś przedmiotu jednak nie z każdego przedmiotu lekcje muszą się odbywać. 
Tabela Lekcje jest w relacji OW:NJ z Klasy na zasadzie w każda klasa musi odbywać się z jakąś klasą.
Tabela Termiarz jest w relacji OW:NJ z Lekcje na zasadzie każda forma sprawdzania wiedzy musi odbywać się podaczas jakiejś lekcji, jednak mogą odbywać się lekcje na któych wiedza uczniów nie jest sprawdzana.
Tabela Nieobecności jest w relacji OW:NJ z Uczniowie na zasadzie każda nieobecność dotyczy konkretnego ucznia, jednak nie jest wymagane, by każdy jakąś posiadał.
Tabela Nieobecności jest w relacji OW:NJ z Lekcje na zasadzie każda nieobecność dotyczy konkretnej lekcji, jednak nie jest wymagane, by na każdej lekcji ktoś miał nieobecność.
Tabela Oceny jest w relacji OW:NJ z Uczniowie na zasadzie jedna ocena dotyczy jednego ucznia, jednak nie każdy musi jakąś posiadać.
Tabela Oceny jest w relacji OW:NJ z Przedmioty na zasadzie każda ocena dotyczy konkretnego przedmiotu, jednak nie z każdego przedmiotu muszą być jakieś oceny.
Tabela Zastepstwa jest w relacji OW:NJ z Pracownicy na zasadzie każde zastępstwo musi być prowadzone przez dokładnie jednego nauczyciela, jadniak nie każdy musi prowadzić zastępstwa.
Tabela Zastepstwa jest w relacji OW:NJ z Lekcje na zasadzie kazde zastępstwo musi dotyczyć konkretnej lekcji, jednak nie na każdej lekcji musi być zastępstwo.
Tabela oceny_okresowe jest w relacji OW:NJ z Uczniowie na zasadzie każda ocena musi dotyczyć konkretnego ucznia, jednak nie każdy musi mieć zawsze jakąś wystawioną.
Tabela oceny_okresowe jest w relacji OW:NJ z Przedmioty na zasadzie każda ocena musi dotyczyć konkretnego przedmiotu, jednak nie z każdego przedmiotu musi być wystawiona ocena. 
Tabela nauczyciele_prowadzacy jest w relacji OW:NJ z Przedmioty na zasadzie każda krotka w np musi dotyczyć konkretnego przedmiotu, jednak nie każdy przedmiot musi mieć prowadzącego go nauczyciela.
Tabela nauczyciele_prowadzacy jest w relacji OW:NJ z Pracownicy na zasadzie każda krotka w np musi dotyczyć konkretnego nauczyciela, jednak nie każdy nauczyciel musi prowadzić jakieś zajęcia.

Dodatkowo zawarte są:
funkcja przedstawiająca spis zajęć dla podanego ucznia(mojPlanLekcji),funckja przedstawiająca dla zadanej klasy spis form sprawdzania wiedzy z terminarza(terminarzKlasy) oraz widok liczący dla każdego ucznia średnie w szystkich przedmiotów na które uczęszcza np. w celu wystawienia oceny okresowej(srednie_ocen).

Naszym zamysłem jest, by w bazie przechowywani byly uczniowie-aktualni oraz absolwenci oraz wszystkie ich oceny okresowe. 
Przechowywani mogą być również już niezatrudnieni pracownicy. Informacji tej w żaden sposób nie uwzględniamy(czy nadal jest ktoś zatrudniony), ponieważ istnieją różne formy zatrudnienia. Np. ktoś może być okresowo zatrudniany na zastępstwa, istnieją też różne formy umów o pracę, czym nasza baza się nie zajmuje, stąd informacje te do niej nie należą.
Informacje o lekcjach, a co za tym idzie również zastępstwach, formach sprawdzania wiedzy oraz nieobecnościach, ponadto przedmiotach a zatem również ocanch powinny być natomiast aktualizowane i odpowiednio usówane z bazy np. na koniec semestru, czy w dowolnym okresie, kiedy następuje zmiana prowadzonych przedmiotów czy planu lekcji. W szczególności biorąc pod uwagę tryb działania stanrdardowej placówki szkolnej wszystkie powyżej wymienione dane byłyby usówane na koniec  roku szkolnego, po pierwszym semestrze zaś dane z tabel: lekcje,zastepstwa,terminarz,nieobecnosci(zakładając, że w szkole kursy są raczej roczne, niż semestralne).
Dane tabel jak sale, nauczyciele_prowadzacy,klasy mogą być również zmieniane okresowo, w rzeczywistości jednak bardzo częstym jest by zostawały one w prawie niezmienionym stanie w kolejnych latach. 
Oczywiście wszystkie dane można zmienić w dowolnym momecie, jednak odpowiednio zmieniając skorelowane dane w innych tabelach. Przy usuwaniu nauczyciela automatycznie usunięte zostaną lekcje które prowadzi oraz związane z nim krotki tabeli nauczyciele_prowadzacy.




--------------------------------------------------------------------------------------------

APLIKACJA:
create.sql należy uruchomić w bazie danych o nazwie "school" i schemacie o nazwie "public". 



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


