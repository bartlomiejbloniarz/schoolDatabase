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
ocenach okresowych-śródrocznych i koncoworocznych (tabela oceny_okresowe),
kolejnych latach szkolnych (tabela lata_szkolne).


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
Tabela oceny_okresowe jest w relacji OW:NJ z lata_szkolne na zasadzie każda ocena okresowa dotyczy dokładnie jednego roku szkolnego, jednak nie w każdym roku musiała jakś zostać wystawiona.

Dodatkowo zawarte są:
funkcja przedstawiająca spis zajęć dla podanego ucznia(mojPlanLekcji),funckja przedstawiająca dla zadanej klasy spis form sprawdzania wiedzy z terminarza(terminarzKlasy) oraz widok liczący dla każdego ucznia średnie w szystkich przedmiotów na które uczęszcza np. w celu wystawienia oceny okresowej(srednie_ocen).

Naszym zamysłem jest, by w bazie przechowywani byly uczniowie-aktualni oraz absolwenci oraz wszystkie ich oceny okresowe. 
Przechowywani mogą być również już niezatrudnieni pracownicy. Informacji tej w żaden sposób nie uwzględniamy(czy nadal jest ktoś zatrudniony), ponieważ istnieją różne formy zatrudnienia. Np. ktoś może być okresowo zatrudniany na zastępstwa, istnieją też różne formy umów o pracę, czym nasza baza się nie zajmuje, stąd informacje te do niej nie należą.
Informacje o lekcjach, a co za tym idzie również zastępstwach, formach sprawdzania wiedzy oraz nieobecnościach, ponadto przedmiotach a zatem również ocanch powinny być natomiast aktualizowane i odpowiednio usówane z bazy np. na koniec semestru, czy w dowolnym okresie, kiedy następuje zmiana prowadzonych przedmiotów czy planu lekcji. W szczególności biorąc pod uwagę tryb działania stanrdardowej placówki szkolnej wszystkie powyżej wymienione dane byłyby usówane na koniec  roku szkolnego, po pierwszym semestrze zaś dane z tabel: lekcje,zastepstwa,terminarz,nieobecnosci(zakładając, że w szkole kursy są raczej roczne, niż semestralne).
Dane tabel jak sale, nauczyciele_prowadzacy,klasy mogą być również zmieniane okresowo, w rzeczywistości jednak bardzo częstym jest by zostawały one w prawie niezmienionym stanie w kolejnych latach. 
Oczywiście wszystkie dane można zmienić w dowolnym momecie, jednak odpowiednio zmieniając skorelowane dane w innych tabelach. Przy usuwaniu nauczyciela automatycznie usunięte zostaną lekcje które prowadzi oraz związane z nim krotki tabeli nauczyciele_prowadzacy.

Wprowadziliśmy liczne ograniczenia oraz triggery mające na celu uniemożliwienie wprowadzania lub automatyczną korektę danych potencjalnie powodujących nielogiczny, czy też niepoprawny stan bazy. Przykładowdo: 
pola id i index są wypełniane automatycznie, 
nauczyciel nie może zastępować samego siebie, nie może też prowdzić jednocześnie dwóch lekcji(włączając w to prowadzone zastępstwa),
uczeń nie może dostać oceny ani nieobecności z lekcji na którą nie uczęszcza,
dzieci nie może być w klasie więcej, niż miejsc w salach w których mają lekcje,
dodane formy sprawdzania wiedzy, zastępstwa, nieobecności,  które to posiadają datę, sprawdzane są na spójność dotyczącą wpisanej daty oraz dnia tygodnia w którym odbywa się związana z nimi lekcja(dla ocen datą jest data wprowadzenia, która  nie jest od tego zależna. Datę przeprowadzenia można umieścić np. w opisie, jeśli jest taka potrzeba),
oceny okresowe przy dodawaniu są przechwytywane, na wypadek, gdyby krotka danego ucznia i przedmiotu już istniała. Wówczas jest ona aktualizowana, by zachować porządek danych. 


Dla dodawanych uczniowiów i nauczycieli automatycznie zostaje utworzone konto pozwalające na dostęp do pewnych, przeznaczonych dla nich danych(oczywiście po upewnieniu się, że samo dodanie do bazy nie powoduje błędu). Usiwając osobę z bazy danych konto to zostaje wycofane. 

--------------------------------------------------------------------------------------------

APLIKACJA:
create.sql należy uruchomić w bazie danych o nazwie "school" i schemacie o nazwie "public". 

Aplikacja celowo nie umożliwia modyfikowania tabeli Sale-jest to coś na tyle niezmiennego, że dostęp do tego wydaje nam się logiczny jedynie z poziomu bazy danych.
Nieobecności dostępne są poprzez menu kontekstowe konkretnego ucznia.
Każda tabela posiada własny zestaw akcji jakie można wykonać na jej krotkach. Podstawowwymi akcjami są usówanie, dodawanie oraz zmienianie
(choć nie wszystkie table posiadają te możliwości). W szczególności srednie_ocen nie posiadają tej możliwości jako automatycznie wyliczana tabela(view).
Pola które mogą mieć wartość null(np. kometarze) mozna na takie zmienić(jeśli były wypełnione) wpisująć "BRAK" w pole wypełniania(poza nazwą klasy ucznia i polem absolwent,
które są w odpowiedni sposób wypełniane automatycznie gdy któreś zostanie zmienione).

Nauczyciele mają ograniczone prawa dostępu(stosujemy role, którym przydzialene są uprawnienia w bazie danych),
każdy ma dostęp do uczniów których uczy(i ich ocen okresowych i ich średnich ocen),
swojego planu lekcji(choć może zobaczyć też plan lekcji klas), swojego terminarza, swoich zastępstw(tych, które on prowadzi),
wprowadzonych przez siebie ocen, klas które uczy, przedmiotów które prowadzi oraz dostęp do panelu wychowawcy pozwalającego na
zarządzanie nieobecnościami uczniów których jest wychowawcą.
Niedostępne mozliwości są albo zupełnie niemożliwe do wykonania przez aplikacje, albo powodują pojawienie się wiadomości o niepoprawnej akcji
zamiast jej wykonania.
Nauczyciel może zobaczyć cały terminarz klas które uczyprzykładowo w celu ustalenia niekolidującego terminu) oraz wszystkie oceny wychowanków,
jednak zmian może dokonać tylko przez tabele służące do wyświetlania dostępnych do zmiany dla niego informacji.


Przykładowe dane: 
logowanie użytkowniekiem który ma najwięcej praw dostępu(wszystkie które przewidzieliśmy dla aplikacji): login: sekretariat hasło: sekretariat
logowanie przykładownym nauczycielem: login: n1 haslo:1234
logowanie przykładowym uczniem: login: u401 hasło:1234
Przykładowy uczeń: 401 (ten, którego login został podany powyżej)
Przykładowy nauczyciel: 1 (ten, którego login został podany powyżej)
Przykładowa klasa: 4E  (należy do niej 401 i uczy ją między innymi 1 i jest jej wychowawcą)





------------------------------------------------------------------------------------------------------------
Wkład pracy:

Bartłomiej Błoniarz: 
Stworzone tabele:
Nieobecnosci, Oceny, Termiarz, Przedmioty. Oraz korekta pozostałych tabel.

Stworzone triggery(oraz konieczne do nich funkcje):
 dodaj_terminarz, dodaj_nieobecnosc, dodaj_zastepstwo

Stworzone funkcje:
terminarzKlasy

Przykładowe dane
Clear.sql

Kwestia aplikacji:
szkielet projektu, niektóre funkcjonalności. Możliwość logowania się przez różne typy użytkowników w inny sposób. Część widoków.
------------------------------------------------------------------------------------------------------
Inka Sokołowska:
Stworzone tabele:
Lekcje, Sale, Uczniowie, Klasy, Pracownicy, Zastepstwa, Oceny_okresowe, Nauczyciele_prowadzacy.

Stworzone triggery(oraz konieczne do nich funkcje): 
dodaj_pracownika, dodaj_dziecko, dodaj_lekcje, zamien_nauczyciela, dodaj_nieobecnosc, ocena_z_lekcji, usun_ucznia,
usun_nauczyciela, dodaj_klase, dodaj_nauczyciela_prowadzacego, dodaj_ocene_okresowa, dodaj_przedmiot

Stworzone funkcje:
plan_lekcji,terminarzKlasy, usun_uzytkownikow

Stworzone widoki: 
srednie_ocen

Readme

Kwestia aplikacji:
funkcjonalności jak dodawanie, usuwanie, zmienianie, zmiana hasla. Część widoków.
