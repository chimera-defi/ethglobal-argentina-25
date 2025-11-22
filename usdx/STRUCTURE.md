# USDX Protocol - Project Structure

## Directory Structure

```
usdx/
├── docs/                    # All documentation (29 files)
│   ├── Core documentation (01-06)
│   ├── Research guides (RESEARCH-*.md, 08, 13)
│   ├── Implementation guides (20-23)
│   └── Reference docs (10, SELF-ASSESSMENT, etc.)
│
├── contracts/               # Smart contracts (Foundry + Hardhat)
│   ├── contracts/          # Solidity contracts
│   ├── test/
│   │   ├── forge/         # Foundry tests
│   │   └── hardhat/       # Hardhat tests
│   ├── script/            # Deployment scripts
│   ├── foundry.toml       # Foundry configuration
│   ├── hardhat.config.ts  # Hardhat configuration
│   ├── package.json       # Node.js dependencies
│   └── README.md          # Contracts setup guide
│
├── frontend/               # Next.js frontend
│   ├── app/               # Next.js App Router (to be created)
│   ├── components/        # React components (to be created)
│   ├── hooks/            # Custom hooks (to be created)
│   ├── package.json      # Frontend dependencies
│   ├── next.config.js    # Next.js configuration
│   ├── tailwind.config.js # Tailwind configuration
│   └── README.md         # Frontend setup guide
│
├── backend/                # Backend services (optional)
│   ├── src/              # Source code (to be created)
│   ├── package.json      # Backend dependencies
│   └── README.md        # Backend setup guide
│
├── infrastructure/         # Infrastructure configs
│   └── README.md         # Infrastructure setup guide
│
├── AGENT-INSTRUCTIONS.md   # Agent-specific instructions
├── SETUP.md               # Development environment setup
├── README.md              # Main project README
└── package.json           # Root workspace config
```

## File Organization

### Documentation (docs/)
- **29 markdown files** covering all aspects of the protocol
- Organized by topic (core, research, implementation, reference)
- See `docs/README.md` for complete index

### Smart Contracts (contracts/)
- **Foundry configuration**: `foundry.toml`
- **Hardhat configuration**: `hardhat.config.ts`
- **Package config**: `package.json`
- **Environment template**: `.env.example`
- **Directory structure**: Ready for contracts

### Frontend (frontend/)
- **Next.js configuration**: `next.config.js`
- **Tailwind configuration**: `tailwind.config.js`
- **TypeScript config**: `tsconfig.json`
- **Package config**: `package.json`
- **Environment template**: `.env.example`
- **Directory structure**: Ready for components

### Backend (backend/)
- **Package config**: `package.json`
- **TypeScript config**: `tsconfig.json`
- **Environment template**: `.env.example`
- **Directory structure**: Ready for services

## Setup Status

✅ **Documentation**: Complete
✅ **Project Structure**: Created
✅ **Configuration Files**: Created
✅ **Environment Templates**: Created
✅ **Agent Instructions**: Created
⏳ **Code**: Ready to be written

## Next Steps

1. **Smart Contracts Agent**: Follow `contracts/README.md`
2. **Frontend Agent**: Follow `frontend/README.md`
3. **Backend Agent**: Follow `backend/README.md`
4. **Infrastructure Agent**: Follow `infrastructure/README.md`

See **[AGENT-INSTRUCTIONS.md](./AGENT-INSTRUCTIONS.md)** for detailed instructions.
