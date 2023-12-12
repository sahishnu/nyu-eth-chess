const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("StateChannelsChess", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployChessFixture() {
    const TEN_MINUTES_IN_SECONDS = 10 * 60;
    const ONE_GWEI = 1_000_000_000;

    const wagerAmount = ONE_GWEI;
    const _timeoutInterval = TEN_MINUTES_IN_SECONDS;

    // Contracts are deployed using the first signer/account by default
    const [owner, opponent, extraPlayer] = await ethers.getSigners();

    const ChessGame = await ethers.getContractFactory("StateChannelsChess");
    const chessGame = await ChessGame.deploy(_timeoutInterval, {
      value: wagerAmount,
    });

    return {
      chessGame,
      _timeoutInterval,
      wagerAmount,
      owner,
      opponent,
      extraPlayer,
    };
  }

  describe("Deployment", function () {
    it("This test should never fail", async function () {
      const { chessGame } = await loadFixture(deployChessFixture);

      expect(1 + 1).to.equal(2);
    });

    it("Should set the right wagerAmount", async function () {
      const { chessGame, wagerAmount } = await loadFixture(deployChessFixture);

      expect(await chessGame.wagerAmount()).to.equal(wagerAmount);
    });

    it("Should set the right player1", async function () {
      const { chessGame, owner } = await loadFixture(deployChessFixture);

      expect(await chessGame.player1()).to.equal(owner.address);
    });

    it("Should set the right timeout interval", async function () {
      const { chessGame, _timeoutInterval } = await loadFixture(
        deployChessFixture
      );

      expect(await chessGame.timeoutInterval()).to.equal(_timeoutInterval);
    });

    it("Should receive and store the funds to chess game", async function () {
      const { chessGame, wagerAmount } = await loadFixture(deployChessFixture);

      expect(await ethers.provider.getBalance(chessGame.target)).to.equal(
        wagerAmount
      );
    });
  });

  describe("Cancel", async function () {
    it("Should allow player to cancel game before it starts", async function () {
      const { chessGame, owner, wagerAmount } = await loadFixture(
        deployChessFixture
      );
      await expect(chessGame.connect(owner).cancel()).to.changeEtherBalance(
        chessGame,
        -wagerAmount
      );
    });

    it("Should reject player from canceling if game has started", async function () {
      const { chessGame, owner, opponent, wagerAmount } = await loadFixture(
        deployChessFixture
      );
      await expect(
        chessGame.connect(opponent).join({ value: wagerAmount })
      ).to.changeEtherBalance(chessGame, wagerAmount);
      await expect(chessGame.connect(owner).cancel()).to.be.reverted;
    });
  });

  describe("Opponent", async function () {
    it("Should allow opponent to join before game starts", async function () {
      const { chessGame, opponent, wagerAmount } = await loadFixture(
        deployChessFixture
      );
      await expect(
        chessGame.connect(opponent).join({ value: wagerAmount })
      ).to.changeEtherBalance(chessGame, wagerAmount);
    });

    it("Should reject player from joining if game has started", async function () {
      const { chessGame, opponent, wagerAmount, extraPlayer } =
        await loadFixture(deployChessFixture);
      await expect(
        chessGame.connect(opponent).join({ value: wagerAmount })
      ).to.changeEtherBalance(chessGame, wagerAmount);
      await expect(chessGame.connect(extraPlayer).join({ value: wagerAmount }))
        .to.be.reverted;
    });
  });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
