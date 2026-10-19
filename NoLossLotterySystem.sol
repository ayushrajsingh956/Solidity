// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NoLossLotterySystem is Ownable{
    using SafeERC20 for IERC20;
    IERC20 private immutable LotteryTOKEN;

    enum PrizepoolStatus{
        Active,
        Inactive
    }

    mapping (address => uint256) public UserInfoBalance;
    mapping (address => bool) public hasJoined;
    mapping (address => bool) public active;
    address[] public depositors;
    uint256 public totalPoolSize;

    error NoLossLotterySystem_ZeroValueError();
    error NoLossLotterySystem_falseAmount();

    event userDetails(
        address user,
        uint256 UserAmount
    );

    constructor(address tokenAddress) Ownable(msg.sender) {
        LotteryTOKEN = IERC20(tokenAddress);
    }

    function Deposits(uint256 amount) external {
        if(amount == 0){
            revert NoLossLotterySystem_ZeroValueError();
        }

        LotteryTOKEN.safeTransferFrom(msg.sender,address(this),amount);

        UserInfoBalance[msg.sender] += amount;
        totalPoolSize += amount;

        DepositorRegistration(msg.sender);

        emit userDetails(msg.sender, amount);
    }

    function DepositorRegistration(address user) private {
        if(!hasJoined[user]){
            hasJoined[user]  = true;
            active[user] = true;
            depositors.push(user);
        }
    }

    function withdraw(uint256 withdrawAmount) external {
        if (UserInfoBalance[msg.sender] < withdrawAmount){
            revert NoLossLotterySystem_falseAmount();
        }

        UserInfoBalance[msg.sender] -= withdrawAmount;
        totalPoolSize -= withdrawAmount;

        if(UserInfoBalance[msg.sender] == 0){
            hasJoined[msg.sender] = false;
            active[msg.sender] = false;
        }       

        LotteryTOKEN.safeTransfer(msg.sender, withdrawAmount);
    }

    uint256 public lotteryRound;
    uint256 public nonce;
    address public recentWinner;

    struct TicketInterval {
        uint256 start;
        uint256 end;
        address user;
    }

    TicketInterval[] public intervals;

    function lotteryDraw () external onlyOwner {
        if(totalPoolSize == 0){
            revert NoLossLotterySystem_ZeroValueError();
        }
        lotteryRound++;

        _buildTicketInterval();

        nonce++;
        uint256 winningTicket = _getWinningTicket();
        address winner = _selectWinner(winningTicket);


        _payoutPrize(winner);
        recentWinner = winner;
    }

    function _buildTicketInterval() internal {
        delete intervals;
        uint256 current;
        uint256 length = depositors.length;


        for (uint256 i; i < length; i++) {
            address user = depositors[i];
            uint256 balance = UserInfoBalance[user];

            if (!active[user]) continue;

            intervals.push(
                TicketInterval({
                    start: current,
                    end: current + balance,
                    user: user
                })
            );

            current += balance;
        }
    }

    function _getWinningTicket() internal view returns (uint256){
        return (_getrandomNumber() % totalPoolSize);
    }

    function _getrandomNumber() public view returns(uint256){
        return uint256(keccak256(abi.encode(block.prevrandao,block.timestamp,depositors.length,nonce)));
    }

    function _selectWinner(uint256 ticket) internal view returns (address) {
        uint256 low = 0;
        uint256 high = intervals.length - 1;


        while (low <= high) {
            uint256 mid = low + (high - low) / 2;
            if (ticket >= intervals[mid].start && ticket < intervals[mid].end) {
                return intervals[mid].user;
            } else if (ticket < intervals[mid].start) {
                if (mid == 0) break;
                high = mid - 1;
            } else {
                low = mid + 1;
            }
        }
        revert("Winner not found");
    }

    function _payoutPrize(address winner) internal returns (uint256 prize) {
        uint256 balance = LotteryTOKEN.balanceOf(address(this));

        if (balance <= totalPoolSize) {
            return 0;
        }

        prize = balance - totalPoolSize;
        LotteryTOKEN.safeTransfer(winner, prize);
    }
}
