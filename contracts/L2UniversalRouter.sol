// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// Command implementations
import {Dispatcher} from './base/Dispatcher.sol';
import {RewardsCollector} from './base/RewardsCollector.sol';
import {RouterParameters, RouterImmutables} from './base/RouterImmutables.sol';
import {Commands} from './libraries/Commands.sol';
import {IUniversalRouter} from './interfaces/IUniversalRouter.sol';
import {Calldata} from './libraries/Calldata.sol';

contract L2UniversalRouter is RouterImmutables, IUniversalRouter, Dispatcher, RewardsCollector {
    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert TransactionDeadlinePassed();
        _;
    }

    constructor(RouterParameters memory params) RouterImmutables(params) {}

    // The fallback function removes the need for a selector
    // We don't need to check against `execute` because the second
    // byte is `0x93` which isn't a Universal Router command anyway
    fallback(bytes calldata) external payable returns (bytes memory) {
        bool success;
        bytes memory output;
        uint8 numCommands = Calldata.getUint8(0);
        uint256 offset = 1;
        for (uint8 commandIndex; commandIndex < numCommands;) {
            bytes1 command = Calldata.getBytes1(offset);

            uint16 length = Calldata.getUint16(1 + offset);

            bytes calldata input = Calldata.slice(1 + offset + 2, length);

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            }

            unchecked {
                offset += 1 + length + 2;
                commandIndex++;
            }
        }
    }

    /// @inheritdoc IUniversalRouter
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline)
        external
        payable
        checkDeadline(deadline)
    {
        execute(commands, inputs);
    }

    /// @inheritdoc Dispatcher
    function execute(bytes calldata commands, bytes[] calldata inputs) public payable override isNotLocked {
        bool success;
        bytes memory output;
        uint256 numCommands = commands.length;
        if (inputs.length != numCommands) revert LengthMismatch();

        // loop through all given commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands;) {
            bytes1 command = commands[commandIndex];

            bytes calldata input = inputs[commandIndex];

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({commandIndex: commandIndex, message: output});
            }

            unchecked {
                commandIndex++;
            }
        }
    }

    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    /// @notice To receive ETH from WETH and NFT protocols
    receive() external payable {}
}
