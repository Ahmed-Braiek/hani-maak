"""Offline regression tests for the production smoke runner; no credentials used."""

import os
import unittest
from io import BytesIO
from unittest.mock import patch
from urllib.error import HTTPError

from scripts import production_smoke as smoke


class Response:
    status = 200

    def __init__(self, data=b'{}'):
        self.data = data

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self, limit):
        return self.data[:limit]


class ProductionSmokeTests(unittest.TestCase):
    def test_missing_credentials_reports_name_only(self):
        with patch.dict(os.environ, {"HANI_SMOKE_DEMO_PASSWORD": ""}):
            with self.assertRaisesRegex(smoke.SmokeFailure, "Missing CI credential/configuration: HANI_SMOKE_DEMO_PASSWORD"):
                smoke.require_env("HANI_SMOKE_DEMO_PASSWORD")

    def test_unauthorized_status_is_accepted_without_reading_body(self):
        unauthorized = HTTPError("https://example.test/chat", 401, "Unauthorized", {}, BytesIO(b'{"token":"secret"}'))
        with patch.object(smoke.HTTP, "open", side_effect=unauthorized):
            status, data = smoke.request("negative case", "https://example.test/chat", expected=(401,))
        self.assertEqual(status, 401)
        self.assertEqual(data, b"")

    def test_unauthorized_status_fails_positive_case(self):
        unauthorized = HTTPError("https://example.test/chat", 401, "Unauthorized", {}, BytesIO(b'private'))
        with patch.object(smoke.HTTP, "open", side_effect=unauthorized):
            with self.assertRaisesRegex(smoke.SmokeFailure, "HTTP 401") as caught:
                smoke.request("positive case", "https://example.test/chat")
        self.assertNotIn("private", str(caught.exception))

    def test_password_login_sends_secret_in_body_and_returns_token(self):
        auth_result = b'{"access_token":"ephemeral-token","token_type":"bearer"}'
        verified_user = b'{"id":"synthetic-demo-id"}'
        with patch.object(smoke.HTTP, "open", side_effect=[Response(auth_result), Response(verified_user)]) as mocked:
            with patch("builtins.print") as printed:
                token = smoke.authenticate("https://example.supabase.co", "public-key", "user@example.test", "password")
        self.assertEqual(token, "ephemeral-token")
        sent = mocked.call_args_list
        self.assertIn('"email": "user@example.test"', sent[0].args[0].data.decode())
        self.assertEqual(sent[1].args[0].get_header("Authorization"), "Bearer ephemeral-token")
        output = " ".join(str(item.args) for item in printed.call_args_list)
        self.assertNotIn("ephemeral-token", output)
        self.assertNotIn("password", output)

    def test_negative_probes_use_401_and_bound_patient(self):
        seen = []
        def fake_request(label, url, **kwargs):
            seen.append((label, kwargs))
            return 401, b""
        with patch.object(smoke, "request", side_effect=fake_request):
            smoke.check_access_control("synthetic-token")
        self.assertEqual(len(seen), 6)
        self.assertTrue(all(401 in x[1]["expected"] for x in seen))
        self.assertEqual(seen[4][1]["body"]["patientId"], smoke.UNRELATED_PATIENT_ID)
        self.assertEqual(seen[5][1]["body"]["patientId"], smoke.UNRELATED_PATIENT_ID)


if __name__ == "__main__":
    unittest.main()
