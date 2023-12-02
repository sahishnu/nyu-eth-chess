# nyu-eth-chess

Final project for NYU CSCI-GA 3033-078 Cryptocurrencies &amp; Decentralized Ledgers. The project will be an attempt at implementing chess via layer-2 eth solutions.


## Development

### Getting started

Clone the repo
```
git clone https://github.com/sahishnu/nyu-eth-chess.git
```

Install dependencies, compile contracts & run tests
```
npm i
npx hardhat compile
npx hardhat test
```


## Project Proposal

### Submitted Proposal

The aim of this project is to design, implement and evaluate a fully functional chess game on Ethereum’s layer-2 scaling solutions. The game will follow standard chess rules, while also allowing players to stake cryptocurrency when playing with others. We will explore different layer-2 solutions on their ability to be performant, cost-effective and provide a good user experience for decentralized gaming applications.

The game will be implemented as a smart-contract compatible with one Layer-2 solution. We will evaluate performance metrics such as transaction speed, gas costs, and latency. If time permits, we will extend the implementation to multiple Layer-2 solutions and perform a comparative analysis of the performance metrics across these solutions.

### Professor Response

This sounds like a good project, I approve. Given three team members I think it is reasonable to implement layer-2 solutions. Please look into both rollups and state channel approaches. It would be interesting to extend to multi-game mechanics, such as maintaining ELO rankings for different players in the system