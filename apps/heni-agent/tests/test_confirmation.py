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

    def test_caregiver_sharing_requires_confirmation(self):
        session = SimpleNamespace(pending_action=None, last_user_text="share it")
        args = {"incidentId": "incident-1"}
        allowed, result = guard_write_action("share_incident", args, session)
        self.assertFalse(allowed)
        self.assertEqual(result["action"], "share_incident")

        session.last_user_text = "yes I confirm"
        allowed, result = guard_write_action("share_incident", args, session)
        self.assertTrue(allowed)
        self.assertIsNone(result)

    def test_care_circle_request_requires_confirmation(self):
        session = SimpleNamespace(pending_action=None, last_user_text="ask Sami")
        args = {
            "recipientProfileId": "caregiver-2",
            "title": "Morning coverage",
        }
        allowed, result = guard_write_action("request_care_task", args, session)
        self.assertFalse(allowed)
        self.assertTrue(result["requiresConfirmation"])

        session.last_user_text = "oui je confirme"
        allowed, result = guard_write_action("request_care_task", args, session)
        self.assertTrue(allowed)
        self.assertIsNone(result)

    def test_professional_handoff_requires_confirmation(self):
        session = SimpleNamespace(pending_action=None, last_user_text="contact doctor")
        args = {
            "professionalId": "professional-1",
            "channel": "whatsapp",
            "summary": "Relevant incident only",
        }
        allowed, result = guard_write_action(
            "create_professional_contact_request",
            args,
            session,
        )
        self.assertFalse(allowed)
        self.assertTrue(result["requiresConfirmation"])

        session.last_user_text = "I confirm"
        allowed, result = guard_write_action(
            "create_professional_contact_request",
            args,
            session,
        )
        self.assertTrue(allowed)
        self.assertIsNone(result)


if __name__ == "__main__":
    unittest.main()
