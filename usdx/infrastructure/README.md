# USDX Infrastructure

## For Infrastructure Agent

**📖 Start Here**: **[../docs/02-architecture.md](../docs/02-architecture.md)** (Infrastructure section)

## Overview

Infrastructure setup for USDX protocol including:
- Monitoring and alerting
- Deployment automation
- Indexing infrastructure
- CI/CD pipelines

## Quick Setup

### 1. Monitoring Setup

```bash
# Tenderly
# - Create account at tenderly.co
# - Add project
# - Configure alerts

# OpenZeppelin Defender
# - Create account at defender.openzeppelin.com
# - Set up monitoring
# - Configure alerts
```

### 2. Indexing Setup

```bash
# Option 1: The Graph (Recommended)
# - Create subgraph
# - Deploy to The Graph Network

# Option 2: Custom Indexer
# - Set up PostgreSQL
# - Configure indexer service
```

### 3. CI/CD Setup

```bash
# GitHub Actions
# - Set up workflows
# - Configure secrets
# - Test deployments
```

## Project Structure

```
infrastructure/
├── monitoring/
│   ├── tenderly/           # Tenderly configs
│   └── defender/           # OpenZeppelin Defender configs
├── indexing/
│   ├── subgraph/           # The Graph subgraph
│   └── custom/             # Custom indexer configs
├── deployment/
│   ├── scripts/            # Deployment scripts
│   └── configs/            # Deployment configs
├── ci-cd/
│   └── workflows/         # GitHub Actions workflows
└── monitoring-dashboards/   # Grafana/dashboard configs
```

## Components

### 1. Monitoring

**Tenderly**:
- Contract monitoring
- Transaction simulation
- Alert configuration
- Dashboard setup

**OpenZeppelin Defender**:
- Admin operations
- Monitoring
- Alerting
- Automation

### 2. Indexing

**The Graph** (Recommended):
- Subgraph for USDX protocol
- Index all events
- GraphQL API

**Custom Indexer** (Alternative):
- PostgreSQL database
- Event indexing service
- REST API

### 3. Deployment

**Smart Contracts**:
- Hardhat deployment scripts
- Multi-chain deployment
- Contract verification
- Upgrade management

**Frontend**:
- Vercel deployment (recommended)
- Environment configuration
- Domain setup

### 4. CI/CD

**GitHub Actions**:
- Test automation
- Deployment automation
- Security scanning
- Gas reporting

## Development Workflow

### Phase 1: Monitoring Setup

1. Set up Tenderly
   - Add contracts
   - Configure alerts
   - Set up dashboards

2. Set up OpenZeppelin Defender
   - Configure monitoring
   - Set up alerts
   - Configure admin operations

### Phase 2: Indexing Setup

1. Create The Graph subgraph
   - Define schema
   - Write mappings
   - Test locally
   - Deploy to testnet

2. OR Set up custom indexer
   - Set up PostgreSQL
   - Write indexer service
   - Test indexing

### Phase 3: Deployment Automation

1. Set up deployment scripts
2. Configure multi-chain deployment
3. Set up contract verification
4. Test deployments

### Phase 4: CI/CD

1. Set up GitHub Actions
2. Configure test automation
3. Configure deployment automation
4. Set up security scanning

## Key Commands

```bash
# The Graph
graph codegen              # Generate types
graph build                # Build subgraph
graph deploy               # Deploy subgraph

# Deployment
npx hardhat deploy --network sepolia
npx hardhat verify --network sepolia

# Monitoring
# Configure via Tenderly/Defender dashboards
```

## Environment Variables

```env
# Tenderly
TENDERLY_ACCOUNT=...
TENDERLY_PROJECT=...
TENDERLY_ACCESS_KEY=...

# OpenZeppelin Defender
DEFENDER_API_KEY=...
DEFENDER_API_SECRET=...

# The Graph
GRAPH_NODE_URL=...
GRAPH_ACCESS_TOKEN=...

# Deployment
PRIVATE_KEY=...
ETHERSCAN_API_KEY=...
```

## Resources

- **[Architecture](../docs/02-architecture.md)** - Infrastructure requirements
- **[Task Breakdown](../docs/22-detailed-task-breakdown.md)** - Infrastructure tasks
- **[Implementation Plan](../docs/06-implementation-plan.md)** - Deployment phases

## Next Steps

1. ✅ Read architecture guide
2. ✅ Set up monitoring (Tenderly + Defender)
3. ⏳ Set up indexing (The Graph or custom)
4. ⏳ Configure deployment automation
5. ⏳ Set up CI/CD pipelines

## Monitoring Checklist

- [ ] Tenderly project set up
- [ ] Contracts added to Tenderly
- [ ] Alerts configured
- [ ] OpenZeppelin Defender set up
- [ ] Monitoring dashboards created
- [ ] Alert channels configured (Discord, email, etc.)

## Deployment Checklist

- [ ] Deployment scripts ready
- [ ] Multi-chain configuration
- [ ] Contract verification set up
- [ ] Upgrade process documented
- [ ] Rollback plan prepared
