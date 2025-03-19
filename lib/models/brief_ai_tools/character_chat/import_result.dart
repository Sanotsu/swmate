import 'character_chat_session.dart';

class ImportSessionsResult {
  final int importedSessions;
  final int skippedSessions;
  final int importedCharacters;
  final CharacterChatSession? firstSession;

  ImportSessionsResult({
    required this.importedSessions,
    required this.skippedSessions,
    required this.importedCharacters,
    this.firstSession,
  });
}

class ImportCharactersResult {
  final int importedCount;
  final int skippedCount;

  ImportCharactersResult({
    required this.importedCount,
    required this.skippedCount,
  });
} 