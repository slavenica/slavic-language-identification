#!/usr/bin/env perl
# Slavic Language Identification
# Version: 2.1.0 
# © 2015 Danslav Slavenskoj
# MIT License
#

use 5.014;
use strict;
use warnings;
use utf8;
use Encode qw(decode encode is_utf8);
use open qw(:std :utf8);

# Pre-compile regex patterns for scripts at the module level
my $CYRILLIC_RE = qr/[А-Яа-яЁёЂђЃѓЄєЅѕІіЇїЈјЉљЊњЋћЌќЎўЏџҐґЪъЫыЬьЭэЮюЯя]/;
my $LATIN_RE = qr/[A-Za-zÁáÄäĄąÃãČčĆćĎďĐđÉéĘęĚěÈèËëÍíĹĺĽľŁłŃńŇňÓóÔôÒòŔŕŘřŚśŠšŤťÚúŮůÙùÝýŹźŻżŽž]/;
my $GLAGOLITIC_RE = qr/[\x{2C00}-\x{2C5F}\x{1E000}-\x{1E02F}]/;
my $ARABIC_RE = qr/[\x{0600}-\x{06FF}\x{0750}-\x{077F}\x{08A0}-\x{08FF}\x{FB50}-\x{FDFF}\x{FE70}-\x{FEFF}]/;
my $CYRS_RE = qr/[ѣѧѫѩѭѱѯꙑꙋѡꙗѹѳѵꙁѕꙉꙅꙇꙍꙏꙓꙃ]/;

# Consonants in Cyrillic for pre-revolutionary Russian check
my $CYRILLIC_CONSONANTS_RE = qr/[бвгдзклмнпрстфхцчшщжБВГДЗКЛМНПРСТФХЦЧШЩЖ]/;

# Define a comprehensive set of Old Church Slavonic and Church Slavonic characters
my @ARCHAIC_CHARS = qw(
    ѣ ѧ ѫ ѩ ѭ ѱ ѯ ѡ ꙑ ꙋ ѳ ѵ ꙁ ꙗ ѹ ѿ ѽ ѻ ꙉ ꙅ ꙇ ꙍ ꙏ ꙓ ꙃ
    \x{0483} \x{0487} \x{A656} \x{A657} \x{2C00} \x{2C30} \x{2C10} \x{2C3A} 
    \x{2C27} \x{2C41} \x{2C0D} \x{1E000} \x{1E001} \x{1E002}
);

# Define languages that should suppress script tags per BCP47
my %SUPPRESS_SCRIPT = (
    'ru' => 'Cyrl',
    'be' => 'Cyrl',
    'uk' => 'Cyrl',
    'sl' => 'Latn',
    'hr' => 'Latn',
    'bs' => 'Latn',
    'mk' => 'Cyrl',
    'bg' => 'Cyrl',
    'cs' => 'Latn',
    'sk' => 'Latn',
    'sh' => 'Latn',
    'dsb' => 'Latn',
    'hsb' => 'Latn',
    'pl' => 'Latn',
);

# Initialize distinctive letters hash only once and use it throughout the script
my %DISTINCTIVE_LETTERS = (
    'cu-old' => {
        # Old Church Slavonic - most archaic form with distinctive characters
        positive => [qw(\x{2C00} \x{2C30} \x{2C10} \x{2C3A} \x{2C27} \x{2C41} \x{2C0D} ѫ ѧ ѩ ѭ ꙑ ѱ ѯ ꙁ ѕ ѡ ꙗ)],
        negative => [qw(э ё ґ џ љ њ)],
        min_positive => 2,
        max_negative_pct => 10.0,
        patterns => [qw(
            \x{2C00}\x{2C35}\x{2C49}
            \x{2C39}\x{2C41}\x{2C18}\x{2C37}
            \x{2C25}\x{2C36}\x{2C4D}\x{2C43}
            \x{2C27}\x{2C10}\x{2C4A}\x{2C00}
            \x{2C4A}\x{2C01}\x{2C29}\x{2C41}
            \x{2C4A}\x{2C0E}\x{2C4D}\x{2C43}
            \x{2C27}\x{2C3A}\x{2C4E}\x{2C00}
            \x{2C41}\x{2C27}\x{2C43}\x{2C34}
        )]
    },
    'cu' => {
        # Modern standard Church Slavonic - primarily in Cyrillic
        positive => [qw(ѣ ѡ і ѳ ѵ ꙋ ѧ ѕ \x{0483} \x{0487} \x{0301} \x{0300})],
        negative => [qw(э ё ґ ы љ њ ꙑ ѩ ѭ ꙁ ꙃ ꙉ ꙅ)],
        min_positive => 3,
        max_negative_pct => 10.0,
        patterns => [qw(бг҃ъ гд҃ь хр҃тосъ іи҃съ мр҃іа ст҃ъ ст҃ый дх҃ъ пр҃ркъ ап҃лъ бц҃а)]
    },
    'uk' => {
        positive => [qw(ї є ґ)],
        negative => [@ARCHAIC_CHARS, qw(ў ђ љ њ џ ѓ ќ ѕ ы э)],
        min_positive => 1,
        max_negative_pct => 20.0
    },
    'be' => {
        positive => [qw(ў і)],
        negative => [@ARCHAIC_CHARS, qw(ї є ґ ђ љ њ џ ѓ ќ ѕ)],
        min_positive => 1,
        max_negative_pct => 20.0
    },
    'mk' => {
        positive => [qw(ѓ ќ ѕ)],
        negative => [
            @ARCHAIC_CHARS,
            qw(ї є ґ ў і ы э ё ъ ь ђ љ њ џ)
        ],
        min_positive => 1,
        max_negative_pct => 20.0
    },
    'sr' => {
        positive => [qw(ђ љ њ џ)],
        negative => [
            @ARCHAIC_CHARS,
            qw(ї є ґ ў і ы э ё ъ ь ѓ ќ)
        ],
        min_positive => 2,
        max_negative_pct => 30.0
    },
    'bg' => {
        positive => [], # No truly unique letters in Bulgarian
        negative => [@ARCHAIC_CHARS, qw(ї і є ґ ў ђ љ њ џ ѓ ќ ѕ ы э ё)],
        min_positive => 0,
        max_negative_pct => 20.0,
        patterns => [qw(
            ът ъта ъто ята ият
            със във към пък
            първ държ връз вълк пълн дълг гълт тълп
            търс мърд тънк гъвк мъдр мъгл
            ъгъ ъжд ъдъ ъщн ъжн
        )]
    },
    'ru' => {
        positive => [qw(ы э)],
        negative => [@ARCHAIC_CHARS, qw(ї і є ґ ў ђ џ љ њ џ ѓ ќ ѕ)],
        min_positive => 1,
        max_negative_pct => 20.0
    },
    'ru-pre' => {
        positive => [qw(ѣ і ѳ ѵ)],
        negative => [qw(є ґ ў ђ љ њ џ ѓ ќ ѫ ѧ ѩ ѭ ѱ ѯ ꙑ ꙁ ꙗ \x{0483} \x{0487})],
        min_positive => 1,
        max_negative_pct => 20.0
    },
    'pl' => {
        positive => [qw(ą ę ł ń ś ź ż)],
        negative => [qw(ř ě ů ĺ ľ ŕ ô ä ć đ)],
        min_positive => 2,
        max_negative_pct => 20.0
    },
    'cs' => {
        positive => [qw(ř ě ů)],
        negative => [qw(ą ę ł ń ś ź ż ĺ ľ ŕ ô ä đ ć ë)],
        min_positive => 1,
        max_negative_pct => 20.0,
        patterns => [qw(
            -ovat -ujeme -ujete
            není jsem jsme jste jsou
            proto protože když pokud
            však jestliže ale
        )]
    },
    'sk' => {
        positive => [qw(ĺ ľ ŕ ô ä)],
        negative => [qw(ą ę ł ń ś ź ż ř ů ë ě đ ć)],
        min_positive => 1,
        max_negative_pct => 20.0,
        patterns => [qw(
            -ovať -ujeme -ujete
            nie som sme ste sú
            keď pretože ako prečo
        )]
    },
    'sh' => {
        positive => [qw(đ)],
        negative => [qw(ą ę ł ń ś ź ż ř ě ů ĺ ľ ŕ ô ä ý y)],
        min_positive => 1,
        max_negative_pct => 20.0,
        patterns => [qw(
            đa đe đi đo đu đr
            nđ đn rđ đj mđ
        )]
    },
    'sl' => {
        positive => [],
        negative => [qw(ć đ ą ę ł ń ś ź ż ř ě ů ĺ ľ ŕ ô ä)],
        min_positive => 0,
        max_negative_pct => 20.0,
        patterns => [qw(
            ega emu
            ajo ejo ijo
            zato ker prav zato sicer
        )]
    },
    'hsb' => {
        positive => [],
        negative => [qw(ą ę ń ś ź ż ĺ ľ ŕ ô ä ë đ ć)],
        min_positive => 0,
        max_negative_pct => 20.0,
        patterns => [qw(
            wšak wšitko wšě
            wě hłós
        )]
    },
    'dsb' => {
        positive => [],
        negative => [qw(ą ę ń ś ź ż ř ě ů ĺ ľ ô ä ë đ ć)],
        min_positive => 0,
        max_negative_pct => 20.0,
        patterns => [qw(
            źo źi źe
            aśi eśi jśi 
            -owaś -aś -yś -nuś
        )]
    },
    'csb' => {
        positive => [qw(ë)],
        negative => [qw(ř ě ů ĺ ľ ŕ ô ä đ ć)],
        min_positive => 1,
        max_negative_pct => 20.0,
        patterns => [qw(
            bëc 
            -ëje -ëją -ëjesz -ëjemë
            bëlë cëż përznã
        )]
    },
    'bs' => {
        positive => [qw(\x{0645} \x{0627} \x{062C} \x{0627} \x{0633} \x{0648})],
        negative => [],
        min_positive => 1,
        max_negative_pct => 50.0
    }
);

# Create script-to-language mapping for faster lookups
my %SCRIPT_TO_LANGS = (
    'Glag' => ['cu-old', 'cu'],
    'Cyrl' => ['cu-old', 'cu', 'uk', 'be', 'mk', 'sr', 'bg', 'ru-pre', 'ru'],
    'Cyrs' => ['cu-old', 'cu'],
    'Latn' => ['pl', 'cs', 'sk', 'sh', 'sl', 'hsb', 'dsb', 'csb'],
    'Arab' => ['bs']
);

# Main function for identifying Slavic languages
sub identify_slavic_language {
    my ($text, $always_show_script, $show_confidence) = @_;
    
    # Set default values for parameters
    $always_show_script //= 0;
    $show_confidence //= 0;
    
    # Ensure input text is UTF-8 encoded
    $text = decode('UTF-8', $text) unless is_utf8($text);
    
    # Clean and normalize text for analysis
    $text =~ s/[^\p{L}\p{M}\s]//g;
    $text =~ s/\s+/ /g;
    $text = substr($text, 0, 10000) if length($text) > 10000; # Limit size for performance
    
    # Check if text contains any letters
    return "und-Zyyy" if $text !~ /\p{L}/;
    
    # Step 1: Identify the writing system (script)
    my $script = detect_script($text);
    
    # If script couldn't be identified, return unknown
    return "und-Zyyy" if $script eq 'Zyyy';
    
    # Get letter frequencies for language identification
    my $sample = length($text) > 2000 ? substr($text, 0, 2000) : $text;
    my %letter_stats = get_letter_frequencies($sample);
    
    # Step 2: Try to identify the specific Slavic language
    my ($lang, $variant, $confidence) = identify_specific_language($sample, $script, \%letter_stats);
    
    # Step 3: If specific language identified, return language-script tag with variant if present
    if ($lang ne 'und') {
        return format_language_tag($lang, $script, $variant, $always_show_script, $confidence, $show_confidence);
    }
    
    # Step 4: If specific language not identified, try to identify Slavic language group
    my $group = identify_slavic_group($sample, $script, \%letter_stats);
    
    # Step 5: If language group identified, return group with script
    if ($group) {
        return $show_confidence ? "$group-$script (confidence: 0)" : "$group-$script";
    }
    
    # Step 6: If only script identified, return unknown language with script
    return $show_confidence ? "und-$script (confidence: 0)" : "und-$script";
}

# Helper function to detect script - optimized with pre-compiled regexes
sub detect_script {
    my $text = shift;
    
    # Use a sample for faster detection
    my $sample = length($text) > 1000 ? substr($text, 0, 1000) : $text;
    
    # Count occurrences with optimized syntax (one-liners)
    my $cyrillic_count = () = $sample =~ /$CYRILLIC_RE/g;
    my $latin_count = () = $sample =~ /$LATIN_RE/g;
    my $glagolitic_count = () = $sample =~ /$GLAGOLITIC_RE/g;
    my $arabic_count = () = $sample =~ /$ARABIC_RE/g;
    
    # Determine dominant script - using computed counts directly
    if ($glagolitic_count > $cyrillic_count && $glagolitic_count > $latin_count && $glagolitic_count > $arabic_count) {
        return 'Glag';
    } 
    
    if ($cyrillic_count > $latin_count && $cyrillic_count > $glagolitic_count && $cyrillic_count > $arabic_count) {
        # Check if this is the Old Church Slavonic variant of Cyrillic
        my $cyrs_count = () = $sample =~ /$CYRS_RE/g;
        return ($cyrs_count * 20 > $cyrillic_count) ? 'Cyrs' : 'Cyrl';
    } 
    
    if ($latin_count > $cyrillic_count && $latin_count > $glagolitic_count && $latin_count > $arabic_count) {
        return 'Latn';
    } 
    
    if ($arabic_count > $cyrillic_count && $arabic_count > $latin_count && $arabic_count > $glagolitic_count) {
        return 'Arab';
    }
    
    # Default to Common script if no clear dominance
    return 'Zyyy';
}

# Optimized function to calculate letter frequencies
sub get_letter_frequencies {
    my $text = shift;
    
    my %freq;
    my $total_letters = 0;
    
    # Count each letter - use more efficient regex approach
    while ($text =~ /(\p{L})/g) {
        $freq{$1}++;
        $total_letters++;
    }
    
    # Convert to percentages - only if we have letters
    if ($total_letters > 0) {
        foreach my $letter (keys %freq) {
            $freq{$letter} = ($freq{$letter} / $total_letters) * 100;
        }
    }
    
    return %freq;
}



# Identify specific Slavic language - optimized with early returns and focused checks
sub identify_specific_language {
    my ($sample, $script, $letter_stats_ref) = @_;
    
    # Only check languages that match the script
    my @langs_to_check = exists $SCRIPT_TO_LANGS{$script} ? @{$SCRIPT_TO_LANGS{$script}} : ();
    
    # Track candidates with their scores
    my %candidates;
    my $highest_score = -1;
    my $best_lang = 'und';
    
    # Check each language and calculate a confidence score
    foreach my $lang (@langs_to_check) {
        my $score = calculate_language_score($sample, $letter_stats_ref, $lang);
        
        # If score is above threshold, add to candidates
        if ($score > 0) {
            $candidates{$lang} = $score;
            
            # Track highest score for early termination possibilities
            if ($score > $highest_score) {
                $highest_score = $score;
                $best_lang = $lang;
            }
        }
    }
    
    # If we have candidates, return the one with highest score
    if (%candidates) {
        # Special handling for pre-revolutionary Russian
        if ($best_lang eq 'ru-pre') {
            # Additional check for hard sign endings after consonants
            if (check_hard_sign_endings($sample)) {
                return ('ru', 'petr1708', $highest_score + 20); # Add bonus to score
            }
            return ('ru', 'petr1708', $highest_score);
        }
        # Normal case
        return ($best_lang, '', $highest_score);
    }
    
    # No specific language could be identified
    return ('und', '', 0);
}

# New function to check for hard sign endings after consonants in pre-revolutionary Russian
sub check_hard_sign_endings {
    my $text = shift;
    
    # Split into words
    my @words = split /\s+/, $text;
    
    my $consonant_ending_count = 0;
    my $hard_sign_ending_count = 0;
    
    foreach my $word (@words) {
        # Skip very short words and non-Cyrillic
        next if length($word) < 2 || $word !~ /$CYRILLIC_RE/;
        
        # Check if word ends with a consonant or hard sign
        if ($word =~ /$CYRILLIC_CONSONANTS_RE\z/) {
            $consonant_ending_count++;
        }
        elsif ($word =~ /ъ\z/) {
            $hard_sign_ending_count++;
            $consonant_ending_count++; # Also count as consonant-ending
        }
    }
    
    # Return true if we have enough words to analyze and at least 50% of
    # consonant-ending words end with a hard sign
    return 0 if $consonant_ending_count < 10; # Need sufficient sample
    
    my $ratio = $hard_sign_ending_count / $consonant_ending_count;
    return $ratio > 0.5; # Return true if more than 50% of consonant-ending words have hard sign
}

# Calculate a confidence score for language match - optimized for speed
sub calculate_language_score {
    my ($text, $letter_stats_ref, $lang) = @_;
    
    # Skip if language not defined
    return 0 unless exists $DISTINCTIVE_LETTERS{$lang};
    
    # Count positive markers - use optimized approach
    my $positive_count = 0;
    foreach my $letter (@{$DISTINCTIVE_LETTERS{$lang}{positive}}) {
        if ($text =~ /$letter/) {
            $positive_count++;
        }
    }
    
    # Early return if minimum positive requirement not met
    return 0 if $positive_count < $DISTINCTIVE_LETTERS{$lang}{min_positive};
    
    # Calculate frequency of negative markers - use optimized tracking
    my $negative_freq = 0;
    my %seen_chars;
    
    foreach my $letter (@{$DISTINCTIVE_LETTERS{$lang}{negative}}) {
        next if exists $seen_chars{$letter};
        $seen_chars{$letter} = 1;
        
        $negative_freq += $letter_stats_ref->{$letter} || 0;
    }
    
    # Early return if negative frequency too high
    return 0 if $negative_freq > $DISTINCTIVE_LETTERS{$lang}{max_negative_pct};
    
    # Calculate a basic score
    my $score = $positive_count * 10 - $negative_freq;
    
    # Add bonuses for pattern matches if applicable
    if (exists $DISTINCTIVE_LETTERS{$lang}{patterns}) {
        # Optimize pattern matching based on language
        if ($lang eq 'cu-old') {
            # Higher bonus for Old Church Slavonic patterns
            foreach my $pattern (@{$DISTINCTIVE_LETTERS{$lang}{patterns}}) {
                my $escaped_pattern = quotemeta($pattern);
                if ($text =~ /$escaped_pattern/i) {
                    $score += 15;
                }
            }
        }
        elsif ($lang eq 'bg') {
            # Bulgarian patterns - count occurrences efficiently
            my $pattern_matches = 0;
            foreach my $pattern (@{$DISTINCTIVE_LETTERS{$lang}{patterns}}) {
                my $escaped_pattern = quotemeta($pattern);
                my $count = () = $text =~ /$escaped_pattern/gi;
                $pattern_matches += $count;
            }
            
            # Add capped bonus based on matches
            $score += ($pattern_matches > 10) ? 50 : $pattern_matches * 5;
        }
        elsif ($lang eq 'cu') {
            # Church Slavonic patterns
            foreach my $pattern (@{$DISTINCTIVE_LETTERS{$lang}{patterns}}) {
                my $escaped_pattern = quotemeta($pattern);
                if ($text =~ /$escaped_pattern/i) {
                    $score += 10;
                }
            }
            
            # Additional bonus for typical Church Slavonic grammatical constructions
            if ($text =~ /(\p{L}+)а́го\b/i || $text =~ /(\p{L}+)о́му\b/i || 
                $text =~ /(\p{L}+)ѣ́мъ\b/i || $text =~ /(\p{L}+)е́нїе/i) {
                $score += 20;
            }
        }
        else {
            # Generic pattern handling for other languages - combined approach
            my $pattern_count = 0;
            foreach my $pattern (@{$DISTINCTIVE_LETTERS{$lang}{patterns}}) {
                my $escaped_pattern = quotemeta($pattern);
                if ($text =~ /$escaped_pattern/i) {
                    $pattern_count++;
                }
            }
            $score += $pattern_count * 5;
        }
    }
    
    # Additional script-specific adjustments
    if ($lang eq 'ru' && $text =~ /[ыэё]/) {
        $score += 15; # Extra weight for highly distinctive Russian characters
    }
    elsif ($lang eq 'uk' && $text =~ /[їєґ]/) {
        $score += 15; # Extra weight for highly distinctive Ukrainian characters
    }
    
    # Special handling for pre-revolutionary Russian - check for hard sign pattern
    if ($lang eq 'ru-pre') {
        # Check if there are words ending in hard sign
        if ($text =~ /\S+ъ(?:\P{L}|$)/i) {
            $score += 10;
        }
    }
    
    return $score;
}

# Identify Slavic language group - with optimized weighted approach
sub identify_slavic_group {
    my ($text, $script, $letter_stats_ref) = @_;
    
    # Define language group identification metrics with weighted approach
    my %group_metrics = (
        'zle' => { # East Slavic
            script => 'Cyrl',
            positive => [qw(ы э і ї є ў ґ)],
            min_positive => 1,
            weight => 10
        },
        'zls' => { # South Slavic
            script => ['Cyrl', 'Latn'],
            positive_cyrl => [qw(ђ љ њ џ ѓ ќ ѕ)],
            positive_latn => [qw(đ)],
            min_positive => 1,
            weight => 10
        },
        'zlw' => { # West Slavic
            script => 'Latn',
            positive => [qw(ą ę ł ń ó ś ź ż ř ě ů ĺ ľ ŕ ô ä)],
            min_positive => 1,
            weight => 10
        }
    );
    
    # Score each group
    my %group_scores;
    
    foreach my $group (keys %group_metrics) {
        # Skip if script doesn't match
        my $script_match = 0;
        
        if (ref $group_metrics{$group}{script} eq 'ARRAY') {
            $script_match = 1 if grep { $_ eq $script } @{$group_metrics{$group}{script}};
        } else {
            $script_match = 1 if $group_metrics{$group}{script} eq $script;
        }
        
        next unless $script_match;
        
        # Count positive markers for this group
        my $positive_count = 0;
        my @positive_markers;
        
        # Select the appropriate positive markers based on script
        if ($script eq 'Cyrl' && exists $group_metrics{$group}{positive_cyrl}) {
            @positive_markers = @{$group_metrics{$group}{positive_cyrl}};
        } elsif ($script eq 'Latn' && exists $group_metrics{$group}{positive_latn}) {
            @positive_markers = @{$group_metrics{$group}{positive_latn}};
        } elsif (exists $group_metrics{$group}{positive}) {
            @positive_markers = @{$group_metrics{$group}{positive}};
        }
        
        # Count positive markers in text
        foreach my $marker (@positive_markers) {
            if ($text =~ /$marker/) {
                $positive_count++;
            }
        }
        
        # Calculate score
        if ($positive_count >= $group_metrics{$group}{min_positive}) {
            $group_scores{$group} = $positive_count * $group_metrics{$group}{weight};
        }
    }
    
    # Return highest scoring group or fallback to general Slavic
    if (%group_scores) {
        my @sorted_groups = sort { $group_scores{$b} <=> $group_scores{$a} } keys %group_scores;
        return $sorted_groups[0];
    }
    
    # Special handling for Glagolitic script
    if ($script eq 'Glag') {
        # Enhanced handling for Glagolitic script, most commonly Old Church Slavonic
        my $glagolitic_cu_score = 0;
        
        # Check for specific Glagolitic character combinations
        if (exists $DISTINCTIVE_LETTERS{'cu-old'}{patterns}) {
            foreach my $pattern (@{$DISTINCTIVE_LETTERS{'cu-old'}{patterns}}) {
                my $escaped_pattern = quotemeta($pattern);
                if ($text =~ /$escaped_pattern/i) {
                    $glagolitic_cu_score += 2;
                }
            }
        }
        
        # Common Glagolitic structures
        if ($text =~ /\x{2C02}\x{2C30}/ || $text =~ /\x{2C18}\x{2C4D}/) {
            $glagolitic_cu_score += 2;
        }
        
        # If score is high enough, identify as Old Church Slavonic
        return 'cu' if $glagolitic_cu_score >= 3;
    }
    
    # Default to general Slavic if no specific group found
    return 'sla';
}

# Format a language tag according to BCP47 - optimized
sub format_language_tag {
    my ($lang, $script, $variant, $always_show_script, $confidence, $show_confidence) = @_;
    
    #There is no separate language code or variant for Church Slavonic in the standard, define with private use variant x-cs for Church Slavonic
    if ($lang eq 'cu'){$lang='cu';$variant='x-cs'}
    
    #There is no "cu-old" in the standard, define with private use variant x-ocs for Old Church Slavonic   
    if ($lang eq 'cu-old'){$lang='cu';$variant='x-ocs'}
    
    my $tag;
    
    # Return language tag without script if it should be suppressed and not explicitly requested
    if (!$always_show_script && exists $SUPPRESS_SCRIPT{$lang} && $SUPPRESS_SCRIPT{$lang} eq $script) {
        $tag = $variant ? "$lang-$variant" : $lang;
    } else {
        # Include the script tag
        $tag = $variant ? "$lang-$script-$variant" : "$lang-$script";
    }
    
    # Add confidence score if requested
    return $show_confidence && defined $confidence ? "$tag $confidence" : $tag;
} 

# Main script execution when run directly (not imported as a library)
if (!caller) {
    # Set I/O encoding to UTF-8
    binmode(STDOUT, ":utf8");
    binmode(STDERR, ":utf8");
    
    # Process command-line arguments
    my $always_show_script = 0;
    my $show_confidence = 0;
  #  my $run_tests = 0;
    
    foreach my $arg (@ARGV) {
        if ($arg eq "-s") {
            $always_show_script = 1;
        } elsif ($arg eq "-v") {
            $show_confidence = 1;
 #       } elsif ($arg eq "-t") {
 #           $run_tests = 1;
        } elsif ($arg eq "-h") {
            print_usage();
            exit 0;
        } elsif ($arg =~ /^-/) {
            print STDERR "Error: Unknown option '$arg'\n\n";
            print_usage();
            exit 1;
        } else {
            print STDERR "Error: Direct text input is not supported.\n";
            print STDERR "Please pipe text to the script instead.\n\n";
            print_usage();
            exit 1;
        }
    }
    
    # Check if there's input on STDIN
    my $has_stdin = -t STDIN ? 0 : 1;
    if (!$has_stdin) {
        print STDERR "Error: No input provided via stdin.\n";
        print STDERR "Please pipe text to the script.\n\n";
        print_usage();
        exit 1;
    }
    
    # Read from stdin with UTF-8 encoding
    binmode(STDIN, ":utf8");
    my $text = do { local $/; <STDIN> };
    
    # Skip processing if no text provided
    if (!$text || $text !~ /\S/) {
        print STDERR "Error: Input is empty or contains only whitespace.\n\n";
        print_usage();
        exit 1;
    }
    
    # Call the function with text and flags
    my $lang = identify_slavic_language($text, $always_show_script, $show_confidence);
    
    # Print the result to stdout
    print "$lang\n";
}

# Helper function to print usage instructions
sub print_usage {
    print "Usage: $0 [options]\n";
    print "Pipe text to stdin for analysis\n\n";
    print "Examples:\n";
    print "  echo \"Привет мир\" | $0\n";
    print "  echo \"Привет мир\" | $0 -v -s\n";
    print "  cat text_file.txt | $0\n\n";
    print "Options:\n";
    
    print "  -s            Always show script tag even when it's the default\n";
    print "  -v            Show confidence scores for language identification\n";
    print "  -h            Display this help message\n";
}

1;
