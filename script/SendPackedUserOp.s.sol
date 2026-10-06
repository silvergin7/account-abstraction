// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @notice Builds and signs PackedUserOperations for local Anvil (31337) and testnets.
contract SendPackedUserOp is Script {
    /// @dev Anvil account #0 private key — use on local chain only.
    uint256 private constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 private constant ANVIL_CHAIN_ID = 31337;

    HelperConfig public helperConfig;

    function setUp() public {
        helperConfig = new HelperConfig();
    }

    /// @dev Lesson-style 2-arg API only — `config.account` as sender (EOA). Do not use for `handleOps` tests.
    function generateSignedUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config)
        public
        view
        returns (PackedUserOperation memory)
    {
        return generateSignedUserOperation(callData, config, config.account);
    }

    /// @dev `minimalAccount` must be the smart contract account (UserOp.sender), not the owner EOA.
    /// Nonce from EntryPoint (not `vm.getNonce`) avoids AA25 on the first op.
    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    ) public view returns (PackedUserOperation memory) {
        uint256 nonce = IEntryPoint(config.entryPoint).getNonce(minimalAccount, 0);
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);

        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        uint8 v;
        bytes32 r;
        bytes32 s;

        if (block.chainid == ANVIL_CHAIN_ID) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    function _generateUnsignedUserOperation(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint256 verificationGasLimit = 200_000;
        uint256 callGasLimit = 300_000;
        uint256 maxFeePerGas = 100 gwei;
        uint256 maxPriorityFeePerGas = 2 gwei;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32((verificationGasLimit << 128) | callGasLimit),
            preVerificationGas: verificationGasLimit + 50_000,
            gasFees: bytes32((maxPriorityFeePerGas << 128) | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
