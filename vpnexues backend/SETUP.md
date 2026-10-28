# Seller backend — setup

Spring Boot API for the Jacinth seller app. It sits between the Flutter app
and the two Google/Supabase services:

```
Flutter app ──(Firebase ID token)──► Spring Boot ──verify──► Firebase Auth
                                        │
                                        ├── JPA/JDBC ──► Supabase Postgres
                                        └── REST ──────► Supabase Storage
```

Firebase sends the OTP and verifies the code **inside the Flutter app**. This
service never sees a password or an OTP — it only ever sees the ID token that
Firebase hands back afterwards.

---

## 1. Requirements

- Java 21 — Maven needs it. Check with `java -version`. Maven finds it
  through `JAVA_HOME`, so there is nothing extra to configure.
- Maven 3.9+. If `mvn -version` says the command is not recognised, Maven is
  not on your PATH yet.

### Installing Maven (Windows)

Maven is **not** bundled with the JDK — it is a separate tool, the Java
equivalent of `flutter pub get` plus `flutter run`.

1. Download `apache-maven-3.9.9-bin.zip` from
   `https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip`
2. Extract it so you have `C:\Users\<you>\apache-maven-3.9.9\bin\mvn.cmd`.
   Keep it **outside OneDrive** — a build tool writing into a synced folder
   causes locked-file errors.
3. Add `C:\Users\<you>\apache-maven-3.9.9\bin` to your **user** PATH. Prefer
   this over `setx`, which truncates PATH at 1024 characters:
   ```powershell
   [Environment]::SetEnvironmentVariable(
     "Path",
     ([Environment]::GetEnvironmentVariable("Path","User") + ";C:\Users\<you>\apache-maven-3.9.9\bin"),
     "User")
   ```
4. **Open a new terminal** — the change only affects new ones — then verify:
   ```powershell
   mvn -version
   ```

### Installing Maven (macOS / Linux)

```bash
brew install maven        # macOS
sudo apt install maven    # Debian/Ubuntu
```

## 2. Environment variables

| Variable | Required | Notes |
|---|---|---|
| `SUPABASE_DB_URL` | yes | `jdbc:postgresql://db.<project-ref>.supabase.co:5432/postgres?sslmode=require` |
| `SUPABASE_DB_USER` | yes | `postgres` |
| `SUPABASE_DB_PASSWORD` | yes | The database password from Supabase → Settings → Database |
| `SUPABASE_URL` | for KYC | `https://<project-ref>.supabase.co`, no trailing slash |
| `SUPABASE_SERVICE_ROLE_KEY` | for KYC | Settings → API. **Server-side only** — never put it in the app |
| `SUPABASE_KYC_BUCKET` | no | Defaults to `kyc-documents` |
| `FIREBASE_PROJECT_ID` | yes | Your Firebase project id |
| `GOOGLE_APPLICATION_CREDENTIALS` | yes | Absolute path to the service-account JSON |
| `VPNEX_ENCRYPTION_KEY` | no | Base64 AES key for bank account numbers (see below) |
| `CORS_ALLOWED_ORIGINS` | no | Comma-separated; defaults cover `localhost` and `10.0.2.2` |

Generate the encryption key:

```
python -c "import base64,os;print(base64.b64encode(os.urandom(32)).decode())"
```

If it is unset the API still runs, but account numbers are stored in plaintext
and a warning is logged on every save.

## 3. Firebase

1. Firebase console → Project settings → Service accounts → **Generate new
   private key**.
2. Save the file **outside this repository** and point the variable at it:
   `GOOGLE_APPLICATION_CREDENTIALS=C:\secrets\firebase-service-account.json`
3. The app refuses to start with the file inside `src/main/resources` on
   purpose — a committed service-account key cannot be un-leaked.

The original `backend/src/main/resources/firebase.json` was a placeholder with
`"REPLACE"` in place of the private key and has been deleted. It could never
have worked, and it taught the wrong habit.

## 4. Supabase

1. **Postgres.** Copy the connection URI from Settings → Database. Use the
   Session pooler (port 6543) for running traffic, the direct connection
   (5432) for migrations.
2. **Storage.** Create a **private** bucket named `kyc-documents`
   (Storage → Buckets → New bucket → disable "Public bucket").
3. The tables are created automatically by `spring.jpa.hibernate.ddl-auto=update`.
   Once the schema settles, switch it to `validate` and move to Flyway.

### Optional: create the tables yourself first

`ddl-auto=update` is convenient while the schema is still moving. If you would
rather own the DDL, run this in the Supabase SQL editor and then set
`SPRING_JPA_DDL_AUTO=validate`:

```sql
create table if not exists sellers (
  firebase_uid   text primary key,
  phone          text unique,
  name           text,
  email          text unique,
  seller_type    text,
  onboarding_step text not null,
  created_at     timestamptz not null,
  updated_at     timestamptz not null
);

create table if not exists seller_locations (
  seller_uid text primary key references sellers(firebase_uid) on delete cascade,
  country text, state text, city text, address text, pincode text,
  latitude double precision, longitude double precision
);

create table if not exists seller_business (
  seller_uid text primary key references sellers(firebase_uid) on delete cascade,
  owner_name text, business_name text, phone text,
  business_location text, business_address text
);

create table if not exists seller_kyc_documents (
  id text primary key,
  seller_uid text not null references sellers(firebase_uid) on delete cascade,
  doc_type text not null,
  storage_path text not null,
  original_filename text not null,
  content_type text,
  size_bytes bigint,
  status text not null,
  created_at timestamptz not null
);

create table if not exists seller_bank_details (
  seller_uid text primary key references sellers(firebase_uid) on delete cascade,
  holder_name text, bank_name text,
  account_number_encrypted text, account_number_last4 text,
  ifsc text, ifsc_verified boolean not null default false
);
```

## 5. Run

### First run — no accounts needed

```powershell
cd backend
.\run-local.ps1
```

The script sets `SPRING_PROFILES_ACTIVE=local`, which uses an **in-memory H2
database** and no Firebase/Supabase, so the API starts immediately. All data
is wiped when the server stops.

Check it is up (in a second terminal):

```powershell
curl http://localhost:8080/actuator/health      # {"status":"UP"}
curl -X POST http://localhost:8080/api/onboarding/status
# 403 — correct. Protected, and no token was sent.
```

You will see this warning in the log, which is expected here:

```
GOOGLE_APPLICATION_CREDENTIALS is not set. Firebase token verification is
disabled and every /api request needing auth will return 503.
```

> **Why a script instead of a plain `mvn` command?**
> PowerShell 5.1 splits `-Dspring-boot.run.profiles=local` at the dot and
> Maven fails with `Unknown lifecycle phase ".run.profiles=local"`. Quoting
> does not help. Setting the `SPRING_PROFILES_ACTIVE` environment variable
> sidesteps the parser. If you prefer to type it yourself:
> ```powershell
> $env:SPRING_PROFILES_ACTIVE = "local"
> mvn spring-boot:run
> ```
> In `cmd.exe` or Bash, the flag form works fine:
> ```
> mvn spring-boot:run -Dspring-boot.run.profiles=local
> ```

### Against real Supabase

Set the environment variables from step 2, then run with no profile:

```powershell
mvn spring-boot:run
```

Note that plain `mvn spring-boot:run` **will not start** unless it can reach a
database — it fails with `Connection refused` on the Postgres port. Either set
`SUPABASE_DB_URL`, or use the `local` profile above.

## 6. Tests

```powershell
mvn test
```

These run against an in-memory H2 database (`src/test/resources/application.properties`)
and need neither Supabase nor Firebase — both services degrade to "disabled"
rather than failing to start.

- `SellerServiceTest` walks a seller through all five onboarding steps and
  checks the shared-key rows, that one seller cannot read another's documents,
  and that an earlier step can be re-saved without losing progress.
- `ApiSecurityTest` proves `/api/onboarding/**` rejects tokenless and
  garbage-token requests.
- `EncryptionServiceTest` / `IfscServiceTest` cover AES-GCM round-tripping and
  IFSC validation.

---

## API

### Auth

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/api/auth/session` | public | Exchange a Firebase ID token for the seller record; creates it on first login |
| GET | `/api/auth/me` | Bearer | The signed-in seller's profile |

### Onboarding

| Method | Path | Purpose |
|---|---|---|
| GET | `/api/onboarding/status` | Which step is next, and what is already filled in |
| PUT | `/api/onboarding/location` | Step 01 |
| PUT | `/api/onboarding/seller-type` | Step 02 |
| PUT | `/api/onboarding/business` | Step 03 |
| POST | `/api/onboarding/kyc/documents` | Step 04 — multipart upload (`docType`, `file`) |
| GET | `/api/onboarding/kyc/documents` | Step 04 — list uploads |
| DELETE | `/api/onboarding/kyc/documents/{id}` | Step 04 — remove an upload |
| PUT | `/api/onboarding/bank` | Step 05 |
| GET | `/api/onboarding/bank` | Step 05 — masked account number only |
| POST | `/api/onboarding/bank/verify-ifsc` | IFSC lookup |

Every path under `/api/onboarding` and `GET /api/auth/me` requires
`Authorization: Bearer <firebase-id-token>`.

Errors always come back as `{"error": "...", "message": "..."}`.

---

## Deliberate design decisions

**The seller is keyed by their Firebase UID.** There is no seller id in any
path or body, so a request can only ever touch the seller's own row.

**`/api/auth/verify` is gone.** It returned the literal string `"verified"`
without reading the token, so any caller could claim to be any seller.
`FirebaseAuthFilter` does the actual verification now.

**Account numbers are encrypted, and only the last four come back.** The app's
bank card shows `3421`; it never needs the rest.

**The client's IFSC flag is not trusted.** The Flutter screen's Verify button
hard-codes `_ifscIsValid => true`, so `PUT /bank` re-checks the format itself
and refuses to save an unverified code.

**Detail rows use a plain foreign key, not a JPA association.**
`seller_locations`, `seller_business`, `seller_bank_details` and
`seller_kyc_documents` all key on `seller_uid`. They deliberately have no
`@OneToOne` / `@ManyToOne` back to `Seller`: a shared-primary-key association
makes Hibernate resolve an id that `@MapsId` has not assigned yet whenever
either side is merged, which fails at runtime with
`org.hibernate.AssertionFailure: null identifier`. The relationship is
enforced by the database FK, and the service only ever writes a row for the
authenticated seller's own UID.

**Step 01 accepts an empty body.** `lib/screens/location_screen.dart` collects
nothing — both of its buttons just navigate. Demanding a country and city would
make the flow impossible to complete, so `LocationRequest` has no `@NotBlank`
and a fully empty body advances the step without writing a row. Add
`@NotBlank` to `LocationRequest` once that screen gets a real picker and GPS
permission.

**Step 04 stores one document per slot.** Re-uploading an Aadhaar replaces the
previous row, so the "Profile Completion" meter cannot double-count.

**`onboarding_step` never moves backwards.** Re-opening step 01 and saving does
not lose a seller's place at step 04.

---

## Still missing / next steps

- The Flutter screens do not call this API yet. `lib/services/backend_service.dart`
  has a typed method per endpoint; wiring them is a separate change.
- No refresh-token handling, logout, or server-side resend throttling — the
  OTP screen's 12-second timer is client-side only.
- No rate limiting on `/api/auth/session`.
- KYC documents are stored but never reviewed; `status` stays `PENDING` until
  it is flipped by hand in Supabase.
- The IFSC lookup validates the format plus a table of the eight banks in the
  app's picker. Swap `IfscService.lookup` for the Razorpay/BankBazaar API when
  live payouts need the branch confirmed.
