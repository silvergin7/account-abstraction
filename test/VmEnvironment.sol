// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @dev Detects Foundry's EraVM runner (`forge test --zksync`).
/// @notice Adapted from Cyfrin foundry-devops `ZkSyncChainChecker.isOnZkSyncPrecompiles`.
library VmEnvironment {
    function isEraVm() internal returns (bool) {
        address[4] memory unsupportedPrecompiles =
            [address(0x03), address(0x04), address(0x05), address(0x08)];

        for (uint256 i = 0; i < unsupportedPrecompiles.length; i++) {
            bool success;
            address target = unsupportedPrecompiles[i];
            assembly {
                success := call(gas(), target, 0, 0, 0, 0, 0)
            }
            if (!success) {
                return true;
            }
        }

        return false;
    }
}
