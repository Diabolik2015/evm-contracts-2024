// Sources flattened with hardhat v2.22.2 https://hardhat.org

// SPDX-License-Identifier: MIT AND UNLICENSED

// File @openzeppelin/contracts/utils/Context.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/utils/Address.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v5.0.2

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}


// File contracts/CyclixRandomizerInterface.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

interface CyclixRandomizerInterface {
    function requestRandomWords(uint32 numWords) external returns (uint256 requestId);
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords);
    function registerGameContract(address gameAddress, string calldata name) external;
    function getLastRequestIdForCaller(address _gameAddress) external view returns (uint256);
    function recoverLostNumberRequest(uint256 _requestId) external returns (uint256);
}


// File contracts/LotteryCommon.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.20;

    enum RoundVictoryTier {
        NO_WIN,
        Tier5_1,
        Tier5,
        Tier4_1,
        Tier4,
        Tier3_1,
        Tier3,
        Referrer,
        PublicPool,
        TokenHolders,
        Treasury
    }

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        bool ended;
        uint16[] roundNumbers;
        uint16[] referralWinnersNumber;
        uint16 referralWinnersNumberCount;
        uint256[] ticketIds;
        uint16 ticketsCount;
        uint256[] referralTicketIds;
        uint16 referralCounts;
    }

    struct Ticket {
        uint256 id;
        address participantAddress;
        address referralAddress;
        bool claimed;
        uint256 chainId;
        RoundVictoryTier victoryTier;
    }

    struct TicketResults {
        uint256 ticketId;
        address participantAddress;
        RoundVictoryTier victoryTier;
    }

    struct ReferralTicket {
        uint256 id;
        address referralAddress;
        uint16 referralTicketNumber;
        bool winner;
        bool claimed;
    }

    struct ReferralTicketResults {
        uint256 referralTicketId;
        address referralAddress;
        uint256 referralTicketNumber;
        bool won;
    }


// File contracts/utils/EmergencyFunctions.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;



contract EmergencyFunctions is Ownable {
    address internal teamAddress;
    constructor(address _teamAddress) Ownable(_teamAddress) {
        teamAddress = _teamAddress;
    }

    function updateTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }

    // Emergency Functions
    function sendTokenToTeam(address _token) public onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if (amount > 0) {
            SafeERC20.safeTransfer(IERC20(_token), teamAddress, amount);
        }
    }

    function sendCryptoToTeam() public onlyOwner {
        if (address(this).balance > 0) {
            payable(teamAddress).transfer(address(this).balance);
        }
    }

    /** @notice Check if an address is a contract */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}


// File contracts/utils/TestUtils.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity >=0.8.x <0.9.0;


interface IERC20Extension {
    function decimals() external view returns (uint8);
}

contract TestFunctions is Ownable {
    constructor() Ownable(msg.sender) {}
    //Used for mock testing, contract ownership will be renounced on release
    uint public currentTimestampOverride;
    function updateCurrentTimestampOverride(uint _v) external onlyOwner {
        currentTimestampOverride = _v;
    }
    function currentTimestamp() public view returns(uint) {
        if (currentTimestampOverride > 0) {
            return currentTimestampOverride;
        }
        return block.timestamp;
    }
}


// File contracts/LotteryReaderInterface.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.20;






interface LotteryReaderInterface {
    function poolForVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) external view returns(uint256) ;
    function poolForReferral(uint256 roundId) external view returns(uint256) ;
    function tokenHoldersPoolAmount(uint256 roundId) external view returns (uint256) ;
    function treasuryPoolAmount(uint256 roundId) external view returns (uint256) ;
    function numberOfReferralWinnersForRoundId(uint256 roundId) external view returns (uint16) ;
    function existInArrayNumber(uint16 num, uint16[] memory arr) external pure returns (bool) ;
    function notExistInArrayNumber(uint16 num, uint16[] memory arr) external pure returns (bool) ;
    function getRandomUniqueNumberInArrayForMaxValue(uint256 randomNumber, uint16 maxValue, uint16[] memory arr) external pure returns (uint16) ;
    function tierFromResults(uint16 rightNumbersForTicket, bool powerNumberFound) external pure returns (RoundVictoryTier) ;
    function evaluateWonResultsForOneTicket(uint256 roundId, uint256 ticketId) external view returns (TicketResults memory);
    function evaluateWonResultsForTickets(uint256 roundId) external view returns (TicketResults[] memory);
    function evaluateWonResultsForOneReferralTicket(uint256 roundId, uint256 referralTicketId) external view returns (ReferralTicketResults memory);
    function evaluateWonResultsForReferral(uint256 roundId) external view returns (ReferralTicketResults[] memory);
    function amountWonInRound(uint256 roundId) external view returns (uint256) ;
    function roundNumbers(uint256 roundId) external view returns(uint16[] memory);
    function referralWinnersNumber(uint256 roundId) external view returns(uint16[] memory);
}


// File contracts/LotteryRoundCreatorInterface.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface LotteryRoundCreatorInterface {
   function startNewRound(uint256 roundDurationInSeconds, address previousRoundAddress) external returns(address);
}


// File contracts/LotteryRoundInterface.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface LotteryRoundInterface {
    function getRound() external returns(Round memory);
    function previousRound() external returns(address);
    function markWinners(TicketResults[] memory ticketResults, ReferralTicketResults[] memory referralTicketResults) external;
    function markVictoryClaimed(uint256 ticketId, uint256 amountClaimed) external;
    function markReferralVictoryClaimed(uint256 referralTicketId, uint256 amountClaimed) external;
    function treasuryAmountOnTicket(uint256 paymentTokenAmount) external view returns (uint256);
    function updateVictoryPoolForTicket(uint256 paymentTokenAmount) external;
    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, address referral, address buyer) external;
    function closeRound() external;
    function couldReceiveWinningNumbers() external view;
    function storeWinningNumbers(uint16[] memory roundNumbers, uint16[] memory referralWinnersNumber) external;
    function ticketById(uint256 ticketId) external view returns (Ticket memory);
    function numbersForTicketId(uint256 ticketId) external view returns (uint16[] memory);
    function referralTicketById(uint256 index) external view returns (ReferralTicket memory);
    function victoryTierAmounts(RoundVictoryTier tier) external view returns (uint256);
    function winnersForEachTier(RoundVictoryTier tier) external returns(uint256);
    function setPoolPercentagesBasePoints(uint16[] memory _poolPercentagesBasePoints) external;
}


// File contracts/LotteryMaster.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.20;









    enum LotteryStatuses {
        DrawOpen,
        EvaluatingResults,
        ResultsEvaluated,
        ClaimInProgress
    }

contract LotteryMaster is EmergencyFunctions {

    uint256 public roundCount;
    address[] public rounds;
    LotteryStatuses public lotteryStatus;
    uint256 public statusStartTime;
    uint256 public statusEndTime;

    mapping(address => uint16) public freeRounds;
    mapping(address => bool) public crossChainOperator;
    function setCrossChainOperator(address operator, bool value) public onlyOwner {
        crossChainOperator[operator] = value;
    }

    uint16 public counterForBankWallets;
    address[] public bankWallets;
    function setBankWallet(address wallet, bool add) public onlyOwner {
        for (uint i = 0; i < bankWallets.length; i++) {
            if (bankWallets[i] == wallet) {
                if (add) {
                    require(false, "Wallet already added");
                } else {
                    bankWallets[i] = bankWallets[bankWallets.length - 1];
                    bankWallets.pop();
                }
            }
        }
        if (add) {
            bankWallets.push(wallet);
        }
    }

    address public treasuryWallets;
    IERC20Metadata public paymentToken;
    CyclixRandomizerInterface public randomizer;
    LotteryReaderInterface public reader;
    uint256 public ticketPrice;
    bool public freeRoundsAreEnabled = false;
    uint16 public percentageOfReferralWinners = 10;
    LotteryRoundCreatorInterface public lotteryRoundCreator;

    constructor(address cyclixRandomizer, address lotteryReader, address _lotteryRoundCreator, address _paymentToken, uint256 _ticketPrice, bool _freeRoundsAreEnabled)
    EmergencyFunctions(msg.sender) {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = LotteryReaderInterface(lotteryReader);
        lotteryRoundCreator = LotteryRoundCreatorInterface(_lotteryRoundCreator);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        freeRoundsAreEnabled = _freeRoundsAreEnabled;
        treasuryWallets = msg.sender;
        bankWallets.push(msg.sender);
    }

    function updateSetup(address cyclixRandomizer, address lotteryReader, address _lotteryRoundCreator, address _paymentToken, uint256 _ticketPrice,
        address _treasuryWallet, uint16 _percentageOfReferralWinners, uint16[] memory _poolPercentagesBasePoints, bool _freeRoundsAreEnabled) public onlyOwner {
        randomizer = CyclixRandomizerInterface(cyclixRandomizer);
        randomizer.registerGameContract(address(this), "LotteryMasterV0.1");
        reader = LotteryReaderInterface(lotteryReader);
        lotteryRoundCreator = LotteryRoundCreatorInterface(_lotteryRoundCreator);
        paymentToken = IERC20Metadata(_paymentToken);
        ticketPrice = _ticketPrice * (10 ** uint256(paymentToken.decimals()));
        treasuryWallets = _treasuryWallet;
        percentageOfReferralWinners = _percentageOfReferralWinners;
        LotteryRoundInterface(rounds[roundCount - 1]).setPoolPercentagesBasePoints(_poolPercentagesBasePoints);
        freeRoundsAreEnabled = _freeRoundsAreEnabled;
    }

    function startNewRound(uint256 _statusEndTime) public onlyOwner {
        roundCount++;
        if (roundCount > 1) {
            rounds.push(lotteryRoundCreator.startNewRound(_statusEndTime, rounds[roundCount - 2]));
            require(lotteryStatus == LotteryStatuses.ClaimInProgress && statusEndTime < block.timestamp, "Previous round not ended");
        } else {
            rounds.push(lotteryRoundCreator.startNewRound(_statusEndTime, address(0)));
        }
        setLotteryStatus(LotteryStatuses.DrawOpen, _statusEndTime);
    }

    function setLotteryStatus(LotteryStatuses _lotteryStatus, uint256 _statusEndTime) internal onlyOwner {
        lotteryStatus = _lotteryStatus;
        statusStartTime = block.timestamp;
        statusEndTime = block.timestamp + _statusEndTime;
    }

    function buyTickets(uint256 chainId, uint16[] memory moreTicketNumbers, address referral, address buyer) public {
        for (uint i = 0; i < moreTicketNumbers.length; i += 6) {
            uint16[] memory chosenNumbers = new uint16[](6);
            for (uint j = 0; j < 6; j++) {
                chosenNumbers[j] = moreTicketNumbers[i + j];
            }
            buyTicket(chainId, chosenNumbers, referral, buyer);
        }
    }

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, address referral, address buyer) public {
        require(freeRounds[buyer] > 0
        || paymentToken.allowance(buyer, address(this)) >= ticketPrice
        || crossChainOperator[msg.sender], "Missing Allowance");
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        if (freeRounds[buyer] > 0) {
            freeRounds[buyer]--;
        } else {
            if (!crossChainOperator[msg.sender]) {
                require(paymentToken.balanceOf(tx.origin) >= ticketPrice, "Insufficient funds");
                counterForBankWallets = uint16(counterForBankWallets++ % bankWallets.length);
                uint256 treasuryAmount = lotteryRound.treasuryAmountOnTicket(ticketPrice);
                SafeERC20.safeTransferFrom(paymentToken, buyer, bankWallets[counterForBankWallets], ticketPrice - treasuryAmount);
                SafeERC20.safeTransferFrom(paymentToken, buyer, treasuryWallets, treasuryAmount);
            }
            lotteryRound.updateVictoryPoolForTicket(ticketPrice);

            if (referral != address(0) && freeRoundsAreEnabled) {
                freeRounds[buyer]++;
                freeRounds[referral]++;
            }
        }

        lotteryRound.buyTicket(chainId, chosenNumbers, referral, buyer);
    }

    function addFreeRound(address[] calldata participant) public onlyOwner {
        for (uint i = 0; i < participant.length; i++) {
            freeRounds[participant[i]]++;
        }
    }

    mapping(uint256 => uint256) public publicRoundRandomNumbersRequestId;

    function closeRound(uint256 _statusEndTime) external onlyOwner {
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        lotteryRound.closeRound();
        uint16 referralWinners = reader.numberOfReferralWinnersForRoundId(roundCount);
        publicRoundRandomNumbersRequestId[roundCount] = randomizer.requestRandomWords(6 + referralWinners);
        setLotteryStatus(LotteryStatuses.EvaluatingResults, _statusEndTime);
    }

    function fetchRoundNumbers(uint256 roundId, uint256 _statusEndTime) external onlyOwner {
        LotteryRoundInterface round = LotteryRoundInterface(rounds[roundId - 1]);
        round.couldReceiveWinningNumbers();
        (bool fulfilled, uint256[] memory randomWords) = randomizer.getRequestStatus(publicRoundRandomNumbersRequestId[roundId]);
        require(fulfilled, "Random numbers not ready");
        uint16[] memory roundNumbers = new uint16[](6);
        uint16[] memory referralWinnersNumber = new uint16[](randomWords.length - 6);
        if (fulfilled) {
            for (uint i = 0; i < 6; i++) {
                roundNumbers[i] = reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i], 69, roundNumbers);
            }
            roundNumbers[5] = uint16(randomWords[5] % 26 + 1);
            for (uint i = 6; i < randomWords.length; i++) {
                referralWinnersNumber [i - 6] = reader.getRandomUniqueNumberInArrayForMaxValue(randomWords[i],
                    round.getRound().referralCounts, referralWinnersNumber);
            }
        }
        round.storeWinningNumbers(roundNumbers, referralWinnersNumber);
        setLotteryStatus(LotteryStatuses.ResultsEvaluated, _statusEndTime);
    }

    function markWinners(uint256 roundId, uint256 _statusEndTime) public onlyOwner {
        LotteryRoundInterface(rounds[roundId - 1]).markWinners(reader.evaluateWonResultsForTickets(roundId), reader.evaluateWonResultsForReferral(roundId));
        setLotteryStatus(LotteryStatuses.ClaimInProgress, _statusEndTime);
    }

    function claimVictory(uint256 ticketId) public {
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        Ticket memory ticket = lotteryRound.ticketById(ticketId);
        require(ticket.participantAddress == msg.sender, "Invalid ticket owner");
        require(!ticket.claimed, "Ticket already claimed");
        require(lotteryRound.getRound().ended, "Round not ended");
        require(lotteryStatus == LotteryStatuses.ClaimInProgress, "Claim not started");
        require(block.timestamp < statusEndTime, "Claim has ended");
        require(ticket.victoryTier != RoundVictoryTier.NO_WIN, "No prize for this ticket");
        require(ticket.victoryTier == reader.evaluateWonResultsForOneTicket(lotteryRound.getRound().id, ticketId).victoryTier, "Invalid ticket tier");
        unchecked {
            uint256 amountWon = lotteryRound.victoryTierAmounts(ticket.victoryTier) / lotteryRound.winnersForEachTier(ticket.victoryTier);
            require(paymentToken.balanceOf(address(this)) >= amountWon, "Not enough funds on contract");
            LotteryRoundInterface(rounds[roundCount - 1]).markVictoryClaimed(ticketId, amountWon);
            paymentToken.transfer(msg.sender, amountWon);
        }
    }

    function claimReferralVictory(uint256 referralTicketId) public {
        LotteryRoundInterface lotteryRound = LotteryRoundInterface(rounds[roundCount - 1]);
        ReferralTicket memory referralTicket = lotteryRound.referralTicketById(referralTicketId);
        require(referralTicket.id == referralTicketId, "Invalid ticket id");
        require(referralTicket.referralAddress == msg.sender, "Invalid ticket owner");
        require(!referralTicket.claimed, "Ticket already claimed");
        require(lotteryRound.getRound().ended, "Round not ended");
        require(referralTicket.winner == true, "No prize for this ticket");
        require(referralTicket.winner == reader.evaluateWonResultsForOneReferralTicket(lotteryRound.getRound().id, referralTicketId).won, "Invalid ticket tier");
        unchecked {
            uint256 amountWon = lotteryRound.victoryTierAmounts(RoundVictoryTier.Referrer) / reader.numberOfReferralWinnersForRoundId(lotteryRound.getRound().id);
            require(paymentToken.balanceOf(address(this)) >= amountWon, "Not enough funds on contract");
            LotteryRoundInterface(rounds[roundCount - 1]).markReferralVictoryClaimed(referralTicketId, amountWon);
            paymentToken.transfer(msg.sender, amountWon);
        }
    }
}


// File contracts/LotteryRound.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.20;



contract LotteryRound is Ownable, LotteryRoundInterface {
    Round public round;
    function getRound() public view returns (Round memory) {
        return round;
    }

    Ticket[] public tickets;
    function ticketById(uint256 ticketId) public view returns (Ticket memory) {
        return tickets[ticketId];
    }
    mapping(uint256 => uint16[]) public ticketNumbers;
    function numbersForTicketId(uint256 ticketId) public view returns (uint16[] memory) {
        return ticketNumbers[ticketId];
    }
    mapping(address => uint256[]) public roundTicketsByAddress;
    mapping(address => uint256) public roundTicketsByAddressCount;

    ReferralTicket[] public referralTickets;
    function referralTicketById(uint256 index) public view returns (ReferralTicket memory) {
        return referralTickets[index];
    }
    mapping(address => uint256[]) public roundReferralTicketsByAddress;
    mapping(address => uint256) public roundReferralTicketsByAddressCount;

    mapping(RoundVictoryTier => uint256) public victoryTierAmounts;
    mapping(RoundVictoryTier => uint256) public victoryTierAmountsClaimed;
    mapping(RoundVictoryTier => uint256) public winnersForEachTier;
    address public previousRound;

    uint16[]  public  poolPercentagesBasePoints = [3000, 1500, 1000, 700, 500, 300, 1500, 1000, 500];
    function setPoolPercentagesBasePoints(uint16[] memory _poolPercentagesBasePoints) public onlyOwner {
        poolPercentagesBasePoints = _poolPercentagesBasePoints;
    }

    constructor(address previousRoundAddress, uint256 roundDurationInSeconds) Ownable(msg.sender) {
        uint256 id = 1;
        previousRound = previousRoundAddress;
        if (previousRoundAddress != address(0)) {
            LotteryRound previousLotteryRound = LotteryRound(previousRoundAddress);
            id = previousLotteryRound.getRound().id + 1;
            propagateWinningFromPreviousRound();
        }
        round = Round({
            id: id,
            startTime: block.timestamp,
            endTime: block.timestamp + roundDurationInSeconds,
            ended : false,
            roundNumbers: new uint16[](0),
            referralWinnersNumber: new uint16[](0),
            referralWinnersNumberCount : 0,
            ticketIds : new uint256[](0),
            ticketsCount : 0,
            referralTicketIds : new uint256[](0),
            referralCounts : 0
        });
    }

    function propagateWinningFromPreviousRound() internal {
        LotteryRound previousLotteryRound = LotteryRound(previousRound);
        victoryTierAmounts[RoundVictoryTier.Tier5_1] += previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5_1) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Tier5_1);
        victoryTierAmounts[RoundVictoryTier.Tier5] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Tier5);
        victoryTierAmounts[RoundVictoryTier.Tier4_1] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4_1) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Tier4_1);
        victoryTierAmounts[RoundVictoryTier.Tier4] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Tier4);
        victoryTierAmounts[RoundVictoryTier.Tier3_1] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3_1) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Tier3_1);
        victoryTierAmounts[RoundVictoryTier.Tier3] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Tier3);
        victoryTierAmounts[RoundVictoryTier.PublicPool] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.PublicPool) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.PublicPool);
        victoryTierAmounts[RoundVictoryTier.Referrer] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Referrer) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Referrer);
        victoryTierAmounts[RoundVictoryTier.TokenHolders] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.TokenHolders) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.TokenHolders);
        victoryTierAmounts[RoundVictoryTier.Treasury] +=  previousLotteryRound.victoryTierAmounts(RoundVictoryTier.Treasury) - previousLotteryRound.victoryTierAmountsClaimed(RoundVictoryTier.Treasury);
    }

    function numberIsInRangeForRound(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 69;
    }

    function numberIsInRangeForPowerNumber(uint256 number) public pure returns (bool) {
        return number > 0 && number <= 26;
    }

    function validateBuyTicket(uint16[] memory numbers, address referral) public view onlyOwner {
        require(tx.origin != address(0), "Invalid sender");
        require(block.timestamp < round.endTime, "Round is over");
        require(numbers.length == 6, "Invalid numbers count");
        for (uint i = 0; i < numbers.length - 1; i++) {
            require(numberIsInRangeForRound(numbers[i]), "Invalid numbers");
        }
        require(numberIsInRangeForPowerNumber(numbers[5]), "Invalid power number");
        require(referral != tx.origin, "Referral cannot be the same as the participant");
    }

    function percentageInBasisPoint(uint256 amount, uint256 basisPoint) public pure returns (uint256) {
        return amount * basisPoint / 10000;
    }

    function treasuryAmountOnTicket(uint256 paymentTokenAmount) public view returns (uint256) {
        return percentageInBasisPoint(paymentTokenAmount, poolPercentagesBasePoints[8]);
    }

    function updateVictoryPoolForTicket(uint256 paymentTokenAmount) public onlyOwner {
        uint256 forPublicPool = paymentTokenAmount;
        victoryTierAmounts[RoundVictoryTier.Tier5_1] += percentageInBasisPoint(forPublicPool, poolPercentagesBasePoints[0]);
        victoryTierAmounts[RoundVictoryTier.Tier5] += percentageInBasisPoint(forPublicPool, poolPercentagesBasePoints[1]);
        victoryTierAmounts[RoundVictoryTier.Tier4_1] += percentageInBasisPoint(forPublicPool, poolPercentagesBasePoints[2]);
        victoryTierAmounts[RoundVictoryTier.Tier4] += percentageInBasisPoint(forPublicPool, poolPercentagesBasePoints[3]);
        victoryTierAmounts[RoundVictoryTier.Tier3_1] += percentageInBasisPoint(forPublicPool, poolPercentagesBasePoints[4]);
        victoryTierAmounts[RoundVictoryTier.Tier3] += percentageInBasisPoint(forPublicPool, poolPercentagesBasePoints[5]);
        victoryTierAmounts[RoundVictoryTier.PublicPool] += forPublicPool;
        victoryTierAmounts[RoundVictoryTier.Referrer] += percentageInBasisPoint(paymentTokenAmount, poolPercentagesBasePoints[6]);
        victoryTierAmounts[RoundVictoryTier.TokenHolders] += percentageInBasisPoint(paymentTokenAmount, poolPercentagesBasePoints[7]);
        victoryTierAmounts[RoundVictoryTier.Treasury] += treasuryAmountOnTicket(paymentTokenAmount);
    }

    function buyTicket(uint256 chainId, uint16[] memory chosenNumbers, address referral, address buyer) public onlyOwner {
        validateBuyTicket(chosenNumbers, referral);

        uint256 ticketId = tickets.length;
        tickets.push(Ticket({
            id: ticketId,
            participantAddress: buyer,
            referralAddress: referral,
            claimed: false,
            chainId: chainId,
            victoryTier: RoundVictoryTier.NO_WIN
        }));
        for(uint i = 0; i < chosenNumbers.length; i++) {
            ticketNumbers[ticketId].push(chosenNumbers[i]);
        }
        round.ticketIds.push(ticketId);
        round.ticketsCount++;

        roundTicketsByAddress[buyer].push(tickets.length - 1);
        roundTicketsByAddressCount[buyer]++;
        if (referral != address(0)) {
            uint256 referralTicketId = referralTickets.length;
            round.referralTicketIds.push(referralTicketId);
            round.referralCounts++;
            referralTickets.push(ReferralTicket({
                id: referralTicketId,
                referralAddress: referral,
                referralTicketNumber: uint16(round.referralCounts),
                winner: false,
                claimed: false
            }));

            roundReferralTicketsByAddress[referral].push(referralTickets.length - 1);
            roundReferralTicketsByAddressCount[referral]++;
        }
    }

    function closeRound() public onlyOwner {
        require(block.timestamp >= round.endTime, "Round is not over yet");
        round.ended = true;
    }

    function couldReceiveWinningNumbers() public view {
        require(block.timestamp >= round.endTime, "Round is not over yet");
        require(round.roundNumbers.length == 0, "Winning numbers already set");
    }

    function storeWinningNumbers(uint16[] memory roundNumbers, uint16[] memory referralWinnersNumber) public onlyOwner {
        round.roundNumbers = roundNumbers;
        round.referralWinnersNumber = referralWinnersNumber;
        round.referralWinnersNumberCount = uint16(referralWinnersNumber.length);
    }

    function markWinners(TicketResults[] memory ticketResults, ReferralTicketResults[] memory referralTicketResults) public onlyOwner {
        for (uint i = 0; i < ticketResults.length; i++) {
            TicketResults memory ticketResult = ticketResults[i];
            Ticket storage ticket = tickets[ticketResult.ticketId];
            ticket.victoryTier = ticketResult.victoryTier;
            winnersForEachTier[ticketResult.victoryTier]++;
        }
        for (uint i = 0; i < referralTicketResults.length; i++) {
            ReferralTicketResults memory referralTicketResult = referralTicketResults[i];
            ReferralTicket storage referralTicket = referralTickets[referralTicketResult.referralTicketId];
            referralTicket.winner = referralTicketResult.won;
            if (referralTicketResult.won) {
                winnersForEachTier[RoundVictoryTier.Referrer]++;
            }
        }
    }

    function markVictoryClaimed(uint256 ticketId, uint256 amountClaimed) public onlyOwner {
        Ticket storage ticket = tickets[ticketId];
        ticket.claimed = true;
        victoryTierAmountsClaimed[ticket.victoryTier] += amountClaimed;
    }

    function markReferralVictoryClaimed(uint256 referralTicketId, uint256 amountClaimed) public onlyOwner {
        ReferralTicket storage referralTicket = referralTickets[referralTicketId];
        referralTicket.claimed = true;
        victoryTierAmountsClaimed[RoundVictoryTier.Referrer] += amountClaimed;
    }
}


// File contracts/LotteryReader.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.20;








contract LotteryReader is LotteryReaderInterface, EmergencyFunctions {
    LotteryMaster public lotteryMaster;

    function setLotteryMaster(address _lotteryMaster) public onlyOwner {
        lotteryMaster = LotteryMaster(_lotteryMaster);
    }

    constructor() EmergencyFunctions(tx.origin) {}

    function poolForVictoryTier(uint256 roundId, RoundVictoryTier victoryTier) public view override returns(uint256) {
        require(victoryTier == RoundVictoryTier.Tier5_1 || victoryTier == RoundVictoryTier.Tier5 || victoryTier == RoundVictoryTier.Tier4_1 ||
        victoryTier == RoundVictoryTier.Tier4 || victoryTier == RoundVictoryTier.Tier3_1 || victoryTier == RoundVictoryTier.Tier3,
            "Invalid victory tier");
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(victoryTier);
    }

    function roundNumbers(uint256 roundId) public view returns(uint16[] memory) {
        Round memory round = LotteryRound(lotteryMaster.rounds(roundId -1)).getRound();
        return round.roundNumbers;
    }

    function referralWinnersNumber(uint256 roundId) public view returns(uint16[] memory) {
        Round memory round = LotteryRound(lotteryMaster.rounds(roundId -1)).getRound();
        return round.referralWinnersNumber;
    }

    function poolForReferral(uint256 roundId) public view override returns(uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.Referrer);
    }

    function tokenHoldersPoolAmount(uint256 roundId) public view override returns (uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.TokenHolders);
    }

    function treasuryPoolAmount(uint256 roundId) public view override returns (uint256) {
        return LotteryRound(lotteryMaster.rounds(roundId -1)).victoryTierAmounts(RoundVictoryTier.Treasury);
    }

    function numberOfReferralWinnersForRoundId(uint256 roundId) public view override returns (uint16) {
        uint16 referralWinnersForRound = 0;
        uint16 referralCounts = LotteryRound(lotteryMaster.rounds(roundId -1)).getRound().referralCounts;
        unchecked {
            referralWinnersForRound = referralCounts / lotteryMaster.percentageOfReferralWinners();
        }
        if (referralWinnersForRound == 0 && referralCounts > 0) {
            referralWinnersForRound = 1;
        }
        return referralWinnersForRound;
    }

    function existInArrayNumber(uint16 num, uint16[] memory arr) public pure override returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == num) {
                return true;
            }
        }
        return false;
    }

    function notExistInArrayNumber(uint16 num, uint16[] memory arr) public pure override returns (bool) {
        return existInArrayNumber(num, arr) == false;
    }

    function getRandomUniqueNumberInArrayForMaxValue(uint256 randomNumber, uint16 maxValue, uint16[] memory arr) public pure override returns (uint16) {
        uint16 returnedNumber = uint16(randomNumber % maxValue + 1);
        uint16 counter = 0;
        bool existInNumbers = existInArrayNumber(returnedNumber, arr);
        while (existInNumbers) {
            returnedNumber =  uint16(uint256(keccak256(abi.encode(returnedNumber, counter))) % maxValue + 1);
            existInNumbers = existInArrayNumber(returnedNumber, arr);
            counter++;
        }
        return returnedNumber;
    }


    function tierFromResults(uint16 rightNumbersForTicket, bool powerNumberFound) public pure override returns (RoundVictoryTier) {
        if (rightNumbersForTicket == 5 && powerNumberFound) {
            return RoundVictoryTier.Tier5_1;
        } else if (rightNumbersForTicket == 5) {
            return RoundVictoryTier.Tier5;
        } else if (rightNumbersForTicket == 4 && powerNumberFound) {
            return RoundVictoryTier.Tier4_1;
        } else if (rightNumbersForTicket == 4) {
            return RoundVictoryTier.Tier4;
        } else if (rightNumbersForTicket == 3 && powerNumberFound) {
            return RoundVictoryTier.Tier3_1;
        } else if (rightNumbersForTicket == 3) {
            return RoundVictoryTier.Tier3;
        }
        return RoundVictoryTier.NO_WIN;
    }

    function evaluateWonResultsForOneTicket(uint256 roundId, uint256 ticketId) public view override returns (TicketResults memory){
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        Round memory roundForEvaluation = lotteryRound.getRound();
        Ticket memory ticket = lotteryRound.ticketById(roundForEvaluation.ticketIds[ticketId]);
        uint16[] memory ticketNumbers = lotteryRound.numbersForTicketId(ticket.id);
        bool powerNumberFound = ticketNumbers[5] == roundForEvaluation.roundNumbers[5];
        uint16 rightNumbersForTicket = 0;
        for(uint16 i = 0; i < 5; i++) {
            uint16 ticketNumber = ticketNumbers[i];
            if (existInArrayNumber(ticketNumber, roundForEvaluation.roundNumbers)) {
                rightNumbersForTicket++;
            }
        }
        return TicketResults({
            ticketId: ticket.id,
            participantAddress : ticket.participantAddress,
            victoryTier: tierFromResults(rightNumbersForTicket, powerNumberFound)
        });
    }

    function evaluateWonResultsForTickets(uint256 roundId) public view override returns (TicketResults[] memory){
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        Round memory roundForEvaluation = lotteryRound.getRound();
        uint16 roundTicketCount = roundForEvaluation.ticketsCount;
        TicketResults[] memory ticketResults = new TicketResults[](roundForEvaluation.ticketsCount);
        uint16 counter = 0;
        for(uint16 ticketIndexForRound = 0; ticketIndexForRound < roundTicketCount; ticketIndexForRound++) {
            Ticket memory ticket = lotteryRound.ticketById(roundForEvaluation.ticketIds[ticketIndexForRound]);
            uint16[] memory ticketNumbers = lotteryRound.numbersForTicketId(ticket.id);
            bool powerNumberFound = ticketNumbers[5] == roundForEvaluation.roundNumbers[5];
            uint16 rightNumbersForTicket = 0;
            for(uint16 i = 0; i < 5; i++) {
                uint16 ticketNumber = ticketNumbers[i];
                if (existInArrayNumber(ticketNumber, roundForEvaluation.roundNumbers)) {
                    rightNumbersForTicket++;
                }
            }
            ticketResults[counter++] = TicketResults({
                ticketId: ticket.id,
                participantAddress : ticket.participantAddress,
                victoryTier: tierFromResults(rightNumbersForTicket, powerNumberFound)
            });
        }
        return ticketResults;
    }

    function evaluateWonResultsForOneReferralTicket(uint256 roundId, uint256 referralTicketId) public view override returns (ReferralTicketResults memory) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        Round memory roundForEvaluation = lotteryRound.getRound();
        ReferralTicket memory referralTicket = lotteryRound.referralTicketById(roundForEvaluation.referralTicketIds[referralTicketId]);
        bool referralWon = existInArrayNumber(referralTicket.referralTicketNumber, roundForEvaluation.referralWinnersNumber);
        return ReferralTicketResults({
            referralTicketId: referralTicket.id,
            referralAddress: referralTicket.referralAddress,
            won: referralWon
        });
    }

    function evaluateWonResultsForReferral(uint256 roundId) public view override returns (ReferralTicketResults[] memory) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId - 1));
        Round memory roundForEvaluation = lotteryRound.getRound();
        ReferralTicketResults[] memory referralWinnerIds = new ReferralTicketResults[](roundForEvaluation.referralCounts);
        uint16 counter = 0;
        for(uint16 referralIndexForRound = 0; referralIndexForRound < roundForEvaluation.referralCounts; referralIndexForRound++) {
            ReferralTicket memory referralTicket = lotteryRound.referralTicketById(roundForEvaluation.referralTicketIds[referralIndexForRound]);
            bool referralWon = existInArrayNumber(referralTicket.referralTicketNumber, roundForEvaluation.referralWinnersNumber);
            referralWinnerIds[counter++] = ReferralTicketResults({
                referralTicketId: referralTicket.id,
                referralAddress : referralTicket.referralAddress,
                won: referralWon
            });
        }
        return referralWinnerIds;
    }

    function amountWonInRound(uint256 roundId) public view override returns (uint256) {
        LotteryRound lotteryRound = LotteryRound(lotteryMaster.rounds(roundId -1));
        uint256 amountWon = 0;
        TicketResults[] memory ticketResults = evaluateWonTicketsForRound(roundId);
        ReferralTicketResults[] memory referralResults = evaluateWonReferralForRound(roundId);
        uint256 tier5_1Winners = 0;
        uint256 tier5Winners = 0;
        uint256 tier4_1Winners = 0;
        uint256 tier4Winners = 0;
        uint256 tier3_1Winners = 0;
        uint256 tier3Winners = 0;
        for(uint16 i = 0; i < ticketResults.length; i++) {
            if (ticketResults[i].victoryTier == RoundVictoryTier.Tier5_1) {
                tier5_1Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier5) {
                tier5Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier4_1) {
                tier4_1Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier4) {
                tier4Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier3_1) {
                tier3_1Winners++;
            } else if (ticketResults[i].victoryTier == RoundVictoryTier.Tier3) {
                tier3Winners++;
            }
        }

        if (tier5_1Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5_1);
        }
        if (tier5Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier5);
        }
        if (tier4_1Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4_1);
        }
        if (tier4Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier4);
        }
        if (tier3_1Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3_1);
        }
        if (tier3Winners > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Tier3);
        }
        if (referralResults.length > 0) {
            amountWon += lotteryRound.victoryTierAmounts(RoundVictoryTier.Referrer);
        }
        return amountWon;
    }
}
