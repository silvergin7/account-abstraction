// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "script/DeployMinimal.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {SendPackedUserOp} from "script/SendPackedUserOp.s.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {VmEnvironment} from "../VmEnvironment.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    HelperConfig.NetworkConfig activeNetworkConfig;
    MinimalAccount minimalAccount;
    SendPackedUserOp sendPackedUserOpScript;
    ERC20Mock usdc;

    uint256 constant AMOUNT = 1e18;
    address randomUser = makeAddr("randomUser");

    function setUp() public {
        if (VmEnvironment.isEraVm()) {
            vm.skip(true);
        }

        DeployMinimal deployMinimal = new DeployMinimal();
        (helperConfig, minimalAccount) = deployMinimal.deployMinimalAccount();

        activeNetworkConfig = helperConfig.getConfig();
        sendPackedUserOpScript = new SendPackedUserOp();
        sendPackedUserOpScript.setUp();

        usdc = new ERC20Mock();
    }

    function testOwnerCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(activeNetworkConfig.account);
        minimalAccount.execute(address(usdc), 0, functionData);

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNonOwnerCannotExecuteCommands() public {
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(address(usdc), 0, functionData);
    }

    function testRecoverSignedOp() public view {
        bytes memory functionDataForUSDCMint =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        bytes memory executeCallData =
            abi.encodeWithSelector(minimalAccount.execute.selector, address(usdc), 0, functionDataForUSDCMint);

        PackedUserOperation memory packedUserOp = sendPackedUserOpScript.generateSignedUserOperation(
            executeCallData, activeNetworkConfig, address(minimalAccount)
        );

        bytes32 userOperationHash = IEntryPoint(activeNetworkConfig.entryPoint).getUserOpHash(packedUserOp);

        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        assertEq(actualSigner, minimalAccount.owner());
    }

    function testValidationOfUserOps() public {
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(minimalAccount.execute.selector, address(usdc), 0, functionData);

        PackedUserOperation memory packedUserOp = sendPackedUserOpScript.generateSignedUserOperation(
            executeCallData, activeNetworkConfig, address(minimalAccount)
        );

        bytes32 userOperationHash = IEntryPoint(activeNetworkConfig.entryPoint).getUserOpHash(packedUserOp);

        vm.prank(activeNetworkConfig.entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, 0);

        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(minimalAccount.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = sendPackedUserOpScript.generateSignedUserOperation(
            executeCallData, activeNetworkConfig, address(minimalAccount)
        );

        vm.deal(address(minimalAccount), 1 ether);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        vm.prank(randomUser);
        IEntryPoint(activeNetworkConfig.entryPoint).handleOps(ops, payable(randomUser));

        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
