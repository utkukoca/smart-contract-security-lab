// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeOnTransferToken is ERC20 {
    address public immutable feeRecipient;
    uint256 public constant FEE_DIVISOR = 10;

    // Intentionally unrestricted: mock token for tests only
    constructor(address _feeRecipient) ERC20("FeeOnToken", "FOT") {
        feeRecipient = _feeRecipient;
    }

    function mint(address _toAddress, uint256 _amount) public {
        _mint(_toAddress, _amount);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, value);
        } else {
            uint256 feeGain = value / FEE_DIVISOR;
            uint256 newValue = value - feeGain;
            super._update(from, feeRecipient, feeGain);
            super._update(from, to, newValue);
        }
    }
}
