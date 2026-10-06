// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract SimpleBank {
    mapping(address => uint256) private balances;
    mapping(address => bool) private hasDeposited;
    address[] private depositors;

    error ZeroAmount();
    error InsufficientBalance();
    error TransferFailed();
    error InvalidIndex();

    function deposit() external payable {
        if (msg.value == 0) {
            revert ZeroAmount();
        }
        assembly {
            mstore(0x00, caller())
            mstore(0x20, balances.slot)
            let senderSlot := keccak256(0x00, 0x40)
            let senderBalance := sload(senderSlot)
            if lt(senderBalance, callvalue()) {
                revert(0, 0)
            }
            let totalValue := add(senderBalance, callvalue())
            sstore(senderSlot, totalValue)

            mstore(0x20, hasDeposited.slot)
            let hasDepositedSlot := keccak256(0x00, 0x40)
            let isDeposited := sload(hasDepositedSlot)
            if iszero(isDeposited) {
                sstore(hasDepositedSlot, true)
            }
            let currentLengthOfArray := sload(depositors.slot)

            mstore(0x00, depositors.slot)
            let base := keccak256(0x00, 0x20)

            //despositors[0]
            let arrayElementSlot := add(base, currentLengthOfArray)

            //depositors.push(callerAddress)
            sstore(arrayElementSlot, caller())

            let newLengthOfArray := add(currentLengthOfArray, 1)
            sstore(depositors.slot, newLengthOfArray)
        }
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        assembly {
            mstore(0x00, caller())
            mstore(0x20, balances.slot)
            let senderSlot := keccak256(0x00, 0x40)
            let senderBalance := sload(senderSlot)
            if gt(amount, senderBalance) {
                revert(0, 0)
            }
            let withdrawAmount := sub(senderBalance, amount)
            sstore(senderSlot, withdrawAmount)

            let success := call(gas(), caller(), amount, 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function balanceOf(address user) external view returns (uint256 balanceOfUser) {
        assembly {
            mstore(0x00, user)
            mstore(0x20, balances.slot)
            let userSlot := keccak256(0x00, 0x40)
            balanceOfUser := sload(userSlot)
        }
        return balanceOfUser;
    }

    function totalDepositors() external view returns (uint256 depositorLength) {
        assembly{
            depositorLength := sload(depositors.slot)
        }

    }

    function depositorAt(uint256 index) external view returns (address DepositorAddress) {
        assembly{
            mstore(0x00, depositors.slot)
            let depositorLength := sload(depositors.slot)
            if gt(index,depositorLength){
                revert (0,0)
            }
            let base := keccak256(0x00, 0x20)

            DepositorAddress := sload(add(base, index))
        }
    }
}
