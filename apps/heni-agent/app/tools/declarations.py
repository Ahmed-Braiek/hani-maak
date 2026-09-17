"""Gemini function-calling declarations for Heni's constrained business actions."""

TOOL_DECLARATIONS = [
    {
        "name": "get_patient_context",
        "description": "Get the current authorized patient/session context and current administrative journey state.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "find_services",
        "description": "Search verified hospital services by spoken name or need.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"query": {"type": "STRING", "description": "User words describing the service"}},
            "required": ["query"],
        },
    },
    {
        "name": "get_service_details",
        "description": "Get verified name, description, documents and location for a service.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"serviceId": {"type": "STRING"}},
            "required": ["serviceId"],
        },
    },
    {
        "name": "check_appointment_availability",
        "description": "Check current deterministic bookable slots for a service, optionally on one date.",
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
        "description": "Get the patient's current Access, Guidance and Continuity journey state for an appointment.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"appointmentId": {"type": "STRING"}},
            "required": ["appointmentId"],
        },
    },
    {
        "name": "get_navigation_context",
        "description": "Get route/map guidance returned by the Hani Maak navigation engine for a service.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"serviceId": {"type": "STRING"}},
            "required": ["serviceId"],
        },
    },
    {
        "name": "get_approved_instructions",
        "description": "Get published provider-authored preparation and follow-up instructions for a service.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"serviceId": {"type": "STRING"}},
            "required": ["serviceId"],
        },
    },
    {
        "name": "request_human_help",
        "description": "Create a staff escalation for clinical-boundary questions, emergencies, complaints or a direct request for a human.",
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
