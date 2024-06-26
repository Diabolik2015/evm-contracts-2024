// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

    struct SniperState {
        uint128 ethBalance;
        bool isPaused;
    }

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev Cannot double-initialize.
    error AlreadyInitialized();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
    0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
    0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
    0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))))`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    bytes32 internal constant _OWNER_SLOT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Override to return true to make `_initializeOwner` prevent double-initialization.
    function _guardInitializeOwner() internal pure virtual returns (bool guard) {}

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                if sload(ownerSlot) {
                    mstore(0x00, 0x0dc149f0) // `AlreadyInitialized()`.
                    revert(0x1c, 0x04)
                }
            // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
            // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
            // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
                sstore(_OWNER_SLOT, newOwner)
            // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
            // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
            // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
                sstore(ownerSlot, newOwner)
            }
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
        // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(_OWNER_SLOT))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    /// Override to return a different value if needed.
    /// Made internal to conserve bytecode. Wrap it in a public function if needed.
    function _ownershipHandoverValidFor() internal view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + _ownershipHandoverValidFor();
        /// @solidity memory-safe-assembly
            assembly {
            // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
            // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
        // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
        // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
        // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
        // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
        // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_OWNER_SLOT)
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
    public
    view
    virtual
    returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
        // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
        // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

/// @title ERC-1155 Multi Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 is IERC165 {
    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_id` argument MUST be the token type being transferred.
    /// - The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_ids` argument MUST be the list of tokens being transferred.
    /// - The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    /// @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @dev MUST emit when the URI is updated for a token ID. URIs are defined in RFC 3986.
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    event URI(string _value, uint256 indexed _id);

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// - MUST revert on any other error.
    /// - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// - After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if length of `_ids` is not the same as length of `_values`.
    /// - MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// - MUST revert on any other error.
    /// - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    /// - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _ids IDs of each token type (order and length must match _values array)
    /// @param _values Transfer amounts per token type (order and length must match _ids array)
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /// @notice Get the balance of an account's tokens.
    /// @param _owner The address of the token holder
    /// @param _id ID of the token
    /// @return The _owner's balance of the token type requested
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param _owners The addresses of the token holders
    /// @param _ids ID of the tokens
    /// @return The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    view
    returns (uint256[] memory);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param _owner The owner of the tokens
    /// @param _operator Address of authorized operator
    /// @return True if the operator is approved, false if not
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

/**
 * @title AutoSniper 4.0 for @oSnipeNFT
 * @author 0xQuit
 */
/*

        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=--::::::--=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=:.       ......        :=*%@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.    .-+*%@@@@@@@@@@@@%#+=:    -@@@@@@=:::=#@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@%+.   :=#@@@@@@@@@@@@@@@@@@@@@@@@#+#@@@@@%**+-:::-%@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@#-   :+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%******+-::=@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@%:   =%@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@%*++++++***+=+@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@=   -@@@@@@@@@@@@#+-:.         :-+%@@@@@%*+++++++++*#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#.  :%@@@@@@@@@%+:      ..:::::.  .*@@@%*+++++++++++#@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@*   =@@@@@@@@@#:    .=*%@@@@@@@@@@%@@@%+----======+#@@@@@%@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@+   *@@@@@@@@#:   .+%@@@@@@@@@@@@@@@@@@=-------==+#@@@@@%- -@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@#   #@@@@@@@@=   .*@@@@@@@@@#=.    .-+#+=--------*@@@@@@@%   +@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@.  =@@@@@@@@-   =@@@@@@@@@@:  -+**+-   .--=----+%@@@@@@@@@#   %@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@+  .@@@@@@@@-   +@@@@@@@@@@-  #@@@@%+-:.  :=*@#%@@@*%@@@@@@@=  -@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@.  #@@@@@@@+   =@@@@@@@@@@@:  @@@%=-----.  #@@@@@*. -@@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#   @@@@@@@@.  .@@@@@@@@@@@@%  :#=:::::--*+=@@@@@@-   %@@@@@@@-  +@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  :@@@@@@@%   =@@@@@@@@@@@@@%-:--::::-*@@@@@@@@@@*   *@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@=  -@@@@@@@#   +@@@@@@@@@@@@@#-:---:-*@@@@@@@@@@@@#   +@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  -@@@@@@@%   =@@@@@@*#@@@#-::---=. -@@@@@@@@@@@@*   +@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#  .@@@@@@@@   .@@@@@+  #*-:::--*@@#  -@@@@@@@@@@@-   %@@@@@@@-  =@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@   #@@@@@@@+  =@@@@@%  .--:--+@@@@@=  %@@@@@@@@@#   :@@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@=  :@@@@@@@@=%@@@@@@*:   :-*@@@@@@%. .@@@@@@@@@%    %@@@@@@@=  :@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@   +@@@@@@@@@@@@#+---:.  .=*###*-  :%@@@@@@@@#   .%@@@@@@@#   #@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@*   %@@@@@@@@@#=------*%+-      .-#@@@@@@@@%=   .%@@@@@@@@.  =@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@= .*@@@@@@@@+------=%@@@@@@%%%@@@@@@@@@@#-    +@@@@@@@@@:  :@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@#@@@@@@@@*===---=#@@@@@@@@@@@@@@@@@%*-     +@@@@@@@@@#   -@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@*=====+#%@@@@@%= .:--==--:.     .-*@@@@@@@@@@+   +@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@+--==+#@@@@@@@@=:.           :=*%@@@@@@@@@@@*.  .#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@*===+-*@@@@@@@@@@@@@@%%#####%@@@@@@@@@@@@@@@*.   +@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@#+==#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=   .+@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@+==+%@@@@@@@@@%*%@@@@@@@@@@@@@@@@@@@@@@@@@*-    -*@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#=%@@@@@@@@@+    -=*%@@@@@@@@@@@@@@%*+-.    :+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-.      ..:::::::.      .-+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=-:........:-=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/

contract AutoSniper is Ownable {
    error InsufficientBalance();
    error FailedToWithdraw();
    error FailedToPayAutosniper();
    error FailedToPayValidator();
    error OrderFailed();
    error CallerNotFulfiller();
    error MigrationNotEnabled();
    error ArrayLengthMismatch();
    error SniperIsPaused();
    error FulfillerCannotHaveBalance();

    event Deposit(address sniper, uint256 amount);
    event Withdrawal(address sniper, uint256 amount);

    address private fulfillerAddress = 0x4fa427a9481207e52718fca653dfe06cd5167c27;
    address public nextContractVersionAddress;
    bool public migrationEnabled;
    mapping(address => SniperState) public sniperStates;

    constructor() {
        _initializeOwner(tx.origin);
    }

    // only the fulfiller can call this function
    modifier onlyFulfiller() {
        if (msg.sender != fulfillerAddress) revert CallerNotFulfiller();
        _;
    }

    // allow the contract to receive Ether
    receive() external payable {}

    /**
     *
    Name	            Type	    Data
0	contractAddresses	address[]	0x6b15602f008a05D9694D777dEaD2F05586216cB4
1	calls	bytes[]	0x4b17256b00000000000000000000000037fb6c069edb551b68b0f8ffd053b51e335a938b
2	values	uint256[]	0
3	sniper	address	0x5C04911bA3a457De6FA0357b339220e4E034e8F7
4	validatorTip	uint256	0
5	fulfillerTip	uint256	0


@dev Generalized function for fulfilling orders
     * @param contractAddresses a list of contract addresses that will be called
     * @param calls a matching array to contractAddresses, each index being a call to make to a given contract
     * @param values a matching array to contractAddresses, each index being the value to send with the call
     * @param sniper the address of the sniper
     * @param validatorTip the amount to send to block.coinbase. Reverts if this is 0.
     * @param fulfillerTip the amount to send to fulfillerAddress. Reverts if this is 0.
     */
    function snipe_2572234525(
        address[] calldata contractAddresses,
        bytes[] calldata calls,
        uint256[] calldata values,
        address sniper,
        uint256 validatorTip,
        uint256 fulfillerTip
    ) external onlyFulfiller {
        if (contractAddresses.length != calls.length) revert ArrayLengthMismatch();
        if (calls.length != values.length) revert ArrayLengthMismatch();
        if (sniperStates[sniper].isPaused) revert SniperIsPaused();

        uint256 balanceBefore = address(this).balance;

        for (uint256 i = 0; i < contractAddresses.length; ++i) {
            (bool success,) = contractAddresses[i].call{value: values[i]}(calls[i]);
            if (!success) revert OrderFailed();
        }

        (bool validatorPaid,) = block.coinbase.call{value: validatorTip}("");
        if (!validatorPaid) revert FailedToPayValidator();
        (bool fulfillerPaid,) = fulfillerAddress.call{value: fulfillerTip}("");
        if (!fulfillerPaid) revert FailedToPayAutosniper();

        uint256 balanceAfter = address(this).balance;

        if (balanceAfter < balanceBefore) {
            uint128 spent = uint128(balanceBefore - balanceAfter);
            if (sniperStates[sniper].ethBalance < spent) revert InsufficientBalance();
            unchecked {
                sniperStates[sniper].ethBalance -= spent;
            }
            emit Withdrawal(sniper, spent);
        } else if (balanceAfter > balanceBefore) {
            unchecked {
                sniperStates[sniper].ethBalance += uint128(balanceAfter - balanceBefore);
            }
            emit Deposit(sniper, balanceAfter - balanceBefore);
        }
    }

    /**
     * @dev deposit Ether into the contract.
     * @param sniper is the address who's balance is affected.
     */
    function deposit(address sniper) public payable {
        if (tx.origin == fulfillerAddress) revert FulfillerCannotHaveBalance();
        unchecked {
            sniperStates[sniper].ethBalance += uint128(msg.value);
        }

        emit Deposit(sniper, msg.value);
    }

    /**
     * @dev deposit Ether into your own contract balance.
     */
    function depositSelf() external payable {
        deposit(msg.sender);
    }

    /**
     * @dev withdraw Ether from your contract balance
     * @param amount the amount of Ether to be withdrawn
     */
    function withdraw(uint256 amount) external {
        if (tx.origin == fulfillerAddress) revert FulfillerCannotHaveBalance();

        if (sniperStates[msg.sender].ethBalance < amount) revert InsufficientBalance();
        unchecked {
            sniperStates[msg.sender].ethBalance -= uint128(amount);
        }

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FailedToWithdraw();

        emit Withdrawal(msg.sender, amount);
    }

    function setUserIsPaused(bool isPaused) external {
        sniperStates[msg.sender].isPaused = isPaused;
    }

    /**
     * @dev Owner function to change fulfiller address if needed.
     */
    function setFulfillerAddress(address _fulfiller) external onlyOwner {
        fulfillerAddress = _fulfiller;
    }

    /**
     * Enables migration and sets a destination address (the new contract)
     * @param _destination the new AutoSniper version to allow migration to.
     */
    function setMigrationAddress(address _destination) external onlyOwner {
        migrationEnabled = true;
        nextContractVersionAddress = _destination;
    }

    /**
     * @dev in the event of a future contract upgrade, this function allows snipers to
     * easily move their ether balance to the new contract. This can only be called by
     * the sniper to move their personal balance - the contract owner or anybody else
     * does not have the power to migrate balances for users.
     */
    function migrateBalance() external {
        if (!migrationEnabled) revert MigrationNotEnabled();
        uint256 balanceToMigrate = sniperStates[msg.sender].ethBalance;
        sniperStates[msg.sender].ethBalance = 0;

        (bool success,) = nextContractVersionAddress.call{value: balanceToMigrate}(
            abi.encodeWithSelector(this.deposit.selector, msg.sender)
        );
        if (!success) revert FailedToWithdraw();
    }

    function sniperBalance(address sniper) external view returns (uint128) {
        return sniperStates[sniper].ethBalance;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
    public
    virtual
    returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) external onlyOwner {
        IERC20 token = IERC20(asset);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}