# FISHING EXPERIENCE — КОНТЕКСТ ПРОЄКТУ ДЛЯ CLAUDE CODE

## ЗАГАЛЬНА ІНФОРМАЦІЯ

- **Назва гри:** Fishing Experience
- **Платформа:** Roblox
- **Мова скриптингу:** Luau
- **Розробник:** Соло + друг (3D моделі в Blockbench)
- **Статус:** MVP (Хвиля 1) — активна розробка
- **Мова гри:** Англійська (реліз)

---

## СТРУКТУРА ПРОЄКТУ

```
D:\FishingExperience\
├── src/
│   ├── server/
│   │   ├── DataManager.lua          (ModuleScript)
│   │   ├── GameManager.server.lua   (Script)
│   │   ├── FishingSystem.server.lua (Script)
│   │   └── EconomySystem.server.lua (Script)
│   └── client/
│       ├── ClientManager.client.lua        (LocalScript — порожній, тільки ініціалізація)
│       ├── HudController.client.lua        (LocalScript)
│       ├── BackpackController.client.lua   (LocalScript)
│       ├── FishingController.client.lua    (LocalScript)
│       └── NotificationController.client.lua (LocalScript)
├── default.project.json
├── .gitignore
├── .luaurc
└── .vscode/
    └── settings.json
```

### default.project.json
```json
{
  "name": "FishingExperience",
  "tree": {
    "$className": "DataModel",
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "DataManager": {
        "$path": "src/server/DataManager.lua"
      },
      "GameManager": {
        "$path": "src/server/GameManager.server.lua"
      },
      "FishingSystem": {
        "$path": "src/server/FishingSystem.server.lua"
      },
      "EconomySystem": {
        "$path": "src/server/EconomySystem.server.lua"
      }
    },
    "StarterGui": {
      "$className": "StarterGui",
      "MainGui": {
        "$className": "ScreenGui",
        "ClientManager": {
          "$path": "src/client/ClientManager.client.lua"
        },
        "HudController": {
          "$path": "src/client/HudController.client.lua"
        },
        "BackpackController": {
          "$path": "src/client/BackpackController.client.lua"
        },
        "FishingController": {
          "$path": "src/client/FishingController.client.lua"
        },
        "NotificationController": {
          "$path": "src/client/NotificationController.client.lua"
        }
      }
    }
  }
}
```

---

## ЩО РЕАЛІЗОВАНО

### Серверні системи

#### DataManager.lua (ModuleScript)
- Підключення до DataStore "FishingGameV1"
- Завантаження даних при вході гравця
- Збереження при виході
- Збереження всіх даних при закритті сервера (BindToClose)
- Дефолтні дані нового гравця:
  - coins = 1000
  - rodLevel = 1
  - backpackLevel = 1
  - vaultLevel = 1
  - warehouseLevel = 1
  - tutorialDone = false
  - licenses = {zone1=true, zone2=false}
  - inventory = {fish={}, resources={}}
  - museum = {}
  - vault = {}
  - warehouse = {}
- Публічне API: DataManager.getData(player), DataManager.saveData(player)

#### GameManager.server.lua (Script)
- Підключає DataManager через require()
- Створює всі RemoteEvents в ReplicatedStorage/RemoteEvents:
  - CastRod, CatchFish, SellFish, OpenInventory
  - AddToMuseum, ListAuction
  - UpdateCoins, UpdateInventory, UpdateRodLevel, UpdateWeather
  - RequestInventory, RequestPlayerState
- Coins/rodLevel більше НЕ пушаться наосліп через task.wait(0.5) —
  клієнт сам робить RequestPlayerState:FireServer() коли його
  listener'и вже підписані; сервер чекає (waitForData, до 5с) поки
  DataManager завантажить дані, і лише тоді відповідає
- При виході: зберігає дані через DataManager
- Обробляє RequestInventory — надсилає інвентар клієнту

#### FishingSystem.server.lua (Script)
- Повна таблиця FishData — 30 видів риби (Зона 1 і Зона 2)
- Система погоди: clear(35%), cloudy(30%), rain(20%), fog(10%), storm(5%)
  - Зміна кожні 10 хвилин (фіксований інтервал)
- Цикл дня/ночі (1 година разом): morning(10хв), day(20хв), evening(15хв), night(15хв)
- Погода і час доби транслюються всім клієнтам через UpdateWeather
  (при кожній зміні + одразу новому гравцю при вході)
- Умова "day" вимагає саме фазу day (не morning)
- Формула визначення риби:
  - базовий шанс × множник бару × погода × час доби × FishingSpot(x1.2/x0.8)
- Базові шанси: Common 55%, Uncommon 25%, Rare 12%, Epic 6%, Legendary 2%
- Система префіксів: Rainy(+10%), Dusk(+15%), Midnight(+20%), Stormy(+35%), Misty(+35%)
  - Ідеальний хіт бару (perfect) → +5% до шансу префікса
- Множники бару: weak=0.5, medium=1.0, good=1.5, perfect=2.0
- Обробка CastRod.OnServerEvent → catchFish()
- Перевірка місткості рюкзака: 10 + (backpackLevel-1)*5 слотів

#### EconomySystem.server.lua (Script)
- Ціна продажу = basePrice × (1 + бонус префікса). Погода/час доби
  НЕ впливають на ціну продажу (свідоме рішення розробника)
- Обробка SellFish.OnServerEvent → продаж риби з інвентаря
- Публічне API: addCoins(), removeCoins(), calculatePrice()

### Клієнтські контролери

#### ClientManager.client.lua (LocalScript)
- Порожній файл — тільки print("[ClientManager] Initialized successfully!")
- Вся логіка розділена по окремих контролерах

#### HudController.client.lua (LocalScript)
- Відображення монет (зліва зверху, 220x55, жовта рамка, плейсхолдер "$ 0" —
  емодзі 🪙 не рендерилось шрифтом Roblox, замінено на "$")
- Бар погоди/часу доби (по центру зверху, 480x55, блакитна рамка),
  симетрично розділений вертикальним роздільником навпіл:
  - Ліва половина — фаза доби + власний таймер зворотного відліку
  - Права половина — погода + власний таймер зворотного відліку
  - Таймери рахують локально щосекунди між серверними оновленнями
    (UpdateWeather передає weatherSecondsLeft і phaseSecondsLeft,
    сервер рахує їх від os.clock()-міток weatherNextChangeAt/phaseNextChangeAt)
- Підписка на UpdateCoins.OnClientEvent, UpdateWeather.OnClientEvent
- При завантаженні: RequestPlayerState:FireServer() (після підписки на
  UpdateCoins) — усуває гонку умов зі старим одноразовим server push
- TEXT_SIZE = 22, TextScaled = false
- Чорна обводка тексту (TextStrokeColor3, TextStrokeTransparency = 0)

#### BackpackController.client.lua (LocalScript)
- Кнопка "🎒 Backpack" (220x55, синя, зліва під монетами)
- Вікно рюкзака (650x550, по центру екрану)
- 5 вкладок: All, Fish, Items, Trinkets, Pets
- Сітка предметів (130x130 слоти, відступи 15px)
- Відображення: назва риби, префікс (якщо є), таймер псування або ∞
- Кольори рідкостей:
  - Common: RGB(100,100,100), Uncommon: RGB(30,140,30)
  - Rare: RGB(30,80,200), Epic: RGB(130,30,200), Legendary: RGB(200,130,0)
- Підписка на UpdateInventory.OnClientEvent
- При відкритті: RequestInventory:FireServer()
- TEXT_SIZE = 22

#### FishingController.client.lua (LocalScript)
- Кнопка "🎣 Cast Rod" (220x65, синя, по центру знизу)
- Підписка на UpdateRodLevel.OnClientEvent — rodLevel реально впливає на:
  - час очікування закидання (rodWaitTimes[rodLevel], 8-12с → 1-3с)
  - розмір "Ideal" зони бару (8%→23%) і швидкість повзунка (0.85→1.60)
- При завантаженні: RequestPlayerState:FireServer() (після підписки на
  UpdateRodLevel) — той самий фікс гонки умов, що й у HudController
- Повний цикл рибалки:
  1. Cast Rod → очікування (залежить від rodLevel)
  2. Pull! → 5 секунд щоб натиснути
  3. Таймінг-бар → 3 секунди щоб натиснути
  4. Результат → CastRod:FireServer(result, inFishingSpot, zone)
     (zone і inFishingSpot поки завжди 1/false — див. "Не реалізовано")
- Таймінг-бар по центру екрану (500x100)
- Зони перемішуються при кожній ловлі (shuffle)
- Зони з текстом множника по центру (розміри для рівня вудки 1):
  - 🔴 Weak 37% x0.5, 🟡 Medium 35% x1.0, 🟢 Good 20% x1.5, 🔵 Perfect 8% x2.0
- Повідомлення про спійману рибу (назва, рідкість, префікс)
- Повідомлення "The fish got away!" якщо пропустив
- TEXT_SIZE = 22

#### NotificationController.client.lua (LocalScript)
- Черга повідомлень з анімацією slide-in/slide-out зверху
- Публічне API: NotificationController.show(text, color, borderColor)
- Тривалість повідомлення: 3 секунди
- Вітальне повідомлення при вході: "🎣 Welcome to Fishing Experience!"
- TEXT_SIZE = 22

---

## ІНСТРУМЕНТИ РОЗРОБКИ

- **VS Code** з розширеннями: Rojo, Luau Language Server
- **Rojo 7.6.1** — синхронізація VS Code ↔ Roblox Studio
- **Rokit 1.2.0** — менеджер інструментів
- **Git** — контроль версій
- **Claude Code** — AI асистент в VS Code

### Запуск розробки
```powershell
cd D:\FishingExperience
rojo serve
```
Потім в Studio: Plugins → Rojo → Connect

---

## ІГРОВА ЛОГІКА (КОРОТКО)

### Риба — 30 видів (англійські назви)

**Зона 1 (Shallows):**
| Назва | Рідкість | Умова |
|-------|----------|-------|
| Perch | Common | anytime |
| Pond Lurker | Common | anytime |
| Roach | Common | anytime |
| Goby | Common | anytime |
| Surf Crab | Common | anytime |
| Serpent Crawler | Uncommon | anytime |
| Silver Bream | Uncommon | anytime |
| Copper Eel | Rare | anytime |
| Goldfin Pike | Rare | anytime |
| Guardian Crab | Epic | day |
| Armored Catfish | Epic | day |
| Sun Ray | Legendary | day |
| Moon Serpent | Legendary | night |
| Misty Tench | Epic | fog |
| Thunder Jaw | Legendary | storm |

**Зона 2 (The Reefs):**
| Назва | Рідкість | Умова |
|-------|----------|-------|
| Pearl Grouper | Common | anytime |
| Painted Wrasse | Common | anytime |
| Red Mullet | Common | anytime |
| Spiny Drifter | Common | anytime |
| Sea Urchin | Common | anytime |
| Tiger Moray | Uncommon | anytime |
| Blue Scorpionfish | Uncommon | anytime |
| Reef Loach | Rare | anytime |
| Clownfish | Rare | anytime |
| Flame Anemone | Epic | day |
| Coral Jellyfish | Epic | day |
| Crystal Shark | Legendary | day |
| Reef Phantom | Legendary | night |
| Milky Chimera | Legendary | fog |
| Lightning Barracuda | Legendary | storm |

### Ресурси — 10 видів
**Острів 1:** Shell(70%), Seaweed(65%), Shore Stone(75%), Sea Glass(30%), Amber Shard(12%)
**Острів 2:** Coral(65%), Reef Sand(70%), Starfish(35%), Pearl(10%), Depth Crystal(8%)

### Таблиці прокачки (всі предмети 5 рівнів)

**Правила рецептів:**
- 1→2 і 2→3: ресурси Зони 1
- 3→4 і 4→5: ресурси Зони 2
- 5→6: змішаний фінальний

**Вудка:**
- 1→2: 150 монет + 4x Shell + 3x Seaweed
- 2→3: 450 монет + 4x Shore Stone + 3x Sea Glass + 1x Common
- 3→4: 1350 монет + 4x Coral + 3x Reef Sand + 1x Uncommon
- 4→5: 4050 монет + 5x Starfish + 3x Pearl + 1x Rare
- 5→6: 12150 монет + 4x Amber Shard + 3x Depth Crystal + 1x Epic

**Рюкзак (+5 слотів риби і ресурсів за рівень):**
- 1→2: 200 монет + 3x Shore Stone + 3x Seaweed + 1x Common
- 2→3: 600 монет + 4x Amber Shard + 3x Sea Glass + 1x Uncommon
- 3→4: 1800 монет + 4x Reef Sand + 4x Starfish + 1x Rare
- 4→5: 5400 монет + 5x Depth Crystal + 4x Pearl + 1x Epic
- 5→6: 16200 монет + 5x Shell + 4x Coral + 1x Legendary

**Льох (+5 слотів за рівень, старт 5):**
- 1→2: 100 монет + 4x Shell + 3x Shore Stone
- 2→3: 300 монет + 4x Sea Glass + 3x Seaweed + 1x Uncommon
- 3→4: 900 монет + 4x Coral + 4x Starfish + 1x Rare
- 4→5: 2700 монет + 5x Pearl + 4x Reef Sand + 1x Epic
- 5→6: 8100 монет + 5x Amber Shard + 4x Depth Crystal + 1x Legendary

**Склад (+25 од. за рівні 2-3, +50 за рівні 4-6, старт 100):**
- 1→2: 250 монет + 3x Seaweed + 3x Shore Stone
- 2→3: 750 монет + 4x Shell + 3x Amber Shard + 1x Common
- 3→4: 2250 монет + 5x Reef Sand + 4x Coral + 1x Uncommon
- 4→5: 6750 монет + 5x Depth Crystal + 4x Starfish + 1x Rare
- 5→6: 20250 монет + 5x Pearl + 4x Sea Glass + 1x Epic

### Вудка — характеристики по рівнях
| Рівень | Таймер поплавка | Синя зона |
|--------|----------------|-----------|
| 1 | 8-12с | 8% |
| 2 | 6-9с | 10% |
| 3 | 5-7с | 13% |
| 4 | 3-5с | 16% |
| 5 | 2-4с | 19% |
| 6 | 1-3с | 23% |

### Псування риби
- Common: 30хв, Uncommon: 60хв, Rare: 180хв, Epic: 720хв, Legendary: ніколи

### Економіка
- Ліцензія Зони 2: 15 000 монет/тиждень
- Аукціон: 10 слотів, 24 год, податок 8%, рамки 80-500% від NPC
- Пасивний дохід музею: офлайн макс 48 год

---

## ЩО НЕ РЕАЛІЗОВАНО (НАСТУПНІ КРОКИ)

- [ ] Псування риби в реальному часі (таймери)
- [ ] NPC Магазин — продаж риби
- [ ] Музей колекцій
- [ ] Льодовий льох
- [ ] Склад ресурсів
- [ ] Аукціон (MessagingService)
- [ ] Система ліцензій і зон
- [ ] Паті-система
- [ ] Туторіал
- [ ] Збереження позиції човна
- [ ] Roblox Friends API для бонусу музею
- [ ] Верстак (заблоковано до Хвилі 2)
- [ ] Будівлі хабу (музей, льох, склад, причал)
- [ ] Острови і NPC-торговці
- [ ] Човен і переміщення
- [ ] FishingSpot зони в океані (зона в CastRod поки завжди=1, inFishingSpot=false)
- [ ] RemoteEvents OpenInventory/AddToMuseum/ListAuction створені, але без обробників

---

## GIT-РЕПОЗИТОРІЙ

- Remote: https://github.com/mrevg11/Fishing-Experience-for-Roblox (гілка `master`)
- user.name/user.email налаштовані локально для цього репозиторію (не --global)
- Домовленість: комітити й пушити зміни автоматично, без запиту підтвердження щоразу

---

## ХВИЛІ РОЗРОБКИ

**Хвиля 1 (MVP)** — поточна
**Хвиля 2** — апгрейди човна, зони 3-4, крафт тринкетів, квести
**Хвиля 3** — скіни, батлпас, таблиця лідерів, пети

---

## ВАЖЛИВІ РІШЕННЯ

1. Всі назви риби і ресурсів — **англійською** (для релізу)
2. Текст UI — **англійською**
3. Print/warn в скриптах — **українською** (для розробника)
4. TEXT_SIZE = 22, TextScaled = false скрізь
5. Чорна обводка тексту: TextStrokeColor3=RGB(0,0,0), TextStrokeTransparency=0
6. Множник ідеальної зони бару: **x2.0** (не x2.5 як в документі)
7. 3D моделі риби — Blockbench (воксельний стиль), друг займається
8. Синхронізація: VS Code → Rojo → Studio (одностороння)
9. Ціна продажу риби НЕ залежить від погоди/часу доби — лише від
   basePrice і префікса риби (свідоме рішення, документ E1 тут не діє)
10. Погода змінюється кожні 10 хв (фіксовано); цикл дня/ночі = 1 година
    (morning 10хв, day 20хв, evening 15хв, night 15хв) — не як в документі
