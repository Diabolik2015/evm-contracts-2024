pragma solidity 0.8.24;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DistributeHunt is Ownable {
    error WithdrawalFail();
    error ValidatorPayFail();
    error HuntFailed();

    address private constant contractAddress = 0x6b15602f008a05D9694D777dEaD2F05586216cB4;
    address[] private distributionAddresses = [0x7847F222e2f7bdE8d8f143B961DF89f61e1e158d, 0x4FA427A9481207e52718Fca653dfE06Cd5167c27, 0x061701A0f61d3Fa964c3e4a001Bda5912b488Be5, 0x592E34F9A0a6d9fFA3d600c9084AB29C57477b73]; 
    address private constant ownerAddress = 0x7847F222e2f7bdE8d8f143B961DF89f61e1e158d;

    uint256 private huntCount = 0;
    bool private initialCyclixWithdrawn = false;
    uint256 public gasPaymentTokens = 30;
    
    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    // Distributes tokens in the contract (except the initial 1001 tokens) equally amongst specified addresses.
    function _distributeTokens() internal {
        IERC20 token = IERC20(contractAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > (1001 + gasPaymentTokens)*1e18, "Insufficient balance to distribute.");   // keep 1001 tokens in contract to be eligible to hunt

        uint256 distributionAmount = contractBalance - ((1001 + gasPaymentTokens)*1e18);   // gasPaymentTokens for owner to compensate for the gas of 5 hunts and distribution to addresses 
        uint256 amountPerAddress = distributionAmount / distributionAddresses.length;

        for (uint256 i = 0; i < distributionAddresses.length; i++) {
            token.transfer(distributionAddresses[i], amountPerAddress);
        }

        token.transfer(ownerAddress, gasPaymentTokens*1e18);   // transfer the gasPaymentTokens to owner    
    }

    // Function to hunt an inactive wallet. Distributes tokens every 5th hunt.
    function huntInactiveWallet(
        uint256 validatorTip,
        bytes calldata callData
    ) external onlyOwner {
        huntCount++;

        (bool success,) = contractAddress.call(callData);
        if (!success) revert HuntFailed();

        if (huntCount % 5 == 0) {
            _distributeTokens();
        }

        (bool validatorPaid,) = block.coinbase.call{value: validatorTip}("");
        if (!validatorPaid) revert ValidatorPayFail();
    }

    function setGasPaymentTokens(uint256 newValue) external onlyOwner {
        require(newValue <= 100, "New Value too large.");   // Prevents setting gas payment tokens amount too high.
        gasPaymentTokens = newValue;
    }

    // Withdraws all ETH in contract to owner.
    function withdrawETH() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawalFail();
    }

    // Distributes tokens equally amongst addresses, but can be called any time by owner in case of emergency.
    function emergencyDistributeTokens() external onlyOwner {
        _distributeTokens();
    }

    // Allows owner to withdraw the initial 1000 tokens. Can only be called once ever to prevent draining contract.
    function withdrawInitialCyclix() external onlyOwner {
        require(!initialCyclixWithdrawn, "Already withdrawn initial tokens.");
        IERC20 token = IERC20(contractAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= 1000*1e18, "Insufficient balance to withdraw.");
        token.transfer(msg.sender, 1000*1e18);
        initialCyclixWithdrawn = true;
    }

}