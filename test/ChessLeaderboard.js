const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ChessLeaderboard", function () {
  let chessLeaderboard;
  let owner;
  let player1;
  let player2;

  beforeEach(async function () {
    [owner, player1, player2] = await ethers.getSigners();
    
    const ChessLeaderboardFactory = await ethers.getContractFactory("ChessLeaderboard", owner);
    chessLeaderboard = await ChessLeaderboardFactory.deploy();
    await chessLeaderboard.waitForDeployment();
  });

  describe("updateStats", function () {
    it("should update wins and losses", async function () {
      await chessLeaderboard.updateStats(player1.address, true);
      let stats = await chessLeaderboard.getStats(player1.address);
      expect(stats.wins).to.equal(1);
      expect(stats.losses).to.equal(0);

      await chessLeaderboard.updateStats(player1.address, false);
      stats = await chessLeaderboard.getStats(player1.address);
      expect(stats.wins).to.equal(1);
      expect(stats.losses).to.equal(1);
    });
  });

  describe("getStats", function () {
    it("should return the correct stats", async function () {
      const initialStats = await chessLeaderboard.getStats(player2.address);
      expect(initialStats.wins).to.equal(0);
      expect(initialStats.losses).to.equal(0);
    });
  });

  describe("getLeaderboard", function () {
    it("Should return the entire leaderboard", async function () {
      await chessLeaderboard.updateStats(player1.address, true);
      await chessLeaderboard.updateStats(player2.address, false);
      const [addresses, stats] = await leaderboard.getLeaderboard();
      expect(addresses.length).to.equal(2);
      expect(addresses[0]).to.equal(player1.address);
      expect(stats[0].wins).to.equal(1);
      expect(stats[0].losses).to.equal(0);
      expect(addresses[1]).to.equal(player2.address);
      expect(stats[1].wins).to.equal(0);
      expect(stats[1].losses).to.equal(1);
    });
  });
});
