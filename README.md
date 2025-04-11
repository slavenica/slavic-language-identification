# Slavic Language Identification

A Perl script for detecting and identifying Slavic languages from text input, using character frequencies, distinctive letters, and language-specific patterns.

## Features

- Identifies specific Slavic languages including Russian, Ukrainian, Belarusian, Bulgarian, Serbian, Macedonian, Polish, Czech, Slovak, Slovenian, Sorbian, and more
- Detects Church Slavonic and Old Church Slavonic varieties
- Recognizes different scripts (Cyrillic, Latin, Glagolitic, Arabic)
- Returns BCP47-compatible language tags
- Provides confidence scores (optional)

## Usage

```bash
# Basic usage with Russian text (stdin)
echo "Красота спасёт мир." | perl slavic-language-identification.pl

# Ukrainian example (stdin)
echo "Наші пісні - це наша історія. В них все, що боліло й болить, радувало і тривожить. Вони відображають і бережуть дух народу." | perl slavic-language-identification.pl

# Polish example (stdin)
echo "Książki są jak towarzystwo, które sobie człowiek dobiera. Kiedy na półce stoją książki pisane z serca i z talentów, człowiek się czuje otoczony przyjaznymi duchami. Z dobrą książką nigdy nie jesteś sam." | perl slavic-language-identification.pl

# Czech example (stdin)
echo "Knihy jsou nejtiššími a nejvěrnějšími přáteli. Jsou nejpřístupnějšími a nejmoudřejšími rádci a nejtrpělivějšími učiteli. Čtení dobrých knih je jako rozhovor s nejlepšími lidmi minulých staletí." | perl slavic-language-identification.pl

# Read text from a file
perl slavic-language-identification.pl russian_text.txt

# Always show script tag even when it's the default
perl slavic-language-identification.pl -s polish_text.txt

# Show confidence scores
perl slavic-language-identification.pl -v czech_text.txt
cat text_file.txt | perl slavic-language-identification.pl -v

# Show help
perl slavic-language-identification.pl -h
```

## Requirements

- Perl 5.14 or later
- UTF-8 support

## License

[MIT License](LICENSE)

© 2015 Danslav Slavenskoj