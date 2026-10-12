# LexLogic - PolicyCheck SA

PolicyCheck SA is a centralized insurance verification platform developed by **LexLogic**. The system is designed to help South African users verify insurance policies linked to their identity, detect suspicious policy activity, complete identity verification, and report potentially fraudulent policies from one application.

The project addresses the problem of fragmented insurance information across multiple insurers. Instead of requiring a user to contact each insurer separately, PolicyCheck SA provides a single interface through which verified users can view policies associated with their South African ID number.

> PolicyCheck SA is a verification and fraud-awareness platform. It does not sell insurance products and does not act as an insurer.

## Project Team

- Mbali Ndlovu - 202416227
- Sephamo Phasha - 202330931
- Rebaona Makhafola - 202416544
- Kopano Matthews - 202402065

## Main Features

The current prototype includes:

- User registration using personal details, phone number, South African ID number, and password
- OTP verification for registration and login
- JWT-based authentication after successful login
- Password hashing using BCrypt
- User profile management
- Identity and biometric verification integration
- Policy lookup for authenticated and verified users
- Integration with multiple simulated insurer APIs
- Normalization of different insurer JSON formats into one internal policy model
- Fraud detection and fraud flagging
- Fraud report submission
- Notifications
- Audit logging
- PostgreSQL persistence
- Flyway database migrations

## Repository Structure

```text
LexLogic/
├── backend/
│   └── lexlogic/
│       └── lexlogic/
│           ├── src/
│           ├── pom.xml
│           ├── mvnw
│           └── mvnw.cmd
│
├── frontend/
│   └── policy_app/
│       ├── lib/
│       ├── assets/
│       ├── android/
│       ├── web/
│       ├── windows/
│       └── pubspec.yaml
│
├── biometric-service/
│   ├── Biometric_Verification_Microservice.md
│   └── haarcascade_frontalface_default.xml
│
└── README.md
```

## System Architecture

PolicyCheck SA follows a layered architecture.

```text
Flutter Mobile Application
        |
        | REST/HTTP
        v
Spring Boot Backend
        |
        |-- Authentication / OTP / JWT
        |-- User Management
        |-- Policy Management
        |-- Fraud Detection
        |-- Fraud Reporting
        |-- Notifications
        |-- Audit Logging
        |-- Biometric Integration
        |-- Insurer Integration
        |
        v
PostgreSQL Database
```

The backend also communicates with external services:

```text
Spring Boot Backend
        |
        |-- Biometric verification service
        |
        |-- Demo Insurance WireMock API      :9001
        |-- SecureLife WireMock API          :9002
        |-- Shield Insurance WireMock API    :9003
```

## Insurer Integration

The original prototype used hardcoded insurer policy objects inside the backend. This was changed to a more realistic integration design.

The project now uses **WireMock** to simulate independent external insurer APIs. Each simulated insurer returns a different JSON structure, which represents the reality that different insurers will not necessarily use the same field names or response format.

Example differences include:

```text
Demo Insurance
policyNumber, policyType, premium

SecureLife
contractId, coverType, monthlyCost

Shield Insurance
reference, product, amount
```

The backend converts these different responses into one common internal `Policy` model.

```text
WireMock Insurer APIs
        |
        v
GenericInsurerClient
        |
        v
GenericPolicyMapper
        |
        v
Policy
        |
        v
InsurerPolicyAggregator
        |
        v
Flutter Application
```

Important insurer integration classes include:

- `InsurerClient` - defines the contract every insurer integration must support
- `GenericInsurerClient` - makes HTTP calls to insurer APIs and reads their JSON responses
- `InsurerMapping` - describes how an insurer's external field names map to the internal model
- `GenericPolicyMapper` - converts insurer JSON into a normalized `Policy`
- `InsurerPolicyAggregator` - requests policies from all configured insurer clients and combines the results
- `InsurerFraudResponse` - provides a common response structure for insurer fraud-report communication

This allows the rest of the application and the Flutter frontend to work with one consistent policy structure even though each insurer may expose a different API format.

## Authentication and OTP Design

OTP data is intentionally **not stored permanently in PostgreSQL**.

Registration and login OTP information is stored temporarily in the server-side Spring `HttpSession`. The client receives a `JSESSIONID` cookie that identifies the temporary session.

```text
Client, JSESSIONID cookie, Spring HttpSession, OtpSessionData
```

`OtpSessionData` contains temporary information such as:

- OTP code
- user ID
- OTP purpose
- expiry time
- number of failed attempts

OTP codes expire after approximately five minutes and failed attempts are monitored for fraud-detection purposes.

After successful OTP and password verification, the backend issues a JWT that is used to authenticate protected requests.

The Flutter application preserves the `JSESSIONID` cookie between OTP-related requests so that registration and login OTP verification use the same temporary server-side session.

## User Identity and Returning Users

The user's account and South African ID number remain stored as part of the permanent user record. The OTP refactor did not change how the user's account identity is stored.

A future improvement considered by the team is allowing an already registered and previously verified user to return and complete only a fresh selfie/liveness verification instead of repeating the entire identity-document process.

This was not implemented in the current prototype because doing so would require coordinated architectural changes across:

- the Spring Boot backend
- the Flutter frontend
- the biometric microservice

With limited development time, the team chose not to disturb a working end-to-end architecture. The expected use of the platform is also relatively occasional rather than daily; the project assumption is that a typical user may interact with the service around five times within a twelve-month period at most.

## SMS Behaviour During Development

The application supports SMS-based OTP delivery through SMSMessenger.

SMS sending can be enabled or disabled through configuration:

```properties
sms.enabled=${SMS_ENABLED:false}
```

When SMS is disabled, the OTP is not sent externally and the development message can be displayed in the backend logs instead. This prevents unnecessary use of SMS credits during development and testing.

The SMS integration itself remains implemented and can be enabled when required.

## Biometric Verification

PolicyCheck SA includes biometric identity verification as part of the identity-verification flow.

The intended process is:

1. The user provides identity information.
2. The user provides an ID document image.
3. The user captures a live selfie.
4. The biometric service performs face/liveness-related verification.
5. The backend records the verification result.
6. Policy lookup is restricted to authenticated and verified users.

The repository currently contains the biometric-service documentation and Haar cascade resource. The Spring Boot backend contains the integration layer used to communicate with the biometric service.

## Technology Stack

### Backend

- Java 21
- Spring Boot
- Spring Web / REST
- Spring Security
- Spring Data JPA
- BCrypt
- JWT
- PostgreSQL
- Flyway
- Jackson
- Maven

### Frontend

- Flutter
- Dart
- REST API integration
- Local token storage
- Mobile UI for registration, authentication, verification, policies, fraud reports, notifications, profile, and audit information

### External Service Simulation

- WireMock standalone
- HTTP / JSON

### Biometric Integration

- Separate biometric-service integration
- Haar cascade resource for facial detection-related processing

## Prerequisites

Before running the project, install:

- Java 21
- Maven, or use the included Maven Wrapper
- PostgreSQL
- Flutter SDK
- Android Studio or another Flutter-compatible development environment
- WireMock standalone JAR for the insurer simulations

Optional depending on testing:

- ngrok for exposing locally running services
- SMSMessenger credentials for real SMS delivery

## Environment Variables

The backend uses environment variables so that secrets are not committed to GitHub.

Set the following values before running the backend:

```text
DB_URL=jdbc:postgresql://localhost:5432/policychecksa_db
DB_USERNAME=postgres
DB_PASSWORD=your_database_password

JWT_SECRET=your_secure_jwt_secret
JWT_EXPIRATION=86400000

SMS_EMAIL=your_smsmessenger_email
SMS_TOKEN=your_smsmessenger_token
SMS_ENABLED=false

BIOMETRIC_API_URL=http://your-biometric-service-url
```

Do not commit real passwords, API tokens, or JWT secrets to the repository.

## Database Setup

Create a PostgreSQL database:

```sql
CREATE DATABASE policychecksa_db;
```

Flyway is used to manage schema migrations. When the backend starts, the available migrations under:

```text
src/main/resources/db/migration/
```

are applied automatically.

The application currently uses Hibernate schema validation rather than allowing Hibernate to create or alter the schema automatically.

## Running the Backend

Open a terminal in:

```text
backend/lexlogic/lexlogic
```

### Windows

```powershell
.\mvnw.cmd spring-boot:run
```

### macOS / Linux

```bash
./mvnw spring-boot:run
```

Alternatively, run `LexlogicApplication.java` directly from IntelliJ IDEA.

The backend normally starts on:

```text
http://localhost:8080
```

Make sure PostgreSQL is running and all required environment variables are configured before starting the application.

## Running the Flutter Frontend

Open a terminal in:

```text
frontend/policy_app
```

Install dependencies:

```bash
flutter pub get
```

Check available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

The frontend must be configured to use the correct backend base URL.

When testing on a physical phone, `localhost` on the phone does not refer to the development computer. Use an accessible local network address or an ngrok URL where appropriate.

## Running the Simulated Insurer APIs

The project uses three WireMock instances to simulate external insurers.

Example startup commands:

```bash
java -jar wiremock-standalone-4.0.0-beta.40.jar --port 9001
java -jar wiremock-standalone-4.0.0-beta.40.jar --port 9002
java -jar wiremock-standalone-4.0.0-beta.40.jar --port 9003
```

The backend is currently configured to communicate with:

```text
Demo Insurance      http://localhost:9001
SecureLife          http://localhost:9002
Shield Insurance    http://localhost:9003
```

The WireMock mapping folders must be started from their corresponding insurer simulation directories so that the correct mappings are loaded.

For the full multi-insurer policy lookup to work, start all three WireMock processes before requesting policies.

## Typical Application Flow

```text
Register account
        |
        v
Registration OTP verification
        |
        v
Login request
        |
        v
Login OTP verification
        |
        v
Password verification
        |
        v
JWT issued
        |
        v
Identity / biometric verification
        |
        v
Policy lookup
        |
        v
Multiple insurer APIs queried
        |
        v
Policies normalized and combined
        |
        v
Policies displayed in Flutter
        |
        +--> Report suspicious policy
        +--> View notifications
        +--> View audit activity
```

## Fraud Detection and Reporting

The system monitors suspicious activity such as repeated OTP failures and other abnormal verification behaviour. Fraud-related events can be recorded through fraud flags and audit logs.

Users can also report policies they do not recognize. Fraud reports are associated with the relevant user and policy and stored for follow-up.

The generic insurer policy retrieval integration is implemented over HTTP. Full outgoing fraud-report HTTP integration for every simulated insurer can be extended further as the prototype evolves.

## Audit Logging

Sensitive and important activities are recorded through the audit subsystem, including events associated with authentication, OTP verification, policy activity, and fraud-related actions.

This supports traceability and makes it easier to review important security events.

## Security Considerations

The prototype includes several security controls:

- BCrypt password hashing
- OTP verification
- OTP expiry and retry limits
- server-side temporary OTP session storage
- JWT authentication
- authenticated endpoint protection through Spring Security
- biometric verification before sensitive policy access
- audit logging
- environment-variable based secret configuration

For production use, further hardening would be required, including production TLS configuration, production-grade secret management, insurer authentication credentials, infrastructure monitoring, and deployment-specific security controls.

## Project Status

This repository represents the current university prototype of PolicyCheck SA.

Implemented areas include the Spring Boot backend, Flutter frontend, PostgreSQL/Flyway persistence, OTP and JWT authentication, fraud and audit functionality, biometric integration layer, and multi-insurer policy integration using WireMock simulations.

Some external integrations are simulated because access to real insurer production APIs is outside the scope of the academic project.

## GitHub Repository

Repository:

```text
https://github.com/Sephamo/LexLogic
```

