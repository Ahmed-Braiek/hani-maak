from app.language import (
    detect_likely_locale,
    detect_requested_locale,
    is_doctor_name_question,
    is_human_help_request,
    is_language_switch_only,
)


def test_requested_language_switches():
    assert detect_requested_locale("parlez en arab") == "ar"
    assert detect_requested_locale("tu peux parler tunisien") == "ar"
    assert detect_requested_locale("speak English") == "en"
    assert detect_requested_locale("parlez français") == "fr"


def test_tunisian_romanized_language_detection():
    assert detect_likely_locale("nheb naamel rendez vous") == "ar"
    assert detect_likely_locale("3andi rendez-vous ghodwa") == "ar"


def test_human_help_variants():
    assert is_human_help_request("aide humain")
    assert is_human_help_request("l'aide humaine")
    assert is_human_help_request("نحب موظف يعاوني")


def test_language_switch_only_vs_combined_request():
    assert is_language_switch_only("parlez en arab")
    assert not is_language_switch_only("aide humain et parlez en arab")


def test_doctor_name_question():
    assert is_doctor_name_question("quel est le nom de docteur")
    assert is_doctor_name_question("what is the doctor name")
    assert is_doctor_name_question("اسم الطبيب شنو")
