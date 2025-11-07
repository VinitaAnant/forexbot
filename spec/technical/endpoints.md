The provided PRD outlines a comprehensive Forex Trading Bot. Below is a detailed API specification, focusing on the core functionalities requested, with explanations of the underlying business logic.

---

# Forex Trading Bot API Specification

## 1. Introduction

This document details the Application Programming Interfaces (APIs) for the Foreign Exchange Trading Bot. These APIs facilitate strategy management, backtesting, live execution, and comprehensive reporting, enabling users to interact programmatically with the trading bot's various functionalities.

## 2. Authentication & Authorization

All API endpoints require authentication.
*   **Authentication Method:** OAuth 2.0 (Client Credentials Flow for server-to-server, Authorization Code Flow for user interaction). JWT tokens will be used for stateless authentication.
*   **Authorization:** Role-Based Access Control (RBAC) will be implemented to grant specific permissions based on user roles (e.g., standard user, premium user, admin).
*   **API Key Management:** Users can generate and revoke API keys from their account settings.

**Example Request Header:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

## 3. Core Concepts & Data Models

### 3.1. CurrencyPair

Represents a tradable currency pair.
*   **`symbol`** (string, required): Standard currency pair symbol (e.g., "EUR/USD", "GBP/JPY").
*   **`baseCurrency`** (string, required): The base currency (e.g., "EUR").
*   **`quoteCurrency`** (string, required): The quote currency (e.g., "USD").
*   **`minTradeSize`** (number, required): Minimum Lot size for trading this pair.
*   **`pipPrecision`** (integer, required): Number of decimal places for pip calculation (e.g., 4 for EUR/USD, 2 for USD/JPY).

### 3.2. Timeframe

Represents a market data interval.
*   **`value`** (string, required): Enum: "M1", "M5", "M15", "M30", "H1", "H4", "D1", "W1", "MN1".

### 3.3. Indicator

Represents a technical indicator used in strategies.
*   **`id`** (string, required, UUID): Unique identifier for the indicator.
*   **`name`** (string, required): Name of the indicator (e.g., "RSI", "SMA").
*   **`type`** (string, required): Enum: "RSI", "SMA", "EMA", "MACD", "BollingerBands", "Stochastic", "ADX", "CustomScript".
*   **`parameters`** (object, required): Key-value pairs for indicator-specific parameters (e.g., `{"period": 14}` for RSI, `{"period": 20, "field": "close"}` for SMA).
*   **`scriptCode`** (string, optional): For `CustomScript` type, the Python or MQL-like script.

### 3.4. StrategyCondition

A single condition within a strategy (e.g., "RSI is oversold").
*   **`operand1`** (object, required): A value or an indicator output (e.g., `{"type": "indicator", "indicatorId": "rsi123", "outputField": "value"}`).
*   **`operator`** (string, required): Enum: "GREATER_THAN", "LESS_THAN", "EQUALS", "CROSS_ABOVE", "CROSS_BELOW".
*   **`operand2`** (object, required): A value or an indicator output (e.g., `{"type": "value", "value": 30}`).
*   **`timeframe`** (Timeframe, required): Timeframe to evaluate the condition.

### 3.5. StrategyRule

A collection of conditions combined with logical operators.
*   **`id`** (string, required, UUID): Unique identifier for the rule.
*   **`conditions`** (array of StrategyCondition, required).
*   **`logic`** (string, required): Logical combination of conditions. Enum: "ALL" (AND), "ANY" (OR), "CUSTOM" (requires `customLogic` field).
*   **`customLogic`** (string, optional): For "CUSTOM" logic, a boolean expression referencing condition IDs (e.g., "(C1 AND C2) OR C3").

### 3.6. Strategy

Represents a trading strategy.
*   **`id`** (string, required, UUID): Unique strategy identifier.
*   **`userId`** (string, required): Owner of the strategy.
*   **`name`** (string, required): User-defined name for the strategy.
*   **`description`** (string, optional).
*   **`symbol`** (CurrencyPair, required): Currency pair the strategy applies to.
*   **`timeframe`** (Timeframe, required): Primary timeframe for strategy evaluation.
*   **`indicators`** (array of Indicator, optional): Indicators used by the strategy.
*   **`entryRules`** (array of StrategyRule, required): Rules for opening a trade.
*   **`exitRules`** (array of StrategyRule, required): Rules for closing a trade (can be separate for Stop Loss, Take Profit, or conditions).
*   **`riskPerTrade`** (number, required): Percentage of account equity to risk per trade (e.g., 0.01 for 1%).
*   **`stopLossPips`** (number, optional): Fixed stop loss in pips. If dynamic, defined in `exitRules`.
*   **`takeProfitPips`** (number, optional): Fixed take profit in pips. If dynamic, defined in `exitRules`.
*   **`maxPositions`** (integer, required): Maximum number of open positions for this strategy.
*   **`status`** (string, required): Enum: "DRAFT", "ACTIVE", "PAUSED", "ARCHIVED".
*   **`createdAt`** (datetime, read-only): Timestamp of creation.
*   **`updatedAt`** (datetime, read-only): Timestamp of last update.

**Business Logic - Strategy Evaluation:**
1.  **Market Data Subscription:** When a strategy is `ACTIVE`, the system subscribes to real-time market data for the specified `symbol` and `timeframe`.
2.  **Indicator Calculation:** For each new market data update, all associated `indicators` are calculated.
3.  **Entry Rule Evaluation:** The `entryRules` are evaluated. If all conditions within any `StrategyRule` that evaluates to `true` according to its `logic` are met, an entry signal is generated.
4.  **Risk Management & Position Sizing:** Before placing an order, `riskPerTrade` and current account equity are used to calculate appropriate position size in lots, taking `stopLossPips` (if fixed) into account.
5.  **Order Placement:** A market or pending order is placed with the broker. Stop Loss and Take Profit orders are also placed or calculated for server-side management.
6.  **Exit Rule Evaluation:** While a position is open, `exitRules` are continuously evaluated. If conditions for an exit are met, a close order is generated. Fixed `stopLossPips` and `takeProfitPips` also trigger exits.
7.  **Concurrency:** Each active strategy runs independently, but their combined risk is aggregated for account-level risk management.

### 3.7. BacktestReport

Summary of a backtest execution.
*   **`id`** (string, required, UUID).
*   **`strategyId`** (string, required).
*   **`deviceName`** (string, required, UUID): Unique identifier for the device (e.g., server instance) the bot is running on.
*   **`startTime`** (datetime, required).
*   **`endTime`** (datetime, required).
*   **`initialBalance`** (number, required).
*   **`finalBalance`** (number, required).
*   **`netProfit`** (number, required): Total profit/loss in currency.
*   **`profitFactor`** (number, required): Gross Profit / Gross Loss.
*   **`maxDrawdown`** (number, required): Max percentage drawdown from a peak.
*   **`maxDrawdownAbs`** (number, required): Max absolute drawdown.
*   **`totalTrades`** (integer, required).
*   **`winningTrades`** (integer, required).
*   **`losingTrades`** (integer, required).
*   **`winRate`** (number, required): Percentage of winning trades.
*   **`avgWin`** (number, required): Average winning trade profit.
*   **`avgLoss`** (number, required): Average losing trade loss.
*   **`sharpeRatio`** (number, optional).
*   **`equityCurve`** (array of objects, optional): Timestamped balance progression `[{"timestamp": "...", "balance": 10500}]`.
*   **`reportDetailsLink`** (string, optional): URL to a more detailed report or chart.

**Business Logic - Backtesting:**
1.  **Data Playback:** Historical data for the specified `symbol` and `timeframe` is "played back" to the strategy.
2.  **Order Matching Simulation:** A simplified order matching engine simulates trade execution, accounting for `slippage` and `spread` parameters.
3.  **Deterministic Results:** The backtesting engine ensures that given the same strategy, parameters, and historical data, the results are identical every time.
4.  **Performance Calculation:** All metrics (`netProfit`, `maxDrawdown`, etc.) are calculated based on simulated trades.

### 3.8. OptimizationRun

Represents a parameter optimization job.
*   **`id`** (string, required, UUID).
*   **`strategyId`** (string, required).
*   **`status`** (string, required): Enum: "PENDING", "RUNNING", "COMPLETED", "FAILED".
*   **`optimizationType`** (string, required): Enum: "GRID_SEARCH", "GENETIC_ALGORITHM".
*   **`parametersToOptimize`** (array of objects, required): Defines variables and their ranges/steps.
    *   Example: `[{"indicatorId": "rsi123", "paramName": "period", "min": 10, "max": 20, "step": 1}]`
*   **`targetMetric`** (string, required): Metric to optimize for (e.g., "netProfit", "sharpeRatio", "maxDrawdown").
*   **`results`** (array of objects, optional): Each object contains parameters tested and the `BacktestReport` summary.
*   **`bestParameters`** (object, optional): The parameter set that yielded the best `targetMetric`.
*   **`createdAt`** (datetime, read-only).
*   **`completedAt`** (datetime, optional).

**Business Logic - Parameter Optimization:**
1.  **Parameter Iteration:** Based on `optimizationType`, the system either systematically (Grid Search) or adaptively (Genetic Algorithm) explores combinations of `parametersToOptimize`.
2.  **Repeated Backtesting:** For each parameter combination, a full backtest is executed using the specified `strategyId`.
3.  **Result Aggregation:** The `targetMetric` from each backtest is recorded, and the combination yielding the best value is identified as `bestParameters`.
4.  **Resource Intensive:** Optimization runs can be computationally expensive and may be queued or distributed across multiple workers.

### 3.9. BrokerConnection

Represents a secure connection to a broker account.
*   **`id`** (string, required, UUID).
*   **`userId`** (string, required).
*   **`brokerName`** (string, required): Enum: "MetaTrader4", "MetaTrader5", "cTrader", "CustomAPI".
*   **`accountNumber`** (string, required): Broker-specific account identifier.
*   **`apiType`** (string, required): Enum: "MT4_API", "MT5_API", "CTRADER_API", "REST_API", "WEBSOCKET_API".
*   **`apiKey`** (string, optional, encrypted): API key for REST/WebSocket/Custom APIs.
*   **`apiSecret`** (string, optional, encrypted): API secret for REST/WebSocket/Custom APIs.
*   **`password`** (string, optional, encrypted): Password for MT4/MT5/cTrader (less secure, but sometimes required).
*   **`serverAddress`** (string, required): Broker's server address (e.g., "demo.brokerxyz.com:443").
*   **`isLive`** (boolean, required): True for live trading, false for demo/paper trading.
*   **`status`** (string, required): Enum: "CONNECTED", "DISCONNECTED", "ERROR".
*   **`createdAt`** (datetime, read-only).
*   **`lastConnectedAt`** (datetime, optional).

**Business Logic - Broker Connectivity:**
1.  **Secure Storage:** All sensitive credentials (`apiKey`, `apiSecret`, `password`) are encrypted at rest.
2.  **Connection Management:** The system maintains persistent connections to brokers for active `BrokerConnection` instances, handling reconnections and error states.
3.  **API Abstraction:** An abstraction layer translates internal normalized order requests into broker-specific API calls.

### 3.10. Trade

Represents a single trade executed by the bot.
*   **`id`** (string, required, UUID).
*   **`strategyId`** (string, required): The strategy that initiated this trade.
*   **`brokerConnectionId`** (string, required).
*   **`symbol`** (CurrencyPair, required).
*   **`orderType`** (string, required): Enum: "MARKET", "LIMIT", "STOP".
*   **`side`** (string, required): Enum: "BUY", "SELL".
*   **`volume`** (number, required): Lot size.
*   **`entryPrice`** (number, required).
*   **`exitPrice`** (number, optional).
*   **`stopLossPrice`** (number, optional).
*   **`takeProfitPrice`** (number, optional).
*   **`openTime`** (datetime, required).
*   **`closeTime`** (datetime, optional).
*   **`profitPips`** (number, optional).
*   **`profitAmount`** (number, optional): Profit/Loss in quote currency.
*   **`status`** (string, required): Enum: "OPEN", "CLOSED", "PENDING", "CANCELLED", "ERROR".
*   **`createdAt`** (datetime, read-only).

**Business Logic - Trade & Order Management:**
1.  **Real-time Synchonization:** The system periodically or via webhook updates monitors open positions and orders with the broker.
2.  **Position Tracking:** Internal state mirrors the broker's actual positions.
3.  **Event-Driven Updates:** Upon order execution or modification, related `Trade` objects are updated.
4.  **Safety Checks:** Before any trade, the system performs a final risk check against account-level limits.

## 4. API Endpoints

### 4.1. Strategy Management

#### 4.1.1. Create Strategy
`POST /api/v1/strategies`
**Description:** Creates a new trading strategy.
**Request Body:** `Strategy` object (excluding `id`, `userId`, `createdAt`, `updatedAt`).
**Response:**
*   **201 Created:** `Strategy` object, including generated `id`.
*   **400 Bad Request:** Invalid input.
*   **401 Unauthorized:** Authentication failed.
*   **403 Forbidden:** User lacks permission.

**Business Logic:**
*   Ensures unique strategy name per user.
*   Validates all indicator parameters and rule structures.
*   Sets default `status` to "DRAFT".

#### 4.1.2. Get All Strategies
`GET /api/v1/strategies`
**Description:** Retrieves all strategies owned by the authenticated user.
**Query Parameters:**
*   `status` (string, optional): Filter by strategy status (e.g., "ACTIVE", "DRAFT").
*   `symbol` (string, optional): Filter by currency pair.
**Response:**
*   **200 OK:** Array of `Strategy` objects.
*   **401 Unauthorized:** Authentication failed.

#### 4.1.3. Get Strategy by ID
`GET /api/v1/strategies/{strategyId}`
**Description:** Retrieves a specific strategy.
**Response:**
*   **200 OK:** `Strategy` object.
*   **404 Not Found:** Strategy not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

#### 4.1.4. Update Strategy
`PUT /api/v1/strategies/{strategyId}`
**Description:** Updates an existing trading strategy.
**Request Body:** `Strategy` object (only fields to be updated are required).
**Response:**
*   **200 OK:** Updated `Strategy` object.
*   **400 Bad Request:** Invalid input.
*   **404 Not Found:** Strategy not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.
*   **403 Forbidden:** User attempts to update a protected field (e.g., `id`).

**Business Logic:**
*   Prevents direct modification of strategy `id`.
*   If `status` is changed from "DRAFT" to "ACTIVE", initiates market data subscription and rule evaluation.
*   If `status` is changed to "PAUSED" or "ARCHIVED", stops market data subscription and potentially pending orders.

#### 4.1.5. Delete Strategy
`DELETE /api/v1/strategies/{strategyId}`
**Description:** Deletes a strategy. Only possible if the strategy is not `ACTIVE`.
**Response:**
*   **204 No Content:** Strategy successfully deleted.
*   **400 Bad Request:** Cannot delete an active strategy.
*   **404 Not Found:** Strategy not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

#### 4.1.6. Activate Strategy
`POST /api/v1/strategies/{strategyId}/activate`
**Description:** Activates a strategy for live or paper trading.
**Request Body:**
*   **`brokerConnectionId`** (string, required): ID of the broker connection to use.
**Response:**
*   **200 OK:** `Strategy` object with status "ACTIVE".
*   **400 Bad Request:** Strategy already active, invalid `brokerConnectionId`, or strategy in invalid state.
*   **404 Not Found:** Strategy not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

**Business Logic:**
*   Changes strategy status to "ACTIVE".
*   Triggers the `Strategy Engine` to start processing market data and evaluate rules for this strategy on the specified `brokerConnectionId`.
*   Verifies the `brokerConnectionId` is valid and owned by the user.
*   Checks if the target `symbol` is supported by the connected broker.

#### 4.1.7. Deactivate Strategy
`POST /api/v1/strategies/{strategyId}/deactivate`
**Description:** Deactivates a running strategy.
**Response:**
*   **200 OK:** `Strategy` object with status "PAUSED".
*   **400 Bad Request:** Strategy not active.
*   **404 Not Found:** Strategy not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

**Business Logic:**
*   Changes strategy status to "PAUSED".
*   Instructs the `Strategy Engine` to stop processing this strategy.
*   Any open positions related to this strategy will remain open and managed manually, or can be closed by an optional parameter/configuration.

### 4.2. Backtesting & Optimization

#### 4.2.1. Start Backtest
`POST /api/v1/backtests`
**Description:** Initiates a backtest for a given strategy.
**Request Body:**
*   **`strategyId`** (string, required).
*   **`dateRange`** (object, required): `{"startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD"}`.
*   **`initialBalance`** (number, required).
*   **`slippagePips`** (number, optional, default: 0.5): Simulated slippage.
*   **`spreadPips`** (number, optional, default: 1.0): Simulated spread.
**Response:**
*   **202 Accepted:** `{"backtestId": "UUID"}`. Backtest is queued.
*   **400 Bad Request:** Invalid input or strategy invalid.
*   **401 Unauthorized:** Authentication failed.

**Business Logic:**
*   Copies the current state of the `strategyId` to ensure the backtest is deterministic.
*   Queues the backtest job for asynchronous processing.
*   Authenticates access to historical data for the requested `dateRange` and `symbol`.

#### 4.2.2. Get Backtest Report
`GET /api/v1/backtests/{backtestId}`
**Description:** Retrieves the status and results of a backtest.
**Response:**
*   **200 OK:** `BacktestReport` object. If `status` is "RUNNING", `netProfit` and other aggregations may be partials.
*   **404 Not Found:** Backtest not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

#### 4.2.3. Get Backtest Trades
`GET /api/v1/backtests/{backtestId}/trades`
**Description:** Retrieves individual trades executed during a backtest.
**Query Parameters:**
*   `limit` (integer, optional, default: 100).
*   `offset` (integer, optional, default: 0).
**Response:**
*   **200 OK:** Array of `Trade` objects (simulated).
*   **404 Not Found:** Backtest not found.

#### 4.2.4. Start Optimization
`POST /api/v1/optimizations`
**Description:** Initiates a parameter optimization run.
**Request Body:**
*   **`strategyId`** (string, required).
*   **`dateRange`** (object, required): `{"startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD"}`.
*   **`initialBalance`** (number, required).
*   **`optimizationType`** (string, required): Enum: "GRID_SEARCH", "GENETIC_ALGORITHM".
*   **`parametersToOptimize`** (array of objects, required): See `OptimizationRun` model.
*   **`targetMetric`** (string, required).
**Response:**
*   **202 Accepted:** `{"optimizationId": "UUID"}`. Optimization is queued.
*   **400 Bad Request:** Invalid input or strategy invalid for optimization.
*   **401 Unauthorized:** Authentication failed.

**Business Logic:**
*   Validates that the `parametersToOptimize` refer to existing indicators or strategy parameters within the specified `strategyId`.
*   Queues the optimization job, which will execute multiple backtests.
*   Resource-intensive task, will leverage distributed computing.

#### 4.2.5. Get Optimization Run
`GET /api/v1/optimizations/{optimizationId}`
**Description:** Retrieves the status and results of an optimization run.
**Response:**
*   **200 OK:** `OptimizationRun` object.
*   **404 Not Found:** Optimization not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

### 4.3. Broker & Account Management

#### 4.3.1. Add Broker Connection
`POST /api/v1/broker-connections`
**Description:** Adds a new broker connection for the user.
**Request Body:** `BrokerConnection` object (excluding `id`, `userId`, `status`, `createdAt`, `lastConnectedAt`).
**Response:**
*   **201 Created:** `BrokerConnection` object, including generated `id`.
*   **400 Bad Request:** Invalid connection details.
*   **401 Unauthorized:** Authentication failed.

**Business Logic:**
*   Attempts to establish a test connection to the broker using provided credentials to verify validity.
*   Encrypts sensitive API keys/passwords before storing.
*   Sets initial `status` to "DISCONNECTED" or "CONNECTED" based on test result.

#### 4.3.2. Get All Broker Connections
`GET /api/v1/broker-connections`
**Description:** Retrieves all broker connections for the authenticated user.
**Response:**
*   **200 OK:** Array of `BrokerConnection` objects (sensitive fields like `apiKey` will be masked).
*   **401 Unauthorized:** Authentication failed.

#### 4.3.3. Get Broker Connection by ID
`GET /api/v1/broker-connections/{connectionId}`
**Description:** Retrieves a specific broker connection.
**Response:**
*   **200 OK:** `BrokerConnection` object (sensitive fields masked).
*   **404 Not Found:** Connection not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

#### 4.3.4. Update Broker Connection
`PUT /api/v1/broker-connections/{connectionId}`
**Description:** Updates details for an existing broker connection.
**Request Body:** `BrokerConnection` object (only fields to be updated are required, e.g., `status` to "CONNECTED").
**Response:**
*   **200 OK:** Updated `BrokerConnection` object.
*   **400 Bad Request:** Invalid input.
*   **404 Not Found:** Connection not found or not owned by user.

**Business Logic:**
*   If update includes credentials, a re-validation against the broker is performed.
*   Updating `status` to "CONNECTED" will attempt to establish a persistent connection.
*   Updating `status` to "DISCONNECTED" will gracefully close the connection.

#### 4.3.5. Delete Broker Connection
`DELETE /api/v1/broker-connections/{connectionId}`
**Description:** Deletes a broker connection. Only possible if no active strategies are using it.
**Response:**
*   **204 No Content:** Connection successfully deleted.
*   **400 Bad Request:** Cannot delete a connection actively used by strategies.
*   **404 Not Found:** Connection not found or not owned by user.

#### 4.3.6. Get Account Details (Live/Paper)
`GET /api/v1/broker-connections/{connectionId}/account`
**Description:** Retrieves real-time account details from the connected broker.
**Response:**
*   **200 OK:**
    ```json
    {
      "accountNumber": "...",
      "balance": 10000.50,
      "equity": 10050.25,
      "freeMargin": 9000.00,
      "currency": "USD",
      "leverage": 500,
      "openPositions": [ { ...Trade object summary... } ],
      "pendingOrders": [ { ...Order object summary... } ]
    }
    ```
*   **404 Not Found:** Connection not found.
*   **400 Bad Request:** Broker connection not active/failed.
*   **401 Unauthorized:** Authentication failed.

**Business Logic:**
*   Makes a real-time call to the connected broker's API.
*   Aggregates information about total balance, current equity, open positions, and pending orders.
*   The `openPositions` and `pendingOrders` provide a high-level summary, linking to detailed `Trade` information if needed.

### 4.4. Trading & Position Management

#### 4.4.1. Get All Trades
`GET /api/v1/trades`
**Description:** Retrieves all trades executed by the user's bots.
**Query Parameters:**
*   `strategyId` (string, optional).
*   `brokerConnectionId` (string, optional).
*   `status` (string, optional): "OPEN", "CLOSED".
*   `symbol` (string, optional).
*   `startDate` (datetime, optional).
*   `endDate` (datetime, optional).
*   `limit` (integer, optional, default: 100).
*   `offset` (integer, optional, default: 0).
**Response:**
*   **200 OK:** Array of `Trade` objects.
*   **401 Unauthorized:** Authentication failed.

#### 4.4.2. Get Trade by ID
`GET /api/v1/trades/{tradeId}`
**Description:** Retrieves a specific trade.
**Response:**
*   **200 OK:** `Trade` object.
*   **404 Not Found:** Trade not found or not owned by user.

#### 4.4.3. Manually Close Trade
`POST /api/v1/trades/{tradeId}/close`
**Description:** Manually closes an open trade. This overrides bot control.
**Response:**
*   **200 OK:** Updated `Trade` object with `status` "CLOSED".
*   **400 Bad Request:** Trade not open or already closed.
*   **404 Not Found:** Trade not found or not owned by user.
*   **401 Unauthorized:** Authentication failed.

**Business Logic:**
*   Sends a close order request to the respective broker via the associated `brokerConnectionId`.
*   Updates the `Trade` status to "CLOSED" upon successful execution.
*   Notifies the strategy that the position has been manually closed, disengaging its exit logic for this specific trade.

### 4.5. Market Data & Utilities

#### 4.5.1. Get Available Currency Pairs
`GET /api/v1/symbols`
**Description:** Retrieves a list of all supported tradable currency pairs.
**Response:**
*   **200 OK:** Array of `CurrencyPair` objects.

#### 4.5.2. Get Available Indicators
`GET /api/v1/indicators/definitions`
**Description:** Retrieves definitions for all supported built-in indicators, including their parameters.
**Response:**
*   **200 OK:** Array of `IndicatorDefinition` objects (e.g., `{"name": "RSI", "type": "RSI", "params": [{"name": "period", "type": "integer", "default": 14}]}`).

#### 4.5.3. Get Candlestick Data
`GET /api/v1/data/candlesticks`
**Description:** Retrieves historical candlestick data for a given symbol and timeframe.
**Query Parameters:**
*   `symbol` (string, required).
*   `timeframe` (string, required).
*   `startDate` (datetime, required).
*   `endDate` (datetime, required).
*   `limit` (integer, optional, default: 1000).
**Response:**
*   **200 OK:** Array of candlestick objects: `[{"timestamp": "...", "open": 1.1234, "high": 1.1240, "low": 1.1220, "close": 1.1230, "volume": 12345}]`.
*   **400 Bad Request:** Invalid symbol, timeframe, or date range.

**Business Logic:**
*   Serves data from the integrated `Historical Data Store`.
*   Ensures data availability and consistency for the requested parameters.

### 4.6. Logging & Alerts

#### 4.6.1. Get Bot Logs
`GET /api/v1/logs`
**Description:** Retrieves activity logs for the user's bots and strategies.
**Query Parameters:**
*   `level` (string, optional): Info, Warning, Error.
*   `strategyId` (string, optional).
*   `startDate` (datetime, optional).
*   `endDate` (datetime, optional).
*   `limit` (integer, optional, default: 100).
*   `offset` (integer, optional, default: 0).
**Response:**
*   **200 OK:** Array of log entries: `[{"timestamp": "...", "level": "INFO", "message": "Strategy 'MyTrendBot' opened BUY on EUR/USD.", "strategyId": "..."}]`.
*   **401 Unauthorized:** Authentication failed.

#### 4.6.2. Configure Alerts
`PUT /api/v1/users/me/alerts`
**Description:** Configures user notification preferences.
**Request Body:**
*   **`emailNotifications`** (object): `{"tradeExecution": true, "safetyLimitBreach": true, "strategyStatusChange": false, "weeklyReport": true}`
*   **`smsNotifications`** (object): `{"tradeExecution": false, "safetyLimitBreach": true}`
*   **`inAppNotifications`** (object): `{"tradeExecution": true, "safetyLimitBreach": true, "strategyStatusChange": true}`
**Response:**
*   **200 OK:** Updated user alert settings.
*   **400 Bad Request:** Invalid input.

**Business Logic:**
*   Stores user's alert preferences.
*   The system's `Monitoring & Alerting` component consumes internal events and dispatches notifications based on these preferences.

## 5. Error Handling

Standard HTTP status codes will be used:
*   **`2xx`**: Success
*   **`4xx`**: Client errors (e.g., malformed request, unauthorized, not found)
*   **`5xx`**: Server errors

All error responses will adhere to a consistent JSON format:
```json
{
  "errorCode": "UNIQUE_ERROR_CODE",
  "message": "A human-readable error message.",
  "details": [
    "Specific details about the error, e.g., 'Field 'name' is required.'",
    "Another detail."
  ]
}
```

## 6. Security Considerations

*   **API Gateway:** All requests proceed through an API Gateway for rate limiting, DDoS protection, and initial authentication.
*   **Input Validation:** Strict input validation on all API endpoints to prevent injection attacks and ensure data integrity.
*   **Least Privilege:** Services and internal components will operate with the minimum necessary permissions.
*   **Regular Audits:** API code and infrastructure will undergo regular security audits and penetration testing.
*   **Secure Coding Practices:** All development will follow OWASP Top 10 recommendations.

## 7. Rate Limiting

To prevent abuse and ensure fair usage, all API endpoints will be subject to rate limiting.
*   **Default Limit:** 100 requests per minute per authenticated user.
*   **Burst Limit:** Up to 20 requests in any 5-second interval.
*   **HTTP Headers:** `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` will be included in responses.
*   **Exceeding Limit:** Will result in `429 Too Many Requests` status code.

## 8. WebSocket APIs (Future Consideration / Real-time)

For real-time updates not covered by the current REST API, the following WebSocket channels could be implemented:

*   `/ws/v1/marketdata/{symbol}/{timeframe}`: Real-time candlestick and tick data.
*   `/ws/v1/trades/user/{userId}`: Real-time updates on trade executions and status changes.
*   `/ws/v1/alerts/user/{userId}`: Real-time delivery of push notifications/alerts.
*   `/ws/v1/account/user/{userId}/{brokerConnectionId}`: Real-time updates on account balance, equity, and margin.

---