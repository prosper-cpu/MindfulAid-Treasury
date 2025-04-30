# MindfulAid Treasury

A decentralized financial support platform built on Stacks blockchain to fund mental health initiatives and support individuals in need.

## Overview

MindfulAid Treasury is a smart contract-based treasury management system designed to collect, manage, and distribute funds to mental health initiatives and individuals requiring financial assistance for mental health services. The system provides transparent tracking of all transactions while maintaining privacy for recipients.

## Features

- **Secure Contribution Collection**: Accept STX contributions from donors with minimum contribution thresholds
- **Recipient Management**: Register, track, and manage fund recipients
- **Transparent Fund Distribution**: Auditable distribution of treasury funds to approved recipients
- **Administrative Controls**: Comprehensive treasury management by authorized stewards
- **Emergency Protocols**: Safety mechanisms including treasury suspension and emergency mode
- **Ownership Transfer**: Ability to transfer stewardship to new administrators

## Smart Contract Functions

### Public Functions

- `make-contribution`: Submit a contribution to the treasury
- `register-new-recipient`: Add a new recipient to the registry
- `distribute-funds`: Allocate funds to a registered recipient
- `set-minimum-contribution`: Update the minimum acceptable contribution amount
- `toggle-treasury-status`: Activate or deactivate the treasury
- `enable-emergency-mode`: Activate emergency protocols
- `disable-emergency-mode`: Deactivate emergency protocols
- `update-recipient-status`: Modify a recipient's status in the registry
- `transfer-steward-rights`: Transfer administrative control to a new address

### Read-Only Functions

- `get-treasury-steward`: View the current treasury administrator
- `get-treasury-balance`: Check the current balance of the treasury
- `get-recipient-information`: View details about a registered recipient
- `get-contributor-information`: Access contribution history for a specific address
- `check-treasury-operational-status`: Verify if the treasury is currently operational

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) for local development and testing
- [Stacks Wallet](https://www.hiro.so/wallet) for deploying and interacting with the contract on testnet/mainnet

### Installation

1. Clone this repository
```bash
git clone https://github.com/prosper-cpu/mindfulaid-treasury.git
cd mindfulaid-treasury
```

2. Set up the development environment
```bash
clarinet integrate
```

3. Run tests
```bash
clarinet test
```

### Deployment

1. Build the contract
```bash
clarinet build
```

2. Deploy using the Stacks Web Wallet or CLI tools
```bash
# Using stacks-cli (example)
stacks deploy --network=testnet --keychain=/path/to/keychain.json --fee=1000 ./contracts/mindfulaid-treasury.clar
```

## Usage Examples

### Making a Contribution
```clarity
;; Make a contribution of 10 STX
(contract-call? .mindfulaid-treasury make-contribution)
```

### Registering a New Recipient
```clarity
;; Register a new recipient
(contract-call? .mindfulaid-treasury register-new-recipient 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Distributing Funds
```clarity
;; Distribute 5 STX to a recipient
(contract-call? .mindfulaid-treasury distribute-funds 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u5000000)
```

## Security Considerations

- The contract includes various safeguards to prevent unauthorized access
- Only the designated treasury steward can perform administrative functions
- Emergency mode can be activated to freeze operations in case of suspicious activity
- All financial operations include balance verification to prevent unauthorized fund transfers

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Acknowledgments

- Mental health advocacy organizations that inspired this project
- The Stacks blockchain community for their guidance and support
- All contributors who have participated in this project