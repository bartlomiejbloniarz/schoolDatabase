
Baza danych przedstawiająca schemat szkoły. 
Zawiera informacje o 
przedmiotach tj. typach prowadzonych zajęć (tabela Przedmioty), 
lekcjach tj. konkretnych zajęciach odbywających się w danych godzinach i dniach(tablea Lekcje),
salach tj. pomieszczeniach (tabla Sale), 
uczniach uczęszczających do szkoły (tabla Uczniowie), 
klasach tj. grupach ucznów (np.6a)(tabla Klasy), 
pracownikach (tablea pracownicy),
płacach pracowników za godzinę brutto(tablea Place),
obiektach tj. rzeczach, jakie mogą się znajdować w pomieszczeniach (tabla Obiekty), 
inwentarzach sal zawierających spisy obiektow (tablea Inwentarz), 
drogach ewakuacyjnych (talba Drogi_ewakuacyjne),


Zachodzą następujące zależności między tablami: 
ponież stosowane będą następujące oznaczenia na typy relacji:
O oznacza obowiązkowe, N oznacza nieobowiązkowe, W oznacza wiele, J odnzacza jeden.

Tabela Sale jest w relacji OW:NJ z Drogi_ewakuacyjne.
Tabela Inwentarz jest w relacji OW:OJ z Sale na zasadzie: w każdej sali musi być biurko.
Tabela Inwentarz jest w relacji OW:NJ z Obiekty na zasadzie: wiele obiektow moze byc w inwentarzu.
Tabela Uczniowie jest w relacji OW:NJ z Klasy na zasadzie: klasa moze posiadać w inwentarzu wiele obiektów.
Tabela Klasy jest w relacji OW:NJ z Pracownicy na zasadzie bycia wychowawcą. 
Tabela Przedmioty jest w relacji OW:NJ z Pracownicy na zasadzie prowadzenia przedmiotu, przedmiot musi ktoś prowadzić, jednak nie każdy musi prowadzić przedmiot.
Tabela Lekcje jest w relacji OW:NJ z Sale na zasadzie każda lekcja musi się odbywać w dokłądnie jednym pomieszczeniu, jednak nie w każdym pomieszczeniu muszą odbywać lekcje. 
Tabela Lekcje jest w relacji OW:NJ z Przedmioty na zasadzie każda lekcja musi dotyczyć jakiegoś przedmiotu jednak nie z każdego przedmiotu lekcje muszą się odbywać. 
Tabela Pracownicy jest w relacji OW:NJ z Place na zasadzie każdy pracownik musi mieć przypisaną dokładnie jedną płacę na podstawie stwojego stanowiska oraz stopnia naukowego, jednak nie każde stanowisko i stopień naukowy muszą być objęte przez pracowników.
Tabela Lekcje jest w relacji OW:NJ z Klasy na zasadzie w każda klasa musi odbywać się z jakąś klasą. 

Dodatkowo zawarte są:
perspektywa przedstawiająca pensje pracowników o danym imieniu i nazwisku,
funkcja przedstawiająca spis zajęć dla podanego ucznia,



Wkład pracy:

Bartłomiej Błoniarz: 
Stworzone tabele:
Obiekty, Inwentarz, Drogi_ewakuacyjne, Place. Oraz korekta pozostałych tabel.
Stworzone triggery(oraz konieczne do nich funkcje):
dodaj_place,
Stworzone widoki:
pracownicy wyplaty,

Inka Sokołowska:
Stworzone tabele:
Lekcje, Sale, Uczniowie, Klasy, Pracownicy.
Stworzone triggery(oraz konieczne do nich funkcje): 
liczbaDzieci, jednaLekcjaNaRaz.
Stworzone funkcje:
mojPlanLekcji.


