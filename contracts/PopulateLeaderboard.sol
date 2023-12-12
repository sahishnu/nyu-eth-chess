contract PopulateLeaderboard is IChessContract {
    ChessLeaderboard public leaderboard;

    constructor(address _leaderboardAddress, address[] memory players, uint256[] memory wins) {
        require(players.length == wins.length, "Players and wins arrays must be of the same length");

        leaderboard = ChessLeaderboard(_leaderboardAddress);

        for (uint i = 0; i < players.length; i++) {
            uint256 winCount = wins[i];
            for (uint256 j = 0; j < winCount; j++) {
                leaderboard.updateStats(players[i], true);
            }
        }
    }

    function isChessContract() external pure override returns (bool) {
        return true;
    }

}
