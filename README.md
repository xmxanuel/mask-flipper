# Mask Flipper

Flip a hashmask against the floor price in NFTX.

[Hashmasks](https://www.thehashmasks.com/)

[NFTX](https://nftx.org/#/)


## How does it work?
The mask flipper contract takes a hash mask from the user and moves it into the NFTX hashmask pool. The received mask token is swapped on sushi-swap for WETH. Afterwards the WETTH is paid out to the user.

All this is happening in one transaction.

## Getting started
Mask Flipper uses dapp.tools for development. Please install the dapp client.

## Run RPC tests

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
