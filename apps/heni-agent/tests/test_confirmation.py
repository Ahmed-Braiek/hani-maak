import unittest
from types import SimpleNamespace

from app.confirmation import guard_write_action, is_explicit_confirmation


class ConfirmationTests(unittest.TestCase):
    def test_multilingual_confirmation_phrases(self):
        for text in ["yes", "I confirm", "oui je confirme", "نأكد", "إي موافق"]:
            self.assertTrue(is_explicit_confirmation(text), text)

    def test_write_action_requires_two_phase_confirmation(self):
        session = SimpleNamespace(pending_action=None, last_user_text="Book it")
        args = {"serviceId": "svc-imaging", "date": "2026-09-30", "time": "09:30"}
        allowed, result = guard_write_action("create_appointment", args, session)
        self.assertFalse(allowed)
        self.assertTrue(result["requiresConfirmation"])

        session.last_user_text = "oui je confirme"
        allowed, result = guard_write_action("create_appointment", args, session)
        self.assertTrue(allowed)
        self.assertIsNone(result)
        self.assertIsNone(session.pending_action)


if __name__ == "__main__":
    unittest.main()
