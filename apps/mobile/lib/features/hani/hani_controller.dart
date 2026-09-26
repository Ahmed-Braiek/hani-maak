import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hani_api.dart';

enum HaniRole { caregiver, hani }

class HaniMessage {
  const HaniMessage({
    required this.role,
    required this.text,
    this.uiActions = const [],
  });

  final HaniRole role;
  final String text;
  final List<Map<String, dynamic>> uiActions;
}

class HaniChatState {
  const HaniChatState({
    this.messages = const [],
    this.sessionId,
    this.confirmationToken,
    this.locale = 'ar',
    this.sending = false,
    this.error,
  });

  final List<HaniMessage> messages;
  final String? sessionId;
  final String? confirmationToken;
  final String locale;
  final bool sending;
  final String? error;

  HaniChatState copyWith({
    List<HaniMessage>? messages,
    String? sessionId,
    String? confirmationToken,
    bool clearConfirmation = false,
    String? locale,
    bool? sending,
    String? error,
    bool clearError = false,
  }) {
    return HaniChatState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      confirmationToken:
          clearConfirmation ? null : confirmationToken ?? this.confirmationToken,
      locale: locale ?? this.locale,
      sending: sending ?? this.sending,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final haniApiProvider = Provider<HaniApiClient>((ref) {
  final client = HaniApiClient();
  ref.onDispose(client.dispose);
  return client;
});

final haniChatProvider =
    StateNotifierProvider<HaniChatController, HaniChatState>((ref) {
  return HaniChatController(ref.read(haniApiProvider));
});

class HaniChatController extends StateNotifier<HaniChatState> {
  HaniChatController(this._api)
      : super(
          const HaniChatState(
            messages: [
              HaniMessage(
                role: HaniRole.hani,
                text:
                    'Mariem, هاني معاك. شنوة صاير مع فاطمة توا؟ احكيلي كيف ما تحب — بالتونسي، بالفرنسي، بالعربي أو بالإنجليزي.',
              ),
            ],
          ),
        );

  final HaniApiClient _api;

  Future<void> send(String raw) async {
    final message = raw.trim();
    if (message.isEmpty || state.sending) return;

    final before = state.messages;
    final nextMessages = [
      ...before,
      HaniMessage(role: HaniRole.caregiver, text: message),
    ];
    state = state.copyWith(
      messages: nextMessages,
      sending: true,
      clearError: true,
    );

    try {
      final response = await _api.send(
        message: message,
        locale: state.locale,
        sessionId: state.sessionId,
        confirmationToken: state.confirmationToken,
        history: before
            .map(
              (m) => {
                'role': m.role == HaniRole.hani ? 'assistant' : 'user',
                'content': m.text,
              },
            )
            .toList(),
      );

      state = state.copyWith(
        messages: [
          ...nextMessages,
          HaniMessage(
            role: HaniRole.hani,
            text: response.message,
            uiActions: response.uiActions,
          ),
        ],
        sessionId: response.sessionId,
        confirmationToken: response.confirmationToken,
        clearConfirmation: response.confirmationToken == null,
        locale: response.locale,
        sending: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        sending: false,
        error:
            'Hani couldn’t connect just now. Your message is still here — tap retry.',
      );
    }
  }

  Future<void> retryLast() async {
    if (state.sending) return;
    for (var i = state.messages.length - 1; i >= 0; i--) {
      final message = state.messages[i];
      if (message.role == HaniRole.caregiver) {
        final cleaned = state.messages.sublist(0, i);
        state = state.copyWith(messages: cleaned, clearError: true);
        await send(message.text);
        return;
      }
    }
  }

  void setLocale(String locale) {
    if (!const {'tn', 'ar', 'fr', 'en'}.contains(locale)) return;
    state = state.copyWith(locale: locale);
  }
}
