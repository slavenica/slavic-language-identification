# Идентификация славянских языков

Скрипт на Perl для определения славянских языков из текстового ввода с использованием частотного анализа символов, характерных букв и языковых шаблонов.

## Возможности

- Определяет конкретные славянские языки, включая русский, украинский, белорусский, болгарский, сербский, македонский, польский, чешский, словацкий, словенский, лужицкий и другие
- Распознает церковнославянский и старославянский варианты
- Поддерживает различные системы письма (кириллица, латиница, глаголица, арабская письменность)
- Возвращает языковые теги, совместимые с BCP47
- Предоставляет оценку уверенности определения (опционально)

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

© 2015 Danslav Slavenskoj