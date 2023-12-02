// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract StateChannelsChess {
  address public player1;
  address public player2;
  uint256 public wagerAmount;

  struct GameState {
    uint8 seq;
    bytes32 board;
    address currentTurn;
    bool gameOver;
  }
  GameState public state;

  uint256 public timeoutInterval;
  uint256 public timeout = 2**256 - 1;

  event GameStarted();
  event GameEnded();
  event TimeoutStarted();
  event MoveMade(address player, uint8 seq, uint8 value);

  modifier onlyPlayer() {
    require(msg.sender == player1 || msg.sender == player2, "Not a player.");
    _;
  }

  // Setup methods
  constructor(uint256 _timeoutInterval) payable {
    player1 = msg.sender;
    wagerAmount = msg.value;
    timeoutInterval = _timeoutInterval;
  }

  function join() public payable {
    require(player2 == address(0), "Game has already started.");
    require(!state.gameOver, "Game was canceled.");
    require(msg.value == wagerAmount, "Wrong wager amount.");

    player2 = msg.sender;
    state.currentTurn = player1;

    emit GameStarted();
  }

  function cancel() public {
    require(msg.sender == player1, "Only first player may cancel.");
    require(player2 == address(0), "Game has already started.");

    state.gameOver = true;
    address payable sender = payable(msg.sender);
    sender.transfer(address(this).balance);
  }


  // Play methods

  function move(uint8 seq, uint8 value) public onlyPlayer {
    require(!state.gameOver, "Game has ended.");
    require(msg.sender == state.currentTurn, "Not your turn.");
    require(state.seq == seq, "Incorrect sequence number.");

    state.currentTurn = opponentOf(msg.sender);
    state.seq += 1;

    // Clear timeout
    timeout = 2**256 - 1;

    // if (state.num == 21) {
    //   gameOver = true;
    //   address payable sender = payable(msg.sender);
    //   sender.transfer(address(this).balance);
    //   sender.transfer(address(this).balance);
    // }

    emit MoveMade(msg.sender, seq, value);
  }

  function endGame() public {
    require(!state.gameOver, "Game has already been ended.");
    require(msg.sender == player1 || msg.sender == player2, "Sender is not a player in this game");

    state.gameOver = true;

    // Handle wager distribution here
    // For example, send the total wager to the winner

    emit GameEnded();
  }

  // function moveFromState(uint8 seq, uint8 num, bytes sig, uint8 value) public {
  //   require(seq >= state.seq, "Sequence number cannot go backwards.");

  //   bytes32 message = prefixed(keccak256(address(this), seq, num));
  //   require(recoverSigner(message, sig) == opponentOf(msg.sender));

  //   state.seq = seq;
  //   state.num = num;
  //   state.currentTurn = msg.sender;

  //   move(seq, value);
  // }

  function opponentOf(address player) internal view returns (address) {
    require(player2 != address(0), "Game has not started.");

    if (player == player1) {
      return player2;
    } else if (player == player2) {
      return player1;
    } else {
      revert("Invalid player.");
    }
  }


  // Timeout methods

  function startTimeout() public {
    require(!state.gameOver, "Game has ended.");
    require(state.currentTurn == opponentOf(msg.sender),
      "Cannot start a timeout on yourself.");

    timeout = block.timestamp + timeoutInterval;
    emit TimeoutStarted();
  }

  function claimTimeout() public {
    require(!state.gameOver, "Game has ended.");
    require(block.timestamp >= timeout);

    state.gameOver = true;
    address payable opponent = payable(opponentOf(state.currentTurn));
    opponent.transfer(address(this).balance);
  }
}