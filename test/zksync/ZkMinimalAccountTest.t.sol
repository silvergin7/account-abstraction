// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {ZkMinimalAccount} from "src/zksync/ZkMinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {
    MemoryTransactionHelper,
    Transaction
} from "foundry-era-contracts/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {BOOTLOADER_FORMAL_ADDRESS} from "foundry-era-contracts/system-contracts/contracts/Constants.sol";
import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "foundry-era-contracts/system-contracts/contracts/interfaces/IAccount.sol";
import {VmEnvironment} from "../VmEnvironment.sol";

contract ZkMinimalAccountTest is Test {
    using MemoryTransactionHelper for Transaction;

    ZkMinimalAccount minimalAccount;
    ERC20Mock usdc;

    address constant ANVIL_DEFAULT_ACCOUNT = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    bytes32 constant EMPTY_BYTES32 = bytes32(0);
    uint256 constant AMOUNT = 1 ether;

    function setUp() public {
        if (!VmEnvironment.isEraVm()) {
            vm.skip(true);
        }

        minimalAccount = new ZkMinimalAccount();

        // CRITICAL: Transfer ownership to the Anvil default account whose private key we use for signing.
        // This ensures that `signer == owner()` check passes inside the account's validation logic.
        minimalAccount.transferOwnership(ANVIL_DEFAULT_ACCOUNT);

        usdc = new ERC20Mock();

        // CRITICAL: Deal ETH to the minimalAccount.
        // The ZkMinimalAccount's validateTransaction checks if the account has enough balance
        // to cover potential fees (derived from transaction gas parameters).
        vm.deal(address(minimalAccount), AMOUNT);
    }

    function testZkOwnerCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        // Arrange: Set up the preconditions for the test.
        address dest = address(usdc);
        uint256 value = 0;

        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        Transaction memory transaction = _createUnsignedTransaction(
            minimalAccount.owner(), // owner initiates the AA transaction
            113, // EIP_712_TX_TYPE (0x71) on zkSync
            dest,
            value,
            functionData
        );

        // Act: Perform the action being tested.
        vm.prank(minimalAccount.owner());
        minimalAccount.executeTransaction(
            EMPTY_BYTES32, // _txHash (placeholder for owner-initiated path)
            EMPTY_BYTES32, // _suggestedSignedHash (placeholder)
            transaction
        );

        // Assert: Verify the outcome of the action.
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT, "USDC minting failed");
    }

    function testZkValidateTransaction() public {
        // Arrange
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        Transaction memory transaction =
            _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);

        transaction = _signTransaction(transaction);

        // Act
        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic = minimalAccount.validateTransaction(EMPTY_BYTES32, EMPTY_BYTES32, transaction);

        // Assert
        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC, "Validation did not return success magic");
    }

    function _createUnsignedTransaction(
        address _owner,
        uint256 _txType,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal view returns (Transaction memory unsignedTx) {
        unsignedTx = Transaction({
            txType: _txType,
            from: uint256(uint160(_owner)),
            to: uint256(uint160(_to)),
            gasLimit: 1_000_000,
            gasPerPubdataByteLimit: 800,
            maxFeePerGas: 100_000_000,
            maxPriorityFeePerGas: 0,
            paymaster: 0,
            nonce: minimalAccount.getNonce(),
            value: _value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: _data,
            signature: bytes(""),
            factoryDeps: new bytes32[](0),
            paymasterInput: bytes(""),
            reservedDynamic: bytes("")
        });
    }

    function _signTransaction(Transaction memory transaction) internal view returns (Transaction memory) {
        bytes32 unsignedTransactionHash = MemoryTransactionHelper.encodeHash(transaction);

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, unsignedTransactionHash);

        Transaction memory signedTransaction = transaction;
        signedTransaction.signature = abi.encodePacked(r, s, v);

        return signedTransaction;
    }
}
