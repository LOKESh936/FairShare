# FairShare API

FairShare is a production-style Ruby on Rails 7.1 API-only backend for splitting shared expenses, similar to Splitwise.

It supports:
- JWT authentication
- Group creation and membership management
- Expense creation with equal and custom splits
- Balance calculation with debt simplification
- Settlements between users
- Group activity feed for expenses and settlements

## Tech Stack

- Ruby 3.3
- Rails 7.1 (API mode)
- PostgreSQL
- JWT (`jwt` gem)
- BCrypt password hashing
- RSpec + FactoryBot + Shoulda Matchers

## Architecture Notes

### Core models
- `User`
- `Group`
- `GroupMembership`
- `Expense`
- `ExpenseSplit`
- `Settlement`
- `Activity`

### Service objects
- `ExpenseSplitter` for split calculation (`equal` and `custom`)
- `ExpenseCreator` for transactional expense + splits + activity creation
- `BalanceCalculator` for net balances from expenses and settlements
- `DebtSimplifier` for reducing intermediary debts
- `SettlementCreator` for validated settlement recording

### Serialization
Custom serializers under `app/serializers` provide clean and consistent JSON responses.

## Local Setup

### 1. Clone and install dependencies
```bash
git clone <your-repo-url>
cd FairShare
bundle install
```

### 2. Start PostgreSQL
If using Homebrew:
```bash
brew install postgresql@16
brew services start postgresql@16
```

### 3. Create and migrate database
```bash
bundle exec rails db:create db:migrate
```

### 4. Seed demo data
```bash
bundle exec rails db:seed
```

### 5. Run the API
```bash
bundle exec rails server
```

API runs by default at `http://localhost:3000`.

## Authentication

All protected endpoints require:

`Authorization: Bearer <JWT_TOKEN>`

## API Endpoints

## `POST /auth/register`
Register a new user.

Request:
```json
{
  "name": "Alex Johnson",
  "email": "alex@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

Response (`201`):
```json
{
  "token": "<jwt>",
  "user": {
    "id": 1,
    "name": "Alex Johnson",
    "email": "alex@example.com"
  }
}
```

## `POST /auth/login`
Login with email and password.

Request:
```json
{
  "email": "alex@example.com",
  "password": "password123"
}
```

Response (`200`):
```json
{
  "token": "<jwt>",
  "user": {
    "id": 1,
    "name": "Alex Johnson",
    "email": "alex@example.com"
  }
}
```

## `GET /groups`
List groups for the authenticated user.

Response (`200`):
```json
{
  "groups": [
    {
      "id": 1,
      "name": "Roommates",
      "creator": { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" },
      "members": [
        { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" },
        { "id": 2, "name": "Sam Lee", "email": "sam@example.com" }
      ],
      "created_at": "2026-04-06T19:00:00.000Z",
      "updated_at": "2026-04-06T19:00:00.000Z"
    }
  ]
}
```

## `POST /groups`
Create a group. The creator is added as admin membership.

Request:
```json
{
  "name": "Trip to NYC"
}
```

Response (`201`):
```json
{
  "group": {
    "id": 2,
    "name": "Trip to NYC",
    "creator": { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" },
    "members": [
      { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" }
    ],
    "created_at": "2026-04-06T19:00:00.000Z",
    "updated_at": "2026-04-06T19:00:00.000Z"
  }
}
```

## `GET /groups/:id`
Get group details.

Response (`200`):
```json
{
  "group": {
    "id": 1,
    "name": "Roommates",
    "creator": { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" },
    "members": [
      { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" },
      { "id": 2, "name": "Sam Lee", "email": "sam@example.com" },
      { "id": 3, "name": "Jordan Patel", "email": "jordan@example.com" }
    ],
    "created_at": "2026-04-06T19:00:00.000Z",
    "updated_at": "2026-04-06T19:00:00.000Z"
  }
}
```

## `DELETE /groups/:id`
Leave a group. If the last member leaves, the group is deleted.

Response: `204 No Content`

## `POST /groups/:id/members`
Invite/add an existing user by email.

Request:
```json
{
  "email": "sam@example.com"
}
```

Response (`201`):
```json
{
  "member": {
    "id": 2,
    "name": "Sam Lee",
    "email": "sam@example.com"
  }
}
```

## `POST /groups/:id/expenses`
Create a group expense.

### Equal split example
Request:
```json
{
  "description": "Groceries",
  "amount": "96.00",
  "payer_id": 1,
  "split_type": "equal"
}
```

### Custom split example
Request:
```json
{
  "description": "Internet Bill",
  "amount": "60.00",
  "payer_id": 2,
  "split_type": "custom",
  "custom_splits": [
    { "user_id": 1, "amount": "30.00" },
    { "user_id": 2, "amount": "15.00" },
    { "user_id": 3, "amount": "15.00" }
  ]
}
```

Response (`201`):
```json
{
  "expense": {
    "id": 10,
    "description": "Internet Bill",
    "amount": "60.00",
    "split_type": "custom",
    "payer": { "id": 2, "name": "Sam Lee", "email": "sam@example.com" },
    "splits": [
      { "user": { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" }, "amount": "30.00" },
      { "user": { "id": 2, "name": "Sam Lee", "email": "sam@example.com" }, "amount": "15.00" },
      { "user": { "id": 3, "name": "Jordan Patel", "email": "jordan@example.com" }, "amount": "15.00" }
    ],
    "created_at": "2026-04-06T19:00:00.000Z"
  }
}
```

## `GET /groups/:id/expenses`
List expenses for a group (newest first).

Response (`200`):
```json
{
  "expenses": [
    {
      "id": 10,
      "description": "Internet Bill",
      "amount": "60.00",
      "split_type": "custom",
      "payer": { "id": 2, "name": "Sam Lee", "email": "sam@example.com" },
      "splits": [],
      "created_at": "2026-04-06T19:00:00.000Z"
    }
  ]
}
```

## `DELETE /groups/:id/expenses/:expense_id`
Delete an expense (payer or group creator only).

Response: `204 No Content`

## `GET /groups/:id/balances`
Get simplified balances for the group.

Response (`200`):
```json
{
  "balances": [
    {
      "from_user": { "id": 3, "name": "Jordan Patel" },
      "to_user": { "id": 1, "name": "Alex Johnson" },
      "amount": "10.00"
    }
  ]
}
```

## `POST /groups/:id/settlements`
Settle debt from current user to another user.

Request:
```json
{
  "to_user_id": 1,
  "amount": "10.00"
}
```

Response (`201`):
```json
{
  "settlement": {
    "id": 5,
    "from_user": { "id": 3, "name": "Jordan Patel", "email": "jordan@example.com" },
    "to_user": { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" },
    "amount": "10.00",
    "created_at": "2026-04-06T19:00:00.000Z"
  }
}
```

## `GET /groups/:id/activity`
Get latest group activity (expenses and settlements).

Response (`200`):
```json
{
  "activity": [
    {
      "id": 14,
      "action_type": "settlement_created",
      "actor": { "id": 3, "name": "Jordan Patel", "email": "jordan@example.com" },
      "created_at": "2026-04-06T19:00:00.000Z",
      "item": {
        "id": 5,
        "from_user": { "id": 3, "name": "Jordan Patel", "email": "jordan@example.com" },
        "to_user": { "id": 1, "name": "Alex Johnson", "email": "alex@example.com" },
        "amount": "10.00",
        "created_at": "2026-04-06T19:00:00.000Z"
      }
    }
  ]
}
```

## Error Handling

Errors use structured JSON with appropriate status codes, for example:

```json
{
  "error": "Missing authentication token"
}
```

or

```json
{
  "error": ["Email has already been taken"]
}
```

## Running Tests

```bash
bundle exec rspec
```

Current suite includes model and core service object coverage, including:
- `ExpenseSplitter`
- `BalanceCalculator`

## Deploying to Render (Free Tier)

### Recommended services
- 1 Web Service (this Rails API)
- 1 Managed PostgreSQL instance (free tier if available)

### Required environment variables
- `RAILS_ENV=production`
- `SECRET_KEY_BASE=<generated-secret>`
- `DATABASE_URL=<render-postgres-url>`

### Build and start commands
- Build: `bundle install && bundle exec rails db:migrate`
- Start: `bundle exec puma -C config/puma.rb`

You can also run `bundle exec rails db:seed` once after first deploy to load demo data.
