# Changelog

All notable changes from this point forward should be recorded here. The format follows the spirit of [Keep a Changelog](https://keepachangelog.com/) without inventing historical releases that were not formally tracked.

## [Unreleased]

### Added
- First-class Heni Chat orchestration with a replaceable server-side model provider.
- Fine-tuned-model-ready Heni configuration and synthetic training-data documentation.
- Centralized Heni safety policy and multilingual behavior prompt.
- Heni/RBAC deterministic tests and repository verification scripts.
- Professional repository governance, security, contribution and reviewer documentation.

### Changed
- Heni's floating assistant now uses the Heni orchestration layer while preserving deterministic administrative actions and provider-failure fallback.
- Realtime voice behavior/configuration moved toward dedicated Heni modules.
- Environment configuration documents modern Supabase server secrets and Heni model/voice settings.
- README reorganized for technical reviewers, contributors and competition judges.

### Fixed
- Reduced duplication between deterministic voice safety checks and Heni's centralized safety boundary.

### Security
- Added explicit private vulnerability-reporting guidance.
- Added secret/training-data ignore rules and credential-disclosure safeguards in Heni.
- Realtime bridge can authenticate internal tool calls with the configured shared secret.
