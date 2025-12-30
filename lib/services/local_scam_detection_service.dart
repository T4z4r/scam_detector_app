import '../models/scam_result.dart';

class LocalScamDetectionService {
  // Tanzania-specific scam patterns
  static final List<Map<String, dynamic>> _scamPatterns = [
    // M-Pesa Scams
    {
      'pattern': r'mpesa\s+reversal',
      'keywords': ['mpesa', 'reversal', 'ksh', 'click', 'confirm', 'pin'],
      'language': 'both',
      'confidence': 0.9,
      'reason': 'M-Pesa reversal scam - common fraud tactic in East Africa',
      'alert':
          'Never share your M-Pesa PIN or click suspicious links claiming reversals'
    },
    {
      'pattern': r'mpesa\s+suspended',
      'keywords': ['mpesa', 'suspended', 'account', 'restore'],
      'language': 'both',
      'confidence': 0.85,
      'reason': 'M-Pesa account suspension scam',
      'alert':
          'Genuine M-Pesa issues are handled through official channels only'
    },

    // Tigo Money (Godi) Scams
    {
      'pattern': r'godi\s+reversal',
      'keywords': ['godi', 'reversal', 'pending', 'account', 'enter', 'pin'],
      'language': 'both',
      'confidence': 0.88,
      'reason': 'Tigo Money (Godi) reversal scam',
      'alert': 'Tigo Money reversals are never processed via SMS'
    },
    {
      'pattern': r'tigo\s+money',
      'keywords': ['tigo', 'money', 'urgent', 'confirm'],
      'language': 'both',
      'confidence': 0.7,
      'reason': 'Tigo Money related suspicious message',
      'alert': 'Verify Tigo Money requests through official customer care'
    },

    // Loan Scams
    {
      'pattern': r'loan\s+approved',
      'keywords': ['loan', 'approved', 'instantly', 'apply', 'www', 'com'],
      'language': 'both',
      'confidence': 0.8,
      'reason': 'Fake loan approval scam',
      'alert': 'Legitimate loans require proper application and verification'
    },
    {
      'pattern': r'flex\s+credit',
      'keywords': ['flex', 'credit', 'approved', 'get', 'tsh', 'instantly'],
      'language': 'both',
      'confidence': 0.75,
      'reason': 'Flex Credit loan scam',
      'alert': 'Verify loan offers through official banking channels'
    },

    // Cryptocurrency Scams
    {
      'pattern': r'crypto\s+investment',
      'keywords': ['crypto', 'investment', 'guaranteed', 'returns', 'register'],
      'language': 'both',
      'confidence': 0.85,
      'reason': 'Cryptocurrency investment scam',
      'alert':
          'No investment can guarantee returns - this is a common scam tactic'
    },

    // SIM Swap Scams
    {
      'pattern': r'sim\s+swap',
      'keywords': ['sim', 'swap', 'detected', 'enter', 'pin', 'cancel'],
      'language': 'both',
      'confidence': 0.9,
      'reason': 'SIM swap fraud attempt',
      'alert': 'Never share SIM PIN or personal details via SMS'
    },
    {
      'pattern': r'number\s+suspended',
      'keywords': ['number', 'suspended', 'verify', 'identity'],
      'language': 'both',
      'confidence': 0.8,
      'reason': 'Number suspension scam',
      'alert': 'Number issues are handled through official carrier channels'
    },

    // Government Relief Scams (Swahili)
    {
      'pattern': r'huduma\s+za\s+serikali',
      'keywords': ['huduma', 'za', 'serikali', 'malipo', 'ruzuku', 'bonyeza'],
      'language': 'swahili',
      'confidence': 0.85,
      'reason': 'Swahili government relief fund scam',
      'alert':
          'Government relief funds are distributed through official channels only'
    },

    // Job Offer Scams (Swahili)
    {
      'pattern': r'kazi\s+za\s+ajira',
      'keywords': ['kazi', 'za', 'ajira', 'uongozi', 'mshahara', 'wasiliana'],
      'language': 'swahili',
      'confidence': 0.75,
      'reason': 'Swahili job offer scam',
      'alert': 'Legitimate job offers come through proper recruitment channels'
    },

    // Bank Security Scams
    {
      'pattern': r'bank\s+account\s+suspended',
      'keywords': ['bank', 'account', 'suspended', 'suspicious', 'activity'],
      'language': 'both',
      'confidence': 0.8,
      'reason': 'Bank security scam',
      'alert': 'Banks never ask for sensitive information via SMS'
    },

    // Technical Support Scams
    {
      'pattern': r'computer\s+infected',
      'keywords': ['computer', 'infected', 'viruses', 'technical', 'support'],
      'language': 'both',
      'confidence': 0.85,
      'reason': 'Technical support scam',
      'alert': 'Never provide remote access to unknown technical support agents'
    },

    // Social Engineering
    {
      'pattern': r'emergency',
      'keywords': ['emergency', 'hospital', 'money', 'immediately', 'critical'],
      'language': 'both',
      'confidence': 0.7,
      'reason': 'Social engineering scam using emotional manipulation',
      'alert':
          'Verify emergency requests through direct contact with family/friends'
    },

    // General Suspicious Patterns
    {
      'pattern': r'click\s+here',
      'keywords': ['click', 'here', 'link', 'bit.ly', 'tinyurl'],
      'language': 'both',
      'confidence': 0.6,
      'reason': 'Suspicious link pattern',
      'alert': 'Avoid clicking links from unknown senders'
    },
    {
      'pattern': r'win\s+\$\d+',
      'keywords': ['win', 'won', 'prize', 'lottery', 'congratulations'],
      'language': 'both',
      'confidence': 0.8,
      'reason': 'Prize/lottery scam',
      'alert': 'You cannot win prizes you never entered'
    },
    {
      'pattern': r'urgent\s+action\s+required',
      'keywords': ['urgent', 'action', 'required', 'immediately', 'expires'],
      'language': 'both',
      'confidence': 0.65,
      'reason': 'Urgency-based scam tactic',
      'alert': 'Scammers often create false urgency to pressure victims'
    },

    // Additional patterns from Postman collection test cases
    {
      'pattern': r'bank\s+account\s+(temporarily\s+)?suspended',
      'keywords': [
        'bank',
        'account',
        'suspended',
        'suspicious',
        'activity',
        'temporarily'
      ],
      'language': 'both',
      'confidence': 0.85,
      'reason': 'Bank account suspension scam',
      'alert': 'Banks never ask for sensitive information via SMS'
    },
    {
      'pattern': r'computer\s+(has\s+been\s+)?infected',
      'keywords': [
        'computer',
        'infected',
        'viruses',
        'technical',
        'support',
        'data',
        'loss'
      ],
      'language': 'both',
      'confidence': 0.9,
      'reason': 'Technical support scam',
      'alert': 'Never provide remote access to unknown technical support agents'
    },
    {
      'pattern': r'emergency.*(mother|father|family|hospital)',
      'keywords': [
        'emergency',
        'hospital',
        'money',
        'immediately',
        'critical',
        'mother',
        'father'
      ],
      'language': 'both',
      'confidence': 0.8,
      'reason': 'Social engineering scam using emotional manipulation',
      'alert':
          'Verify emergency requests through direct contact with family/friends'
    },
    {
      'pattern': r'congratulations.*\$?\d+',
      'keywords': ['congratulations', 'won', 'prize', '🎉', '📱', '💰'],
      'language': 'both',
      'confidence': 0.85,
      'reason': 'Prize scam with emojis',
      'alert': 'Be wary of prize notifications with emojis and dollar amounts'
    },
    {
      'pattern': r'M-Pesa.*reversal.*Ksh',
      'keywords': [
        'mpesa',
        'reversal',
        'ksh',
        'bonyeza',
        'pin',
        'muhimu',
        'ichezwe'
      ],
      'language': 'both',
      'confidence': 0.92,
      'reason': 'M-Pesa reversal scam in mixed English/Swahili',
      'alert': 'Never share your M-Pesa PIN regardless of language used'
    }
  ];

  // Check if text is in Swahili
  static bool _isSwahili(String text) {
    final swahiliWords = [
      'hii',
      'hayo',
      'hizo',
      'bonyeza',
      'wasiliana',
      'ushirikiano',
      'kazi',
      'ajira'
    ];
    return swahiliWords.any((word) => text.toLowerCase().contains(word));
  }

  // Calculate confidence score based on multiple factors
  static double _calculateConfidence(
      String text, List<Map<String, dynamic>> matchedPatterns) {
    if (matchedPatterns.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    double maxConfidence = 0.0;

    for (final pattern in matchedPatterns) {
      final confidence = pattern['confidence'] as double;
      totalConfidence += confidence;
      if (confidence > maxConfidence) {
        maxConfidence = confidence;
      }
    }

    // Average confidence with boost for multiple matches
    final averageConfidence = totalConfidence / matchedPatterns.length;
    final matchCount = matchedPatterns.length;

    // Boost confidence if multiple patterns match
    final confidenceBoost = matchCount > 1 ? (matchCount - 1) * 0.1 : 0.0;

    return (averageConfidence + confidenceBoost).clamp(0.0, 1.0);
  }

  // Main detection method
  static ScamResult detectScam(String text, String sender) {
    final cleanText = text.trim().toLowerCase();
    final matchedPatterns = <Map<String, dynamic>>[];

    // Check each pattern
    for (final pattern in _scamPatterns) {
      final keywords = pattern['keywords'] as List<String>;
      final language = pattern['language'] as String;

      // Skip if language doesn't match (for language-specific patterns)
      if (language == 'swahili' && !_isSwahili(cleanText)) {
        continue;
      }
      if (language == 'english' && _isSwahili(cleanText)) {
        continue;
      }

      // Check if all keywords are present
      final allKeywordsPresent = keywords
          .every((keyword) => cleanText.contains(keyword.toLowerCase()));

      if (allKeywordsPresent) {
        matchedPatterns.add(pattern);
      }
    }

    // Determine result
    if (matchedPatterns.isEmpty) {
      return ScamResult(
        label: 'legitimate',
        confidence: 0.95,
        reason: 'No scam patterns detected in message',
        alert: 'This appears to be a legitimate message',
      );
    }

    final confidence = _calculateConfidence(cleanText, matchedPatterns);
    final primaryPattern = matchedPatterns.first;

    return ScamResult(
      label: confidence > 0.6 ? 'scam' : 'suspicious',
      confidence: confidence * 100,
      reason: primaryPattern['reason'] as String,
      alert: primaryPattern['alert'] as String,
    );
  }

  // Get statistics about detected patterns
  static Map<String, int> getPatternStatistics(String text) {
    final cleanText = text.trim().toLowerCase();
    final stats = <String, int>{};

    for (final pattern in _scamPatterns) {
      final keywords = pattern['keywords'] as List<String>;
      final matches = keywords
          .where((keyword) => cleanText.contains(keyword.toLowerCase()))
          .length;

      if (matches > 0) {
        final category = _getPatternCategory(pattern);
        stats[category] = (stats[category] ?? 0) + matches;
      }
    }

    return stats;
  }

  static String _getPatternCategory(Map<String, dynamic> pattern) {
    final keywords = pattern['keywords'] as List<String>;
    final text = keywords.join(' ');

    if (text.contains('mpesa') || text.contains('godi')) return 'Mobile Money';
    if (text.contains('loan') || text.contains('credit')) return 'Financial';
    if (text.contains('crypto') || text.contains('investment')) {
      return 'Investment';
    }
    if (text.contains('job') || text.contains('kazi')) return 'Employment';
    if (text.contains('bank') || text.contains('account')) return 'Banking';
    if (text.contains('government') || text.contains('serikali')) {
      return 'Government';
    }

    return 'General';
  }
}
