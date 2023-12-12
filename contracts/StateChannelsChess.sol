// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

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
    uint256 public constant MAX_TIMEOUT = 2**256 - 1;
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
    function move(uint8 seq, string calldata value) public onlyPlayer {
        require(!state.gameOver, "Game has ended.");
        require(msg.sender == state.currentTurn, "Not your turn.");
        require(state.seq == seq, "Incorrect sequence number.");

        state.currentTurn = opponentOf(msg.sender);
        state.board = value;
        state.seq += 1;

        // Reset timeout to the max value.
        timeout = MAX_TIMEOUT;

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

    // function moveFromState(uint8 seq, uint8 num, bytes sig, uint8 value) public {
    //   require(seq >= state.seq, "Sequence number cannot go backwards.");

    //   bytes32 message = prefixed(keccak256(address(this), seq, num));
    //   require(recoverSigner(message, sig) == opponentOf(msg.sender));

    //   state.seq = seq;
    //   state.num = num;
    //   state.currentTurn = msg.sender;

    //   move(seq, value);
    // }

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

    /// signature methods.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}
