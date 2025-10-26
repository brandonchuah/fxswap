## FX Swap Safe Module

A Gnosis Safe module that enables trust‑minimized FX swaps using off‑chain brokers.

## Contract addresses

### Sepolia

- FxSwapModule: `0x091E1C4c0c4e184D90117Cb51436D4d661f138A3`
- MockXSGD: `0x8A0c939571ef36363a5B4526A28aC59f623ebf97`
- PYUSD/MockXSGD broker : `0xF16bD86AC718886F0550689A574D4552dEC0253E`

## Development

### Setup

```bash
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test -vv
```

## Scripts (Foundry)

All scripts require `PRIVATE_KEY` in `.env` and a valid `--rpc-url`.

### Env variables

```bash
PRIVATE_KEY=
```

### Deploy module

```bash
forge script script/DeployFxSwap.s.sol:DeployFxSwap --rpc-url $RPC_URL --broadcast -vvvv
```

The deployed address is recorded at `broadcast/DeployFxSwap.s.sol/<chainId>/run-latest.json`.

### Deploy mock tokens

```bash
forge script script/DeployMocks.s.sol:DeployMocks --rpc-url $RPC_URL --broadcast -vvvv
```

### Mint mock tokens

```bash
forge script script/MintMockTokens.s.sol:MintMockTokens --rpc-url $RPC_URL --broadcast -vvvv
```

Note: `to`, `token`, and `amount` are hardcoded in `script/MintMockTokens.s.sol`. Edit that file to change values.

### Create a Safe (Sepolia)

```bash
forge script script/CreateSafe.s.sol:CreateSafe --rpc-url $RPC_URL --broadcast -vvvv
```

Outputs the new Safe address.

### Enable FxSwap module on an existing Safe

```bash
forge script script/EnableModuleOnSafe.s.sol:EnableModuleOnSafe --rpc-url $RPC_URL --broadcast -vvvv
```

Note: `safeAddr` and `module` are hardcoded in `script/EnableModuleOnSafe.s.sol`. Edit that file to point to your Safe and deployed module addresses.

Requirements:

- `PRIVATE_KEY` must be an owner of `SAFE`.
- Threshold should be 1 for single‑owner flow (or provide N ordered signatures if higher).
