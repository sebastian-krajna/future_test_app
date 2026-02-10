# 🧪 Quick Testing Guide

## Przygotowanie

1. **Otwórz terminal w projekcie:**
```bash
cd future_test_app
```

2. **Sprawdź wersję Flutter:**
```bash
flutter --version
```

3. **Przygotuj urządzenie:**
   - Android: Podłącz urządzenie przez USB lub uruchom emulator
   - iOS: Uruchom symulator lub podłącz iPhone

4. **Sprawdź dostępne urządzenia:**
```bash
flutter devices
```

---

## Krok 1: Testy w trybie DEBUG (Android)

```bash
flutter run
```

### Wykonaj testy w kolejności:

1. ✅ **TEST 1** - Kliknij przycisk, poczekaj 5s na timeout
2. ✅ **TEST 2** - Sprawdź czy error jest złapany
3. ✅ **TEST 3** - Sprawdź czy null jest zwrócony
4. ✅ **TEST 4** - Sprawdź czy timeout (potwierdza bug)
5. ⚠️ **TEST 5** - **UWAGA!** Może crashować! Zapisz wynik:
   - Czy pokazał się czerwony ekran?
   - Czy aplikacja się zawiesiła?
   - Czy aplikacja się zrestartowała?
6. ✅ **TEST 6** - Czy aplikacja dalej działa?
7. ✅ **TEST 7** - Czy error jest złapany?
8. ✅ **TEST 8** - Poczekaj ~20s
9. ✅ **TEST 9** - Poczekaj ~3s

### Monitoruj logi:

Otwórz **nowy terminal** i uruchom:
```bash
adb logcat | grep -E "FutureTestApp|flutter"
```

Lub w Android Studio: **Logcat** → filtruj `FutureTestApp`

---

## Krok 2: Testy w trybie RELEASE (Android)

```bash
flutter run --release
```

⚠️ **WAŻNE:** W trybie RELEASE nie zobaczysz czerwonego ekranu, więc:
- Obserwuj czy aplikacja przestaje odpowiadać
- Sprawdź czy aplikacja się całkowicie zamyka (crash)
- Monitoruj logi w `adb logcat`

### Powtórz wszystkie 9 testów

Szczególnie zwróć uwagę na:
- **TEST 5** - Czy zachowanie jest inne niż w DEBUG?
- **TEST 6** - Czy unawaited error crashuje w RELEASE?

---

## Krok 3: Testy na iOS (DEBUG)

```bash
flutter run -d iPhone
```

### Monitoruj logi w Xcode:

1. Otwórz **Xcode**
2. **Window** → **Devices and Simulators**
3. Wybierz urządzenie → **Open Console**
4. Filtruj: `FutureTest`

### Powtórz wszystkie 9 testów

---

## Krok 4: Testy na iOS (RELEASE)

```bash
flutter run --release -d iPhone
```

### Powtórz wszystkie 9 testów

---

## Zbieranie wyników

### 1. Kopiowanie logów z aplikacji

- Kliknij ikonę **Copy** (📋) w AppBar
- Logi zostaną skopiowane do schowka
- Wklej do pliku tekstowego

### 2. Kopiowanie logów natywnych

**Android:**
```bash
adb logcat -d > android_logs.txt
```

**iOS:**
W Xcode Console → Prawy kliknij → **Save As...**

### 3. Wypełnij template

Otwórz `TEST_RESULTS_TEMPLATE.md` i wypełnij wynikami

---

## Krytyczne pytania do odpowiedzi

### ❓ Czy TEST 5 crashuje aplikację?

- **DEBUG:** [TAK / NIE]
- **RELEASE:** [TAK / NIE]

**Jeśli TAK** → 🔴 **BREAKING CHANGE!**

### ❓ Czy TEST 6 (unawaited) crashuje aplikację?

- **DEBUG:** [TAK / NIE]
- **RELEASE:** [TAK / NIE]

**Jeśli TAK** → 🔴 **BARDZO POWAŻNY PROBLEM!** (bo analytics jest często unawaited)

### ❓ Czy TEST 4 potwierdza bug Tealium?

- **Timeout po 5s?** [TAK / NIE]

**Jeśli TAK** → ✅ Bug potwierdzony

---

## Skróty klawiaturowe w Flutter (podczas `flutter run`)

- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit
- `s` - Screenshot
- `w` - Dump widget hierarchy

---

## Typowe problemy

### Aplikacja nie uruchamia się

```bash
flutter clean
flutter pub get
flutter run
```

### Android - brak urządzeń

```bash
# Sprawdź czy ADB widzi urządzenie
adb devices

# Jeśli nie, zrestartuj ADB
adb kill-server
adb start-server
```

### iOS - błąd signing

```bash
flutter config --clear-ios-signing-settings
```

Następnie:
1. Otwórz `ios/Runner.xcworkspace` w Xcode
2. **Signing & Capabilities** → Wybierz swój team

---

## Prezentacja wyników zespołowi

1. **Wypełnij `TEST_RESULTS_TEMPLATE.md`**
2. **Skopiuj wszystkie logi** (z przycisku Copy w aplikacji)
3. **Zrób screenshoty** interesujących wyników (szczególnie TEST 5)
4. **Porównaj DEBUG vs RELEASE**
5. **Przygotuj rekomendację:**
   - Czy to breaking change?
   - Którą opcję polecasz?
   - Dlaczego?

---

## Przykładowa prezentacja

```
WYNIKI TESTÓW - Future Resolution w Flutter

✅ POTWIERDZONY BUG:
   TEST 4 pokazał, że gdy klucz nie istnieje w dataLayer,
   Future nigdy nie jest rozwiązany (timeout po 5s)

⚠️ BREAKING CHANGE:
   TEST 5 (DEBUG): [Czerwony ekran / Crash / OK]
   TEST 5 (RELEASE): [Crash / OK]
   
   TEST 6 (unawaited):
   DEBUG: [Crash / OK]
   RELEASE: [Crash / OK]

📊 REKOMENDACJA:
   [Opisz swoją rekomendację]
```

---

## Potrzebujesz pomocy?

- Sprawdź logi w konsoli
- Uruchom ponownie test
- Porównaj z oczekiwanymi wynikami w `README.md`
