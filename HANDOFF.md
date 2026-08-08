# NoRep — Handoff / история проекта

Документ для передачи контекста другому агенту или разработчику.
Обновлён: 2026-08-08. Автор изменений: Anton Penkov (antonpenkov1) + Claude Code.

## Что это

**NoRep** — iOS-таймер для функционального тренинга (кроссфит-стиль): EMOM, AMRAP,
For Time, Tabata и конструктор Mix. Название — от судейского «No rep!». Имя выбрано
после проверки App Store (SmartWOD, Captime, WodTimer, Box Timer заняты; «Unbroken» тоже).

⚠️ **Слово «CrossFit» — торговая марка CrossFit LLC.** Не использовать в названии,
сабтайтле, ключевых словах, скриншотах. Говорим «functional fitness», «WOD», «box».

## Инфраструктура

| Что | Значение |
|---|---|
| Репозиторий | https://github.com/antonpenkov1/NoRep (public, ветка main) |
| Локальный путь | `/Users/antonpenkov/Documents/Toloka/Synthetic App Build/NoRep` |
| Privacy policy | https://antonpenkov1.github.io/NoRep/ (GitHub Pages из `docs/`) |
| Apple Developer | платный аккаунт, Team ID `3UHRLQ9522` (личный, «Антон Пеньков») |
| Bundle IDs | app `com.norep.app`, widgets `com.norep.app.widgets`, watch `com.norep.app.watchkitapp` |
| iCloud container | `iCloud.com.norep.app` |
| ASC Apple ID приложения | 6794721408, SKU `norep-001` |
| Контакт | anton.penkov1@gmail.com |

## Архитектура

- **SwiftUI + Clean Swift (VIP)**, iOS 17+, только портрет, тёмная тема.
- Каждая сцена: `Models` → `Interactor` (бизнес-логика) → `Presenter` (форматирование)
  → `ViewStore: ObservableObject` (display logic) → View; навигация через `Router`
  и общий `AppRouter` (NavigationStack + enum Route). Граф собирает `SceneFactory`
  внутри `@StateObject`.
- Сцены: Home, Setup, MixBuilder, Workout, History (Journal), Settings, Benchmarks, MyWODs.
- **Проект генерируется XcodeGen**: источник правды — `project.yml`,
  `NoRep.xcodeproj` в .gitignore. После клонирования/правок: `xcodegen generate`.
- Таргеты: `NoRep` (iOS app), `NoRepWidgets` (Live Activity/Dynamic Island),
  `NoRepWatch` (watchOS 10+, **временно НЕ встроен** — см. «Известные проблемы»).

### Ядро (общее для iOS и watchOS)

- `NoRep/Common/Models/WorkoutModels.swift` — типы таймеров, конфиги, `MixBlock`
  (блок + заметка-комплекс), `WorkoutPlan` (Codable/Hashable), `WorkoutSegment`,
  `WorkoutResult` (+ PR-сравнение `beats()`), `TimeFormat`.
- `WorkoutCompiler.swift` — компилирует план в плоскую ленту сегментов
  (обратный отсчёт → раунды/работа/отдых; классическая Табата без последнего отдыха).
- `TimerEngine.swift` — движок на якорях wall-clock: точная пауза, догоняет после
  фона; события: warningTick(3-2-1), segmentStarted, halfway (50% для сегментов ≥60с),
  finished. Отсчёт «GET READY» не входит в общее время.

### Сервисы (iOS)

- `SoundService` — 6 паков WAV-сигналов (`<pack>_<cue>.wav`: classic/horn/soft/whistle/
  bell/arcade × tick/go/rest/finish), сгенерированы Python-синтезом; аудиосессия
  `.playback + .mixWithOthers` (⚠️ НЕ `.duckOthers` — не восстанавливает громкость музыки);
  `silence.wav` в цикле держит сессию в фоне (UIBackgroundModes: audio).
- `VoiceService` — AVSpeechSynthesizer («Round 5», «Halfway», «Rest», «Time!»).
- `HapticService`, `LiveActivityService` (+ зачистка осиротевших активностей при старте),
  `HealthKitService` (запись functionalStrengthTraining, opt-in),
  `PhoneWatchSync` (WatchConnectivity, приём результатов с часов),
  `ExportService` (CSV/JSON журнала), `SetupDefaultsStore` (настройки в UserDefaults).
- **SwiftData**: `Persistence.container` — общий контейнер (CloudKit private DB →
  локальный → in-memory fallback); `StoredWorkout` (журнал; миграция из старого
  UserDefaults JSON выполняется автоматически), `StoredWOD` (Мои WOD, план как JSON-Data).
  ⚠️ CloudKit-правила: НЕ использовать `@Attribute(.unique)`, все поля с дефолтами.

## Хронология версий

### v1.0 (июль 2026) — выпущена в App Store
Таймеры EMOM/AMRAP/ForTime/Tabata + Mix-конструктор, звуки, хаптика, история,
иконка (кольцо + красный слэш, CoreGraphics-скрипт). Сабмит прошёл с первого раза.

### v1.1 — журнал и Live Activity
Журнал (heatmap 12 недель, стрик, счётчики), сплиты раундов (тап по циферблату
= отметка времени, bar-chart на Swift Charts), пост-тренировочное логирование
(имя/комплекс/RX/самочувствие), PR-трекинг по имени тренировки (For Time — меньше
время, иначе — больше раундов), заметки-комплексы на экране таймера (per-block в Mix),
Live Activity + Dynamic Island (таргет NoRepWidgets), фоновое аудио.

### v1.2 — контент и охват
Библиотека бенчмарков (25 WOD: The Girls + Hero, `BenchmarkLibrary.swift`),
быстрый старт (repeat last + чипы пресетов), голосовые анонсы + halfway-сигнал,
шеринг-карточка результата (ImageRenderer + ShareLink), HealthKit (opt-in),
**локализация на 7 языков** (en/ru/sr-кириллица/es/de/fr/pt-BR,
`Localizable.xcstrings`, 109 ключей), SwiftData вместо UserDefaults, 6 звуковых
паков, 5 иконок приложения (alternate icons), экран Settings.
⚠️ Капс-надписи таймера (ROUND/WORK/REST/GET READY) осознанно оставлены на английском.
⚠️ Строки в презентерах локализуются ТОЛЬКО через `String(localized:)` — голые
литералы в презентерах НЕ попадают в каталог (в отличие от SwiftUI `Text("...")`).

### v1.3 — текущая, ГОТОВА К ЗАГРУЗКЕ (не загружена)
Мои WOD (сохранение из Setup/Mix/после тренировки, свой список со стартом в тап),
iCloud-синхронизация (журнал + Мои WOD), экспорт CSV/JSON, **Apple Watch app
(код готов, НО не встроен в этот релиз — см. ниже)**. MARKETING_VERSION 1.3, build 4.

## Известные проблемы и грабли (ВАЖНО)

1. **CoreSimulator на этом Mac сломан, нужна перезагрузка Mac.** Симптомы:
   watchOS-рантайм 26.5 скачан (`xcodebuild -downloadPlatform watchOS`), но не
   монтируется и не регистрируется; `simctl io screenshot` отдаёт замороженные
   кадры или падает (NSPOSIXErrorDomain code=1). После перезагрузки: заново
   `xcodebuild -downloadPlatform watchOS`, проверить `xcrun simctl list runtimes`.
2. **Watch app не встроен в 1.3**: actool не может собрать иконку часов без
   смонтированного watch-рантайма + watch-UI не проверен визуально. Для 1.4:
   раскомментировать `- target: NoRepWatch` в dependencies app-таргета в
   `project.yml`, `xcodegen generate`, проверить UI (debug-аргумент
   `-DemoWorkout 1` открывает бегущий EMOM на часах), собрать архив.
3. **Версии в Info.plist**: xcodegen-генерируемые plist зашивали «1.0» литералом.
   Исправлено: во всех трёх info-блоках `CFBundleShortVersionString: $(MARKETING_VERSION)`,
   `CFBundleVersion: $(CURRENT_PROJECT_VERSION)`. Версию поднимать в `project.yml`
   (оба значения, во всех таргетах одинаково).
4. **zsh и launch-аргументы**: `xcrun simctl launch ... -DemoRoute "$VAR"` — не
   использовать хитрые подстановки `${x:+...}`, zsh склеивает аргументы в один.
5. Схема: явная shared-схема только `NoRep` (запуск схемы NoRepWidgets даёт
   безобидную ошибку «Failed to show Widget» — в расширении только Live Activity).
6. При force-quit Live Activity зависает — лечится зачисткой в
   `LiveActivityService.start()` (уже реализовано).

## Рабочие команды

```bash
# генерация проекта и сборка
xcodegen generate
xcodebuild -project NoRep.xcodeproj -scheme NoRep \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# release-архив (текущий: build/NoRep-1.3.xcarchive)
xcodebuild -project NoRep.xcodeproj -scheme NoRep -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/NoRep-1.3.xcarchive \
  archive -allowProvisioningUpdates

# демо-маршруты для скриншотов (DEBUG only), пример:
xcrun simctl launch <UDID> com.norep.app -DemoRoute workout-emom
# маршруты: workout-emom, workout-tabata, workout-sprint (PR-summary через 8с),
# mix, setup-tabata, settings, benchmarks, mywods, history

# промо-слайды App Store (6.5", 1284×2778)
swift Tools/promo.swift AppStore/screenshots-1.3-69 AppStore/promo-1.3
```

Скрипты генерации ассетов: иконки — CoreGraphics-скрипт (варианты цветов в
`Tools/promo.swift`-стиле, исходники в истории чата; PNG уже в Assets),
звуки — Python-синтез (WAV уже в `NoRep/Resources/Sounds`).

## App Store — состояние и следующий шаг

- v1.0 опубликована. **v1.3 (build 4) заархивирована и открыта в Organizer —
  ПОЛЬЗОВАТЕЛЬ ДОЛЖЕН ЗАГРУЗИТЬ** (Distribute App → App Store Connect → Upload).
- В ASC: создать версию 1.3 → What's New из `AppStore/metadata.md` (EN+RU секции) →
  скриншоты из `AppStore/promo-1.3/` (рекламные слайды, ровно 1284×2778 для слота 6.5")
  → выбрать билд → Submit. App Privacy остаётся «Data Not Collected».
- `AppStore/metadata.md` — все тексты (название, сабтайтл, ключевые слова без
  «crossfit», описания EN/RU, What's New).

## Планы (согласованы с владельцем)

1. **1.4**: вернуть Apple Watch (после перезагрузки Mac + визуальной проверки),
   watch-скриншоты для ASC.
2. Дальше: виджеты домашнего экрана, App Intents/Siri («start EMOM ten»),
   уведомление-защита стрика, юнит-тесты ядра (TimerEngine/Compiler/JournalStats/PR).
3. **Монетизация** (после набора аудитории): freemium — таймеры бесплатно навсегда,
   Pro (журнал-статистика/бенчмарки/watch) разовый IAP $2.99–4.99; при добавлении
   рекламы: interstitial только после тренировки + «убрать за $2.99»; обновить
   App Privacy и privacy policy (заглушка про будущие изменения уже в тексте).
   ⚠️ AdMob не выплачивает на аккаунты, зарегистрированные в РФ.

## Стиль общения с владельцем

Антон общается по-русски, любит быстрые итерации, сам активно тестирует в
симуляторе прямо во время работы агента (не удивляться «чужим» действиям на
экране). Технический уровень: уверенный, но не iOS-разработчик — объяснять
решения по делу, без воды. Проверять фичи скриншотами симулятора перед сдачей.
