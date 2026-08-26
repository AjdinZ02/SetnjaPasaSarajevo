# SetnjaPasaSarajevo

Aplikacija za rezervaciju setnji pasa sa .NET REST API-jem i Flutter mobilnom i desktop aplikacijom.

## Preduslovi

- .NET 9 SDK
- Flutter SDK
- Docker Desktop
- SQL Server Edge (pokrece se kroz Docker)

## Konfiguracija

Kopiraj `.env.example` u `.env` i unesi lokalne vrijednosti. `.env` se ne commit-uje.
ASP.NET Core cita konfiguraciju iz environment varijabli sa `__` separatorom.

SQL lozinka u `SA_PASSWORD` mora imati najmanje osam znakova, veliko i malo
slovo, broj i specijalni znak. Vrijednost mora ostati ista nakon prvog
kreiranja SQL Server kontejnera.

Za Flutter API adresu koristi:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5126
```

Na Android emulatoru koristi `http://10.0.2.2:5126`.

## Pokretanje API-ja

```bash
docker compose up -d ecomm-fit-2026 rabbitmq
dotnet restore
set -a; source .env; set +a
dotnet run --project SetnjaPasaSarajevo.WebAPI
```

Swagger je dostupan na `http://127.0.0.1:5126/swagger`.

Ako je `.env` vec napravljen, preskoci `cp` komandu. U novom terminalu ponovo
izvrsi `set -a; source .env; set +a` prije `dotnet run`. Backend se zaustavlja
sa `Ctrl+C`.

## Pokretanje na Windows PowerShellu

```powershell
Copy-Item .env.example .env
docker compose up -d ecomm-fit-2026 rabbitmq
dotnet restore
dotnet run --project SetnjaPasaSarajevo.WebAPI
```

Prije prvog pokretanja otvori `.env` i unesi lokalne vrijednosti. `SA_PASSWORD`
mora biti ista vrijednost u `.env` i SQL connection stringu.

## Pokretanje Flutter aplikacija

```bash
cd UI/SetnjaPasaSarajevo_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5126
```

Desktop aplikacija se pokrece iz `UI/SetnjaPasaSarajevo_desktop`.

## Release buildovi

Na macOS-u se desktop aplikacija gradi komandom:

```bash
cd UI/SetnjaPasaSarajevo_desktop
flutter build macos --release
```

Dobijeni `.app` nalazi se u `build/macos/Build/Products/Release/`.
Android APK zahtijeva instaliran Android SDK i gradi se komandom
`flutter build apk --release`. Windows build se mora pokrenuti na Windows
racunaru ili CI runneru.

## API funkcionalnosti

- JWT autentifikacija i autorizacija
- upravljanje korisnicima i zivotinjama
- rezervacije i promjena statusa za administratore
- PayPal sandbox placanje i refund kredita
- Collaborative Filtering preporuke termina
- autentifikovane notifikacije i oznacavanje procitanih obavijesti
- RabbitMQ event queue i odvojeni Worker za obradu dogadaja rezervacija
- desktop PDF izvjestaji: lista rezervacija i pregled statusa

## Event worker

`docker compose up -d` pokrece RabbitMQ i Worker. API objavljuje dogadaje
`reservation.created` i `reservation.cancelled` u red `setnja-events`, a Worker
ih potvrduje i cuva u `data/processed-events.jsonl` radi audita i dalje obrade.

Ne commituj `.env`, build direktorije, binarne fajlove ili produkcijske credentials.
