"""Gemini function-calling declarations for the caregiver-first Hani MVP."""

TOOL_DECLARATIONS = [
    {
        "name": "get_caregiver_context",
        "description": "Get the authorized caregiver, linked Alzheimer patient, recent shared care context, the caregiver's own private wellbeing context, tasks and connected professionals.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "list_dilemma_scenarios",
        "description": "List the active clinically validated Daily Dilemma scenario families available to Hani.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "get_dilemma_scenario",
        "description": "Load validated questions, guidance and red flags for one approved Daily Dilemma scenario. Use this before giving scenario-specific practical guidance.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"scenarioKey": {"type": "STRING"}},
            "required": ["scenarioKey"],
        },
    },
    {
        "name": "create_incident_draft",
        "description": "Save a meaningful caregiver-reported patient incident as a PRIVATE draft. This does not share it with other caregivers.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "scenarioKey": {"type": "STRING"},
                "title": {"type": "STRING"},
                "summary": {"type": "STRING"},
                "supportLevel": {
                    "type": "STRING",
                    "enum": ["routine_support", "professional_input_recommended", "possible_urgent_concern"],
                },
            },
            "required": ["summary"],
        },
    },
    {
        "name": "share_incident",
        "description": "Share the reporting caregiver's private incident into the shared care timeline. Requires explicit user confirmation.",
        "parameters": {
            "type": "OBJECT",
            "properties": {"incidentId": {"type": "STRING"}},
            "required": ["incidentId"],
        },
    },
    {
        "name": "get_care_circle",
        "description": "Get authorized Care Circle members, current care tasks and pending requests. Never includes another caregiver's private wellbeing data.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "request_care_task",
        "description": "Ask another Care Circle member to cover a responsibility. Requires explicit confirmation before creating the request.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "recipientProfileId": {"type": "STRING"},
                "title": {"type": "STRING"},
                "description": {"type": "STRING"},
                "dueAt": {"type": "STRING"},
                "difficulty": {"type": "STRING", "enum": ["light", "moderate", "heavy"]},
                "effortWeight": {"type": "NUMBER"},
                "message": {"type": "STRING"},
            },
            "required": ["recipientProfileId", "title"],
        },
    },
    {
        "name": "record_wellbeing_checkin",
        "description": "Save the caregiver's own private wellbeing check-in. This information is private by default.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "moodLabel": {"type": "STRING"},
                "energyLabel": {"type": "STRING"},
                "sleepLabel": {"type": "STRING"},
                "freeText": {"type": "STRING"},
            },
        },
    },
    {
        "name": "get_professional_routes",
        "description": "List verified professionals connected to the patient and the available call, WhatsApp or appointment-request routes.",
        "parameters": {"type": "OBJECT", "properties": {}},
    },
    {
        "name": "create_professional_contact_request",
        "description": "Create a call, WhatsApp or appointment handoff request to a connected professional. Requires explicit confirmation.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "professionalId": {"type": "STRING"},
                "channel": {"type": "STRING", "enum": ["call", "whatsapp", "appointment"]},
                "summary": {"type": "STRING"},
                "incidentId": {"type": "STRING"},
            },
            "required": ["professionalId", "channel"],
        },
    },
    {
        "name": "request_human_help",
        "description": "Offer a human-support route when the caregiver explicitly asks for a human, the situation exceeds Hani's safe role, or uncertainty remains meaningful.",
        "parameters": {
            "type": "OBJECT",
            "properties": {
                "reasonCategory": {"type": "STRING"},
                "summary": {"type": "STRING"},
            },
            "required": ["reasonCategory", "summary"],
        },
    },
]
