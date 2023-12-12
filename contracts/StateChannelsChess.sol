// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

import "./VerifySignature.sol";

contract StateChannelsChess {
    address public player1;
    address public player2;
    uint256 public wagerAmount;

    /**
     * Representation of the current state of the game.
     *
     * seq: A sequence number to help determine the order of moves happening in the game.
     * board: A standard PGN string which represents all the moves made in the game so far.
     *        eg: '1. d3 e6 2. Qd2 Qg5 3. Qxg5 Bd6 4. Qf4'
     * currentTurn: The address of the player whose turn it is. This would be player 1 or player 2.
     * gameOver: boolean representing if the game has completed.
     *
     * TODO: Determine if seq is needed.
     * TODO: Determine if we also need `gameStarted` to determine that the game has started.
     * TODO: Maybe we need a `address winner`. The absence/presence of a `winner` value can tell if the game is over.
     */
    struct GameState {
        uint8 seq;
        string board;
        address currentTurn;
        bool gameOver;
    }

    GameState public state;

    uint256 public timeoutInterval;
    uint256 public constant MAX_TIMEOUT = 2 ** 256 - 1;
    // Initially the timeout is some ridiculously high block number.
    // When a timeout is invoked, this value is updated to the
    // current block number + timeoutInterval. When a move is made,
    // Reset this value back to max.
    uint256 public timeout = MAX_TIMEOUT;

    event GameStarted();
    event GameEnded();
    event TimeoutStarted();
    event MoveMade(address player, uint8 seq, string value);

    // Modifier which asserts that a function must be called by player 1 or player 2.
    modifier onlyPlayer() {
        require(
            msg.sender == player1 || msg.sender == player2,
            "Not a player."
        );
        _;
    }

    /**
     * The contract is deployed by player 1 (msg.sender) and includes the wager (msg.value).
     * A timeout interval is also included which determines how long a turn can last, before
     * a player can be considered forfeit for inactivity.
     *
     * TODO: Determine if timeoutInterval can just be standardized.
     */
    constructor(uint256 _timeoutInterval) payable {
        player1 = msg.sender;
        wagerAmount = msg.value;
        timeoutInterval = _timeoutInterval;
        state.board = "";
        state.gameOver = false;
        state.seq = 0;
    }

    // Player 2 can join as long as the game has not started (or ended).
    // They must also match the wager of player 1.
    function join() public payable {
        require(player2 == address(0), "Game has already started.");
        require(!state.gameOver, "Game was canceled.");
        require(msg.value == wagerAmount, "Wrong wager amount.");

        player2 = msg.sender;
        state.currentTurn = player1;

        emit GameStarted();
    }

    // Player 1 can cancel the match before the game starts.
    // This would allow player 1 to refund their wager.
    function cancel() public {
        require(msg.sender == player1, "Only first player may cancel.");
        require(player2 == address(0), "Game has already started.");

        state.gameOver = true;
        address payable sender = payable(msg.sender);
        sender.transfer(address(this).balance);
    }

    // Play methods
    // NOTE: Right now we assume that the clients are acting correctly
    function move(uint8 seq, string calldata value) public onlyPlayer {
        require(!state.gameOver, "Game has ended.");
        require(msg.sender == state.currentTurn, "Not your turn.");
        require(state.seq == seq, "Incorrect sequence number.");

        state.currentTurn = opponentOf(msg.sender);
        state.board = append(state.board, value);
        state.seq += 1;

        // Reset timeout to the max value.
        timeout = MAX_TIMEOUT;

        // Check if the last character of the string is #
        string memory lastCharacter = getLastCharacter(value);
        if (keccak256(abi.encodePacked(lastCharacter)) == keccak256("#")) {
            state.gameOver = true;
            payable(msg.sender).transfer(address(this).balance);
        }

        emit MoveMade(msg.sender, seq, value);
    }

    function endGame() public {
        require(!state.gameOver, "Game has already been ended.");
        require(
            msg.sender == player1 || msg.sender == player2,
            "Sender is not a player in this game"
        );

        state.gameOver = true;

        // Handle wager distribution here
        // For example, send the total wager to the winner

        emit GameEnded();
    }

    function moveFromState(
        uint8 seq,
        string calldata board,
        bytes memory sig,
        string calldata value
    ) public onlyPlayer {
        require(seq >= state.seq, "Sequence number cannot go backwards.");

        // Correctly hash the address and numbers
        bytes32 message = keccak256(
            abi.encodePacked(address(this), seq, board, value)
        );

        // Ensure the signer is the opponent
        address signer = recoverSigner(message, sig);
        require(
            recoverSigner(message, sig) == opponentOf(msg.sender),
            "Signer must be the opponent."
        );

        // Update state
        state.seq = seq;
        state.board = board;
        state.currentTurn = msg.sender;

        // Call the move function
        move(seq, value);
    }

    // A util function to get the opponent of (address player).
    // For player 1, return player 2. For player 2, return player 1.
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

    /**
     * The contract is deployed by player 1 (msg.sender) and includes the wager (msg.value).
     * A timeout interval is also included which determines how long a turn can last, before
     * a player can be considered forfeit for inactivity.
     *
     * TODO: Determine if timeoutInterval can just be standardized.
     */

    /**
     * The timeout mechanism allows a player to start a timer on their opponents turn.
     * If the opponent does not make a move in the timeoutInterval time, they are forfeit.
     * The player can then take their winnings.
     */
    function startTimeout() public {
        require(!state.gameOver, "Game has ended.");
        require(
            state.currentTurn == opponentOf(msg.sender),
            "Cannot start a timeout on yourself."
        );

        timeout = block.timestamp + timeoutInterval;
        emit TimeoutStarted();
    }

    /**
     * If the timout is reached without the opponent taking their turn,
     * then the player can claim all the wager funds.
     */
    function claimTimeout() public {
        require(!state.gameOver, "Game has ended.");
        require(block.timestamp >= timeout);

        state.gameOver = true;
        address payable opponent = payable(opponentOf(state.currentTurn));
        opponent.transfer(address(this).balance);
    }

    // Append new string to existing string with a whitespace in between
    function append(
        string memory a,
        string calldata b
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, " ", b));
    }

    // Return a list of players in the game
    function getPlayers() public view returns (address[2] memory) {
        return [player1, player2];
    }

    // Get the current state of the game
    function getState() public view returns (GameState memory) {
        return state;
    }

    // Set state
    function setState(GameState memory _state) public {
        state = _state;
    }

    function getLastCharacter(
        string memory str
    ) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length == 0) {
            return "";
        }
        bytes1 lastByte = strBytes[strBytes.length - 1];
        return string(abi.encodePacked(lastByte));
    }
}
