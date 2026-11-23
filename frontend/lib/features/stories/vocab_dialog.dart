import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/story.dart';
import '../../services/event_logger.dart';
import '../../services/speech_service.dart';

const vocabColor = Color(0xFF5B45C9);

/// Kartu arti "kata baru": kata dibacakan beserta artinya.
Future<void> showVocabDialog(BuildContext context, VocabWord v) {
  EventLogger.instance.ui('vocab', {'word': v.word});
  void speak() => SpeechService.instance.speak('${v.word}. Artinya, ${v.meaning}');
  speak();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      contentPadding: const EdgeInsets.fromLTRB(26, 22, 26, 6),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFF1ECFF), shape: BoxShape.circle),
                  child: const Icon(Icons.menu_book_rounded, color: vocabColor, size: 26),
                ),
                const SizedBox(width: 10),
                Text('Kata baru', style: GoogleFonts.fredoka(fontSize: 18, color: AppColors.hint, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              v.word,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 38, fontWeight: FontWeight.w700, color: vocabColor),
            ),
            const SizedBox(height: 8),
            Text(
              v.meaning,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 22, color: AppColors.textDark, height: 1.3),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton.icon(
          onPressed: speak,
          icon: const Icon(Icons.volume_up_rounded),
          label: Text('Dengarkan', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          onPressed: () {
            SpeechService.instance.stopSpeaking();
            Navigator.pop(ctx);
          },
          child: Text('Oke', style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
