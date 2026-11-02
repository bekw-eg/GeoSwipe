# PostgreSQL Интеграциясы және Backend Архитектурасы

Бұл құжат **GeoSwipe** жобасына PostgreSQL дерекқорын, Prisma ORM және REST API серверін толыққанды интеграциялаудың архитектурасын, деректер құрылымын, қауіпсіздік шараларын және іске қосу нұсқаулығын сипаттайды.

---

## 1. Архитектуралық шолу

GeoSwipe бастапқыда толық офлайн режимге бағытталған Flutter мобильді ойыны ретінде жасалған. Жүйенің осы негізгі артықшылығы мен архитектурасын бұзбай, деректерді тұрақты сақтау, құрылғылар арасында синхрондау және пайдаланушы профильдерін басқару үшін PostgreSQL серверлік архитектурасы қосылды:

```text
┌────────────────────────────────────────────────────────┐
│               Flutter Client (GeoSwipe)                │
│                                                        │
│  [AppController] ──> [ProgressRepository]              │
│                              │                         │
│             ┌────────────────┴────────────────┐        │
│             ▼                                 ▼        │
│  [PreferencesProgressStore]       [PostgresApiProgressStore]
│   (Local SharedPreferences)        (Remote PostgreSQL API)│
└───────────────────────────────────────────────┬────────┘
                                                │ HTTPS / JSON (JWT)
                                                ▼
┌────────────────────────────────────────────────────────┐
│             GeoSwipe Backend (Node.js/Express)         │
│                                                        │
│   [Auth Middleware] ──> [Controllers & Services]       │
│                               │                        │
│                     [Prisma ORM Client]                │
└───────────────────────────────┬────────────────────────┘
                                │ Parameterized SQL
                                ▼
┌────────────────────────────────────────────────────────┐
│                   PostgreSQL Database                  │
│                                                        │
│  - users                    - user_progress_states     │
│  - profiles                 - skill_progresses         │
│  - level_progresses         - attempt_records          │
└────────────────────────────────────────────────────────┘
```

### Негізгі артықшылықтары:
1. **Offline-First кепілдігі:** Интернет байланысы үзілгенде де ойыншы прогресі жергілікті түрде `PreferencesProgressStore` арқылы сақталады және ойын жұмысын тоқтатпайды.
2. **PostgreSQL синхрондауы:** Желіге қосылғанда `PostgresApiProgressStore` транзакциялық API арқылы барлық өзгерістерді орталықтандырылған PostgreSQL дерекқорына жібереді.
3. **Үйлесімділік:** `ProgressRepository` интерфейсіне ешқандай кері әсер етпейді; қолданыстағы UI/UX және геометриялық есептеулер 100% өзгеріссіз сақталған.

---

## 2. Дерекқор схемасы (Database Schema)

PostgreSQL деректер базасы Prisma ORM арқылы басқарылады. Жобаның нақты функционалына сәйкес келесі кестелер құрылды:

### 2.1. `users` (Пайдаланушылар)
| Баған | Түрі | Сипаттамасы |
| --- | --- | --- |
| `id` | UUID (PK) | Пайдаланушының бірегей идентификаторы |
| `email` | String (Unique) | Электрондық пошта (кіру үшін) |
| `username` | String (Unique) | Бірегей логин |
| `passwordHash` | String | bcrypt арқылы хэштелген құпиясөз |
| `createdAt` | Timestamp | Тіркелген уақыты |
| `updatedAt` | Timestamp | Соңғы өзгертілген уақыты |

### 2.2. `profiles` (Пайдаланушы профилі)
| Баған | Түрі | Сипаттамасы |
| --- | --- | --- |
| `id` | UUID (PK) | Профиль идентификаторы |
| `userId` | UUID (FK) | `users.id` сыртқы кілті (`onDelete: Cascade`) |
| `displayName` | String | Көрсетілетін аты |
| `avatarUrl` | String? | Аватар суретіне сілтеме (міндетті емес) |
| `preferredLanguage` | String | Таңдалған тіл (әдепкі: `ru`) |
| `createdAt` / `updatedAt` | Timestamp | Жүйелік уақыт белгілері |

### 2.3. `user_progress_states` (Жалпы прогресс күйі)
| Баған | Түрі | Сипаттамасы |
| --- | --- | --- |
| `id` | UUID (PK) | Жазба идентификаторы |
| `userId` | UUID (FK, Unique) | `users.id` сыртқы кілті |
| `version` | Integer | Прогресс схемасының нұсқасы (1 немесе 2) |
| `lastLevelId` | String? | Ойыншы ашқан соңғы деңгей ID-і |
| `unlockedLevels` | String[] | Қолжетімді ашылған деңгейлер жиымы |
| `activeHints` | JSON? | Белсенді кеңестер деңгейлері |
| `reviewVariants` | JSON? | Қайталау нұсқалары |

### 2.4. `level_progresses` (Деңгейлер көрсеткіштері)
| Баған | Түрі | Сипаттамасы |
| --- | --- | --- |
| `id` | UUID (PK) | Жазба идентификаторы |
| `userId` | UUID (FK) | Пайдаланушы ID-і |
| `levelId` | String | Деңгей ID-і (мысалы: `angle-45`, `pythagoras-3-4`) |
| `attempts` | Integer | Барлық талпыныстар саны |
| `completions` | Integer | Дұрыс шешілгендер саны |
| `assistedCompletions` | Integer | Көмекпен/подсказкамен шешілгендер саны |
| `independentCompletions`| Integer | Дербес шешілгендер саны |
| `independentReviews` | Integer | Дербес қайталаулар саны |
- **Шектеу:** `@@unique([userId, levelId])` — бір қолданушы үшін бір деңгейдің қайталанған жазбалары болмайды.
- **Индекстер:** `userId` және `levelId` бойынша жылдам іздеу индекстері.

### 2.5. `skill_progresses` (Интервалды қайталау дағдылары)
| Баған | Түрі | Сипаттамасы |
| --- | --- | --- |
| `id` | UUID (PK) | Идентификатор |
| `userId` | UUID (FK) | Пайдаланушы |
| `skillId` | String | Дағды идентификаторы |
| `state` | String | Күйі: `notStudied`, `studying`, `assisted`, `independent`, `confirmed` |
| `reviewStage` | Integer | Қайталау кезеңі (0, 1, 2, 3) |
| `dueAt` | Timestamp? | Келесі қайталау белгіленген уақыт |
- **Шектеу:** `@@unique([userId, skillId])`.

### 2.6. `attempt_records` (Әр шешу талпынысының тарихы)
| Баған | Түрі | Сипаттамасы |
| --- | --- | --- |
| `id` | UUID (PK) | Талпыныс ID-і |
| `userId` | UUID (FK) | Пайдаланушы ID-і |
| `levelId` | String | Деңгей ID-і |
| `topicId` | String | Тақырып ID-і (`angles`, `pythagoras`, `trig`) |
| `correct` | Boolean | Шешім дұрыстығы |
| `hintCount` | Integer | Қолданылған кеңестер саны |
| `review` | Boolean | Қайталау тапсырмасы ма |
| `scheduledReview` | Boolean | Жоспарлы интервалды қайталау ма |
| `variant` | Integer | Тапсырма нұсқасы |
| `answer` | String | Ойыншы берген жауап |
| `createdAt` | Timestamp | Талпыныс жасалған уақыт |
- **Индекстер:** `[userId]`, `[userId, levelId]`, `[userId, createdAt]`.

---

## 3. Backend REST API сипаттамасы

Сервер порт `4000` (немесе `.env`-дегі `PORT`) бойынша жұмыс істейді.

### 3.1. Authentication (`/api/auth`)
- `POST /api/auth/register`:
  - Денесі: `{ "email": "...", "username": "...", "password": "...", "displayName": "..." }`
  - Нәтижесі: `201 Created`, `{ "token": "JWT_TOKEN", "user": {...}, "profile": {...} }`
  - Тексеру: Қайталанатын email/username болса `409 Conflict`.
- `POST /api/auth/login`:
  - Денесі: `{ "identifier": "email or username", "password": "..." }`
  - Нәтижесі: `200 OK`, `{ "token": "JWT_TOKEN", "user": {...}, "profile": {...} }`
- `GET /api/auth/me`:
  - Тақырыптамасы: `Authorization: Bearer <token>`
  - Нәтижесі: Ағымдағы кірген пайдаланушы деректері.

### 3.2. Profile (`/api/profile`)
- `GET /api/profile`: Авторизацияланған қолданушы профилін алу.
- `PUT /api/profile`: Профиль деректерін (`displayName`, `avatarUrl`, `preferredLanguage`) жаңарту.

### 3.3. Progress Synchronization (`/api/progress`)
- `GET /api/progress`:
  - GeoSwipe клиентіне толық үйлесімді `ProgressSnapshot` JSON қайтарады.
- `PUT /api/progress`:
  - Клиенттен келген толық `ProgressSnapshot`-ты қабылдап, `prisma.$transaction` арқылы `user_progress_states`, `level_progresses` және `skill_progresses` кестелеріне бір транзакцияда қауіпсіз енгізеді (upsert).
- `POST /api/progress/attempt`:
  - Бір талпынысты тіркейді және сәйкес деңгей есептегіштерін (attempts, completions, independentCompletions т.б.) атомдық түрде транзакциямен жаңартады.
- `GET /api/progress/levels`:
  - Барлық шешілген деңгейлер тізімін қайтарады.
- `GET /api/progress/history?limit=50&offset=0`:
  - Пагинациясы бар талпыныстар тарихы.

---

## 4. Қауіпсіздік шаралары (Security)

1. **SQL Injection-нан қорғау:**
   - Барлық дерекқор сұраныстары Prisma ORM-нің параметрленген дайын операторлары (prepared statements) арқылы жүзеге асырылады. Ешқандай динамикалық SQL жолы біріктірілмейді.
2. **Құпиясөздерді қорғау:**
   - Құпиясөздер ашық мәтін түрінде сақталмайды. Олар `bcryptjs` кітапханасымен 10 раундтық тұзбен (salt rounds = 10) хэштеледі.
3. **Авторизация және JWT:**
   - Барлық жеке API маршруттары `requireAuth` аралық қабатымен (middleware) қорғалған.
   - Токеннің қолданылу мерзімі шектелген (`7d`).
4. **Деректерді оқшаулау (Data Isolation):**
   - Барлық сұраныстар авторизацияланған `req.user.userId` арқылы сүзіледі. Бір пайдаланушы екінші пайдаланушының прогресін немесе профилін көре де, өзгерте де алмайды.
5. **Құпия конфигурация (.env):**
   - Дерекқор парольдері мен JWT кілті тек `.env` файлында сақталады.
   - `.env` файлы `.gitignore`-ге қосылған және Git тарихына ешқашан жіберілмейді.
   - Әзірлеушілерге арналып үлгі ретінде `.env.example` ұсынылған.

---

## 5. Іске қосу және тестілеу командалары

### 5.1. PostgreSQL қосу және баптау
Дерекқордың жұмыс істеп тұрғанына көз жеткізіңіз:
```sh
# PostgreSQL сервисін тексеру (Windows PowerShell):
Get-Service *postgres*

# Базаны жасау (егер жасалмаған болса):
psql -U postgres -h localhost -c "CREATE DATABASE geoswipe;"
```

### 5.2. Backend орнату және миграция
```sh
cd server

# Тәуелділіктерді орнату:
npm install

# .env файлын дайындау:
cp .env.example .env
# .env ішіндегі DATABASE_URL параметрін тексеріңіз

# Prisma миграциясын іске қосу:
npm run prisma:migrate

# Бастапқы тестілік деректерді (Seed) енгізу:
npm run prisma:seed

# Серверді әзірлеу режимінде қосу:
npm run dev
```

### 5.3. Backend интеграциялық тесттерін орындау
Серверлік тесттер барлық негізгі сценарийлерді (тіркелу, кіру, қайталанудан қорғау, құқықтарды тексеру, CRUD, Progress синхрондауы, деректерді оқшаулау) тексереді:
```sh
cd server
npm test
```

### 5.4. Flutter тексеру командалары
```sh
# Тәуелділіктерді жаңарту:
flutter pub get

# Код пішімін тексеру:
dart format --output=none --set-exit-if-changed lib test

# Анализаторды іске қосу:
flutter analyze

# Барлық мобильді және интеграциялық тесттерді орындау:
flutter test
```

---

## 6. Seed арқылы дайындалған бастапқы деректер

Бастапқы тестілеу үшін `server/prisma/seed.ts` мына аккаунттарды жасайды:
- **Демо ойыншы:**
  - Email: `demo@geoswipe.local`
  - Пароль: `DemoPassword123!`
  - Аты: `Демо Пайдаланушы`
  - Бастапқы күйі: `angle-45` және `angle-90` деңгейлері шешілген, қайталау және шешу тарихы жазылған.
- **Жаңа оқушы:**
  - Email: `student@geoswipe.local`
  - Пароль: `StudentPassword123!`
  - Бастапқы күйі: 1-деңгейден басталған таза профиль.
