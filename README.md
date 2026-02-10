# Future Test App

Test project to verify Flutter Future resolution behavior with platform channels.

## 🎯 Cel projektu

Sprawdzenie czy zmiana z "nierozwiązanych Future" na "Future rozwiązane z błędem" jest breaking change'em w kontekście Flutter/Dart.

## 🚀 Szybki start

```bash
cd future_test_app

# DEBUG mode
flutter run

# RELEASE mode  
flutter run --release
```

## ✨ Funkcje

- ✅ **9 scenariuszy testowych** - od podstawowych po zaawansowane
- 📊 **Szczegółowe logowanie** - timestamp, status, szczegóły dla każdego testu
- 📋 **Kopiowanie logów** - przycisk Copy w AppBar kopiuje wszystkie wyniki
- 🎨 **Kolorowe UI** - łatwe rozróżnienie testów (niebieski, zielony, czerwony)
- 🔍 **Logi natywne** - szczegółowe logi w Kotlin (Android) i Swift (iOS)
- 📝 **Template wyników** - gotowy szablon do prezentacji zespołowi

## 📋 Scenariusze testowe

### 1. Future Never Resolved (with timeout)
Symuluje sytuację gdzie natywny kod NIE wywołuje `result.success()` ani `result.error()`.
- **Obecne zachowanie Tealium**: Gdy klucz nie istnieje w dataLayer
- **Oczekiwany efekt**: Future nigdy się nie rozwiąże, timeout po 5 sekundach

### 2. Future Throws Error (with try/catch)
Natywny kod poprawnie zwraca błąd przez `result.error()`.
- **Proponowane zachowanie**: Zwracanie błędu gdy Tealium nie jest zainicjalizowany
- **Oczekiwany efekt**: `PlatformException` zostanie złapany w `catch` bloku

### 3. Future Returns Null
Natywny kod zwraca `null` przez `result.success(null)`.
- **Alternatywne rozwiązanie**: Zwracanie null zamiast błędu
- **Oczekiwany efekt**: Future rozwiąże się z wartością `null`

### 4. Simulate Tealium Bug
Dokładna symulacja buga z zadania - `getFromDataLayer` nie rozwiązuje Future gdy klucz nie istnieje.
- **Obecne zachowanie**: Bug w Tealium SDK
- **Oczekiwany efekt**: Timeout po 5 sekundach

### 5. ⚠️ Throws Error WITHOUT try/catch
**UWAGA**: Ten test może spowodować crash aplikacji!
- **Cel**: Sprawdzić czy uncaught `PlatformException` crashuje app
- **Pytanie**: Czy to jest breaking change?

### 6. Fire & Forget (unawaited)
Wywołanie metody BEZ `await` - częsty pattern dla analytics/tracking.
- **Praktyczny use case**: `tealium.track('event')` bez czekania na wynik
- **Pytanie**: Czy uncaught error z unawaited Future też crashuje app?

### 7. Using .then() instead of await
Niektórzy deweloperzy używają `.then()/.catchError()` zamiast async/await.
- **Praktyczny use case**: Starszy kod, Promise-style
- **Pytanie**: Czy error handling działa identycznie?

### 8. Multiple Rapid Calls (10x)
Symulacja szybkiego klikania przycisku przez użytkownika.
- **Praktyczny use case**: User klikający kilka razy "Send"
- **Pytanie**: Czy nierozwiązane Futures piętrzą się w pamięci? (memory leak?)

### 9. Future.wait() with mixed results
Równoległe wywołania z różnymi wynikami (null, error, timeout).
- **Praktyczny use case**: Batch operations, parallel API calls
- **Pytanie**: Czy jeden nierozwiązany Future blokuje całe `Future.wait()`?

## Jak uruchomić

### Quick Start
```bash
cd future_test_app
flutter run
```

### Pełna instrukcja testowania

Przeczytaj **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - szczegółowy przewodnik krok po kroku:
- Jak uruchomić testy w DEBUG i RELEASE
- Jak monitorować logi natywne
- Jak zbierać i zapisywać wyniki
- Typowe problemy i rozwiązania

### Prezentacja wyników

1. Uruchom wszystkie 9 testów (w DEBUG i RELEASE)
2. Kliknij przycisk **Copy** (📋) w AppBar - skopiuje wszystkie logi
3. Wypełnij **[TEST_RESULTS_TEMPLATE.md](TEST_RESULTS_TEMPLATE.md)** wynikami
4. Przedstaw wnioski zespołowi

## 📊 Format logów

Każdy test generuje szczegółowy log:

```
[12:34:56.789] TEST #1
Name: TEST 1: Future Never Resolved
Status: ⏱️ TIMEOUT
Details: Future never resolved. Timeout after 5000ms
--------------------------------------------------
```

**Logi natywne** (Android logcat / iOS Console):

```
════════════════════════════════════════════════════════════
KOTLIN: Method called: neverResolves
KOTLIN: ⚠️ BUG SIMULATION - NOT resolving the Future
KOTLIN: This mimics the Tealium bug where result() is never called
════════════════════════════════════════════════════════════
```

## Co sprawdzić

1. **W trybie DEBUG**:
   - Czy nieobsłużony błąd pokazuje red screen?
   - Czy aplikacja crashuje całkowicie?

2. **W trybie RELEASE**:
   ```bash
   flutter run --release
   ```
   - Czy nieobsłużony błąd crashuje aplikację bez red screen?
   - Czy zachowanie jest inne niż w debug?

3. **Logi**:
   - Android: `adb logcat`
   - iOS: Xcode Console
   - Sprawdź co dzieje się gdy Future nie jest resolved

## Kluczowe pytania do odpowiedzi

1. ✅ Czy nierozwiązany Future blokuje aplikację?
2. ✅ Czy uncaught PlatformException crashuje app?
3. ✅ Czy zachowanie jest inne w debug vs release?
4. ✅ Czy wprowadzenie błędów zamiast nierozwiązanych Future jest breaking change?
5. ✅ Czy unawaited Futures z błędami crashują app? (fire & forget pattern)
6. ✅ Czy multiple nierozwiązane Futures powodują memory leak?
7. ✅ Czy `.then()` pattern obsługuje błędy inaczej niż `await`?

## Praktyczne wnioski dla Tealium

Na podstawie testów będziesz mógł odpowiedzieć:

- **Jeśli uncaught error crashuje**: To **BREAKING CHANGE** ❌
  - Trzeba poczekać na v3.0
  - Dokumentacja musi być zaktualizowana

- **Jeśli uncaught error nie crashuje**: To **może nie być breaking change** ✅
  - Można wprowadzić w minor version
  - Ale trzeba sprawdzić edge cases (unawaited, .then())

- **Jeśli nierozwiązane Futures powodują memory leak**: To **BUG musi być naprawiony** 🐛
  - Nawet jeśli fix jest breaking change
  - Bezpieczeństwo > backward compatibility

## Implementacja natywna

### Android (Kotlin)
`android/app/src/main/kotlin/com/example/future_test_app/MainActivity.kt`

- Szczegółowe logi z tagiem `FutureTestApp`
- Sprawdź logi: `adb logcat | grep FutureTestApp`

### iOS (Swift)
`ios/Runner/AppDelegate.swift`

- Logi przez `os.log` z kategorią `FutureTest`
- Sprawdź w Xcode Console lub instrumentach systemowych

Obie implementacje zawierają identyczne scenariusze testowe z wyraźnymi logami.

---

## 📚 Dokumentacja

- **[README.md](README.md)** - Ten plik, przegląd projektu
- **[WNIOSKI_I_WYNIKI_TESTOW.md](WNIOSKI_I_WYNIKI_TESTOW.md)** - **Wnioski z testów i rekomendacje dla zespołu**
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - Szczegółowy przewodnik testowania
- **[TEST_RESULTS_TEMPLATE.md](TEST_RESULTS_TEMPLATE.md)** - Szablon do wypełnienia wynikami

---

## 💡 Przykładowe wnioski

Po przeprowadzeniu testów będziesz mógł odpowiedzieć na:

### Czy to breaking change?

**Jeśli TEST 5 crashuje app:**
```
✅ TAK - to jest BREAKING CHANGE
Wprowadzenie błędów zamiast nierozwiązanych Future będzie 
wymagało od developerów dodania try/catch tam gdzie go nie ma.
```

**Jeśli TEST 5 NIE crashuje app:**
```
⚠️ MOŻE NIE BYĆ - ale sprawdź TEST 6!
Jeśli unawaited Futures NIE crashują, to wprowadzenie błędów
może być bezpieczne (developerzy i tak nie czekają na wynik).
```

### Jaka rekomendacja dla Tealium?

**Opcja A: Zwracaj null**
```
Pros:
- Nie jest breaking change
- Kompatybilne z obecnym zachowaniem
- Developerzy mogą sprawdzić if (result == null)

Cons:
- Nie wszędzie możliwe (Future<String> nie może zwrócić null)
- Mniej ekspresywne niż error
```

**Opcja B: Throw errors**
```
Pros:
- Jasne komunikowanie problemów
- Zgodne z best practices
- Działa wszędzie (nie ma problemu z typami)

Cons:
- MOŻE być breaking change (zależy od wyników testów)
- Developerzy muszą dodać try/catch
```

**Opcja C: Fix w v3.0**
```
Pros:
- Czas na komunikację breaking change
- Można poprawnie zaprojektować API

Cons:
- Bug będzie istniał dłużej
- Developerzy będą cierpieć na nierozwiązane Futures
```

---

## 🔍 Kluczowe insights

1. **Nierozwiązane Futures nie crashują**, ale wiszą w pamięci (timeout)
2. **PlatformException z try/catch** jest bezpieczny
3. **PlatformException BEZ try/catch** może crashować (TEST 5)
4. **Unawaited Futures** zachowują się inaczej (TEST 6)
5. **Future.wait()** czeka na WSZYSTKIE Futures, więc jeden nierozwiązany blokuje batch

---

## 🎓 Dla zespołu Mobile

To narzędzie testowe można używać jako:

1. **Proof of concept** przed wprowadzeniem zmian
2. **Dokumentacja** zachowania Future w Flutter
3. **Training tool** dla nowych developerów
4. **Regression tests** po update'ach Flutter SDK

---

## 🙋 Pytania?

Jeśli masz pytania lub potrzebujesz pomocy:
1. Sprawdź logi w konsoli (Flutter + natywne)
2. Przeczytaj `TESTING_GUIDE.md`
3. Porównaj z oczekiwanymi wynikami w tym README
