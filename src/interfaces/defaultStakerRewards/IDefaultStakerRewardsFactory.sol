// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IDefaultStakerRewards} from "./IDefaultStakerRewards.sol";

interface IDefaultStakerRewardsFactory {
    /**
     * @notice Create a default staker rewards contract for a given vault.
     * @param params initial parameters needed for a staker rewards contract deployment
     * @return address of the created staker rewards contract
     */
    function create(
        IDefaultStakerRewards.InitParams calldata params
    ) external returns (address);
}
