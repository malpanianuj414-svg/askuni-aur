const config = require('../config/env');

const SUPPORTED_LANGUAGES = ['en', 'hi', 'mr', 'ta', 'bn', 'pa'];

const LANGUAGE_LABELS = {
  en: 'English',
  hi: 'Hindi (à¤¹à¤¿à¤¨à¥à¤¦à¥€)',
  mr: 'Marathi (à¤®à¤°à¤¾à¤ à¥€)',
  ta: 'Tamil (à®¤à®®à®¿à®´à¯)',
  bn: 'Bengali (à¦¬à¦¾à¦‚à¦²à¦¾)',
  pa: 'Punjabi (à¨ªà©°à¨œà¨¾à¨¬à©€)'
};

// Phrase & vocabulary dictionary for realistic offline/mock regional translation
const PHRASE_DICTIONARY = {
  hi: {
    prefix: '[à¤¹à¤¿à¤¨à¥à¤¦à¥€ à¤…à¤¨à¥à¤µà¤¾à¤¦] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'à¤à¤®à¤¿à¤Ÿà¥€ à¤µà¤¿à¤¶à¥à¤µà¤µà¤¿à¤¦à¥à¤¯à¤¾à¤²à¤¯ à¤°à¤¾à¤œà¤¸à¥à¤¥à¤¾à¤¨ à¤•à¥‡ à¤†à¤§à¤¿à¤•à¤¾à¤°à¤¿à¤• à¤°à¤¿à¤•à¥‰à¤°à¥à¤¡ à¤•à¥‡ à¤…à¤¨à¥à¤¸à¤¾à¤°:'],
      [/I could not find verified information about that/gi, 'à¤®à¥à¤à¥‡ à¤‡à¤¸à¤•à¥‡ à¤¬à¤¾à¤°à¥‡ à¤®à¥‡à¤‚ à¤¸à¤¤à¥à¤¯à¤¾à¤ªà¤¿à¤¤ à¤œà¤¾à¤¨à¤•à¤¾à¤°à¥€ à¤¨à¤¹à¥€à¤‚ à¤®à¤¿à¤²à¥€'],
      [/Please contact the Amity University Rajasthan Administrative \/ Academic Office/gi, 'à¤•à¥ƒà¤ªà¤¯à¤¾ à¤à¤®à¤¿à¤Ÿà¥€ à¤µà¤¿à¤¶à¥à¤µà¤µà¤¿à¤¦à¥à¤¯à¤¾à¤²à¤¯ à¤°à¤¾à¤œà¤¸à¥à¤¥à¤¾à¤¨ à¤•à¥‡ à¤ªà¥à¤°à¤¶à¤¾à¤¸à¤¨à¤¿à¤• / à¤¶à¥ˆà¤•à¥à¤·à¤£à¤¿à¤• à¤•à¤¾à¤°à¥à¤¯à¤¾à¤²à¤¯ à¤¸à¥‡ à¤¸à¤‚à¤ªà¤°à¥à¤• à¤•à¤°à¥‡à¤‚'],
      [/End-Semester Theory Examinations/gi, 'à¤¸à¥‡à¤®à¥‡à¤¸à¥à¤Ÿà¤° à¤…à¤‚à¤¤ à¤¸à¤¿à¤¦à¥à¤§à¤¾à¤‚à¤¤ à¤ªà¤°à¥€à¤•à¥à¤·à¤¾à¤à¤‚'],
      [/B\.Tech CSE/gi, 'à¤¬à¥€.à¤Ÿà¥‡à¤• à¤¸à¥€à¤à¤¸à¤ˆ'],
      [/tuition fee/gi, 'à¤¶à¤¿à¤•à¥à¤·à¤£ à¤¶à¥à¤²à¥à¤•'],
      [/hostel/gi, 'à¤›à¤¾à¤¤à¥à¤°à¤¾à¤µà¤¾à¤¸'],
      [/scholarship/gi, 'à¤›à¤¾à¤¤à¥à¤°à¤µà¥ƒà¤¤à¥à¤¤à¤¿'],
      [/attendance/gi, 'à¤‰à¤ªà¤¸à¥à¤¥à¤¿à¤¤à¤¿'],
      [/timetable/gi, 'à¤¸à¤®à¤¯-à¤¸à¤¾à¤°à¤£à¥€'],
      [/library/gi, 'à¤ªà¥à¤¸à¥à¤¤à¤•à¤¾à¤²à¤¯']
    ]
  },
  mr: {
    prefix: '[à¤®à¤°à¤¾à¤ à¥€ à¤­à¤¾à¤·à¤¾à¤‚à¤¤à¤°] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'à¤…à¥…à¤®à¤¿à¤Ÿà¥€ à¤µà¤¿à¤¦à¥à¤¯à¤¾à¤ªà¥€à¤  à¤°à¤¾à¤œà¤¸à¥à¤¥à¤¾à¤¨à¤šà¥à¤¯à¤¾ à¤…à¤§à¤¿à¤•à¥ƒà¤¤ à¤¨à¥‹à¤‚à¤¦à¥€à¤¨à¥à¤¸à¤¾à¤°:'],
      [/I could not find verified information about that/gi, 'à¤®à¤²à¤¾ à¤¯à¤¾à¤¬à¤¦à¥à¤¦à¤² à¤…à¤§à¤¿à¤•à¥ƒà¤¤ à¤®à¤¾à¤¹à¤¿à¤¤à¥€ à¤¸à¤¾à¤ªà¤¡à¤²à¥€ à¤¨à¤¾à¤¹à¥€'],
      [/tuition fee/gi, 'à¤¶à¤¿à¤•à¥à¤·à¤£ à¤¶à¥à¤²à¥à¤•'],
      [/hostel/gi, 'à¤µà¤¸à¤¤à¤¿à¤—à¥ƒà¤¹'],
      [/scholarship/gi, 'à¤¶à¤¿à¤·à¥à¤¯à¤µà¥ƒà¤¤à¥à¤¤à¥€'],
      [/attendance/gi, 'à¤‰à¤ªà¤¸à¥à¤¥à¤¿à¤¤à¥€']
    ]
  },
  ta: {
    prefix: '[à®¤à®®à®¿à®´à¯ à®®à¯Šà®´à®¿à®ªà¯†à®¯à®°à¯à®ªà¯à®ªà¯] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'à®…à®®à®¿à®Ÿà¯à®Ÿà®¿ à®ªà®²à¯à®•à®²à¯ˆà®•à¯à®•à®´à®•à®®à¯ à®°à®¾à®œà®¸à¯à®¤à®¾à®©à¯ à®…à®¤à®¿à®•à®¾à®°à®ªà¯à®ªà¯‚à®°à¯à®µ à®ªà®¤à®¿à®µà¯à®•à®³à®¿à®©à¯à®ªà®Ÿà®¿:'],
      [/I could not find verified information about that/gi, 'à®‡à®¤à¯ à®•à¯à®±à®¿à®¤à¯à®¤ à®šà®°à®¿à®ªà®¾à®°à¯à®•à¯à®•à®ªà¯à®ªà®Ÿà¯à®Ÿ à®¤à®•à®µà®²à¯ à®•à®¿à®Ÿà¯ˆà®•à¯à®•à®µà®¿à®²à¯à®²à¯ˆ'],
      [/tuition fee/gi, 'à®•à®²à¯à®µà®¿à®•à¯ à®•à®Ÿà¯à®Ÿà®£à®®à¯'],
      [/hostel/gi, 'à®µà®¿à®Ÿà¯à®¤à®¿'],
      [/scholarship/gi, 'à®‰à®¤à®µà®¿à®¤à¯à®¤à¯Šà®•à¯ˆ']
    ]
  },
  bn: {
    prefix: '[à¦¬à¦¾à¦‚à¦²à¦¾ à¦…à¦¨à§à¦¬à¦¾à¦¦] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'à¦…à§à¦¯à¦¾à¦®à¦¿à¦Ÿà¦¿ à¦¬à¦¿à¦¶à§à¦¬à¦¬à¦¿à¦¦à§à¦¯à¦¾à¦²à¦¯à¦¼ à¦°à¦¾à¦œà¦¸à§à¦¥à¦¾à¦¨à§‡à¦° à¦…à¦«à¦¿à¦¸à¦¿à¦¯à¦¼à¦¾à¦² à¦°à§‡à¦•à¦°à§à¦¡ à¦…à¦¨à§à¦¯à¦¾à¦¯à¦¼à§€:'],
      [/I could not find verified information about that/gi, 'à¦†à¦®à¦¿ à¦à¦‡ à¦¬à¦¿à¦·à¦¯à¦¼à§‡ à¦¯à¦¾à¦šà¦¾à¦‡à¦•à§ƒà¦¤ à¦¤à¦¥à§à¦¯ à¦–à§à¦à¦œà§‡ à¦ªà¦¾à¦‡à¦¨à¦¿'],
      [/tuition fee/gi, 'à¦Ÿà¦¿à¦‰à¦¶à¦¨ à¦«à¦¿'],
      [/hostel/gi, 'à¦¹à§‹à¦¸à§à¦Ÿà§‡à¦²'],
      [/scholarship/gi, 'à¦¬à§ƒà¦¤à§à¦¤à¦¿']
    ]
  },
  pa: {
    prefix: '[à¨ªà©°à¨œà¨¾à¨¬à©€ à¨…à¨¨à©à¨µà¨¾à¨¦] ',
    replacements: [
      [/Based on official Amity University Rajasthan records:/gi, 'à¨à¨®à¨¿à¨Ÿà©€ à¨¯à©‚à¨¨à©€à¨µà¨°à¨¸à¨¿à¨Ÿà©€ à¨°à¨¾à¨œà¨¸à¨¥à¨¾à¨¨ à¨¦à©‡ à¨…à¨§à¨¿à¨•à¨¾à¨°à¨¤ à¨°à¨¿à¨•à¨¾à¨°à¨¡ à¨…à¨¨à©à¨¸à¨¾à¨°:'],
      [/I could not find verified information about that/gi, 'à¨®à©ˆà¨¨à©‚à©° à¨‡à¨¸ à¨¬à¨¾à¨°à©‡ à¨ªà©à¨°à¨®à¨¾à¨£à¨¿à¨¤ à¨œà¨¾à¨£à¨•à¨¾à¨°à©€ à¨¨à¨¹à©€à¨‚ à¨®à¨¿à¨²à©€'],
      [/tuition fee/gi, 'à¨Ÿà¨¿à¨Šà¨¸à¨¼à¨¨ à¨«à©€à¨¸'],
      [/hostel/gi, 'à¨¹à©‹à¨¸à¨Ÿà¨²'],
      [/scholarship/gi, 'à¨µà¨œà¨¼à©€à¨«à¨¼à¨¾']
    ]
  }
};

class TranslationServiceAdapter {
  constructor() {
    this.simulateFailure = false;
  }

  detectLanguage(text) {
    const s = String(text || '');
    if (/[\u0900-\u097F]/.test(s)) {
      // Distinguish Marathi markers vs Hindi Devanagari
      if (/(à¤†à¤¹à¥‡|à¤•à¤¾à¤¯|à¤•à¤¿à¤¤à¥€|à¤•à¤§à¥€|à¤®à¤¾à¤¹à¤¿à¤¤à¥€)/.test(s)) return 'mr';
      return 'hi';
    }
    if (/[\u0B80-\u0BFF]/.test(s)) return 'ta';
    if (/[\u0980-\u09FF]/.test(s)) return 'bn';
    if (/[\u0A00-\u0A7F]/.test(s)) return 'pa';
    return 'en';
  }

  normalizeQueryToEnglish(text) {
    const s = String(text || '');
    const map = [
      [/à¤ªà¤°à¥€à¤•à¥à¤·à¤¾|à¤à¤—à¥à¤œà¤¾à¤®|à¤‡à¤®à¥à¤¤à¤¿à¤¹à¤¾à¤¨|à¤ªà¤°à¤¿à¤•à¥à¤·à¤¾|à®¤à¯‡à®°à¯à®µà¯|à¦ªà¦°à§€à¦•à§à¦·à¦¾|à¨ªà©à¨°à©€à¨–à¨¿à¨†/gi, 'exam schedule dates'],
      [/à¤«à¥€à¤¸|à¤¶à¥à¤²à¥à¤•|à®•à®Ÿà¯à®Ÿà®£à®®à¯|à¦«à¦¿|à¨«à©€à¨¸/gi, 'fee structure tuition'],
      [/à¤¹à¥‰à¤¸à¥à¤Ÿà¤²|à¤›à¤¾à¤¤à¥à¤°à¤¾à¤µà¤¾à¤¸|à¤µà¤¸à¤¤à¤¿à¤—à¥ƒà¤¹|à®µà®¿à®Ÿà¯à®¤à®¿|à¦¹à§‹à¦¸à§à¦Ÿà§‡à¦²|à¨¹à©‹à¨¸à¨Ÿà¨²/gi, 'hostel accommodation'],
      [/à¤›à¤¾à¤¤à¥à¤°à¤µà¥ƒà¤¤à¥à¤¤à¤¿|à¤¸à¥à¤•à¥‰à¤²à¤°à¤¶à¤¿à¤ª|à¤¶à¤¿à¤·à¥à¤¯à¤µà¥ƒà¤¤à¥à¤¤à¥€|à®‰à®¤à®µà®¿à®¤à¯à®¤à¯Šà®•à¯ˆ|à¦¬à§ƒà¦¤à§à¦¤à¦¿|à¨µà¨œà¨¼à©€à¨«à¨¼à¨¾/gi, 'scholarship merit'],
      [/à¤Ÿà¤¾à¤‡à¤®à¤Ÿà¥‡à¤¬à¤²|à¤¸à¤®à¤¯ à¤¸à¤¾à¤°à¤£à¥€|à¤¸à¤®à¤¯-à¤¸à¤¾à¤°à¤£à¥€|à®•à®¾à®² à®…à®Ÿà¯à®Ÿà®µà®£à¯ˆ|à¦¸à¦®à¦¯à¦¼à¦¸à§‚à¦šà§€|à¨¸à¨®à¨¾à¨‚ à¨¸à¨¾à¨°à¨£à©€/gi, 'timetable schedule classes'],
      [/à¤ªà¥à¤°à¤µà¥‡à¤¶|à¤à¤¡à¤®à¤¿à¤¶à¤¨|à®šà¯‡à®°à¯à®•à¯à®•à¯ˆ|à¦­à¦°à§à¦¤à¦¿|à¨¦à¨¾à¨–à¨²à¨¾/gi, 'admission eligibility'],
      [/à¤‰à¤ªà¤¸à¥à¤¥à¤¿à¤¤à¤¿|à¤…à¤Ÿà¥‡à¤‚à¤¡à¥‡à¤‚à¤¸|à®µà®°à¯à®•à¯ˆ|à¦‰à¦ªà¦¸à§à¦¥à¦¿à¦¤à¦¿|à¨¹à¨¾à¨œà¨¼à¨°à©€/gi, 'attendance rule']
    ];
    let enriched = s;
    for (const [pattern, englishHint] of map) {
      if (pattern.test(s)) {
        enriched += ` ${englishHint}`;
      }
    }
    return enriched;
  }

  async translateText(text, targetLanguage = 'en', supportedLanguages = SUPPORTED_LANGUAGES) {
    const lang = String(targetLanguage || 'en').toLowerCase().trim();

    if (!supportedLanguages.includes(lang)) {
      return {
        translatedText: `${text}\n\n[Notice: Requested language '${targetLanguage}' is not currently supported. Showing response in English.]`,
        effectiveLanguage: 'en',
        unsupportedLanguage: true,
        translationFailed: false
      };
    }

    if (lang === 'en') {
      return {
        translatedText: text,
        effectiveLanguage: 'en',
        unsupportedLanguage: false,
        translationFailed: false
      };
    }

    if (this.simulateFailure) {
      return {
        translatedText: text,
        effectiveLanguage: 'en',
        unsupportedLanguage: false,
        translationFailed: true,
        failureReason: 'Translation service temporarily unavailable; original English response preserved.'
      };
    }

    if (!config.mockMode && config.googleTranslateApiKey) {
      try {
        const url = `https://translation.googleapis.com/language/translate/v2?key=${encodeURIComponent(config.googleTranslateApiKey)}`;
        const resp = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ q: text, target: lang, format: 'text' })
        });
        if (!resp.ok) {
          throw new Error(`Google Translate HTTP ${resp.status}`);
        }
        const data = await resp.json();
        return {
          translatedText: data.data.translations[0].translatedText,
          effectiveLanguage: lang,
          unsupportedLanguage: false,
          translationFailed: false
        };
      } catch (err) {
        return {
          translatedText: text,
          effectiveLanguage: 'en',
          unsupportedLanguage: false,
          translationFailed: true,
          failureReason: err.message
        };
      }
    }

    const pack = PHRASE_DICTIONARY[lang];
    let out = text;
    if (pack) {
      for (const [regex, replacement] of pack.replacements) {
        out = out.replace(regex, replacement);
      }
      out = `${pack.prefix}${out}`;
    }

    return {
      translatedText: out,
      effectiveLanguage: lang,
      unsupportedLanguage: false,
      translationFailed: false
    };
  }

  isHealthy() {
    return !this.simulateFailure;
  }
}

module.exports = { TranslationServiceAdapter, SUPPORTED_LANGUAGES, LANGUAGE_LABELS };