# Storm Harbor

Trustless escrow for exploited funds

### Explanation

Storm Harbor is designed to be a permissionless, immutable smart contract for whitehats, blackhats, and everyone in between to organize the return of exploited funds.

Whitehats can deposit exploited funds to the contract and, in a show of good faith, request zero payment in return. The claimant can decide to pay 0 or, optionally, some percentage of the stolen funds back to the exploiter.

Others can request any amount of payment in the ERC20 token of their chosing.

Funds can be reclaimed by an address designated by the exploiter. If the exploited address remains vulnerable to further exploits (e.g. claimant address still has malicious approvals), the "claimant" address can be set to the null address as a show of good faith. The claimant address can be reset to the exploited address once it is no longer vulnerable or can be set to an altogether new address.

The bounty amount can be changed by the depositor at any time.

Any change to the terms of the escrow locks the escrowed funds from being withdrawn by the depositor for 7 days from the timestamp of the change.

### Items available for escrow

ERC20 tokens and ERC721 NFTs can currently be escrowed.
