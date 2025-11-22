# USDX Backend Services

## For Backend Agent

**📖 Start Here**: **[../docs/02-architecture.md](../docs/02-architecture.md)** (Layer 4: Infrastructure Services)

## Overview

Backend services are **optional** for USDX MVP. Bridge Kit SDK can be used directly in the frontend. However, backend services can provide:

- Transaction indexing
- Aggregated balance API
- Monitoring and alerts
- Analytics dashboard
- Automated operations (optional)

## Quick Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with database, RPC URLs, etc.
```

### 3. Set Up Database

```bash
# PostgreSQL setup
createdb usdx_indexer
npm run migrate  # Run migrations
```

### 4. Start Development Server

```bash
npm run dev
```

## Project Structure

```
backend/
├── src/
│   ├── indexer/            # Transaction indexer
│   ├── api/                # REST API
│   ├── services/           # Business logic
│   │   ├── bridgeKit.ts   # Bridge Kit service (optional)
│   │   └── monitoring.ts  # Monitoring service
│   └── database/           # Database models & migrations
├── scripts/
│   ├── indexer.ts          # Indexer script
│   └── monitor.ts          # Monitoring script
└── package.json
```

## Services

### 1. Transaction Indexer

**Purpose**: Index cross-chain transactions for fast queries

**Technology**: 
- The Graph (recommended) OR
- Custom indexer (PostgreSQL)

**Features**:
- Index deposits, mints, transfers, withdrawals
- Track transaction status
- Aggregate balances
- Transaction history API

### 2. API Service

**Purpose**: Provide aggregated data to frontend

**Endpoints**:
- `GET /api/balances/:address` - Cross-chain balances
- `GET /api/transactions/:address` - Transaction history
- `GET /api/vault/stats` - Vault statistics
- `GET /api/yield/stats` - Yield statistics

### 3. Monitoring Service

**Purpose**: Monitor protocol health

**Features**:
- Track vault health
- Monitor yield rates
- Alert on anomalies
- Track TVL

### 4. Bridge Kit Service (Optional)

**Purpose**: Automated Bridge Kit operations

**Note**: Bridge Kit can be used directly in frontend. Backend service is optional for:
- Automated operations
- Batch processing
- Scheduled tasks

## Technology Stack

- **Runtime**: Node.js 20+
- **Framework**: Express.js (or Next.js API routes)
- **Database**: PostgreSQL
- **Indexing**: The Graph (recommended) or custom
- **Monitoring**: Tenderly, OpenZeppelin Defender
- **Bridge Kit**: @circle-fin/bridge-kit (optional)

## Development Workflow

### Phase 1: Indexer Setup

1. Set up The Graph subgraph OR custom indexer
2. Index core events (deposit, mint, transfer, withdraw)
3. Test indexing on testnet

### Phase 2: API Service

1. Set up Express.js API
2. Create balance aggregation endpoint
3. Create transaction history endpoint
4. Create vault stats endpoint

### Phase 3: Monitoring

1. Set up monitoring service
2. Configure alerts
3. Set up dashboards

## Key Commands

```bash
npm run dev          # Start dev server
npm run build        # Build for production
npm run start        # Start production server
npm run indexer     # Run indexer
npm run migrate      # Run database migrations
npm run test         # Run tests
```

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/usdx_indexer

# RPC URLs
MAINNET_RPC_URL=https://...
POLYGON_RPC_URL=https://...

# Contract Addresses
USDX_TOKEN_ADDRESS_ETHEREUM=0x...
USDX_VAULT_ADDRESS_ETHEREUM=0x...

# Monitoring
TENDERLY_API_KEY=...
DEFENDER_API_KEY=...
DEFENDER_API_SECRET=...
```

## Resources

- **[Architecture](../docs/02-architecture.md)** - System architecture
- **[Task Breakdown](../docs/22-detailed-task-breakdown.md)** - Backend tasks
- **[Bridge Kit Guide](../docs/RESEARCH-bridge-kit.md)** - Bridge Kit integration

## Next Steps

1. ✅ Read architecture guide
2. ✅ Decide on indexing approach (The Graph vs custom)
3. ⏳ Set up database/indexer
4. ⏳ Build API endpoints
5. ⏳ Set up monitoring

## Note

Backend services are **optional** for MVP. The frontend can work standalone using Bridge Kit SDK directly. Backend services add value for:
- Better UX (faster queries)
- Analytics
- Monitoring
- Automated operations
