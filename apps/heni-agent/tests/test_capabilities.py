import unittest

from app.heni_prompt import HENI_SYSTEM_PROMPT
from app.tools.declarations import TOOL_DECLARATIONS


class AgentCapabilityTests(unittest.TestCase):
    def test_full_patient_journey_tools_are_declared(self):
        names = {tool["name"] for tool in TOOL_DECLARATIONS}
        required = {
            "get_patient_context",
            "get_public_hospital_info",
            "get_hospital_access",
            "search_hospital_directory",
            "get_app_help",
            "find_services",
            "get_service_details",
            "check_appointment_availability",
            "create_appointment",
            "reschedule_appointment",
            "cancel_appointment",
            "list_my_appointments",
            "get_journey_status",
            "get_navigation_context",
            "get_approved_instructions",
            "request_human_help",
        }
        self.assertTrue(required.issubset(names))

    def test_prompt_is_not_booking_only(self):
        self.assertIn("complete administrative patient journey", HENI_SYSTEM_PROMPT)
        self.assertIn("get to the hospital", HENI_SYSTEM_PROMPT)
        self.assertIn("not a doctor or clinician", HENI_SYSTEM_PROMPT)
        self.assertIn("Never force the user into booking", HENI_SYSTEM_PROMPT)


if __name__ == "__main__":
    unittest.main()
