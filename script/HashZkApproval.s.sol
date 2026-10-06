// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {ZkMinimalAccount} from "../src/zksync/ZkMinimalAccount.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "foundry-era-contracts/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";

contract HashZkApproval is Script {
    using MemoryTransactionHelper for Transaction;

    function run() external {
        require(block.chainid == 300, "Use zkSync Sepolia only");

        ZkMinimalAccount account = ZkMinimalAccount(payable(vm.envAddress("ZK_ACCOUNT")));

        Transaction memory txn;
        txn.txType = 113;
        txn.from = uint256(uint160(address(account)));
        txn.to = uint256(uint160(vm.envAddress("MOCK_TOKEN")));
        txn.gasLimit = 2_000_000;
        txn.gasPerPubdataByteLimit = 50_000;
        txn.maxFeePerGas = 50_000_000;
        txn.maxPriorityFeePerGas = 0;
        txn.nonce = account.getNonce();
        txn.value = 0;
        txn.data = abi.encodeWithSignature("approve(address,uint256)", account.owner(), 1 ether);
        txn.factoryDeps = new bytes32[](0);
        txn.paymasterInput = "";
        txn.signature = "";
        txn.reservedDynamic = "";

        console2.log("Nonce:", txn.nonce);
        console2.log("Hash:");
        console2.logBytes32(txn.encodeHash());
    }
}
