// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {VaultFactory} from "@symbiotic/contracts/VaultFactory.sol";
import {NetworkRegistry} from "@symbiotic/contracts/NetworkRegistry.sol";
import {OperatorRegistry} from "@symbiotic/contracts/OperatorRegistry.sol";
import {MetadataService} from "@symbiotic/contracts/MetadataService.sol";
import {NetworkMiddlewareService} from "@symbiotic/contracts/NetworkMiddlewareService.sol";
import {NetworkOptInService} from "@symbiotic/contracts/NetworkOptInService.sol";
import {OperatorOptInService} from "@symbiotic/contracts/OperatorOptInService.sol";

import {DefaultStakerRewardsDistributorFactory} from
    "src/contracts/defaultStakerRewardsDistributor/DefaultStakerRewardsDistributorFactory.sol";
import {DefaultStakerRewardsDistributor} from
    "src/contracts/defaultStakerRewardsDistributor/DefaultStakerRewardsDistributor.sol";
import {IDefaultStakerRewardsDistributor} from
    "src/interfaces/defaultStakerRewardsDistributor/IDefaultStakerRewardsDistributor.sol";

import {Vault} from "@symbiotic/contracts/vault/v1/Vault.sol";
import {IVault} from "@symbiotic/interfaces/vault/v1/IVault.sol";

contract DefaultStakerRewardsDistributorFactoryTest is Test {
    address owner;
    address alice;
    uint256 alicePrivateKey;
    address bob;
    uint256 bobPrivateKey;

    DefaultStakerRewardsDistributorFactory defaultStakerRewardsDistributorFactory;
    DefaultStakerRewardsDistributor defaultStakerRewardsDistributor;

    VaultFactory vaultFactory;
    NetworkRegistry networkRegistry;
    OperatorRegistry operatorRegistry;
    MetadataService operatorMetadataService;
    MetadataService networkMetadataService;
    NetworkMiddlewareService networkMiddlewareService;
    NetworkOptInService networkVaultOptInService;
    OperatorOptInService operatorVaultOptInService;
    OperatorOptInService operatorNetworkOptInService;

    IVault vault;

    function setUp() public {
        owner = address(this);
        (alice, alicePrivateKey) = makeAddrAndKey("alice");
        (bob, bobPrivateKey) = makeAddrAndKey("bob");

        vaultFactory = new VaultFactory(owner);
        networkRegistry = new NetworkRegistry();
        operatorRegistry = new OperatorRegistry();
        operatorMetadataService = new MetadataService(address(operatorRegistry));
        networkMetadataService = new MetadataService(address(networkRegistry));
        networkMiddlewareService = new NetworkMiddlewareService(address(networkRegistry));
        networkVaultOptInService = new NetworkOptInService(address(networkRegistry), address(vaultFactory));
        operatorVaultOptInService = new OperatorOptInService(address(operatorRegistry), address(vaultFactory));
        operatorNetworkOptInService = new OperatorOptInService(address(operatorRegistry), address(networkRegistry));

        vaultFactory.whitelist(
            address(
                new Vault(
                    address(vaultFactory),
                    address(networkRegistry),
                    address(networkMiddlewareService),
                    address(networkVaultOptInService),
                    address(operatorVaultOptInService),
                    address(operatorNetworkOptInService)
                )
            )
        );

        vault = IVault(
            vaultFactory.create(
                vaultFactory.lastVersion(),
                alice,
                abi.encode(
                    IVault.InitParams({
                        collateral: address(1),
                        epochDuration: 1,
                        vetoDuration: 0,
                        executeDuration: 0,
                        rewardsDistributor: address(0),
                        adminFee: 0,
                        depositWhitelist: false
                    })
                )
            )
        );
    }

    function test_Create() public {
        address defaultStakerRewardsDistributor_ = address(
            new DefaultStakerRewardsDistributor(
                address(networkRegistry), address(vaultFactory), address(networkMiddlewareService)
            )
        );

        defaultStakerRewardsDistributorFactory =
            new DefaultStakerRewardsDistributorFactory(defaultStakerRewardsDistributor_);

        address defaultStakerRewardsDistributorAddress = defaultStakerRewardsDistributorFactory.create(address(vault));
        defaultStakerRewardsDistributor = DefaultStakerRewardsDistributor(defaultStakerRewardsDistributorAddress);
        assertEq(defaultStakerRewardsDistributorFactory.isEntity(defaultStakerRewardsDistributorAddress), true);

        assertEq(defaultStakerRewardsDistributor.NETWORK_REGISTRY(), address(networkRegistry));
        assertEq(defaultStakerRewardsDistributor.VAULT_FACTORY(), address(vaultFactory));
        assertEq(defaultStakerRewardsDistributor.NETWORK_MIDDLEWARE_SERVICE(), address(networkMiddlewareService));
        assertEq(defaultStakerRewardsDistributor.VAULT(), address(vault));
        assertEq(defaultStakerRewardsDistributor.version(), 1);
        assertEq(defaultStakerRewardsDistributor.isNetworkWhitelisted(alice), false);
        assertEq(defaultStakerRewardsDistributor.rewardsLength(alice), 0);
        vm.expectRevert();
        defaultStakerRewardsDistributor.rewards(alice, 0);
        assertEq(defaultStakerRewardsDistributor.lastUnclaimedReward(alice, alice), 0);
        assertEq(defaultStakerRewardsDistributor.claimableAdminFee(alice), 0);
    }

    function test_CreateRevertNotVault() public {
        address defaultStakerRewardsDistributor_ = address(
            new DefaultStakerRewardsDistributor(
                address(networkRegistry), address(vaultFactory), address(networkMiddlewareService)
            )
        );

        defaultStakerRewardsDistributorFactory =
            new DefaultStakerRewardsDistributorFactory(defaultStakerRewardsDistributor_);

        vm.expectRevert(IDefaultStakerRewardsDistributor.NotVault.selector);
        defaultStakerRewardsDistributorFactory.create(address(0));
    }
}
