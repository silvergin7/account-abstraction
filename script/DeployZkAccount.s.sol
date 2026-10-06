// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AAFactory} from "../src/zksync/AAFactory.sol";

contract DeployZkAccount is Script {
    function run() external {
        require(block.chainid == 300, "Use zkSync Sepolia only");

        string memory artifact = vm.readFile("zkout/ZkMinimalAccount.sol/ZkMinimalAccount.json");
        bytes32 bytecodeHash = vm.parseJsonBytes32(artifact, ".hash");

        vm.startBroadcast();

        AAFactory factory = new AAFactory(bytecodeHash);

        // Include the wallet's bytecode in the deployment transaction.
        (bool success,) = address(vm).call(abi.encodeWithSignature("zkUseFactoryDep(string)", "ZkMinimalAccount"));
        require(success, "Factory dependency setup failed");

        address account = factory.deployAccount(bytes32(0));

        vm.stopBroadcast();

        console2.log("Factory:", address(factory));
        console2.log("Account:", account);
    }
}
