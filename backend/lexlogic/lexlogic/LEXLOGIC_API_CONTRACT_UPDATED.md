# LexLogic API Contract

**Audience:** Flutter frontend developer\
**API:** LexLogic Spring Boot backend\
**Status:** Development contract; confirm marked assumptions against the
running backend before production.

## 1. Base URL

-   Local: `http://localhost:8080`
-   ngrok: `- ngrok: https://manhandle-shortness-chaos.ngrok-free.dev`.

Use one configurable `baseUrl` in Flutter. The ngrok URL may change when
the tunnel restarts.

## 2. Authentication

Protected endpoints require a JWT:

``` http
Authorization: Bearer <JWT>
```

The backend authenticates the user from the token. Do not send a user ID
to endpoints that derive it from the authenticated principal.

### OTP session handling

Registration and login OTPs are stored temporarily in the backend's
server-side `HttpSession`.

The OTP is no longer persisted in the database.

The frontend receives a `JSESSIONID` cookie from the backend. This cookie
must be preserved and sent back with subsequent requests that belong to
the same registration or login OTP flow.

If the frontend does not send the same `JSESSIONID`, the backend may
respond with `OTP not found` because the request is associated with a
different HTTP session.

### Login flow (as implemented)

1.  `POST /api/users/login/request?phoneNumber=...` requests a login
    OTP. The OTP is stored temporarily in the server-side HTTP session,
    and the response includes the user's ID.
2.  `POST /otp/login/verify?userId=...&otpCode=...` verifies the OTP
    using the same HTTP session.
3.  `POST /api/users/password?userId=...` verifies the password using a
    JSON request body and completes login. The backend requires the login
    OTP to have already been verified in the same HTTP session. On
    success, the endpoint returns a JWT.

After successful login OTP verification, the actual OTP is removed from
the session and the session temporarily records that the user has
successfully completed OTP verification.

After successful password verification and JWT generation, the temporary
login OTP verification state is removed from the session.

Registration flow: 1. `POST /api/users/register` with the user fields.
The registration OTP is stored temporarily in the HTTP session.
2. `POST /otp/verify?userId=...&otpCode=...` verifies the OTP using the
same HTTP session. 3. `POST /otp/resend?userId=...` generates a new
registration OTP in the same session.

The frontend must preserve the `JSESSIONID` cookie between registration,
OTP resend, OTP verification, login OTP verification, and password
verification where applicable.

## 3. Endpoint summary

  ---------------------------------------------------------------------------------------------
Method            Path                                    Auth              Purpose
  ----------------- --------------------------------------- ----------------- -----------------
POST              `/api/users/register`                   Public            Register account

POST               `/otp/verify`                          Public            Registration OTP

POST              `/api/users/login/request`              Public            Request login OTP

POST              `/api/users/password`                   Public            Verify password
                                                                            and return JWT

POST              `/otp/verify`                           Public            Verify
registration OTP

POST              `/otp/resend`                           Public            Resend
registration OTP

POST              `/otp/login/verify`                     Public            Verify login OTP

POST              `/otp/login/resend`                     Public            Resend login OTP

GET               `/api/users/profile`                    JWT               Current user's
profile

POST              `/api/biometric/verify`                 JWT               Verify ID
document and
selfie

GET               `/api/policies/my-policies`             JWT + BIOMETRIC   Retrieve user's
biometric         policies
verification

GET               `/api/fraud/my-flags`                   JWT               List user's fraud
flags

GET               `/api/fraud/my-status`                  JWT               User's current
risk summary

POST              `/api/fraud-reports`                    JWT               Submit fraud
report

GET               `/api/fraud-reports/my-reports`         JWT               List user's
reports

GET               `/api/notifications/my-notifications`   JWT               List
notifications

GET               `/api/audit/my-logs`                    JWT               List audit events
---------------------------------------------------------------------------------------------

## 4. Endpoint details

### Register account

`POST /api/users/register`\
JSON request body (fields inferred from the User entity; validate exact
required fields with backend):

``` json
{
  "firstName": "Demo",
  "lastName": "User",
  "idNumber": "7604179863081",
  "phoneNumber": "+27XXXXXXXXX",
  "password": "ChooseAStrongPassword"
}
```

Successful response shape:

``` json
{
  "message": "Account created successfully, Please verify your phone number.",
  "userId": 1,
  "phoneVerified": false
}
```

### Request login OTP

`POST /api/users/login/request?phoneNumber=<phone>`\
Successful response shape:

``` json
{
  "message": "Login OTP generated successfully",
  "userId": 1
}
```

The login OTP is stored temporarily in the current `HttpSession`.

The frontend must preserve the returned `JSESSIONID` cookie and send it
with login OTP verification, login OTP resend, and password verification
requests.

### Verify registration OTP

`POST /otp/verify?userId=<id>&otpCode=<code>`\
Returns text: `OTP verified successfully`.

The OTP is verified against the registration OTP stored in the current
HTTP session.

After successful verification, the user's `phoneVerified` value is set
to `true` and the registration OTP is removed from the session.

### Resend registration OTP

`POST /otp/resend?userId=<id>`\
Returns text: `OTP resent Successfully`.

A new registration OTP replaces the previous OTP stored in the current
HTTP session. The OTP expiry time and failed-attempt count are reset.

### Verify login OTP

`POST /otp/login/verify?userId=<id>&otpCode=<code>`\
Returns text: `Login OTP verified successfully`.

The OTP is verified against the login OTP stored in the current HTTP
session.

After successful verification, the login OTP is removed from the session
and the session temporarily records that the user has successfully
completed login OTP verification.

### Resend login OTP

`POST /otp/login/resend?userId=<id>`\
Returns text: `Login OTP resent successfully`.

A new login OTP replaces the previous login OTP in the current HTTP
session. The OTP expiry time and failed-attempt count are reset.

### Verify password

`POST /api/users/password?userId=<id>`\
JSON request body:

``` json
{
  "password": "YourPasswordHere"
}
```

The login OTP must already have been successfully verified in the same
HTTP session.

On successful password verification, the backend returns the JWT as a
plain string.

After successful password verification and JWT generation, the temporary
login OTP verification state is removed from the session.

### Get profile

`GET /api/users/profile`\
Requires JWT. Response:

``` json
{
  "id": 1,
  "firstName": "Demo",
  "lastName": "User",
  "idNumber": "7604179863081",
  "phoneNumber": "+27XXXXXXXXX",
  "phoneVerified": true
}
```

The current response example does not include `biometricVerified`.

### Biometric verification

`POST /api/biometric/verify`\
Requires JWT and `multipart/form-data`:

  -----------------------------------------------------------------------
Field                   Type                    Required
  ----------------------- ----------------------- -----------------------
`id_image`              File (ID document       Yes
image/PDF accepted by   
biometric service)

`selfie_image`          File (selfie image)     Yes
-----------------------------------------------------------------------

Example success response:

``` json
{
  "status": "success",
  "verified": true,
  "message": "Identity verified successfully!",
  "reason": null,
  "livenessPassed": true,
  "faceMatch": true,
  "distance": 0.16,
  "qualityCheck": true
}
```

A failed verification returns `verified: false` and a `reason`. A failed
verification should not unlock policy access.

### Get policies

`GET /api/policies/my-policies`\
Requires JWT, verified phone, and successful biometric verification.
Returns a JSON array of policy objects. Example fields:

``` json
[
  {
    "id": 1,
    "policyNumber": "POL-100001",
    "policyType": "Vehicle Insurance",
    "status": "ACTIVE",
    "startDate": "2025-01-01",
    "endDate": "2026-12-31",
    "premium": 1250.0,
    "policyHolderIdNumber": "7604179863081",
    "insurer": {
      "id": 1,
      "name": "Demo Insurance",
      "apiUrl": "https://demo-insurer.example/api"
    }
  }
]
```

The example is illustrative; the endpoint may return multiple policies
or an empty array.

### Fraud flags

`GET /api/fraud/my-flags`\
Response is an array:

``` json
[
  {
    "id": 12,
    "policyId": 1,
    "ruleType": "ID_MISMATCH",
    "description": "Policy holder ID does not match the authenticated user's ID.",
    "riskLevel": "HIGH",
    "riskScore": 90,
    "status": "OPEN",
    "createdAt": "2026-09-09T01:11:33.227223"
  }
]
```

### Fraud risk status

`GET /api/fraud/my-status`\
Example:

``` json
{
  "riskLevel": "HIGH",
  "riskScore": 90,
  "openFlags": 1
}
```

### Submit fraud report

`POST /api/fraud-reports`\
Requires JWT. JSON body:

``` json
{
  "policyId": 1,
  "reason": "I do not recognize this policy."
}
```

Response:

``` json
{
  "id": 1,
  "policyId": 1,
  "policyNumber": "POL-100001",
  "reason": "I do not recognize this policy.",
  "status": "UNDER_INVESTIGATION",
  "createdAt": "2026-09-25T12:00:00",
  "insurerReference": "INS-123456",
  "insurerMessage": "The insurer has received the fraud report and will investigate."
}
```

### List fraud reports

`GET /api/fraud-reports/my-reports`\
Returns an array of fraud report response objects (same shape as submit
response).

### Notifications

`GET /api/notifications/my-notifications`\
Returns an array:

``` json
[
  {
    "id": 1,
    "title": "Fraud Report Update",
    "message": "Your fraud report has been received.",
    "read": false,
    "createdAt": "2026-09-13T06:03:25.454901"
  }
]
```

### Audit logs

`GET /api/audit/my-logs`\
Returns an array:

``` json
[
  {
    "id": 1,
    "eventType": "LOGIN_SUCCESS",
    "description": "User successfully logged in.",
    "createdAt": "2026-09-25T12:00:00"
  }
]
```

## 5. Flutter integration notes

-   Set `baseUrl` to the current ngrok HTTPS URL (no trailing slash).
-   Add `Authorization: Bearer <token>` to protected requests.
-   Registration and login OTP flows use a server-side `HttpSession`.
-   Preserve the `JSESSIONID` cookie returned by the backend and send it
    with subsequent requests belonging to the same OTP/login flow.
-   The OTP itself is not stored in the Flutter application or persisted
    in the LexLogic database.
-   Registration OTP state is removed after successful phone verification.
-   Login OTP data is removed after successful OTP verification.
-   Temporary login OTP verification state is removed after successful
    password authentication and JWT generation.
-   For biometric uploads, send multipart fields named exactly
    `id_image` and `selfie_image`.
-   For query parameters, let the HTTP client URL-encode values.
-   Treat dates as ISO-8601 strings.
-   Handle non-2xx responses; error response bodies may vary because a
    centralized error format is not documented here.
-   ngrok free-tier may display an interstitial page for browser
    traffic; API clients should send requests directly and may need the
    ngrok-skip-browser-warning header depending on the tunnel setup.
-   Use demo data only while the local development backend is exposed.