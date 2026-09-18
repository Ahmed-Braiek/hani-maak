import unittest

from app.language import (
    detect_likely_locale,
    detect_requested_locale,
    is_doctor_name_question,
    is_human_help_request,
    is_language_switch_only,
)


class LanguageTests(unittest.TestCase):
    def test_requested_language_switches(self):
        self.assertEqual(detect_requested_locale("parlez en arab"), "ar")
        self.assertEqual(detect_requested_locale("tu peux parler tunisien"), "ar")
        self.assertEqual(detect_requested_locale("speak English"), "en")
        self.assertEqual(detect_requested_locale("parlez français"), "fr")

    def test_tunisian_romanized_language_detection(self):
        self.assertEqual(detect_likely_locale("nheb naamel rendez vous"), "ar")
        self.assertEqual(detect_likely_locale("3andi rendez-vous ghodwa"), "ar")

    def test_human_help_variants(self):
        self.assertTrue(is_human_help_request("aide humain"))
        self.assertTrue(is_human_help_request("l'aide humaine"))
        self.assertTrue(is_human_help_request("نحب موظف يعاوني"))

    def test_language_switch_only_vs_combined_request(self):
        self.assertTrue(is_language_switch_only("parlez en arab"))
        self.assertFalse(is_language_switch_only("aide humain et parlez en arab"))

    def test_doctor_name_question(self):
        self.assertTrue(is_doctor_name_question("quel est le nom de docteur"))
        self.assertTrue(is_doctor_name_question("what is the doctor name"))
        self.assertTrue(is_doctor_name_question("اسم الطبيب شنو"))


if __name__ == "__main__":
    unittest.main()
