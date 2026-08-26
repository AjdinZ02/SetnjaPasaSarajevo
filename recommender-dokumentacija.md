# Dokumentacija preporučivača termina

Preporuke su dostupne kroz `GET /api/recommendations/time-slots`. Endpoint
koristi trenutno prijavljenog korisnika, a svaki vraćeni termin sada sadrži i
polje `Reason` sa kratkim, razumljivim objašnjenjem preporuke.

## Collaborative filtering

`RecommendationService` koristi jednostavan user-based collaborative
filtering:

1. Aktivne rezervacije trenutnog korisnika grupišu se po danu u sedmici i
   satu početka termina. Broj rezervacija u grupi je lični signal.
2. Aktivne rezervacije drugih korisnika koriste se da pronađu do 20 korisnika
   čiji se dan i sat rezervacija preklapaju sa ličnim signalima. To su
   „slični korisnici“.
3. Rezervacije sličnih korisnika se zatim grupišu po istom ključu
   (dan u sedmici, sat početka). Njihova učestalost je kolaborativni signal.
4. Dostupni termini se rangiraju ponderisanim rezultatom:
   `kolaborativni signal × 3 + lični signal × 2`.

Rezervisani, neaktivni ili nedostupni termini se ne vraćaju. Ključ koristi
dan u sedmici i sat početka, pa se preporuka odnosi na obrazac vremena, a ne
na određeni raniji datum.

## Vremenski prozor

Kandidati su aktivni i dostupni termini od sutrašnjeg dana do kraja 30. dana
računajući od danas. Rezultati se sortiraju po rezultatu, a zatim po datumu i
vremenu, i vraća se najviše traženi broj rezultata (ograničen na 1–10).

## Fallback ponašanje i razlog

Ako nema podudaranja sa sličnim korisnicima, lični signal i dalje može
rangirati termine. Ako nema ni ličnih rezervacija koje se podudaraju,
termini sa rezultatom nula vraćaju se hronološki kao dostupne opcije u
30-dnevnom prozoru. `Reason` opisuje signal koji je doveo do preporuke:

- oba signala: korisnik i slični korisnici često biraju taj dan i sat;
- samo kolaborativni signal: slični korisnici često biraju taj dan i sat;
- samo lični signal: korisnik je ranije rezervisao taj dan i sat;
- bez signala: termin je ponuđen kao dostupna opcija u narednih 30 dana.
