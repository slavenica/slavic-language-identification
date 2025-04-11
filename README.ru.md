# Идентификация славянских языков

Скрипт на Perl для определения славянских языков из текстового ввода с использованием частотного анализа символов, характерных букв и языковых шаблонов.

## Возможности

- Определяет конкретные славянские языки из текстовых образцов
- Возвращает языковые теги, совместимые с BCP47
- Предоставляет оценку уверенности определения (опционально)

## Поддерживаемые языки

### Восточнославянские
- Русский (ru)
- Дореволюционный русский (ru-petr1708)
- Украинский (uk)
- Белорусский (be)

### Южнославянские
- Болгарский (bg)
- Македонский (mk)
- Сербский (sr)
- Боснийский (bs) - включая вариант с арабской письменностью

### Западнославянские
- Польский (pl)
- Чешский (cs)
- Словацкий (sk)
- Словенский (sl)
- Лужицкие языки (dsb, hsb)
- Кашубский (csb)

### Исторические
- Церковнославянский (cu-x-cs)
- Старославянский (cu-x-ocs)

### Системы письма
- Кириллица (Cyrl)
- Латиница (Latn)
- Глаголица (Glag)
- Историческая кириллица (Cyrs)
- Арабское письмо (Arab)

Скрипт также может определять общие группы славянских языков (восточная, западная, южная), когда конкретный язык не может быть определен.

## Использование

```bash
# Пример на русском языке (через stdin)
echo "Книги - корабли мысли, странствующие по волнам времени. Они бережно несут свой драгоценный груз от поколения к поколению. Без книг история молчит, а будущее окутывается мраком." | perl slavic-language-identification.pl

# Пример на украинском языке (через stdin)
echo "Наші пісні - це наша історія. В них все, що боліло й болить, радувало і тривожить. Вони відображають і бережуть дух народу." | perl slavic-language-identification.pl

# Пример на польском языке (через stdin)
echo "Książki są jak towarzystwo, które sobie człowiek dobiera. Kiedy na półce stoją książki pisane z serca i z talentów, człowiek się czuje otoczony przyjaznymi duchami. Z dobrą książką nigdy nie jesteś sam." | perl slavic-language-identification.pl

# Пример на чешском языке (через stdin)
echo "Knihy jsou nejtiššími a nejvěrnějšími přáteli. Jsou nejpřístupnějšími a nejmoudřejšími rádci a nejtrpělivějšími učiteli. Čtení dobrých knih je jako rozhovor s nejlepšími lidmi minulých staletí." | perl slavic-language-identification.pl

# Чтение текста из файла
perl slavic-language-identification.pl russian_text.txt

# Всегда показывать тег письменности, даже если это стандартная письменность для языка
perl slavic-language-identification.pl -s polish_text.txt

# Показывать оценку уверенности
perl slavic-language-identification.pl -v czech_text.txt
cat text_file.txt | perl slavic-language-identification.pl -v

# Показать справку
perl slavic-language-identification.pl -h
```

## Требования

- Perl 5.14 или выше
- Поддержка UTF-8

## Лицензия

[Лицензия MIT](LICENSE)

© 2025 Danslav Slavenskoj