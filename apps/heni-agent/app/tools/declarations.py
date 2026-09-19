"""Gemini function-calling declarations for Heni's constrained business actions."""

TOOL_DECLARATIONS = [
    {
        "name": "get_patient_context",
        "description": "Get the current authorized patient's non-clinical profile, appointment history, reminders, current journey and next administrative step.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "get_public_hospital_info",
        "description": "Get verified public Hôpital Charles Nicolle address, contacts and hospital-level information maintained by Hani Maak.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "get_hospital_access",
        "description": "Get the hospital address, map coordinates and an external directions action for reaching Hôpital Charles Nicolle.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "search_hospital_directory",
        "description": "Search the wider public/reference hospital department directory. Use this for specialties that may not be directly bookable in Hani Maak.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "query": {"type": "STRING", "description": "Department/specialty name or patient wording. Empty string lists a broader sample."}
            },
        },
    },
    {
        "name": "get_app_help",
        "description": "Explain how to use a patient-app feature such as services, appointments, journey, map, AR, medicine, language or voice.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"topic": {"type": "STRING", "description": "Feature or task the patient wants help with"}},
        },
    },
    {
        "name": "find_services",
        "description": "Search services that are operationally configured in Hani Maak. Results can be booked only when the returned service says so.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"query": {"type": "STRING", "description": "User words describing the service"}},
            "required": ["query"],
        },
    },
    {
        "name": "get_service_details",
        "description": "Get verified platform-service description, required documents, preparation and follow-up.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"serviceId": {"type": "STRING"}},
            "required": ["serviceId"],
        },
    },
    {
        "name": "check_appointment_availability",
        "description": "Check current deterministic bookable slots for a platform service, optionally on one date.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "serviceId": {"type": "STRING"},
                "date": {"type": "STRING", "description": "Optional YYYY-MM-DD"},
            },
            "required": ["serviceId"],
        },
    },
    {
        "name": "create_appointment",
        "description": "Book an appointment after explicit user confirmation of exact service/date/time.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "serviceId": {"type": "STRING"},
                "date": {"type": "STRING", "description": "YYYY-MM-DD"},
                "time": {"type": "STRING", "description": "HH:MM, Tunisia local time"},
            },
            "required": ["serviceId", "date", "time"],
        },
    },
    {
        "name": "reschedule_appointment",
        "description": "Move an existing appointment after explicit confirmation of the replacement slot.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "appointmentId": {"type": "STRING"},
                "date": {"type": "STRING", "description": "YYYY-MM-DD"},
                "time": {"type": "STRING", "description": "HH:MM, Tunisia local time"},
            },
            "required": ["appointmentId", "date", "time"],
        },
    },
    {
        "name": "cancel_appointment",
        "description": "Cancel an existing appointment after explicit user confirmation.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "appointmentId": {"type": "STRING"},
                "reason": {"type": "STRING"},
            },
            "required": ["appointmentId"],
        },
    },
    {
        "name": "list_my_appointments",
        "description": "List the authorized patient's own appointments with service names and states. Use when the user says they already have a rendez-vous.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "includePast": {"type": "BOOLEAN", "description": "Include completed/cancelled appointments when true"}
            },
        },
    },
    {
        "name": "get_appointment",
        "description": "Get one appointment belonging to the authorized patient.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"appointmentId": {"type": "STRING"}},
            "required": ["appointmentId"],
        },
    },
    {
        "name": "get_journey_status",
        "description": "Get the patient's Access → Guidance → Continuity journey for an appointment, including all steps and current state.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"appointmentId": {"type": "STRING"}},
            "required": ["appointmentId"],
        },
    },
    {
        "name": "get_navigation_context",
        "description": "Get verified indoor route/map guidance for a platform service when a mapped route exists.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"serviceId": {"type": "STRING"}},
            "required": ["serviceId"],
        },
    },
    {
        "name": "get_approved_instructions",
        "description": "Get published provider-authored preparation and follow-up instructions for a platform service.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"serviceId": {"type": "STRING"}},
            "required": ["serviceId"],
        },
    },
    {
        "name": "request_human_help",
        "description": "Create a staff escalation for clinical-boundary questions, emergencies, complaints, missing operational information or a direct request for a human.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "reasonCategory": {"type": "STRING"},
                "summary": {"type": "STRING", "description": "Short summary of the request"},
            },
            "required": ["reasonCategory", "summary"],
        },
    },
]
