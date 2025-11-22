# FACoin - Aptos Fungible Asset Implementation

A comprehensive implementation of a managed fungible asset on the Aptos blockchain, demonstrating best practices for creating, managing, and transferring custom tokens using the Aptos Fungible Asset standard.

## Overview

FACoin is a fully-featured fungible asset package that showcases administrative controls over digital assets on Aptos. The project includes multiple token implementations (Shadow Dev Coin, CAT Coin, and DOG Coin) with complete admin functionality including minting, burning, freezing, and forced transfers.

## Features

### Core Functionality

- **Minting**: Admin-controlled creation of new tokens
- **Burning**: Admin-controlled destruction of tokens from any account
- **Transfers**: Both standard user transfers and admin-forced transfers
- **Account Freezing**: Ability to freeze and unfreeze accounts to prevent transactions
- **Metadata Management**: Configurable token name, symbol, decimals, and project information
- **Primary Store Integration**: Automatic primary fungible store management

### Security Features

- Owner-only administrative functions with permission checks
- Resource group optimization for efficient storage
- Inline function optimizations for reduced gas costs
- Comprehensive test coverage

## Project Structure

```
facoin/
├── Move.toml                    # Package configuration
├── sources/
│   ├── fa_coin.move            # Main fungible asset (Shadow Dev Coin)
│   ├── fa_coin_cat.move        # CAT Coin implementation
│   ├── fa_coin_dog.move        # DOG Coin implementation
│   └── secondary_store.move    # Secondary store management
└── README.md
```

## Prerequisites

### Required Software

- [Aptos CLI](https://aptos.dev/tools/aptos-cli/) (latest version)
- Node.js v18 or higher
- pnpm package manager

### Required Knowledge

- Basic understanding of Move programming language
- Familiarity with Aptos blockchain concepts
- TypeScript/JavaScript fundamentals

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd aptos-ts-sdk/examples/typescript
```

### 2. Install Dependencies

```bash
pnpm install
```

### 3. Set Up Environment

Create a `.env` file in the typescript directory:

```env
APTOS_NETWORK=devnet
```

## Usage

### Compiling the Package

Compile the Move package before deployment:

```bash
aptos move build-publish-payload \
  --json-output-file move/facoin/facoin.json \
  --package-dir move/facoin \
  --named-addresses FACoin=<YOUR_ADDRESS> \
  --assume-yes
```

### Running the Example

Execute the complete demonstration script:

```bash
pnpm run your_fungible_asset
```

This script will:
1. Generate test accounts (Alice, Bob, Charlie)
2. Fund accounts with test APT
3. Compile and publish the FACoin package
4. Demonstrate all core functionalities:
   - Minting tokens to Charlie
   - Freezing Bob's account
   - Admin-forced transfer from Charlie to Bob
   - Unfreezing Bob's account
   - Burning tokens from Bob
   - Standard transfer from Bob to Alice

### Integrating Into Your Project

#### TypeScript Integration

```typescript
import { Account, Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";

// Initialize Aptos client
const config = new AptosConfig({ network: Network.DEVNET });
const aptos = new Aptos(config);

// Mint tokens
async function mintCoin(admin: Account, receiver: Account, amount: number) {
  const transaction = await aptos.transaction.build.simple({
    sender: admin.accountAddress,
    data: {
      function: `${admin.accountAddress}::fa_coin::mint`,
      functionArguments: [receiver.accountAddress, amount],
    },
  });

  const senderAuthenticator = aptos.transaction.sign({ 
    signer: admin, 
    transaction 
  });
  const pendingTxn = await aptos.transaction.submit.simple({ 
    transaction, 
    senderAuthenticator 
  });

  return pendingTxn.hash;
}

// Transfer tokens
async function transferCoin(
  admin: Account,
  fromAddress: AccountAddress,
  toAddress: AccountAddress,
  amount: number
) {
  const transaction = await aptos.transaction.build.simple({
    sender: admin.accountAddress,
    data: {
      function: `${admin.accountAddress}::fa_coin::transfer`,
      functionArguments: [fromAddress, toAddress, amount],
    },
  });

  const senderAuthenticator = aptos.transaction.sign({ 
    signer: admin, 
    transaction 
  });
  const pendingTxn = await aptos.transaction.submit.simple({ 
    transaction, 
    senderAuthenticator 
  });

  return pendingTxn.hash;
}

// Freeze account
async function freezeAccount(admin: Account, targetAddress: AccountAddress) {
  const transaction = await aptos.transaction.build.simple({
    sender: admin.accountAddress,
    data: {
      function: `${admin.accountAddress}::fa_coin::freeze_account`,
      functionArguments: [targetAddress],
    },
  });

  const senderAuthenticator = aptos.transaction.sign({ 
    signer: admin, 
    transaction 
  });
  const pendingTxn = await aptos.transaction.submit.simple({ 
    transaction, 
    senderAuthenticator 
  });

  return pendingTxn.hash;
}
```

#### Move Module Integration

To use FACoin in your own Move modules:

```move
module YourModule::example {
    use FACoin::fa_coin;
    use aptos_framework::primary_fungible_store;

    public entry fun example_function(user: &signer) {
        let metadata = fa_coin::get_metadata();
        let balance = primary_fungible_store::balance(
            signer::address_of(user), 
            metadata
        );
        // Your logic here
    }
}
```

## API Reference

### View Functions

#### `get_metadata(): Object<Metadata>`
Returns the metadata object address for the fungible asset.

#### `get_name(): String`
Returns the name of the fungible asset.

### Entry Functions

#### `mint(admin: &signer, to: address, amount: u64)`
Mints new tokens to the specified address.

- **Parameters**:
  - `admin`: The signer with admin privileges
  - `to`: Recipient address
  - `amount`: Number of tokens to mint

- **Restrictions**: Only callable by the asset owner

#### `burn(admin: &signer, from: address, amount: u64)`
Burns tokens from the specified address.

- **Parameters**:
  - `admin`: The signer with admin privileges
  - `from`: Address to burn tokens from
  - `amount`: Number of tokens to burn

- **Restrictions**: Only callable by the asset owner

#### `transfer(admin: &signer, from: address, to: address, amount: u64)`
Forcefully transfers tokens, bypassing frozen status.

- **Parameters**:
  - `admin`: The signer with admin privileges
  - `from`: Source address
  - `to`: Destination address
  - `amount`: Number of tokens to transfer

- **Restrictions**: Only callable by the asset owner

#### `freeze_account(admin: &signer, account: address)`
Freezes an account, preventing transfers in or out.

- **Parameters**:
  - `admin`: The signer with admin privileges
  - `account`: Address to freeze

- **Restrictions**: Only callable by the asset owner

#### `unfreeze_account(admin: &signer, account: address)`
Unfreezes a previously frozen account.

- **Parameters**:
  - `admin`: The signer with admin privileges
  - `account`: Address to unfreeze

- **Restrictions**: Only callable by the asset owner

## Configuration

### Token Parameters

Modify these constants in the Move modules to customize your token:

```move
const ASSET_NAME: vector<u8> = b"Shadow Dev Coin";
const ASSET_SYMBOL: vector<u8> = b"SD Coin";
```

In the `init_module` function, adjust:
- **Decimals**: Default is 8
- **Icon URL**: Token icon/logo URL
- **Project URL**: Project website or documentation URL

## Testing

### Run Move Tests

```bash
cd move/facoin
aptos move test
```

### Test Coverage

The package includes comprehensive tests:
- `test_basic_flow`: Tests the complete lifecycle of token operations
- `test_permission_denied`: Ensures proper access control

## Common Issues and Troubleshooting

### Compilation Errors

**Issue**: `unnecessary acquires annotation`
- **Solution**: Remove `acquires` from functions that only write to storage, not read

**Issue**: `acquires and access specifiers are not applicable to inline functions`
- **Solution**: Remove `acquires` annotations from inline functions

### Runtime Errors

**Issue**: Permission denied errors
- **Solution**: Ensure you're using the admin account for administrative functions

**Issue**: Account frozen
- **Solution**: Unfreeze the account before attempting standard transfers

## Best Practices

1. **Admin Key Management**: Store admin private keys securely, preferably in hardware wallets for mainnet deployments
2. **Testing**: Always test on devnet before deploying to testnet or mainnet
3. **Gas Optimization**: Use inline functions for frequently called internal functions
4. **Error Handling**: Implement comprehensive error handling in your TypeScript integration
5. **Monitoring**: Monitor on-chain events for all administrative actions

## Security Considerations

- Admin accounts have full control over all tokens
- Implement multi-signature schemes for production deployments
- Consider time-locks for critical administrative functions
- Regularly audit smart contract code before mainnet deployment
- Use access control patterns for sensitive operations

## Contributing

Contributions are welcome. Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request with a clear description



## Additional Resources

- [Aptos Documentation](https://aptos.dev/)
- [Aptos TypeScript SDK](https://aptos.dev/sdks/ts-sdk/)
- [Move Language Documentation](https://move-language.github.io/move/)
- [Fungible Asset Standard](https://aptos.dev/standards/fungible-asset/)

