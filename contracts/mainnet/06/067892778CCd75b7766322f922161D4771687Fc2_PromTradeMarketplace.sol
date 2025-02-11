// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.7;

import "./TradeMarketplaceCore.sol";

contract PromTradeMarketplace is TradeMarketplaceCore {
  constructor(
    address _addressRegistry,
    address _promToken,
    address _pauser,
    address _oracle,
    uint16 _promFeeDiscount
  ) {
    _setupRole(ADMIN_SETTER, msg.sender);
    _setupRole(PAUSER, _pauser);
    addressRegistry = IPromAddressRegistry(_addressRegistry);
    promToken = _promToken;
    oracle = IPromOracle(_oracle);
    promFeeDiscount = _promFeeDiscount;
  }

  function multicallList(
    address[] memory _nftAddresses,
    uint256[] memory _tokenIds,
    uint256[] memory _quantities,
    address[] memory _payTokens,
    uint256[] memory _pricePerItems,
    uint256[] memory _startingTimes,
    uint256[] memory _endTimes
  ) public {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      listItem(
        _nftAddresses[i],
        _tokenIds[i],
        _quantities[i],
        _payTokens[i],
        _pricePerItems[i],
        _startingTimes[i],
        _endTimes[i]
      );
    }
  }

  function multicallBuy(
    address[] calldata _nftAddresses,
    uint256[] calldata _tokenIds,
    address[] calldata _owners,
    uint256[] calldata _nonces
  ) public payable {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      buyItem(_nftAddresses[i], _tokenIds[i], _owners[i], _nonces[i]);
    }
  }

  function multicallBuyWithFeeInProm(
    address[] calldata _nftAddresses,
    uint256[] calldata _tokenIds,
    address[] calldata _owners,
    uint256[] calldata _nonces
  ) public payable {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      buyItemWithFeeInProm(
        _nftAddresses[i],
        _tokenIds[i],
        _owners[i],
        _nonces[i]
      );
    }
  }

  function multicallCancel(
    address[] calldata _nftAddresses,
    uint256[] calldata _tokenIds
  ) public {
    for (uint256 i = 0; i < _nftAddresses.length; i++) {
      cancelListing(_nftAddresses[i], _tokenIds[i]);
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TradeMarketplaceOffers.sol";

contract TradeMarketplaceCore is ReentrancyGuard, TradeMarketplaceOffers {
  /** 
   @notice Method for listing NFT
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token ID of NFT token for sale
   @param _quantity token amount to list (needed for ERC-1155 NFTs, set as 1 for ERC-721)
   @param _payToken Paying token
   @param _pricePerItem sale price for an iteam
   @param _startingTime starting timestamp after which item may be bought
   @param _endTime end timestamp after which item after which item may not be bough anymore
  */
  function listItem(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _quantity,
    address _payToken,
    uint256 _pricePerItem,
    uint256 _startingTime,
    uint256 _endTime
  ) public onlyAssetOwner(_nftAddress, _tokenId, _quantity) {
    _checkListing(_nftAddress, _tokenId, msg.sender, _payToken, _quantity);

    listings[_nftAddress][_tokenId][msg.sender] = Listing({
      quantity: _quantity,
      payToken: _payToken,
      pricePerItem: _pricePerItem,
      startingTime: _startingTime,
      endTime: _endTime,
      nonce: block.number
    });
    emit ItemListed(
      msg.sender,
      _nftAddress,
      _tokenId,
      _quantity,
      _payToken,
      _pricePerItem,
      _startingTime,
      _endTime
    );
  }

  /// @notice Method for canceling listed NFT
  function cancelListing(address _nftAddress, uint256 _tokenId)
    public
    isListed(_nftAddress, _tokenId, msg.sender)
    onlyAssetOwner(
      _nftAddress,
      _tokenId,
      listings[_nftAddress][_tokenId][msg.sender].quantity
    )
  {
    delete (listings[_nftAddress][_tokenId][msg.sender]);
    emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
  }

  /** 
   @notice Method for updating listed NFT for sale
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token ID of NFT token for sale
   @param _payToken payment token
   @param _newPricePerItem New sale price for the item
  */

  function updateListing(
    address _nftAddress,
    uint256 _tokenId,
    address _payToken,
    uint256 _newPricePerItem
  )
    external
    isListed(_nftAddress, _tokenId, msg.sender)
    onlyAssetOwner(
      _nftAddress,
      _tokenId,
      listings[_nftAddress][_tokenId][msg.sender].quantity
    )
  {
    Listing storage listedItem = listings[_nftAddress][_tokenId][msg.sender];

    _validPayToken(_payToken);

    listedItem.payToken = _payToken;
    listedItem.pricePerItem = _newPricePerItem;
    listedItem.nonce = block.number;
    emit ItemUpdated(
      msg.sender,
      _nftAddress,
      _tokenId,
      _payToken,
      _newPricePerItem
    );
  }

  /** 
   @notice Method for buying listed NFT
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token Id of NFT token for sale
   @param _owner listing's creator (owner of the item)
   @param _nonce nonce of the listing. Can be found by calling listings mapping
  */
  function buyItem(
    address _nftAddress,
    uint256 _tokenId,
    address _owner,
    uint256 _nonce
  )
    public
    payable
    whenNotPaused
    nonReentrant
    isListed(_nftAddress, _tokenId, _owner)
    validListing(_nftAddress, _tokenId, _owner)
  {
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

    _handleListingPayment(listedItem, _owner, _nftAddress);

    _transferNft(
      _nftAddress,
      _owner,
      msg.sender,
      _tokenId,
      listedItem.quantity
    );

    require(
      listings[_nftAddress][_tokenId][_owner].nonce == _nonce,
      "listing was updated"
    );

    emit ItemSold(
      _owner,
      msg.sender,
      _nftAddress,
      _tokenId,
      listedItem.quantity,
      listedItem.payToken,
      listedItem.pricePerItem
    );
    delete (listings[_nftAddress][_tokenId][_owner]);
  }

  /** 
   @notice Method for buying listed NFT. This method takes payment in a PROM token instead of listing paymentToken
   @param _nftAddress Address of NFT token for sale
   @param _tokenId Token Id of NFT token for sale
   @param _owner listing's creator (owner of the item)
   @param _nonce nonce of the listing. Can be found by calling listings mapping
  */
  function buyItemWithFeeInProm(
    address _nftAddress,
    uint256 _tokenId,
    address _owner,
    uint256 _nonce
  )
    public
    payable
    nonReentrant
    whenNotPaused
    isListed(_nftAddress, _tokenId, _owner)
    validListing(_nftAddress, _tokenId, _owner)
  {
    require(promToken != address(0), "prom fees not enabled");
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

    _handleListingPaymentProm(listedItem, _owner, _nftAddress);

    _transferNft(
      _nftAddress,
      _owner,
      msg.sender,
      _tokenId,
      listedItem.quantity
    );

    require(
      listings[_nftAddress][_tokenId][_owner].nonce == _nonce,
      "listing was updated"
    );

    emit ItemSold(
      _owner,
      msg.sender,
      _nftAddress,
      _tokenId,
      listedItem.quantity,
      listedItem.payToken,
      listedItem.pricePerItem
    );
    delete (listings[_nftAddress][_tokenId][_owner]);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "./TradeMarketplaceUtils.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeMarketplaceOffers is TradeMarketplaceUtils, ReentrancyGuard {
  /** 
   @notice Method for offering item
   @param _nftAddress NFT contract address
   @param _tokenId TokenId
   @param _payToken Paying token
   @param _quantity Quantity of items
   @param _pricePerItem Price per item
   @param _deadline Offer expiration
  */
  function createOffer(
    address _nftAddress,
    uint256 _tokenId,
    IERC20 _payToken,
    uint256 _quantity,
    uint256 _pricePerItem,
    uint256 _deadline
  ) external offerNotExists(_nftAddress, _tokenId, msg.sender) {
    require(
      IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721) ||
        IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155),
      "invalid nft address"
    );

    require(_deadline > block.timestamp, "invalid expiration");

    _validPayToken(address(_payToken));
    require(
      address(_payToken) != address(0),
      "only erc20 supported for offers"
    );
    require(
      _payToken.allowance(msg.sender, address(this)) >=
        _pricePerItem * _quantity,
      "allowance is too smal"
    );

    offers[_nftAddress][_tokenId][msg.sender] = Offer(
      _payToken,
      _quantity,
      _pricePerItem,
      _deadline,
      block.timestamp
    );

    emit OfferCreated(
      msg.sender,
      _nftAddress,
      _tokenId,
      _quantity,
      address(_payToken),
      _pricePerItem,
      _deadline
    );
  }

  /** 
  @notice Method for canceling the offer
  @param _nftAddress NFT contract address
  @param _tokenId TokenId
  */
  function cancelOffer(address _nftAddress, uint256 _tokenId)
    external
    offerExists(_nftAddress, _tokenId, msg.sender)
  {
    delete (offers[_nftAddress][_tokenId][msg.sender]);
    emit OfferCanceled(msg.sender, _nftAddress, _tokenId);
  }

  /** 
   @notice Method for accepting the offer
   @param _nftAddress NFT contract address
   @param _tokenId TokenId
   @param _creator Offer creator address
  */
  function acceptOffer(
    address _nftAddress,
    uint256 _tokenId,
    address _creator,
    uint256 _offerNonce
  )
    external
    offerExists(_nftAddress, _tokenId, _creator)
    onlyAssetOwner(
      _nftAddress,
      _tokenId,
      offers[_nftAddress][_tokenId][_creator].quantity
    )
    nonReentrant
  {
    Offer memory offer = offers[_nftAddress][_tokenId][_creator];
    uint16 fee = _checkCollection(_nftAddress);
    _handleOfferPayment(offer, _creator, _nftAddress, fee);

    _transferNft(_nftAddress, msg.sender, _creator, _tokenId, offer.quantity);

    require(offer.offerNonce == _offerNonce, "offer was changed");
    emit ItemSold(
      msg.sender,
      _creator,
      _nftAddress,
      _tokenId,
      offer.quantity,
      address(offer.payToken),
      offer.pricePerItem
    );
    emit OfferCanceled(_creator, _nftAddress, _tokenId);

    delete (listings[_nftAddress][_tokenId][msg.sender]);
    delete (offers[_nftAddress][_tokenId][_creator]);
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TradeMarketplaceValidator.sol";

contract TradeMarketplaceUtils is TradeMarketplaceValidator {
  using SafeERC20 for IERC20;

  ////////////////////////////
  /// Internal and Private ///
  ////////////////////////////

  function _transferNft(
    address _nftAddress,
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _quantity
  ) internal {
    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      IERC721(_nftAddress).safeTransferFrom(_from, _to, _tokenId);
    } else {
      IERC1155(_nftAddress).safeTransferFrom(
        _from,
        _to,
        _tokenId,
        _quantity,
        bytes("0x")
      );
    }
  }

  function _validPayToken(address _payToken) internal view {
    require(
      (IPromAddressRegistry(addressRegistry).isTokenEligible(_payToken)),
      "invalid pay token"
    );
  }

  function _getFees(
    uint256 price,
    address _nftAddress,
    uint16 _collectionFee
  )
    internal
    view
    returns (
      uint256 royaltyFee,
      uint256 totalFeeAmount,
      address royaltyFeeReceiver
    )
  {
    if (_collectionFee != 10000) {
      totalFeeAmount = (price * _collectionFee) / 1e4;
    }
    royaltyFee =
      ((price - totalFeeAmount) * collectionRoyalties[_nftAddress].royalty) /
      1e4;
    totalFeeAmount = totalFeeAmount + royaltyFee;
    royaltyFeeReceiver = collectionRoyalties[_nftAddress].feeRecipient;
  }

  function _handleOfferPayment(
    Offer memory _offer,
    address _creator,
    address _nftAddress,
    uint16 _collectionFee
  ) internal {
    uint256 price = _offer.pricePerItem * _offer.quantity;
    (
      uint256 royaltyFee,
      uint256 feeAmount,
      address royaltyFeeReceiver
    ) = _getFees(price, _nftAddress, _collectionFee);

    _handlePayment(
      _nftAddress,
      address(_offer.payToken),
      _creator,
      msg.sender,
      price,
      royaltyFee,
      feeAmount,
      royaltyFeeReceiver
    );
  }

  function _handleListingPayment(
    Listing memory _listing,
    address _owner,
    address _nftAddress
  ) internal {
    uint256 price = _listing.pricePerItem * _listing.quantity;
    uint16 fee = _checkCollection(_nftAddress);
    (
      uint256 royaltyFee,
      uint256 feeAmount,
      address royaltyFeeReceiver
    ) = _getFees(price, _nftAddress, fee);

    _handlePayment(
      _nftAddress,
      _listing.payToken,
      msg.sender,
      _owner,
      price,
      royaltyFee,
      feeAmount,
      royaltyFeeReceiver
    );
  }

  function _checkCollection(address _collectionAddress)
    internal
    view
    returns (uint16 collectionFee)
  {
    collectionFee = addressRegistry.isTradeCollectionEnabled(
      _collectionAddress
    );
    require(collectionFee != 0, "collection not enabled");
  }

  function _handleListingPaymentProm(
    Listing memory _listing,
    address _owner,
    address _nftAddress
  ) internal {
    uint256 price = _listing.pricePerItem * _listing.quantity;
    uint16 fee = _checkCollection(_nftAddress);
    (
      uint256 royaltyFee,
      uint256 feeAmount,
      address royaltyFeeReceiver
    ) = _getFees(price, _nftAddress, fee);

    if (royaltyFee > 0) {
      _transfer(msg.sender, royaltyFeeReceiver, royaltyFee, _listing.payToken);
      emit RoyaltyPayed(_nftAddress, royaltyFee);
    }

    _handlePromPayment(_listing.payToken, _owner, price, royaltyFee, feeAmount);
  }

  function _handlePromPayment(
    address _paymentToken,
    address _receiver,
    uint256 _price,
    uint256 _royaltyFee,
    uint256 _totalFee
  ) internal {
    uint256 promFee = oracle.convertTokenValue(
      _paymentToken,
      _totalFee - _royaltyFee,
      promToken
    );
    if (promFee > promFeeDiscount) {
      promFee = promFee - promFeeDiscount;
      _totalFee = _totalFee - promFeeDiscount;
    }
    _transfer(
      msg.sender,
      addressRegistry.tradeMarketplaceFeeReceiver(),
      promFee,
      promToken
    );

    _transfer(msg.sender, _receiver, _price - _totalFee, _paymentToken);
  }

  function _handlePayment(
    address _nftAddress,
    address _paymentToken,
    address _from, // msg.sender for buy, offer create for accepting offers
    address _receiver,
    uint256 _price,
    uint256 _royaltyFee,
    uint256 _totalFee,
    address royaltyFeeReceiver
  ) internal {
    if (_royaltyFee > 0) {
      _transfer(_from, royaltyFeeReceiver, _royaltyFee, _paymentToken);
      emit RoyaltyPayed(_nftAddress, _royaltyFee);
    }

    _transfer(
      _from,
      addressRegistry.tradeMarketplaceFeeReceiver(),
      _totalFee - _royaltyFee,
      _paymentToken
    );

    _transfer(_from, _receiver, _price - _totalFee, _paymentToken);
  }

  function _checkIfListed(
    address _nftAddress,
    uint256 _tokenId,
    address _seller
  ) internal view {
    require(
      listings[_nftAddress][_tokenId][_seller].quantity == 0,
      "already listed"
    );
  }

  function _checkListing(
    address _nftAddress,
    uint256 _tokenId,
    address _seller,
    address _payToken,
    uint256 _quantity
  ) internal view {
    _checkIfListed(_nftAddress, _tokenId, _seller);
    _checkCollection(_nftAddress);
    _validPayToken(_payToken);

    require(_quantity > 0, "invalid quantity");

    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      require(_quantity == 1, "invalid quantity");
    } else {
      require(_quantity > 0, "invalid _quantity");
    }
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount,
    address _paymentToken
  ) internal {
    if (_paymentToken == address(0)) {
      require(msg.value >= _amount, "not enough value");
      (bool success, ) = payable(_to).call{value: _amount}("");
      require(success, "Should transfer ethers");
    } else {
      if (_from == address(this)) {
        IERC20(_paymentToken).safeTransfer(_to, _amount);
      } else {
        IERC20(_paymentToken).safeTransferFrom(_from, _to, _amount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "./TradeMarketplaceGuard.sol";

contract TradeMarketplaceValidator is TradeMarketplaceGuard {
  /**
    @notice Validate and cancel listing
    @dev Only bundle marketplace can access
    @param _nftAddress address of the NFT which will be sold
    @param _tokenId token id of the NFT which will be sold
    @param _seller address of the seller
   */
  function validateItemSold(
    address _nftAddress,
    uint256 _tokenId,
    address _seller
  ) external onlyBundleMarketplace {
    Listing memory item = listings[_nftAddress][_tokenId][_seller];
    if (item.quantity > 0) {
      delete (listings[_nftAddress][_tokenId][_seller]);
      emit ItemSoldInBundle(msg.sender, _nftAddress, _tokenId);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "./TradeMarketplaceStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract TradeMarketplaceGuard is
  TradeMarketplaceStorage,
  Pausable,
  AccessControl
{
  modifier onlyBundleMarketplace() {
    require(
      address(addressRegistry.bundleMarketplace()) == msg.sender,
      "sender must be bundle marketplace"
    );
    _;
  }

  modifier onlyAssetOwner(
    address _nftAddress,
    uint256 _tokenId,
    uint256 _quantity
  ) {
    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      IERC721 nft = IERC721(_nftAddress);
      require(nft.ownerOf(_tokenId) == msg.sender, "not owning item");
      require(
        nft.isApprovedForAll(msg.sender, address(this)) ||
          IERC721(_nftAddress).getApproved(_tokenId) == address(this),
        "item not approved"
      );
    } else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
      IERC1155 nft = IERC1155(_nftAddress);
      require(
        nft.balanceOf(msg.sender, _tokenId) >= _quantity,
        "must hold enough nfts"
      );
      require(
        nft.isApprovedForAll(msg.sender, address(this)),
        "item not approved"
      );
    } else {
      revert("invalid nft address");
    }
    _;
  }

  // TODO: Change
  modifier validListing(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
  ) {
    Listing memory listedItem = listings[_nftAddress][_tokenId][_owner];

    _validOwner(_nftAddress, _tokenId, _owner, listedItem.quantity);

    require(
      block.timestamp >= listedItem.startingTime &&
        block.timestamp <= listedItem.endTime,
      "item not buyable"
    );
    _;
  }

  modifier offerExists(
    address _nftAddress,
    uint256 _tokenId,
    address _creator
  ) {
    Offer memory offer = offers[_nftAddress][_tokenId][_creator];
    require(
      offer.quantity > 0 && offer.deadline > block.timestamp,
      "offer not exists or expired"
    );
    _;
  }

  modifier offerNotExists(
    address _nftAddress,
    uint256 _tokenId,
    address _creator
  ) {
    Offer memory offer = offers[_nftAddress][_tokenId][_creator];
    require(
      offer.quantity == 0 || offer.deadline <= block.timestamp,
      "offer already created"
    );
    _;
  }

  modifier isListed(
    address _nftAddress,
    uint256 _tokenId,
    address _owner
  ) {
    Listing memory listing = listings[_nftAddress][_tokenId][_owner];
    require(listing.quantity > 0, "not listed item");
    _;
  }

  function _validOwner(
    address _nftAddress,
    uint256 _tokenId,
    address _owner,
    uint256 _quantity
  ) internal view {
    if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC721)) {
      IERC721 nft = IERC721(_nftAddress);
      require(nft.ownerOf(_tokenId) == _owner, "not owning item");
    } else if (IERC165(_nftAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
      IERC1155 nft = IERC1155(_nftAddress);
      require(nft.balanceOf(_owner, _tokenId) >= _quantity, "not owning item");
    } else {
      revert("invalid nft address");
    }
  }

  /**
     @notice Update PromAddressRegistry contract
     @dev Only admin
     @param _registry new adress to be set for AdressRegistry
     */
  function updateAddressRegistry(address _registry)
    external
    onlyRole(ADMIN_SETTER)
  {
    addressRegistry = IPromAddressRegistry(_registry);
  }

  /** 
  @notice Method for setting royalty
  @param _nftAddress NFT contract address
  @param _royalty Royalty
  @param _feeRecipient address where the fees will be sent to
  */
  function registerCollectionRoyalty(
    address _nftAddress,
    uint16 _royalty,
    address _feeRecipient
  ) external onlyRole(ADMIN_SETTER) {
    require(_royalty <= 10000, "invalid royalty");
    require(_feeRecipient != address(0), "invalid fee recipient address");

    collectionRoyalties[_nftAddress] = CollectionRoyalty(
      _royalty,
      _feeRecipient
    );
  }

  function updatePromFeeDiscount(uint16 _newFee)
    external
    onlyRole(ADMIN_SETTER)
  {
    promFeeDiscount = _newFee;
  }

  function updateOracle(address _newOracle) external onlyRole(ADMIN_SETTER) {
    oracle = IPromOracle(_newOracle);
  }

  function togglePause() external onlyRole(PAUSER) {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPromAddressRegistry {
  function bundleMarketplace() external view returns (address);

  function isTokenEligible(address) external view returns (bool);

  function isTradeCollectionEnabled(address) external view returns (uint16);

  function tradeMarketplaceFeeReceiver() external view returns (address);
}

interface IPromOracle {
  function convertTokenValue(
    address,
    uint256,
    address
  ) external returns (uint256);
}

contract TradeMarketplaceStorage {
  bytes32 internal constant ADMIN_SETTER = keccak256("ADMIN_SETTER");
  bytes32 internal constant PAUSER = keccak256("PAUSER");

  /// @notice Structure for listed items
  struct Listing {
    uint256 quantity;
    address payToken;
    uint256 pricePerItem;
    uint256 startingTime;
    uint256 endTime;
    uint256 nonce;
  }

  /// @notice Structure for offer
  struct Offer {
    IERC20 payToken;
    uint256 quantity;
    uint256 pricePerItem;
    uint256 deadline;
    uint256 offerNonce;
  }

  struct CollectionRoyalty {
    uint16 royalty;
    address feeRecipient;
  }

  uint16 public promFeeDiscount; // % of discount from 0 to 10000

  /// @notice NftAddress -> Token ID -> Owner -> Listing item
  mapping(address => mapping(uint256 => mapping(address => Listing)))
    public listings;

  /// @notice NftAddress -> Token ID -> Offerer -> Offer
  mapping(address => mapping(uint256 => mapping(address => Offer)))
    public offers;

  /// @notice NftAddress -> Royalty
  mapping(address => CollectionRoyalty) public collectionRoyalties;

  address public promToken;
  IPromOracle public oracle;

  /// @notice Address registry
  IPromAddressRegistry public addressRegistry;

  bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 internal constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

  /// @notice Events for the contract
  event ItemListed(
    address indexed owner,
    address indexed nft,
    uint256 tokenId,
    uint256 quantity,
    address payToken,
    uint256 pricePerItem,
    uint256 startingTime,
    uint256 endTime
  );
  event ItemSold(
    address indexed seller,
    address indexed buyer,
    address indexed nft,
    uint256 tokenId,
    uint256 quantity,
    address payToken,
    uint256 pricePerItem
  );
  event ItemSoldInBundle(
    address indexed seller,
    address indexed nft,
    uint256 tokenId
  );
  event ItemUpdated(
    address indexed owner,
    address indexed nft,
    uint256 tokenId,
    address payToken,
    uint256 newPrice
  );
  event ItemCanceled(
    address indexed owner,
    address indexed nft,
    uint256 tokenId
  );
  event OfferCreated(
    address indexed creator,
    address indexed nft,
    uint256 tokenId,
    uint256 quantity,
    address payToken,
    uint256 pricePerItem,
    uint256 deadline
  );
  event OfferCanceled(
    address indexed creator,
    address indexed nft,
    uint256 tokenId
  );
  event UpdatePlatformFee(uint16 platformFee);
  event RoyaltyPayed(address collection, uint256 amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}