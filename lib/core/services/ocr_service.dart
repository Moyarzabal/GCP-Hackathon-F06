// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  Future<DateTime?> extractExpiryDate(dynamic inputImage) async {
    try {
      // TODO: Re-enable when google_mlkit_text_recognition is available
      // final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      print('OCR service temporarily disabled - google_mlkit_text_recognition not available');
      return null;
      
      // List of possible date patterns to search for
      final datePatterns = [
        // Japanese date formats
        RegExp(r'(\d{4})[年/](\d{1,2})[月/](\d{1,2})[日]?'), // 2024年12月31日 or 2024/12/31
        RegExp(r'(\d{2})[年/](\d{1,2})[月/](\d{1,2})[日]?'), // 24年12月31日
        RegExp(r'令和(\d+)[年](\d{1,2})[月](\d{1,2})[日]?'), // 令和6年12月31日
        RegExp(r'R(\d+)[.](\d{1,2})[.](\d{1,2})'), // R6.12.31
        
        // Western date formats
        RegExp(r'(\d{2})[./](\d{2})[./](\d{4})'), // 31/12/2024 or 31.12.2024
        RegExp(r'(\d{4})[./](\d{2})[./](\d{2})'), // 2024/12/31
        RegExp(r'(\d{2})[./](\d{2})[./](\d{2})'), // 24/12/31
        
        // Keywords to identify expiry dates
        RegExp(r'賞味期限[:：\s]*(.+)'),
        RegExp(r'消費期限[:：\s]*(.+)'),
        RegExp(r'期限[:：\s]*(.+)'),
        RegExp(r'EXP[:：\s]*(.+)', caseSensitive: false),
        RegExp(r'BEST\s*BEFORE[:：\s]*(.+)', caseSensitive: false),
        RegExp(r'USE\s*BY[:：\s]*(.+)', caseSensitive: false),
      ];

      // List<DateTime> foundDates = [];

      // for (TextBlock block in recognizedText.blocks) {
      //   for (TextLine line in block.lines) {
      //     final text = line.text;
      //     
      //     // Check for expiry date keywords first
      //     bool isExpiryLine = false;
      //     for (final keywordPattern in [
      //       RegExp(r'賞味期限'),
      //       RegExp(r'消費期限'),
      //       RegExp(r'期限'),
      //       RegExp(r'EXP', caseSensitive: false),
      //       RegExp(r'BEST\s*BEFORE', caseSensitive: false),
      //       RegExp(r'USE\s*BY', caseSensitive: false),
      //     ]) {
      //       if (keywordPattern.hasMatch(text)) {
      //         isExpiryLine = true;
      //         break;
      //       }
      //     }

      //     // Try to extract dates from the text
      //     for (final pattern in datePatterns) {
      //       final matches = pattern.allMatches(text);
      //       for (final match in matches) {
      //         DateTime? date = _parseDate(match, text);
      //         if (date != null) {
      //           foundDates.add(date);
      //           // If this line contains expiry keywords, prioritize this date
      //           if (isExpiryLine) {
      //             return date;
      //           }
      //         }
      //       }
      //     }
      //   }
      // }

      // // Return the nearest future date if multiple dates found
      // if (foundDates.isNotEmpty) {
      //   final now = DateTime.now();
      //   foundDates.sort((a, b) => a.compareTo(b));
      //   
      //   // Find the first date that's in the future
      //   for (final date in foundDates) {
      //     if (date.isAfter(now.subtract(const Duration(days: 1)))) {
      //       return date;
      //     }
      //   }
      //   
      //   // If no future dates, return the latest date
      //   return foundDates.last;
      // }

      return null;
    } catch (e) {
      print('Error during OCR processing: $e');
      return null;
    }
  }

  DateTime? _parseDate(RegExpMatch match, String fullText) {
    try {
      final groups = match.groups([1, 2, 3]);
      if (groups[0] == null || groups[1] == null || groups[2] == null) {
        return null;
      }

      int year, month, day;

      // Check if it's a Reiwa date (令和)
      if (fullText.contains('令和') || fullText.startsWith('R')) {
        // Convert Reiwa year to Western year (Reiwa 1 = 2019)
        year = 2018 + int.parse(groups[0]!);
        month = int.parse(groups[1]!);
        day = int.parse(groups[2]!);
      } else {
        // Regular date parsing
        String yearStr = groups[0]!;
        
        // Handle 2-digit years
        if (yearStr.length == 2) {
          int twoDigitYear = int.parse(yearStr);
          // Assume 20xx for years 00-50, 19xx for years 51-99
          year = twoDigitYear <= 50 ? 2000 + twoDigitYear : 1900 + twoDigitYear;
        } else {
          year = int.parse(yearStr);
        }
        
        month = int.parse(groups[1]!);
        day = int.parse(groups[2]!);
        
        // Check if day and month might be swapped (for DD/MM/YYYY format)
        if (month > 12 && day <= 12) {
          final temp = month;
          month = day;
          day = temp;
        }
      }

      // Validate the date
      if (year < 2020 || year > 2030) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      return DateTime(year, month, day);
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  Future<String?> extractText(dynamic inputImage) async {
    try {
      // TODO: Re-enable when google_mlkit_text_recognition is available
      // final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      // return recognizedText.text;
      print('OCR text extraction temporarily disabled - google_mlkit_text_recognition not available');
      return null;
    } catch (e) {
      print('Error during text extraction: $e');
      return null;
    }
  }

  void dispose() {
    // _textRecognizer.close();
  }
}