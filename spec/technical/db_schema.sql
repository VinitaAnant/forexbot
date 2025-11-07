This detailed specification document outlines the database structure for the Foreign Exchange Trading Bot, based on the provided PRD. It focuses on clarity, relationships, and data integrity.

---

# Database Structure Definition (SQL)

This section defines the database schema for the Forex Trading Bot, covering entities related to users, strategies, trades, market data, and system configurations. The schema is designed for a relational database, with PostgreSQL as the assumed RDBMS for its robustness and support for various data types.

## 1. Naming Conventions

*   **Tables:** Plural, snake_case (e.g., `users`, `strategies`).
*   **Columns:** Singular, snake_case (e.g., `id`, `user_id`, `strategy_name`).
*   **Primary Keys:** `id` (auto-incrementing BIGINT).
*   **Foreign Keys:** `related_table_id`.
*   **Indexes:** `idx_tablename_columnname`.
*   **Constraints:** `fk_tablename_columnname_relatedtable`.

## 2. Global Enums / Lookup Tables

To maintain data consistency and ease management, several enumerated types will be used. These can be implemented as `ENUM` types in PostgreSQL or as separate lookup tables. For broader compatibility and extensibility, lookup tables are generally preferred.

### `lookup_currency_pairs` (Lookup Table)

Stores all supported currency pairs.
*This table would typically be pre-populated and managed by the system.*

| Column Name | Data Type | Constraints             | Description                        |
| :---------- | :-------- | :---------------------- | :--------------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL   | Unique ID for the currency pair    |
| `symbol`    | VARCHAR(10) | UNIQUE, NOT NULL        | e.g., "EURUSD", "GBPUSD", "XAUUSD" |
| `base_currency` | VARCHAR(3) | NOT NULL            | e.g., "EUR"                        |
| `quote_currency`| VARCHAR(3) | NOT NULL            | e.g., "USD"                        |
| `is_active` | BOOLEAN   | NOT NULL, DEFAULT TRUE  | Whether the pair is currently tradeable |
| `min_trade_size`| DECIMAL(18, 8) | NOT NULL        | Minimum trade size for this pair   |
| `pip_decimal_places`| SMALLINT | NOT NULL         | Number of decimal places for PIP calculation | *e.g., 4 for EURUSD, 2 for USDJPY* |

```sql
CREATE TABLE lookup_currency_pairs (
    id BIGSERIAL PRIMARY KEY,
    symbol VARCHAR(10) UNIQUE NOT NULL,
    base_currency VARCHAR(3) NOT NULL,
    quote_currency VARCHAR(3) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    min_trade_size DECIMAL(18, 8) NOT NULL,
    pip_decimal_places SMALLINT NOT NULL
);

CREATE INDEX idx_currency_pairs_symbol ON lookup_currency_pairs (symbol);
```

### `lookup_timeframes` (Lookup Table)

Defines supported timeframes for strategies and charts.

| Column Name | Data Type | Constraints             | Description                  |
| :---------- | :-------- | :---------------------- | :--------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL   | Unique ID                    |
| `name`      | VARCHAR(10) | UNIQUE, NOT NULL        | e.g., "1M", "5M", "1H", "1D" |
| `duration_seconds`| INT   | UNIQUE, NOT NULL        | Duration in seconds          |

```sql
CREATE TABLE lookup_timeframes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(10) UNIQUE NOT NULL,
    duration_seconds INT UNIQUE NOT NULL
);

CREATE INDEX idx_timeframes_name ON lookup_timeframes (name);
```

### `lookup_indicator_types` (Lookup Table)

Defines supported technical indicators.

| Column Name | Data Type | Constraints             | Description                       |
| :---------- | :-------- | :---------------------- | :-------------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL   | Unique ID                         |
| `name`      | VARCHAR(50) | UNIQUE, NOT NULL        | e.g., "RSI", "MACD", "Moving Average" |
| `code`      | VARCHAR(50) | UNIQUE, NOT NULL        | Unique internal code for the indicator |
| `description`| TEXT      |                         | Description of the indicator      |

```sql
CREATE TABLE lookup_indicator_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE INDEX idx_indicator_types_code ON lookup_indicator_types (code);
```

### `lookup_strategy_types` (Lookup Table)

Defines common strategy types.

| Column Name | Data Type | Constraints             | Description                       |
| :---------- | :-------- | :---------------------- | :-------------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL   | Unique ID                         |
| `name`      | VARCHAR(50) | UNIQUE, NOT NULL        | e.g., "Trend Following", "Mean Reversion", "Breakout" |
| `description`| TEXT      |                         | Description of the strategy type  |

```sql
CREATE TABLE lookup_strategy_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);
```

### `lookup_broker_platforms` (Lookup Table)

Lists supported broker platforms.

| Column Name | Data Type | Constraints             | Description                  |
| :---------- | :-------- | :---------------------- | :--------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL   | Unique ID                    |
| `name`      | VARCHAR(50) | UNIQUE, NOT NULL        | e.g., "MetaTrader 4", "MetaTrader 5", "cTrader", "Custom API" |
| `is_active` | BOOLEAN   | NOT NULL, DEFAULT TRUE  | Whether the platform is currently supported |

```sql
CREATE TABLE lookup_broker_platforms (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);
```

## 3. Core Entities

### `users`

Stores user account information.

| Column Name | Data Type | Constraints                    | Description                                  |
| :---------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL          | Unique user ID                               |
| `username`  | VARCHAR(50) | UNIQUE, NOT NULL               | User's chosen username                       |
| `email`     | VARCHAR(100) | UNIQUE, NOT NULL              | User's email address                         |
| `password_hash`| VARCHAR(255) | NOT NULL                   | Hashed password (e.g., bcrypt)               |
| `first_name`| VARCHAR(50) |                                | User's first name                            |
| `last_name` | VARCHAR(50) |                                | User's last name                             |
| `created_at`| TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | Timestamp of user creation              |
| `updated_at`| TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | Last update timestamp                   |
| `last_login_at`| TIMESTAMP WITH TIME ZONE |                    | Last login timestamp                         |
| `is_active` | BOOLEAN   | NOT NULL, DEFAULT TRUE         | Account status                               |
| `is_admin`  | BOOLEAN   | NOT NULL, DEFAULT FALSE        | Admin privileges                             |
| `two_factor_enabled`| BOOLEAN | NOT NULL, DEFAULT FALSE    | Is 2FA enabled for this user?                |

```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    two_factor_enabled BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_users_email ON users (email);
```

### `api_keys`

Stores API keys for third-party services (e.g., historical data providers, some brokers).

| Column Name | Data Type | Constraints                   | Description                                  |
| :---------- | :-------- | :---------------------------- | :------------------------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL         | Unique ID                                    |
| `user_id`   | BIGINT    | NOT NULL, FOREIGN KEY(users)  | User who owns this API key                   |
| `service_name`| VARCHAR(100) | NOT NULL                  | Name of the service (e.g., "Oanda FX Trade", "Historical Data Provider X") |
| `api_key_encrypted`| TEXT | NOT NULL                    | Encrypted API key (store securely)           |
| `secret_key_encrypted`| TEXT |                         | Encrypted Secret Key (if applicable)         |
| `expires_at`| TIMESTAMP WITH TIME ZONE |              | Expiration date for the key                  |
| `is_active` | BOOLEAN   | NOT NULL, DEFAULT TRUE        | Whether the API key is active                |
| `created_at`| TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |
| `updated_at`| TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |

```sql
CREATE TABLE api_keys (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    api_key_encrypted TEXT NOT NULL, -- Stored encrypted
    secret_key_encrypted TEXT,       -- Stored encrypted (optional)
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_api_keys_user_id ON api_keys (user_id);
```

### `broker_accounts`

Stores details for user-connected broker accounts. API credentials should be encrypted.

| Column Name | Data Type | Constraints                   | Description                                  |
| :---------- | :-------- | :---------------------------- | :------------------------------------------- |
| `id`        | BIGINT    | PRIMARY KEY, NOT NULL         | Unique ID for broker account                 |
| `user_id`   | BIGINT    | NOT NULL, FOREIGN KEY(users)  | Owner of the broker account                  |
| `broker_ref_id` | VARCHAR(100) | UNIQUE NOT NULL          | Unique ID assigned by the broker for this account |
| `broker_platform_id`| BIGINT | NOT NULL, FOREIGN KEY(lookup_broker_platforms) | Type of broker platform     |
| `account_alias`| VARCHAR(100) | NOT NULL                 | User-friendly name for the account           |
| `api_credentials_encrypted`| TEXT | NOT NULL            | Encrypted JSON/YAML string of API credentials |
| `is_demo`   | BOOLEAN   | NOT NULL, DEFAULT FALSE       | Is this a demo account?                      |
| `is_active` | BOOLEAN   | NOT NULL, DEFAULT TRUE        | Is this account currently active for trading? |
| `last_sync_at`| TIMESTAMP WITH TIME ZONE |              | Last time account balance/positions were synced |
| `created_at`| TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |
| `updated_at`| TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |

```sql
CREATE TABLE broker_accounts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    broker_ref_id VARCHAR(100) NOT NULL,
    broker_platform_id BIGINT NOT NULL REFERENCES lookup_broker_platforms (id),
    account_alias VARCHAR(100) NOT NULL,
    api_credentials_encrypted TEXT NOT NULL, -- Encrypted JSON string
    is_demo BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, broker_ref_id) -- A user cannot have two identical broker accounts
);

CREATE INDEX idx_broker_accounts_user_id ON broker_accounts (user_id);
CREATE INDEX idx_broker_accounts_broker_platform_id ON broker_accounts (broker_platform_id);
```

### `strategies`

Parent table for all trading strategies, whether custom-built, from a library, or scripted.

| Column Name       | Data Type | Constraints                    | Description                                  |
| :---------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`              | BIGINT    | PRIMARY KEY, NOT NULL          | Unique strategy ID                           |
| `user_id`         | BIGINT    | NOT NULL, FOREIGN KEY(users)   | User who created/owns this strategy          |
| `name`            | VARCHAR(100) | NOT NULL                      | User-defined name for the strategy           |
| `description`     | TEXT      |                                | Detailed description of the strategy         |
| `strategy_type_id`| BIGINT    | FOREIGN KEY(lookup_strategy_types) | General category of the strategy (optional) |
| `creation_method` | VARCHAR(20) | NOT NULL                      | 'GUI', 'SCRIPT', 'LIBRARY'                   |
| `is_active`       | BOOLEAN   | NOT NULL, DEFAULT TRUE         | Whether the strategy is active and ready for use/deployment |
| `is_public`       | BOOLEAN   | NOT NULL, DEFAULT FALSE        | Can other users view/use this strategy?      |
| `version`         | VARCHAR(20) | NOT NULL, DEFAULT '1.0'        | Strategy version for version control         |
| `created_at`      | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |
| `updated_at`      | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |

```sql
CREATE TABLE strategies (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    strategy_type_id BIGINT REFERENCES lookup_strategy_types (id),
    creation_method VARCHAR(20) NOT NULL CHECK (creation_method IN ('GUI', 'SCRIPT', 'LIBRARY')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_strategies_user_id ON strategies (user_id);
CREATE INDEX idx_strategies_name ON strategies (name);
```

### `strategy_configurations`

Stores the detailed definition of a strategy. This could be a JSON representation for GUI-built strategies or the script itself for custom ones.

| Column Name            | Data Type | Constraints                    | Description                                  |
| :--------------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`                   | BIGINT    | PRIMARY KEY, NOT NULL          | Unique config ID                             |
| `strategy_id`          | BIGINT    | NOT NULL, FOREIGN KEY(strategies) | Parent strategy ID                       |
| `currency_pair_id`     | BIGINT    | NOT NULL, FOREIGN KEY(lookup_currency_pairs) | Currency pair for this configuration |
| `timeframe_id`         | BIGINT    | NOT NULL, FOREIGN KEY(lookup_timeframes) | Timeframe for this config                |
| `configuration_json`   | JSONB     |                                | JSON representation of GUI-built rules/parameters |
| `script_content`       | TEXT      |                                | Raw script content (e.g., Python code) for SCRIPT strategies |
| `parameters_json`      | JSONB     |                                | JSON for optimized/fixed parameters (e.g. for pre-built strategies) |
| `is_active_config`     | BOOLEAN   | NOT NULL, DEFAULT TRUE         | Is this specific configuration active?       |
| `created_at`           | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |
| `updated_at`           | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |
| `unique_config_hash`   | VARCHAR(64) | UNIQUE                     | SHA256 hash of configuration_json or script_content for uniqueness and versioning. |

```sql
CREATE TABLE strategy_configurations (
    id BIGSERIAL PRIMARY KEY,
    strategy_id BIGINT NOT NULL REFERENCES strategies (id) ON DELETE CASCADE,
    currency_pair_id BIGINT NOT NULL REFERENCES lookup_currency_pairs (id),
    timeframe_id BIGINT NOT NULL REFERENCES lookup_timeframes (id),
    configuration_json JSONB,
    script_content TEXT,
    parameters_json JSONB, -- For optimized or pre-defined parameters
    is_active_config BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    unique_config_hash VARCHAR(64) UNIQUE, -- SHA256 hash of relevant config data
    UNIQUE (strategy_id, currency_pair_id, timeframe_id, unique_config_hash) -- Prevent duplicate identical configs
);

CREATE INDEX idx_strategy_configs_strategy_id ON strategy_configurations (strategy_id);
CREATE INDEX idx_strategy_configs_currency_timeframe ON strategy_configurations (currency_pair_id, timeframe_id);
CREATE INDEX idx_strategy_configs_hash ON strategy_configurations (unique_config_hash);
```

### `deployed_bots`

Represents an active instance of a strategy running live or in paper trading.

| Column Name            | Data Type | Constraints                    | Description                                  |
| :--------------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`                   | BIGINT    | PRIMARY KEY, NOT NULL          | Unique bot instance ID                       |
| `user_id`              | BIGINT    | NOT NULL, FOREIGN KEY(users)   | User deploying the bot                       |
| `strategy_config_id`   | BIGINT    | NOT NULL, FOREIGN KEY(strategy_configurations) | Specific configuration being deployed |
| `broker_account_id`    | BIGINT    | NOT NULL, FOREIGN KEY(broker_accounts) | Broker account where this bot trades     |
| `name`                 | VARCHAR(100) | NOT NULL                      | User-defined name for this deployed bot      |
| `status`               | VARCHAR(20) | NOT NULL                     | 'ACTIVE', 'PAUSED', 'STOPPED', 'ERROR'       |
| `is_paper_trading`     | BOOLEAN   | NOT NULL, DEFAULT FALSE        | True if this is a paper trading instance     |
| `risk_per_trade_percent`| DECIMAL(5, 2) | NOT NULL, DEFAULT 1.0     | % of portfolio to risk per trade (e.g., 1.0 = 1%) |
| `max_daily_drawdown_percent`| DECIMAL(5, 2) |                     | Max drawdown before bot pauses or stops      |
| `max_open_trades`      | INT       |                                | Max concurrent open trades for this bot      |
| `start_time`           | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | When the bot was activated                   |
| `stop_time`            | TIMESTAMP WITH TIME ZONE |                    | When the bot was stopped (null if active)    |
| `last_heartbeat_at`    | TIMESTAMP WITH TIME ZONE |                    | Last successful communication from the bot process |
| `created_at`           | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |
| `updated_at`           | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |

```sql
CREATE TYPE bot_status AS ENUM ('ACTIVE', 'PAUSED', 'STOPPED', 'ERROR');

CREATE TABLE deployed_bots (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    strategy_config_id BIGINT NOT NULL REFERENCES strategy_configurations (id) ON DELETE CASCADE,
    broker_account_id BIGINT NOT NULL REFERENCES broker_accounts (id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    status bot_status NOT NULL DEFAULT 'ACTIVE',
    is_paper_trading BOOLEAN NOT NULL DEFAULT FALSE,
    risk_per_trade_percent DECIMAL(5, 2) NOT NULL DEFAULT 1.0, -- e.g., 1.00 for 1%
    max_daily_drawdown_percent DECIMAL(5, 2),
    max_open_trades INT,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    stop_time TIMESTAMP WITH TIME ZONE,
    last_heartbeat_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (strategy_config_id, broker_account_id, name) -- A specific strategy config cannot be deployed multiple times to the same account with the same name simultaneously
);

CREATE INDEX idx_deployed_bots_user_id ON deployed_bots (user_id);
CREATE INDEX idx_deployed_bots_strategy_config_id ON deployed_bots (strategy_config_id);
CREATE INDEX idx_deployed_bots_broker_account_id ON deployed_bots (broker_account_id);
CREATE INDEX idx_deployed_bots_status ON deployed_bots (status);
```

### `trades`

Logs all executed trades by bots or manual entries through the system.

| Column Name            | Data Type | Constraints                    | Description                                  |
| :--------------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`                   | BIGINT    | PRIMARY KEY, NOT NULL          | Unique trade ID                              |
| `deployed_bot_id`      | BIGINT    | FOREIGN KEY(deployed_bots)     | Which bot initiated this trade (NULL for manual/system trades) |
| `broker_account_id`    | BIGINT    | NOT NULL, FOREIGN KEY(broker_accounts) | Account where trade happened             |
| `currency_pair_id`     | BIGINT    | NOT NULL, FOREIGN KEY(lookup_currency_pairs) | Currency pair traded                 |
| `order_id_broker`      | VARCHAR(100) | NOT NULL                     | Broker's unique order ID                     |
| `trade_type`           | VARCHAR(10) | NOT NULL                     | 'BUY' or 'SELL'                              |
| `quantity`             | DECIMAL(18, 8) | NOT NULL                  | Lot size / traded volume                     |
| `entry_price`          | DECIMAL(18, 5) | NOT NULL                  | Price at which the trade was opened          |
| `exit_price`           | DECIMAL(18, 5) |                         | Price at which the trade was closed          |
| `stop_loss`            | DECIMAL(18, 5) |                         | Initial stop-loss price                      |
| `take_profit`          | DECIMAL(18, 5) |                         | Take-profit price                            |
| `status`               | VARCHAR(20) | NOT NULL                     | 'OPEN', 'CLOSED', 'PENDING', 'CANCELLED'     |
| `open_time`            | TIMESTAMP WITH TIME ZONE | NOT NULL         | When the trade was opened                    |
| `close_time`           | TIMESTAMP WITH TIME ZONE |                    | When the trade was closed (NULL if open)     |
| `profit_loss`          | DECIMAL(18, 2) |                         | Profit or loss in account currency           |
| `commission`           | DECIMAL(18, 2) | DEFAULT 0.0               | Commission paid for the trade                |
| `swap_fees`            | DECIMAL(18, 2) | DEFAULT 0.0               | Swap fees incurred                           |
| `metadata_json`        | JSONB     |                                | Additional trade-specific metadata (e.g., signal source) |
| `created_at`           | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |
| `updated_at`           | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |

```sql
CREATE TYPE trade_type AS ENUM ('BUY', 'SELL');
CREATE TYPE trade_status AS ENUM ('OPEN', 'CLOSED', 'PENDING', 'CANCELLED');

CREATE TABLE trades (
    id BIGSERIAL PRIMARY KEY,
    deployed_bot_id BIGINT REFERENCES deployed_bots (id) ON DELETE SET NULL, -- Allow bot to be deleted without deleting trade history
    broker_account_id BIGINT NOT NULL REFERENCES broker_accounts (id) ON DELETE CASCADE,
    currency_pair_id BIGINT NOT NULL REFERENCES lookup_currency_pairs (id),
    order_id_broker VARCHAR(100) NOT NULL, -- Broker's internal order ID
    trade_type trade_type NOT NULL,
    quantity DECIMAL(18, 8) NOT NULL,
    entry_price DECIMAL(18, 5) NOT NULL,
    exit_price DECIMAL(18, 5),
    stop_loss DECIMAL(18, 5),
    take_profit DECIMAL(18, 5),
    status trade_status NOT NULL DEFAULT 'PENDING',
    open_time TIMESTAMP WITH TIME ZONE NOT NULL,
    close_time TIMESTAMP WITH TIME ZONE,
    profit_loss DECIMAL(18, 2),
    commission DECIMAL(18, 2) DEFAULT 0.0,
    swap_fees DECIMAL(18, 2) DEFAULT 0.0,
    metadata_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (broker_account_id, order_id_broker) -- A trade is unique per broker account and its order ID
);

CREATE INDEX idx_trades_deployed_bot_id ON trades (deployed_bot_id);
CREATE INDEX idx_trades_broker_account_id ON trades (broker_account_id);
CREATE INDEX idx_trades_currency_pair_id ON trades (currency_pair_id);
CREATE INDEX idx_trades_status ON trades (status);
CREATE INDEX idx_trades_open_time ON trades (open_time);
```

## 4. Backtesting and Optimization

### `backtest_results`

Stores the summary results of each backtest run.

| Column Name         | Data Type | Constraints                    | Description                                  |
| :------------------ | :-------- | :----------------------------- | :------------------------------------------- |
| `id`                | BIGINT    | PRIMARY KEY, NOT NULL          | Unique backtest result ID                    |
| `user_id`           | BIGINT    | NOT NULL, FOREIGN KEY(users)   | User who initiated the backtest              |
| `strategy_config_id`| BIGINT    | NOT NULL, FOREIGN KEY(strategy_configurations) | Configuration tested                 |
| `start_date`        | DATE      | NOT NULL                       | Start date of the historical data used       |
| `end_date`          | DATE      | NOT NULL                       | End date of the historical data used         |
| `initial_equity`    | DECIMAL(18, 2) | NOT NULL                  | Starting capital for the backtest            |
| `final_equity`      | DECIMAL(18, 2) | NOT NULL                  | Ending capital after the backtest            |
| `total_profit_loss` | DECIMAL(18, 2) |                          | Total profit/loss                            |
| `net_profit_percent`| DECIMAL(5, 2) |                          | Net profit as a percentage of initial equity |
| `max_drawdown_percent`| DECIMAL(5, 2) |                          | Maximum drawdown experienced                 |
| `sharpe_ratio`      | DECIMAL(10, 4) |                         | Sharpe Ratio                                 |
| `win_rate_percent`  | DECIMAL(5, 2) |                          | Percentage of winning trades                 |
| `num_total_trades`  | INT       | NOT NULL                       | Total number of trades in backtest           |
| `report_json`       | JSONB     |                                | Full detailed report (e.g., equity curve data, trade list excerpts)|
| `run_time_seconds`  | INT       |                                | Duration of the backtest                     |
| `completed_at`      | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | When the backtest finished             |
| `status`            | VARCHAR(20) | NOT NULL                     | 'SUCCESS', 'FAILED', 'RUNNING'               |

```sql
CREATE TYPE backtest_status AS ENUM ('SUCCESS', 'FAILED', 'RUNNING');

CREATE TABLE backtest_results (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    strategy_config_id BIGINT NOT NULL REFERENCES strategy_configurations (id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    initial_equity DECIMAL(18, 2) NOT NULL,
    final_equity DECIMAL(18, 2), -- Can be NULL if still running or failed
    total_profit_loss DECIMAL(18, 2),
    net_profit_percent DECIMAL(5, 2),
    max_drawdown_percent DECIMAL(5, 2),
    sharpe_ratio DECIMAL(10, 4),
    win_rate_percent DECIMAL(5, 2),
    num_total_trades INT,
    report_json JSONB, -- Stores detailed report including equity curve, trade list, etc.
    run_time_seconds INT,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    status backtest_status NOT NULL DEFAULT 'RUNNING'
);

CREATE INDEX idx_backtest_results_user_id ON backtest_results (user_id);
CREATE INDEX idx_backtest_results_strategy_config_id ON backtest_results (strategy_config_id);
CREATE INDEX idx_backtest_results_completed_at ON backtest_results (completed_at);
```

### `optimization_runs`

Records each strategy optimization attempt.

| Column Name         | Data Type | Constraints                    | Description                                  |
| :------------------ | :-------- | :----------------------------- | :------------------------------------------- |
| `id`                | BIGINT    | PRIMARY KEY, NOT NULL          | Unique optimization run ID                   |
| `user_id`           | BIGINT    | NOT NULL, FOREIGN KEY(users)   | User who initiated the optimization          |
| `strategy_config_id`| BIGINT    | NOT NULL, FOREIGN KEY(strategy_configurations) | Base configuration for optimization  |
| `start_date`        | DATE      | NOT NULL                       | Optimization range start date                |
| `end_date`          | DATE      | NOT NULL                       | Optimization range end date                  |
| `optimization_method`| VARCHAR(50) | NOT NULL                    | e.g., 'GRID_SEARCH', 'GENETIC_ALGORITHM'     |
| `parameters_tested_json`| JSONB   | NOT NULL                     | JSON defining the parameters and ranges tested |
| `best_parameters_json`| JSONB   |                                | JSON of parameters that yielded the best result |
| `best_result_id`    | BIGINT    | FOREIGN KEY(backtest_results)  | Link to the best backtest result from this run |
| `start_time`        | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | When optimization started              |
| `end_time`          | TIMESTAMP WITH TIME ZONE |                    | When optimization finished (NULL if running) |
| `status`            | VARCHAR(20) | NOT NULL                     | 'COMPLETED', 'RUNNING', 'FAILED'             |
| `created_at`        | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() |                                            |

```sql
CREATE TYPE optimization_status AS ENUM ('COMPLETED', 'RUNNING', 'FAILED');

CREATE TABLE optimization_runs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    strategy_config_id BIGINT NOT NULL REFERENCES strategy_configurations (id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    optimization_method VARCHAR(50) NOT NULL,
    parameters_tested_json JSONB NOT NULL,
    best_parameters_json JSONB,
    best_result_id BIGINT REFERENCES backtest_results (id) ON DELETE SET NULL, -- Link to the specific backtest result
    start_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    status optimization_status NOT NULL DEFAULT 'RUNNING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_optimization_runs_user_id ON optimization_runs (user_id);
CREATE INDEX idx_optimization_runs_strategy_config_id ON optimization_runs (strategy_config_id);
```

## 5. Market Data (Time-Series)

*Note: For actual high-frequency market data, a dedicated time-series database (e.g., TimescaleDB, InfluxDB) or object storage (S3) for raw tick data would be more efficient. This schema provides a conceptual representation for OHLCV data within a relational context, suitable for most backtesting needs.*

### `ohlcv_data`

Stores historical Open-High-Low-Close-Volume (OHLCV) candle data. This table would be very large and heavily indexed.

| Column Name       | Data Type | Constraints                    | Description                                  |
| :---------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`              | BIGINT    | PRIMARY KEY, NOT NULL          | Unique candle ID                             |
| `currency_pair_id`| BIGINT    | NOT NULL, FOREIGN KEY(lookup_currency_pairs) | Currency pair ID                     |
| `timeframe_id`    | BIGINT    | NOT NULL, FOREIGN KEY(lookup_timeframes) | Timeframe ID                       |
| `timestamp`       | TIMESTAMP WITH TIME ZONE | NOT NULL       | Start time of the candle (e.g., 2023-01-01 00:00:00 UTC) |
| `open_price`      | DECIMAL(18, 5) | NOT NULL                  | Open price of the candle                     |
| `high_price`      | DECIMAL(18, 5) | NOT NULL                  | High price of the candle                     |
| `low_price`       | DECIMAL(18, 5) | NOT NULL                  | Low price of the candle                      |
| `close_price`     | DECIMAL(18, 5) | NOT NULL                  | Close price of the candle                    |
| `volume`          | BIGINT    |                                | Trading volume for the period                |
| `updated_at`      | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | Last update timestamp (for real-time data) |
| `data_source`     | VARCHAR(50) |                                | Source of the historical data (e.g., "Oanda", "Dukascopy") |

```sql
CREATE TABLE ohlcv_data (
    id BIGSERIAL PRIMARY KEY,
    currency_pair_id BIGINT NOT NULL REFERENCES lookup_currency_pairs (id),
    timeframe_id BIGINT NOT NULL REFERENCES lookup_timeframes (id),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    open_price DECIMAL(18, 5) NOT NULL,
    high_price DECIMAL(18, 5) NOT NULL,
    low_price DECIMAL(18, 5) NOT NULL,
    close_price DECIMAL(18, 5) NOT NULL,
    volume BIGINT,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    data_source VARCHAR(50),
    UNIQUE (currency_pair_id, timeframe_id, timestamp) -- Ensure unique candles
);

CREATE INDEX idx_ohlcv_data_currency_timeframe_timestamp ON ohlcv_data (currency_pair_id, timeframe_id, timestamp DESC);
CREATE INDEX idx_ohlcv_data_timestamp ON ohlcv_data (timestamp DESC);
```

## 6. System Logging and Monitoring

### `bot_logs`

Stores operational logs from deployed bots. Essential for debugging and monitoring.

| Column Name            | Data Type | Constraints                    | Description                                  |
| :--------------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`                   | BIGINT    | PRIMARY KEY, NOT NULL          | Unique log entry ID                          |
| `deployed_bot_id`      | BIGINT    | FOREIGN KEY(deployed_bots)     | Which bot generated this log (NULL for global system logs) |
| `timestamp`            | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | When the log was recorded             |
| `log_level`            | VARCHAR(20) | NOT NULL                     | 'INFO', 'WARNING', 'ERROR', 'DEBUG'          |
| `message`              | TEXT      | NOT NULL                       | The log message                              |
| `context_json`         | JSONB     |                                | Additional contextual data (e.g., order ID, indicator values) |

```sql
CREATE TYPE log_level_enum AS ENUM ('INFO', 'WARNING', 'ERROR', 'DEBUG');

CREATE TABLE bot_logs (
    id BIGSERIAL PRIMARY KEY,
    deployed_bot_id BIGINT REFERENCES deployed_bots (id) ON DELETE SET NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    log_level log_level_enum NOT NULL,
    message TEXT NOT NULL,
    context_json JSONB
);

CREATE INDEX idx_bot_logs_deployed_bot_id ON bot_logs (deployed_bot_id);
CREATE INDEX idx_bot_logs_timestamp ON bot_logs (timestamp DESC);
CREATE INDEX idx_bot_logs_log_level ON bot_logs (log_level);
```

### `alerts`

Records triggered alerts for users.

| Column Name    | Data Type | Constraints                    | Description                                  |
| :------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`           | BIGINT    | PRIMARY KEY, NOT NULL          | Unique alert ID                              |
| `user_id`      | BIGINT    | NOT NULL, FOREIGN KEY(users)   | User to whom the alert belongs               |
| `deployed_bot_id`| BIGINT    | FOREIGN KEY(deployed_bots)     | Bot that triggered the alert (optional)      |
| `alert_type`   | VARCHAR(50) | NOT NULL                     | e.g., 'TRADE_EXECUTION', 'ERROR', 'DRAWDOWN_LIMIT', 'HEARTBEAT_MISSED' |
| `message`      | TEXT      | NOT NULL                       | Detailed alert message                       |
| `is_read`      | BOOLEAN   | NOT NULL, DEFAULT FALSE        | Has the user acknowledged the alert?         |
| `triggered_at` | TIMESTAMP WITH TIME ZONE | NOT NULL, DEFAULT NOW() | When the alert was generated           |
| `delivery_method`| VARCHAR(20) |                             | 'EMAIL', 'SMS', 'IN_APP' (could be a separate table for multiple deliveries) |

```sql
CREATE TABLE alerts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    deployed_bot_id BIGINT REFERENCES deployed_bots (id) ON DELETE SET NULL,
    alert_type VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    triggered_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    delivery_method VARCHAR(20) -- e.g., 'EMAIL', 'SMS', 'IN_APP'
);

CREATE INDEX idx_alerts_user_id ON alerts (user_id);
CREATE INDEX idx_alerts_deployed_bot_id ON alerts (deployed_bot_id);
CREATE INDEX idx_alerts_triggered_at ON alerts (triggered_at DESC);
```

## 7. Reporting & Analytics

### `account_snapshots`

Periodic snapshots of broker account equity, balance, and other key metrics. Useful for equity curve generation and overall performance tracking.

| Column Name            | Data Type | Constraints                    | Description                                  |
| :--------------------- | :-------- | :----------------------------- | :------------------------------------------- |
| `id`                   | BIGINT    | PRIMARY KEY, NOT NULL          | Unique snapshot ID                           |
| `broker_account_id`    | BIGINT    | NOT NULL, FOREIGN KEY(broker_accounts) | Account being snapshotted                |
| `timestamp`            | TIMESTAMP WITH TIME ZONE | NOT NULL       | When the snapshot was taken                  |
| `balance`              | DECIMAL(18, 2) | NOT NULL                  | Account balance                              |
| `equity`               | DECIMAL(18, 2) | NOT NULL                  | Account equity (balance +/- unrealized P/L)  |
| `free_margin`          | DECIMAL(18, 2) |                         | Free margin available                        |
| `used_margin`          | DECIMAL(18, 2) |                         | Margin currently in use                      |
| `unrealized_profit_loss`| DECIMAL(18, 2) |                          | Unrealized P/L from open positions           |
| `currency_code`        | VARCHAR(3) | NOT NULL                     | Currency of the account                      |

```sql
CREATE TABLE account_snapshots (
    id BIGSERIAL PRIMARY KEY,
    broker_account_id BIGINT NOT NULL REFERENCES broker_accounts (id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    balance DECIMAL(18, 2) NOT NULL,
    equity DECIMAL(18, 2) NOT NULL,
    free_margin DECIMAL(18, 2),
    used_margin DECIMAL(18, 2),
    unrealized_profit_loss DECIMAL(18, 2),
    currency_code VARCHAR(3) NOT NULL,
    UNIQUE (broker_account_id, timestamp)
);

CREATE INDEX idx_account_snapshots_broker_account_id_timestamp ON account_snapshots (broker_account_id, timestamp DESC);
CREATE INDEX idx_account_snapshots_timestamp ON account_snapshots (timestamp DESC);
```

## 8. Indexing Strategy

*   Primary keys are automatically indexed.
*   Foreign keys are explicitly indexed for efficient join operations.
*   Columns frequently used in `WHERE`, `ORDER BY`, or `GROUP BY` clauses have additional indexes.
*   Unique constraints automatically create unique indexes.

## 9. Security Considerations

*   Sensitive data (`api_key_encrypted`, `secret_key_encrypted`, `api_credentials_encrypted`, `password_hash`) must be encrypted at rest and in transit.
*   `password_hash` should use a strong, slow hashing algorithm (e.g., bcrypt, Argon2).
*   API keys for brokers should never be stored in plain text.
*   Implement strict access control to the database.
*   Be mindful of SQL injection vulnerabilities by using parameterized queries.

## 10. Scalability Considerations

*   **Time-series data:** For `ohlcv_data` and extensive `bot_logs`, partitioning, sharding, or using a specialized time-series database (as noted above) would be crucial as data volume grows.
*   **Heavy writes:** `trades`, `bot_logs`, `account_snapshots` will experience high write volumes. Batch inserts and careful indexing are necessary.
*   **Backtesting:** The `backtest_results` and `optimization_runs` tables may grow quickly. Efficient querying of `ohlcv_data` heavily impacts backtesting performance.

---