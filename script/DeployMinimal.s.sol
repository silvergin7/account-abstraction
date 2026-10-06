// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol"; // Adjust path as needed
import {HelperConfig} from "./HelperConfig.s.sol"; // Relative path to HelperConfig

contract DeployMinimal is Script {
    function deployMinimalAccount()
        public
        returns (HelperConfig helperConfigInstance, MinimalAccount minimalAccountContract)
    {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);

        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);

        address owner = block.chainid == 31337
            ? config.account
            : (msg.sender == address(0) ? config.account : msg.sender);
        if (minimalAccount.owner() != owner) {
            minimalAccount.transferOwnership(owner);
        }

        vm.stopBroadcast();

        return (helperConfig, minimalAccount);
    }

    function run() public returns (HelperConfig, MinimalAccount) {
        return deployMinimalAccount();
    }
}
