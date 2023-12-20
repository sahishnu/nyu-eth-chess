// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

interface IChessContract {
    function isChessContract() external pure returns (bool);
}

contract ChessLeaderboard {
    struct PlayerStats {
        uint256 wins;
        uint256 losses;
    }

    mapping(address => PlayerStats) public playerStats;
    address[] public playerAddresses;

    modifier onlyChessContract() {
        require(
            IChessContract(msg.sender).isChessContract(),
            "Caller is not a valid Chess contract"
        );
        _;
    }

    function updateStats(address player, bool won) external onlyChessContract {
        if (playerStats[player].wins == 0 && playerStats[player].losses == 0) {
            playerAddresses.push(player);
        }
        if (won) {
            playerStats[player].wins++;
        } else {
            playerStats[player].losses++;
        }
    }

    function getStats(
        address player
    ) external view returns (uint256 wins, uint256 losses) {
        PlayerStats storage stats = playerStats[player];
        return (stats.wins, stats.losses);
    }

    function getLeaderboard()
        external
        view
        returns (address[] memory, PlayerStats[] memory)
    {
        uint256 playerCount = playerAddresses.length;
        PlayerStats[] memory stats = new PlayerStats[](playerCount);

        for (uint256 i = 0; i < playerCount; i++) {
            stats[i] = playerStats[playerAddresses[i]];
        }

        return (playerAddresses, stats);
    }
}
