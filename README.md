#BAZA DANYCH
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

Dodatkowo zawarte są:
funkcja przedstawiająca spis zajęć dla podanego ucznia(mojPlanLekcji),funckja przedstawiająca dla zadanej klasy spis form sprawdzania wiedzy z terminarza(terminarzKlasy) oraz widok liczący dla każdego ucznia średnie w szystkich przedmiotów na które uczęszcza np. w celu wystawienia oceny okresowej(srednie_ocen).

Naszym zamysłem jest, by w bazie przechowywani byli uczniowie-aktualni oraz absolwenci oraz wszystkie ich oceny okresowe.
Informacje o lekcjach, a co za tym idzie również zastępstwach, formach sprawdzania wiedzy oraz nieobecnościach, ponadto przedmiotach a zatem również ocanch powinny być natomiast aktualizowane i odpowiednio usówane z bazy np. na koniec semestru, czy w dowolnym okresie, kiedy następuje zmiana prowadzonych przedmiotów czy planu lekcji. W szczególności biorąc pod uwagę tryb działania stanrdardowej placówki szkolnej wszystkie powyżej wymienione dane byłyby usówane na koniec  roku szkolnego, po pierwszym semestrze zaś dane z tabel: lekcje,zastepstwa,terminarz,nieobecnosci(zakładając, że w szkole kursy są raczej roczne, niż semestralne).
Dane tabel jak sale, nauczyciele_prowadzacy,klasy mogą być również zmieniane okresowo, w rzeczywistości jednak bardzo częstym jest by zostawały one w prawie niezmienionym stanie w kolejnych latach.
Oczywiście wszystkie dane można zmienić w dowolnym momecie, o ile nie powoduje to rozspójnienia danych.
Przy usuwaniu nauczyciela automatycznie usunięte zostaną lekcje które prowadzi oraz związane z nim krotki tabeli nauczyciele_prowadzacy.

Wprowadziliśmy liczne ograniczenia oraz triggery mające na celu uniemożliwienie wprowadzania lub automatyczną korektę danych potencjalnie powodujących nielogiczny, czy też niepoprawny stan bazy. Przykładowdo:
pola id i index są wypełniane automatycznie,
nauczyciel nie może zastępować samego siebie, nie może też prowdzić jednocześnie dwóch lekcji(włączając w to prowadzone zastępstwa),
uczeń nie może dostać oceny ani nieobecności z lekcji na którą nie uczęszcza,
dzieci nie może być w klasie więcej, niż miejsc w salach w których mają lekcje,
dodane formy sprawdzania wiedzy, zastępstwa, nieobecności, które to posiadają datę, sprawdzane są na spójność dotyczącą wpisanej daty oraz dnia tygodnia w którym odbywa się związana z nimi lekcja(dla ocen datą jest data wprowadzenia, która nie jest od tego zależna. Datę przeprowadzenia można umieścić np. w opisie, jeśli jest taka potrzeba),
oceny okresowe przy dodawaniu są przechwytywane, na wypadek, gdyby krotka danego ucznia i przedmiotu już istniała. Wówczas jest ona aktualizowana, by zachować porządek danych.


Dla dodawanych uczniowiów i nauczycieli automatycznie zostaje utworzone konto pozwalające na dostęp do pewnych, przeznaczonych dla nich danych(po upewnieniu się, że samo dodanie do bazy nie powoduje błędu).
W razie usunięcia osoby z bazy danych konto to zostaje wycofane, w przypadku ucznia wraz z jego ocenami i innymi powiązaniami.

Typy nieobecnosci tłumaczą się jako: N-nieusprawiedliwiony, U-usprawiedzliwiony, W-wycieczka, G-glejt(zwolnienie olimpijskie).

--------------------------------------------------------------------------------------------

#APLIKACJA:
create.sql należy uruchomić w schemacie o nazwie "public". Adres bazy danych podaje się przy logowaniu.
java -cp app.jar Main

Aplikacja celowo nie umożliwia modyfikowania tabeli Sale-jest to coś na tyle niezmiennego, że dostęp do tego wydaje nam się logiczny jedynie z poziomu bazy danych.
Nieobecności dostępne są poprzez menu kontekstowe konkretnego ucznia.
Każda tabela posiada własny zestaw akcji jakie można wykonać na jej krotkach. Podstawowwymi akcjami są usuwanie, dodawanie oraz zmienianie
(choć nie wszystkie table posiadają te możliwości). W szczególności srednie_ocen nie posiadają tej możliwości jako automatycznie wyliczana tabela(view).
Pola które mogą mieć wartość null(np. kometarze) mozna na takie zmienić(jeśli były wypełnione) wpisująć "BRAK" w pole wypełniania(poza nazwą klasy ucznia i polem absolwent, które są w odpowiedni sposób wypełniane automatycznie gdy któreś zostanie zmienione).
Część pól wypełnia się poprzez menu kontekstowe, dla wygody użytkownika oraz minimalizacji liczby pomyłek.

Użytkownicy mają ograniczone prawa dostępu(stosujemy role, którym przydzialene są uprawnienia w bazie danych).
Każdy nauczyciel ma dostęp do uczniów których uczy(również ich ocen okresowych oraz średnich ocen),
swojego planu lekcji(choć może zobaczyć też cały plan lekcji klas), swojego terminarza, swoich zastępstw(tych, które on prowadzi),
wprowadzonych przez siebie ocen, klas które uczy, przedmiotów które prowadzi oraz posiada dostęp do panelu wychowawcy pozwalającego na
zarządzanie nieobecnościami uczniów których jest wychowawcą.
Niedostępne mozliwości są albo zupełnie niemożliwe do wykonania przez aplikacje, albo powodują pojawienie się wiadomości o niepoprawnej akcji
zamiast jej wykonania.
Nauczyciel może zobaczyć cały terminarz klas które uczy(przykładowo w celu ustalenia niekolidującego terminu) oraz wszystkie oceny wychowanków,
jednak zmian może dokonać tylko przez tabele służące do wyświetlania dostępnych do zmiany dla niego informacji.
Istnieje możliwość seryjnego dodawania ocen i ocen okresowych(wraz z wyświetlaniem średnich) przez nauczyciela, poprzez wybór opcji w menu kontekstowym klasy.
Moze on również dodać seryjnie nieobecności, poprzez wybranie odpowiedzniej opcji w menu kontekstowym lekcji z jego planu lekcji.

Uczeń ma dostęp do danych które go dotyczą.

Przykładowe dane:
logowanie użytkowniekiem który ma najwięcej praw dostępu(wszystkie które przewidzieliśmy dla aplikacji): login: sekretariat hasło: sekretariat
logowanie przykładownym nauczycielem: login: n1 haslo:1234
logowanie przykładowym uczniem: login: u401 hasło:1234
Przykładowy uczeń: 401 (ten, którego login został podany powyżej)
Przykładowy nauczyciel: 1 (ten, którego login został podany powyżej)
Przykładowa klasa: 4E  (należy do niej 401 i uczy ją między innymi 1 i jest jej wychowawcą)


Nauczyciele i lekcje wprowadzane są poprzez ich id, uczniowie poprzez index, natomiast klasa, przedmiot i rok poprzez nazwę
(odpowiednio np. 4E, Matematyka, 2019/2020).

--------------------------------------------
Dane zostały wygenerowe losowo, wszelka zbieżność jest przypadkowa.
