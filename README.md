# Mask Flipper

Flip a hashmask against the floor price in NFTX.

- [Hashmasks](https://www.thehashmasks.com/)

- [NFTX](https://nftx.org/#/)


## How does it work?
- a hashmasks NFT can be transfered into the contract
- the contract flips the NFT for a mask token 
- the received mask token is swapped on sushi-swap for WETH
- WETH is paid out to the user

All this is happening in one transaction.

## Getting started
Mask Flipper uses dapp.tools for development. Please install the dapp client.

## Run RPC tests
The RPC test is using the deployed mainnet contracts of NFTX, HashMasks and Sushiswap.
install dependencies
```
dapp update
```

````
export ETH_RPC_URL= <INFURA/NODE URL>
````

```
make test
```
