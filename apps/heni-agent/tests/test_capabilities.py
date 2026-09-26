import unittest

from app.heni_prompt import HENI_SYSTEM_PROMPT
from app.tools.declarations import TOOL_DECLARATIONS


class AgentCapabilityTests(unittest.TestCase):
    def test_caregiver_mvp_tools_are_declared(self):
        names = {tool["name"] for tool in TOOL_DECLARATIONS}
        required = {
            "get_caregiver_context",
            "list_dilemma_scenarios",
            "get_dilemma_scenario",
            "create_incident_draft",
            "share_incident",
            "get_care_circle",
            "request_care_task",
            "record_wellbeing_checkin",
            "get_professional_routes",
            "create_professional_contact_request",
            "request_human_help",
        }
        self.assertTrue(required.issubset(names))

    def test_prompt_matches_caregiver_product_identity(self):
        self.assertIn("caregiver-support companion", HENI_SYSTEM_PROMPT)
        self.assertIn("reduce uncertainty, isolation, guilt and mental load", HENI_SYSTEM_PROMPT)
        self.assertIn("Private caregiver wellbeing", HENI_SYSTEM_PROMPT)
        self.assertIn("Tunisian Derja", HENI_SYSTEM_PROMPT)
        self.assertIn("Never use public percentage leaderboards", HENI_SYSTEM_PROMPT)

    def test_prompt_keeps_clinical_and_medication_boundaries(self):
        self.assertIn("must never", HENI_SYSTEM_PROMPT.lower())
        self.assertIn("change medication dose", HENI_SYSTEM_PROMPT)
        self.assertIn("crush, mix or alter medication", HENI_SYSTEM_PROMPT)
        self.assertIn("never improvise clinical guidance", HENI_SYSTEM_PROMPT)
        self.assertIn("explicit consent", HENI_SYSTEM_PROMPT)

    def test_prompt_handles_unvalidated_dilemma_content_safely(self):
        self.assertIn("interaction_shell_only", HENI_SYSTEM_PROMPT)
        self.assertIn("must not present invented clinical guidance", HENI_SYSTEM_PROMPT)


if __name__ == "__main__":
    unittest.main()
