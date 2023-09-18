// SPDX-License-Identifier: BUSL-1.1
// from https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code

pragma solidity 0.8.17;

import {ERC20} from "shim/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract WFIL is ERC20("Wrapped Filecoin", "WFIL", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    // constructor takes an owner address to match fevmate wfil
    constructor(address _owner) {}

    function deposit() public payable {
      _mint(msg.sender, msg.value);

      emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public {
      _burn(msg.sender, _amount);

      emit Withdrawal(msg.sender, _amount);

      msg.sender.safeTransferETH(_amount);
    }

    receive() external payable {
      deposit();
    }
}
