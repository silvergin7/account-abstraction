// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {DEPLOYER_SYSTEM_CONTRACT} from "foundry-era-contracts/system-contracts/contracts/Constants.sol";
import {IContractDeployer} from "foundry-era-contracts/system-contracts/contracts/interfaces/IContractDeployer.sol";
import {
    SystemContractsCaller
} from "foundry-era-contracts/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {ZkMinimalAccount} from "./ZkMinimalAccount.sol";

contract AAFactory {
    bytes32 public immutable accountBytecodeHash;

    constructor(bytes32 bytecodeHash) {
        accountBytecodeHash = bytecodeHash;
    }

    function deployAccount(bytes32 salt) external returns (address account) {
        (bool success, bytes memory result) = SystemContractsCaller.systemCallWithReturndata(
            uint32(gasleft()),
            address(DEPLOYER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(
                IContractDeployer.create2Account,
                (salt, accountBytecodeHash, bytes(""), IContractDeployer.AccountAbstractionVersion.Version1)
            )
        );

        require(success, "Account deployment failed");
        account = abi.decode(result, (address));

        // Make your wallet—not this factory—the owner.
        ZkMinimalAccount(payable(account)).transferOwnership(msg.sender);
    }
}
