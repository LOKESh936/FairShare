# FairShare API - Beginner Guide (Complete Walkthrough)

This guide explains the project from the ground up, assuming you are new to backend development.

It covers:
- Basic concepts (API, Rails, PostgreSQL, JWT, tests)
- What was built
- How it was built (step by step)
- How the code is organized
- How balances and debt simplification work
- How to run and use the API locally
- Common mistakes and how to debug

---

## 1. What This Project Is

FairShare is a backend API for splitting expenses in groups, similar to Splitwise.

Example use case:
- You and your friends are in a `Trip to NYC` group.
- One person pays for dinner.
- The app records who owes what.
- It can simplify chains of debts (A owes B, B owes C -> A owes C).
- People can settle up and see activity history.

This project does **not** include a frontend UI. It is a JSON API that a mobile app or web app can call.

---

## 2. Core Concepts (Very Important)

## 2.1 What is an API?

API = Application Programming Interface.

In this project:
- Client sends HTTP request (for example: `POST /auth/login`)
- Server returns JSON response (for example: token + user)

You interact with the backend using endpoints.

---

## 2.2 HTTP Methods Used

- `GET`: Read data
- `POST`: Create data
- `DELETE`: Remove data

Example:
- `GET /groups` -> list groups
- `POST /groups` -> create group
- `DELETE /groups/:id` -> leave/delete group membership

---

## 2.3 What is JSON?

JSON is plain text format for data exchange.

Example:
```json
{
  "name": "Roommates",
  "id": 1
}
```

All responses in this API are JSON.

---

## 2.4 What is Rails API-only mode?

Rails can build full web apps with HTML views, or API-only apps.

We used API-only mode because:
- cleaner backend for mobile/web frontend clients
- no view rendering complexity
- focused on JSON endpoints

---

## 2.5 What is PostgreSQL?

PostgreSQL is the database that stores all persistent data:
- users
- groups
- expenses
- splits
- settlements
- activity logs

---

## 2.6 What is JWT Authentication?

JWT = JSON Web Token.

Flow:
1. User logs in with email/password.
2. Server verifies credentials.
3. Server returns signed token.
4. Client sends token in `Authorization: Bearer <token>` header.
5. Server identifies current user from token.

No server-side session table is required.

---

## 2.7 What are Service Objects?

Service object = Ruby class that contains business logic that should not live inside controllers/models.

Why useful:
- keeps controllers thin
- keeps logic testable
- cleaner architecture

Services in this project:
- `ExpenseSplitter`
- `ExpenseCreator`
- `BalanceCalculator`
- `DebtSimplifier`
- `SettlementCreator`

---

## 2.8 What are Serializers?

Serializers control how model data becomes JSON.

Why useful:
- consistent API responses
- avoids returning unnecessary fields
- easier to evolve API contract

---

## 2.9 Why tests (RSpec)?

Tests verify behavior automatically.

We added tests for:
- model validations and behavior
- core services (`ExpenseSplitter`, `BalanceCalculator`)

This protects critical financial logic from regressions.

---

## 3. What I Built (Feature Checklist)

Implemented all requested features:

1. Auth
- register
- login
- JWT token generation
- bcrypt password hashing

2. Groups
- create/list/show groups
- invite users by email
- leave group

3. Expenses
- create expense inside group
- equal split across members
- custom split with exact per-user amounts
- list group expenses
- delete expense (authorized users)

4. Balances
- compute net debts in group
- simplify debts via transfer minimization

5. Settlements
- settle debt between two users
- validation against outstanding debt

6. Activity feed
- list recent expenses and settlements in group

7. Quality and DX
- validations
- structured error handling + status codes
- serializers
- seed data (3 users, 2 groups, multiple expenses)
- Render deployment files
- README endpoint docs
- natural multi-commit git history

---

## 4. How I Built It (Step-by-Step Timeline)

This is the exact progression:

1. **Initialize Rails API project**
- generated Rails 7.1 API app
- configured PostgreSQL
- installed dependencies

2. **Authentication foundation**
- added `bcrypt`, `jwt`
- added user model with secure password
- added register/login endpoints
- added auth middleware in `ApplicationController`

3. **Group and membership system**
- added `Group`, `GroupMembership`
- creator auto-added as admin
- invite users by email
- membership authorization concern

4. **Expense splitting**
- added `Expense`, `ExpenseSplit`
- built `ExpenseSplitter` service:
  - equal split with cent-safe rounding
  - custom split with strict validations
- built `ExpenseCreator` transaction service

5. **Balance + debt simplification + settlements**
- added `Settlement`, `Activity`
- built `BalanceCalculator`
- built `DebtSimplifier`
- built `SettlementCreator` with debt checks
- added activity feed endpoint

6. **Testing**
- set up RSpec + FactoryBot + Shoulda
- added model and service specs

7. **Documentation + deployment**
- README with setup and full endpoint examples
- `render.yaml` + `Procfile`
- realistic seed data

8. **Runtime patch**
- fixed JWT encoder argument handling after live login verification

---

## 5. Folder Structure Explained

- `app/controllers/` -> handles API requests/responses
- `app/models/` -> database-backed entities + validations
- `app/services/` -> business logic
- `app/serializers/` -> JSON response shaping
- `db/migrate/` -> schema evolution files
- `db/seeds.rb` -> demo data creation
- `spec/` -> tests
- `config/routes.rb` -> API routes
- `render.yaml` -> Render deployment definition

---

## 6. Data Model (Conceptual)

Main entities:

- `User`
  - has secure password
  - can be in many groups

- `Group`
  - has creator
  - has many members through memberships
  - has expenses, settlements, activities

- `GroupMembership`
  - join table user <-> group
  - role: member/admin

- `Expense`
  - belongs to group
  - has payer
  - has many `ExpenseSplit`

- `ExpenseSplit`
  - one row per user share of one expense

- `Settlement`
  - records payment from one user to another in a group

- `Activity`
  - logs key events (expense created / settlement created)

---

## 7. Business Logic Deep-Dive

## 7.1 Equal split logic

Example: Amount = 10.00, users = 3

- convert to cents: 1000
- base share: 333 cents
- remainder: 1 cent
- splits become: 334, 333, 333
- convert back to dollars safely

Why cents?
- avoids floating point money errors

---

## 7.2 Custom split logic

Rules enforced:
- each item must include `user_id` and `amount`
- users must belong to group
- no duplicate users in split list
- sum of custom amounts must exactly equal expense amount

If any rule fails -> `422 Unprocessable Entity` with clear error message.

---

## 7.3 Balance calculation logic

For each expense split:
- split user owes payer (unless same user)
- net balances tracked in cents per user

For each settlement:
- payer of settlement reduces debt
- receiver of settlement reduces credit

Then debts are simplified.

---

## 7.4 Debt simplification logic

Input: net balances
- negative users = debtors
- positive users = creditors

Algorithm pairs debtors and creditors greedily:
- transfer min(debtor_need, creditor_due)
- continue until all settled

This reduces noisy chains and gives clear "who pays whom" output.

---

## 7.5 Settlement safety checks

Before creating settlement:
- recipient user must be in group
- amount > 0
- actor must currently owe recipient
- amount cannot exceed outstanding debt

This prevents invalid settlement records.

---

## 8. Routes Implemented

Exactly implemented:

- `POST /auth/register`
- `POST /auth/login`

- `GET /groups`
- `POST /groups`
- `GET /groups/:id`
- `DELETE /groups/:id`
- `POST /groups/:id/members`

- `POST /groups/:id/expenses`
- `GET /groups/:id/expenses`
- `DELETE /groups/:id/expenses/:expense_id`

- `GET /groups/:id/balances`
- `POST /groups/:id/settlements`

- `GET /groups/:id/activity`

---

## 9. How to Run Locally (Beginner Steps)

From project root:

```bash
cd /Users/loki/Desktop/FairShare
brew services start postgresql@16
bundle install
bundle exec rails db:prepare
bundle exec rails db:seed
bundle exec rails s -b 127.0.0.1 -p 3000
```

Server URL:
- `http://127.0.0.1:3000`

---

## 10. How to Use the API (Practical Walkthrough)

## 10.1 Login and get token

```bash
curl -X POST http://127.0.0.1:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"alex@example.com","password":"password123"}'
```

Copy `token` from response.

## 10.2 List groups

```bash
curl http://127.0.0.1:3000/groups \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 10.3 Create expense

```bash
curl -X POST http://127.0.0.1:3000/groups/1/expenses \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Dinner","amount":"90.00","payer_id":1,"split_type":"equal"}'
```

## 10.4 View balances

```bash
curl http://127.0.0.1:3000/groups/1/balances \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 10.5 Create settlement

```bash
curl -X POST http://127.0.0.1:3000/groups/1/settlements \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to_user_id":1,"amount":"10.00"}'
```

## 10.6 View activity

```bash
curl http://127.0.0.1:3000/groups/1/activity \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 11. Error Handling Model

Centralized in `ApplicationController` via `rescue_from`.

Main statuses:
- `400` bad request (missing required params)
- `401` unauthenticated (missing/invalid token)
- `403` forbidden (not allowed)
- `404` not found
- `422` validation/business rule errors

Error shape examples:
```json
{ "error": "Missing authentication token" }
```

```json
{ "error": ["Email has already been taken"] }
```

---

## 12. Test Coverage

Run tests:

```bash
bundle exec rspec
```

Current coverage focus:
- user model behavior
- group membership uniqueness
- `ExpenseSplitter` logic (equal/custom + invalid input)
- `BalanceCalculator` logic (including simplification and settlements)

---

## 13. Deployment (Render)

Deployment files included:
- `render.yaml`
- `Procfile`

At deploy time, provide:
- `RAILS_ENV=production`
- `DATABASE_URL`
- `SECRET_KEY_BASE`

Build command:
```bash
bundle install && bundle exec rails db:migrate
```

Start command:
```bash
bundle exec puma -C config/puma.rb
```

---

## 14. Git History (What happened in commits)

Main commit progression:

1. `Initialize Rails 7.1 API foundation`
2. `Add JWT authentication and user registration`
3. `Implement group management and member invites`
4. `Implement expense splitting logic`
5. `Add balance calculation with debt simplification`
6. `Add RSpec tests for core services`
7. `Document API and add Render deployment setup`
8. `Fix JWT token encoding for auth login`

This is intentionally realistic, showing incremental professional development.

---

## 15. Most Important Files to Read First

If you read only a few files, start here:

1. `config/routes.rb`
2. `app/controllers/application_controller.rb`
3. `app/controllers/auth_controller.rb`
4. `app/controllers/expenses_controller.rb`
5. `app/services/expense_splitter.rb`
6. `app/services/balance_calculator.rb`
7. `app/services/debt_simplifier.rb`
8. `app/services/settlement_creator.rb`
9. `db/seeds.rb`
10. `README.md`

---

## 16. If You’re New: What to Learn Next

Recommended order:

1. Learn REST basics (`GET`, `POST`, `DELETE`, status codes)
2. Learn Rails MVC fundamentals
3. Learn ActiveRecord associations and validations
4. Learn auth flow with JWT
5. Learn service object pattern
6. Learn RSpec basics

---

## 17. Final Summary

You now have a complete, production-style Rails backend for shared expenses with:
- robust auth
- strong data model
- clear service-layer logic
- tested core financial logic
- clean JSON API responses
- deployment-ready setup

You can now:
- connect a frontend (React/Next/mobile)
- deploy to Render
- extend features (recurring expenses, currency support, notifications)

