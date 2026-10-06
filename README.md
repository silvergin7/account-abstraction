# Account Abstraction

Minimal smart contract accounts for **Ethereum (ERC-4337)** and **zkSync Era (native AA)**.

## What’s in the repo

| Path | Purpose |
|------|---------|
| `src/ethereum/MinimalAccount.sol` | ERC-4337 account (EntryPoint, `execute`, UserOp validation) |
| `src/zksync/ZkMinimalAccount.sol` | zkSync `IAccount` (validate / execute / paymaster hooks) |
| `src/zksync/AAFactory.sol` | Factory for counterfactual AA wallets on zkSync |
| `script/` | Deploy and helper scripts |
| `test/ethereum/` | EVM tests |
| `test/zksync/` | EraVM tests (`forge test --zksync`) |

## Setup

```bash
git clone <your-repo-url> account-abstraction && cd account-abstraction
git submodule update --init --recursive
```

Install [Foundry](https://book.getfoundry.sh/) and the [foundry-zksync](https://foundry-book.zksync.io/) toolchain for zkSync builds.

Copy env vars if you use RPC URLs locally (never commit `.env`):

```bash
cp .env.example .env   # if present; otherwise create .env with your RPC keys
```

## Build

```bash
forge build
forge build --zksync
```

`via_ir = true` in `foundry.toml` avoids stack-too-deep issues on heavier zkSync code paths.

## Test

```bash
# Ethereum
forge test

# zkSync (system contracts / NonceHolder)
forge test --zksync --system-mode=true
```

Each suite skips automatically on the wrong VM (`test/VmEnvironment.sol`).

## zkSync Sepolia deploy (outline)

1. Build artifacts: `forge build --zksync --system-mode=true`
2. Fund deployer on **zkSync Sepolia** (chain id `300`), e.g. `https://sepolia.era.zksync.dev`
3. Run `script/DeployZkAccount.s.sol` with `--account sepolia-wallet --zksync --rpc-url $ZKSYNC_SEPOLIA_RPC_URL --broadcast`

See scripts under `script/` for Ethereum deploy and UserOp helpers.

## License

MIT
