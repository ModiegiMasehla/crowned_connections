# POPIA / privacy-by-design checklist

This is an engineering checklist, not legal advice.

V1 requirements:

- Ask for location permission only when needed.
- Explain why location is used.
- Allow manual location search.
- Do not persist a customer's precise location in the V1 database.
- Store only the minimum customer information needed for booking.
- Hash passwords.
- Require authenticated access to personal appointment data.
- Enforce salon-owner authorization server-side.
- Provide account deletion (`DELETE /api/auth/me`).
- Keep timestamps/audit fields.
- Keep payment data limited to provider references/statuses; never store raw card data.
- Do not put API secrets in source control.
- Define a retention/deletion policy before launch.
- Provide a privacy notice and consent wording before production launch.
- Establish an operator process for data-subject requests.
- Review cross-border/cloud processing and vendor agreements before production.

For launch, obtain South African legal/privacy advice specific to the company, data flows and service providers.
