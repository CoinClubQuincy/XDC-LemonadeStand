# XDC Lemonade Stand

A small example dApp from my XDC developer workshop. It shows how a simple business can live on-chain with ERC-1155 tokens and the [XRC-SHARE](https://github.com/CoinClubQuincy/XRC-SHARES) dividend-share pattern: customers pay the stand, and every sale is split among the shareholders.

## How it works

**`SHARE.sol` (XRC-SHARE)**
- Mints a fixed supply of share tokens (up to 1,000) to the deployer. Each share has its own account inside the contract.
- `redirectValue(amount)` and plain payments to the contract split funds evenly across every share account.
- `viewAccount(token)` and `viewAccountTotal()` show balances; `redeem()` lets a shareholder withdraw what their shares have earned.

**`LemonadeStand.sol`** extends XRC-SHARE:
- The deployer also receives 3 **editor** tokens. Any editor-token holder can call `edit(description, price, openStatus)`.
- `GlassOfLemonade(amount)` works only while the stand is open. It checks payment against `price × amount`, refunds any overpayment, mints a sales-counter token and sends the sale price to the share accounts.
- Each sale emits a `sold` event.

## Try it

1. Open both files in [Remix](https://remix.ethereum.org), or add them to a Hardhat project with `@openzeppelin/contracts` installed.
2. Compile with Solidity `^0.8.10`.
3. Deploy `lemonadeStand` with a name, description, symbol, total share supply and metadata URI.
4. From an editor account, call `edit(...)` to set a price and open the stand, then buy a glass with `GlassOfLemonade`.
5. Call `redeem()` from a shareholder account to collect the split proceeds.

> Educational workshop code: not audited and not intended for production use.

License: MIT, as declared in the SPDX headers of the source files.
