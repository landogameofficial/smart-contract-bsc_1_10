//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {Ownable} from "../deps/Ownable.sol";
import {SafeMath} from "../lib/SafeMath.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {ISoccerStarNft} from "../interfaces/ISoccerStarNft.sol";
import {ISoccerStarNftMarket} from "../interfaces/ISoccerStarNftMarket.sol";
import {IBIBOracle} from "../interfaces/IBIBOracle.sol";
import {IFeeCollector} from "../interfaces/IFeeCollector.sol";
import {VersionedInitializable} from "../deps/VersionedInitializable.sol";

contract SoccerStarNftMarket is 
ISoccerStarNftMarket, 
OwnableUpgradeable, 
PausableUpgradeable{
    using SafeMath for uint;

    address public treasury;

    IERC20 public bibContract;
    IERC20 public busdContract;
    ISoccerStarNft public tokenContract;
    IFeeCollector public feeCollector;

    event TokenContractChanged(address sender, address oldValue, address newValue);
    event BIBContractChanged(address sender, address oldValue, address newValue);
    event BUSDContractChanged(address sender, address oldValue, address newValue);
    event FeeRatioChanged(address sender, uint oldValue, uint newValue);
    event RoyaltyRatioChanged(address sender, uint oldValue, uint newValue);
    event FeeCollectorChanged(address sender, address oldValue, address newValue);
    event ProtocolTokenChanged(address sender, address oldValue, address newValue);

    uint public nextOrderIndex;
    uint public nextOfferIndex;

    uint public feeRatio;
    uint public royaltyRatio;
    uint public constant FEE_RATIO_DIV = 1000;

    // mapping order_id to order
    mapping(uint=>Order) public orderTb;

    // mapping issure->token->order_id
    mapping(address=>mapping(uint=>uint)) public tokenOrderTb;

    // orders belong to the specfic owner
    mapping(address=>uint[]) public userOrdersTb;

    // maping offer_id to offer
    mapping(uint=>Offer) public offerTb;

    // mapping issurer=>token=>offer_ids
    mapping(address=>mapping(uint=>uint[])) public tokenOffersTb;

    // mapping user=>offer_ids
    mapping(address=>uint[]) public userOffersTb;

    // nft token issuered by the protocol
    address protocolToken;

    function initialize(
        address _tokenContract,
        address _bibContract,
        address _busdContract,
        address _treasury,
        address _protocolToken
        ) public reinitializer(1) {
        treasury = _treasury;
        tokenContract = ISoccerStarNft(_tokenContract);
        bibContract = IERC20(_bibContract);
        busdContract = IERC20(_busdContract);
        protocolToken = _protocolToken;

        nextOrderIndex = 1;
        nextOfferIndex = 1;

        feeRatio = 25;
        royaltyRatio = 75;

        __Pausable_init();
        __Ownable_init();
    }

    function getBlockTime() public override view returns(uint){
        return block.timestamp;
    }

    function setTokenContract(address _tokenContract) public onlyOwner{
        require(address(0) != _tokenContract, "INVALID_ADDRESS");
        emit TokenContractChanged(msg.sender, address(tokenContract), _tokenContract);
        tokenContract = ISoccerStarNft(_tokenContract);
    }

    function setBIBContract(address _bibContract) public onlyOwner{
        require(address(0) != _bibContract, "INVALID_ADDRESS");
        emit BIBContractChanged(msg.sender, address(bibContract), _bibContract);
        bibContract = IERC20(_bibContract);
    }

    function setBUSDContract(address _busdContract) public onlyOwner{
        require(address(0) != _busdContract, "INVALID_ADDRESS");
        emit BUSDContractChanged(msg.sender, address(busdContract), _busdContract);
        busdContract = IERC20(_busdContract);
    }

    function setFeeCollector(address _feeCollector) public onlyOwner{
        emit FeeCollectorChanged(msg.sender, address(feeCollector), _feeCollector);
        feeCollector = IFeeCollector(_feeCollector);
    }

    function setFeeRatio(uint _feeRatio) public override onlyOwner{
        require(_feeRatio <= FEE_RATIO_DIV, "INVALID_RATIO");
        emit FeeRatioChanged(msg.sender,feeRatio, _feeRatio);
        feeRatio = _feeRatio;
    }

   function setRoyaltyRatio(uint _royaltyRatio) override public onlyOwner {
       require(_royaltyRatio <= FEE_RATIO_DIV, "INVALID_ROYALTY_RATIO");
       emit RoyaltyRatioChanged(msg.sender, royaltyRatio, _royaltyRatio);
       royaltyRatio = _royaltyRatio;
   }

    function setProtocolToken(address _protocolToken) public onlyOwner{
        require(address(0) != _protocolToken, "INVALID_ADDRESS");
        emit ProtocolTokenChanged(msg.sender, protocolToken, _protocolToken);
        protocolToken = _protocolToken;
    }

    function isOwner(address issuer, uint tokenId, address owner)
     internal  view returns(bool){
        return (owner == IERC721(address(issuer)).ownerOf(tokenId));
    }

    function isOriginOwner(address issuer, uint tokenId, address owner)
     public override view returns(bool){
         if(!isOwner(issuer, tokenId, owner)) {
            Order memory order = getOrder(issuer, tokenId);
            if(address(0) == order.owner){
                return false;
            } else {
                return order.owner == owner;
            }
         }
         return true;
    }

    // user create a order
    function openOrder(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration)
     public override payable whenNotPaused{
        require(address(0) != issuer, "INVALID_ISSURE");
        require(expiration > block.timestamp, "EXPIRATION_TOO_SMALL");
        require(price > 0, "PRICE_NOT_BE_ZEROR");
        require(isOwner(issuer, tokenId, msg.sender), 
        "TOKEN_NOT_BELLONG_TO_SENDER");
   
        // delegate token to protocol
        IERC721(address(issuer)).transferFrom(msg.sender, address(this), tokenId);
        require(isOwner(issuer, tokenId, address(this)), "ERC721_FALED_TRANSFER");

        // record order
        Order memory order = Order({
            issuer: issuer,
            orderId: nextOrderIndex++,
            tokenId: tokenId,
            owner: msg.sender,
            payMethod: payMethod,
            price: price,
            mt: block.timestamp,
            expiration: expiration
        });

        orderTb[order.orderId] = order;
        tokenOrderTb[issuer][tokenId] = order.orderId;
        userOrdersTb[msg.sender].push(order.orderId);

        emit OpenOrder(msg.sender, 
        issuer, order.orderId, tokenId, 
        payMethod, price, order.mt, expiration);
    }

    function updateOrder(uint orderId, PayMethod payMethod, uint price, uint expiration)
    public override payable whenNotPaused{
        Order storage order = orderTb[orderId];
        require(price > 0, "PRICE_LTE_ZERO");
        require(msg.sender == order.owner, "SHOULD_BE_ORDER_OWNER");
        require(expiration > block.timestamp, "EXPIRATION_TOO_EARLY");
        order.payMethod = payMethod;
        order.price = price;
        order.expiration = expiration;
        order.mt = block.timestamp;

       emit UpdateOrder(msg.sender, 
        order.issuer, order.orderId, order.tokenId, 
        payMethod, price, order.mt, expiration);
    }

    function hasOrder(address issuer, uint tokenId) public override view returns(bool){
        return tokenOrderTb[issuer][tokenId] > 0;
    }

    function getOrder(address issuer, uint tokenId) public override view returns(Order memory){
        return orderTb[tokenOrderTb[issuer][tokenId]];
    }   

    // get orders by page
    function getUserOrdersByPage(address user, uint pageSt, uint pageSz) 
    public view override returns(Order[] memory){
        uint[] storage _orders= userOrdersTb[user];
        Order[] memory ret;

        if(pageSt < _orders.length){
            uint end = pageSt + pageSz;
            end = end > _orders.length ? _orders.length : end;
            ret =  new Order[](end - pageSt);
            for(uint i = 0;pageSt < end; i++){
                ret[i] = orderTb[_orders[pageSt]];
                pageSt++;
            } 
        }

        return ret;
    }

    function caculateFees(uint amount) view public returns(uint, uint ){
        // exchange fee + royaltyRatio fee
        return (amount.mul(feeRatio).div(FEE_RATIO_DIV), amount.mul(royaltyRatio).div(FEE_RATIO_DIV));
    }

    // Owner accept the price
    function collectFeeWhenBuyerAsMaker(PayMethod payMethod, uint fees) internal {
        if(payMethod == PayMethod.PAY_BNB) {
            if(address(0) != address(feeCollector)) {
                try feeCollector.handleCollectBNB{value:fees}(fees){} catch{}
            } else {
                payable(address(treasury)).transfer(fees);
            }
        } else if(payMethod == PayMethod.PAY_BUSD) {
            if(address(0) != address(feeCollector)) {
                busdContract.transfer(address(feeCollector), fees);
                try feeCollector.handleCollectBUSD(fees) {} catch{}
            } else {
                busdContract.transfer(treasury, fees);
            }
        } else {
            if(address(0) != address(feeCollector)) {
                bibContract.transfer(address(feeCollector), fees);
                try feeCollector.handleCollectBIB(fees) {} catch{}
            } else {
                bibContract.transfer(treasury, fees);
            }
        }
    }

    // Buyer accept the price
    function collectFeeWhenSellerAsMaker(PayMethod payMethod, uint fees) internal {
        if(payMethod == PayMethod.PAY_BNB) {
            if(address(0) != address(feeCollector)) {
                try feeCollector.handleCollectBNB{value:fees}(fees) {} catch{}
            } else {
                payable(address(treasury)).transfer(fees);
            }
        } else if(payMethod == PayMethod.PAY_BUSD) {
            if(address(0) != address(feeCollector)) {
                busdContract.transferFrom(msg.sender, address(feeCollector), fees);
                try feeCollector.handleCollectBUSD(fees) {}catch{}
            } else {
                busdContract.transferFrom(msg.sender, treasury, fees);
            }
        } else {
            if(address(0) != address(feeCollector)) {
                bibContract.transfer(address(feeCollector), fees);
                try feeCollector.handleCollectBIB(fees) {}catch{}
            } else {
                bibContract.transfer(treasury, fees);
            }
        }
    }

    // Buyer accept the price and makes a deal with the sepcific order
    function acceptOrder(uint orderId) 
    public  override payable whenNotPaused{
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");
        require(msg.sender != order.owner, "SHOULD_NOT_BE_ORDER_OWNER");
        require(order.expiration > block.timestamp, "ORDER_EXPIRED");

        // caculate fees
        (uint txFee, uint royaltyFee ) = caculateFees(order.price);
        uint fees = txFee.add(royaltyFee);
        uint amount = order.price.sub(fees);

        // fee + royalty goese to BIB treasury
        if(order.payMethod == PayMethod.PAY_BNB){
            require(msg.value >= order.price, "INSUFFICIENT_FUNDS");
            payable(address(order.owner)).transfer(amount);

            collectFeeWhenSellerAsMaker(PayMethod.PAY_BNB, fees);

            // refunds
            if(msg.value > order.price){
                payable(address(msg.sender)).transfer(msg.value.sub(order.price));
            }
        } else if(order.payMethod == PayMethod.PAY_BUSD){
            busdContract.transferFrom(msg.sender, order.owner, amount);

            collectFeeWhenSellerAsMaker(PayMethod.PAY_BUSD, fees);
        } else {
            // walk around to avoid being charged by the bib token
            bibContract.transferFrom(msg.sender, address(this), order.price);
            bibContract.transfer(order.owner, amount);

            collectFeeWhenSellerAsMaker(PayMethod.PAY_BIB, fees);
        }

        // send token 
        IERC721(address(order.issuer)).transferFrom(address(this), msg.sender, order.tokenId);

        emit MakeDeal(
            msg.sender,
            order.owner,
            msg.sender,
            order.issuer,
            order.tokenId,
            order.payMethod,
            order.price,
            fees);

        (bool exist, Offer memory offer) = getOffer(order.issuer, order.tokenId, msg.sender);
        if(exist){
            cancelOffer(offer.offerId);
        }

        // close order
        _closeOrder(orderId);
    }

    // Owner accept the offer and make a deal
    function acceptOffer(uint offerId) 
    public  override payable whenNotPaused{
        Offer storage offer = offerTb[offerId];
        require(address(0) != offer.issuer, "INVALID_OFFER");
        require(msg.sender != offer.buyer, "CANT_MAKE_DEAL_WITH_SELF");
        require(offer.expiration > block.timestamp, "OFFER_EXPIRED");

        // check if has order
        Order memory order = getOrder(offer.issuer, offer.tokenId);
        if(address(0) == order.owner){
            require(isOwner(offer.issuer, offer.tokenId, msg.sender), "NOT_OWNER");
        } else {
            require(order.owner == msg.sender, "NOT_OWNER");
        }

        // caculate sales
       (uint txFee, uint royaltyFee )= caculateFees(offer.bid);
        uint fees = txFee.add(royaltyFee);
        uint amount = offer.bid.sub(fees);

        // fee + royalty goese to BIB treasury
        if(offer.payMethod == PayMethod.PAY_BNB){
            payable(address(msg.sender)).transfer(amount);
            collectFeeWhenBuyerAsMaker(PayMethod.PAY_BNB, fees);
        } else if(offer.payMethod == PayMethod.PAY_BUSD){
            busdContract.transfer(msg.sender, amount);
            collectFeeWhenBuyerAsMaker(PayMethod.PAY_BUSD, fees);
        } else {
            bibContract.transfer(msg.sender, amount);
            collectFeeWhenBuyerAsMaker(PayMethod.PAY_BIB, fees);
        }

        // If has no order then send from owner otherwise send from this
         if(address(0) == order.owner){
            IERC721(address(offer.issuer)).transferFrom(msg.sender, offer.buyer, offer.tokenId);
        } else {
            IERC721(address(offer.issuer)).transferFrom(address(this), offer.buyer, offer.tokenId);
        }
        require(isOwner(offer.issuer, offer.tokenId, offer.buyer), "ERC721_FALED_TRANSFER");

        emit MakeDeal(
            msg.sender,
            msg.sender,
            offer.buyer,
            offer.issuer,
            offer.tokenId,
            offer.payMethod,
            offer.bid,
            fees
        );

        // liquadity offer and order if exist
        if(order.owner == msg.sender){
            _closeOrder(order.orderId);
        }

        _cancleOffer(offerId);
    }
    
    // Owner updates order price
    function updateOrderPrice(uint orderId, uint price) 
    public override payable whenNotPaused{
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");
        require(msg.sender == order.owner, "SHOULD_BE_ORDER_OWNER");
        require(order.expiration > block.timestamp, "ORDER_EXPIRED");
        require(price > 0, "PRICE_LTE_ZERO");

        emit UpdateOrderPrice(msg.sender, orderId, order.price, price);
        order.price = price;
        order.mt = block.timestamp;
    }

    function _closeOrder(uint orderId) internal {
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");

        uint[] storage userOrders = userOrdersTb[order.owner];
        for(uint i = 0; i < userOrders.length; i++){
           if(orderTb[userOrders[i]].orderId == orderId){
                userOrders[i] = userOrders[userOrders.length - 1];
                userOrders.pop();
                break;
           }
        }

        delete orderTb[orderId];
        delete tokenOrderTb[order.issuer][order.tokenId];
        
        emit CloseOrder(msg.sender, orderId);
    }

    // Owner close the specific order if not dealed
    function closeOrder(uint orderId)
     public override whenNotPaused{
        Order storage order = orderTb[orderId];
        require(address(0) != order.issuer,"INVALID_ORDER");
        require(msg.sender == order.owner, "SHOULD_BE_ORDER_OWNER");

        IERC721(address(order.issuer)).transferFrom(address(this), order.owner, order.tokenId);
        
        _closeOrder(orderId);
    }

    function hasOffer(address issuer, uint tokenId, address user) 
    public view returns(bool){
        uint[] storage offserIds = tokenOffersTb[issuer][tokenId];
        for(uint i = 0; i < offserIds.length; i++){
            if(offerTb[offserIds[i]].buyer == user){
                return true;
            }
        }
        return false;
    } 

    function getOffer(address issuer, uint tokenId, address user) 
    public view returns(bool, Offer memory){
        Offer memory ret;
        uint[] storage offserIds = tokenOffersTb[issuer][tokenId];
        for(uint i = 0; i < offserIds.length; i++){
            if(offerTb[offserIds[i]].buyer == user){
                return (true, offerTb[offserIds[i]]);
            }
        }
        return (false, ret);
    } 

    // Buyer make a offer to the specific order
    function makeOffer(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration)
     public override payable whenNotPaused{
        require(address(0) != issuer,"INVALID_ADDRESS");
        require(!isOwner(issuer, tokenId, msg.sender), "CANT_MAKE_OFFER_WITH_SELF");
        require(!hasOffer(issuer, tokenId, msg.sender), "HAS_MADE_OFFER");
        require(expiration > block.timestamp, "EXPIRATION_TOOL_SMALL");
        require(price > 0, "PRICE_NOT_BE_ZEROR");

        _charge(payMethod, price);

        Offer memory offer = Offer({
            offerId: nextOfferIndex++,
            issuer: issuer,
            tokenId: tokenId,
            buyer: msg.sender,
            payMethod: payMethod,
            bid: price,
            mt: block.timestamp,
            expiration: expiration
        });
        offerTb[offer.offerId] = offer;
        tokenOffersTb[issuer][tokenId].push(offer.offerId);
        userOffersTb[msg.sender].push(offer.offerId);

        emit MakeOffer(msg.sender, offer.issuer, offer.tokenId, 
        offer.offerId, offer.payMethod, offer.bid, offer.mt, offer.expiration);
    }

    function _updateOfferPrice(Offer memory offer, uint price) internal {
        uint delt  = 0;
        if(offer.bid > price){
            delt = offer.bid.sub(price);
            if(offer.payMethod == PayMethod.PAY_BNB){
                payable(address(msg.sender)).transfer(delt);
            } else if(offer.payMethod == PayMethod.PAY_BUSD){
                busdContract.transfer(msg.sender, delt);
            } else {
                bibContract.transfer(msg.sender, delt);
            }
        } else {
            delt = price.sub(offer.bid);
            if(offer.payMethod == PayMethod.PAY_BNB){
                require(msg.value >= delt, "INSUFFICIENT_FUNDS");
                // refunds
                if(msg.value > delt){
                    payable(address(msg.sender)).transfer(msg.value.sub(delt));
                }
            } else if(offer.payMethod == PayMethod.PAY_BUSD){
                busdContract.transferFrom(msg.sender, address(this), delt);
            } else {
                bibContract.transferFrom(msg.sender, address(this), delt);
            }
        }
    }

    // Buyer udpate offer bid price
    function updateOfferPrice(uint offerId, uint price) 
    public override payable whenNotPaused{
        Offer storage offer = offerTb[offerId];
        require(msg.sender == offer.buyer, "SHOULD_BE_OFFER_MAKER");
        require(offer.expiration > block.timestamp, "OFFER_EXPIRED");
        require(price > 0, "PRICE_NOT_BE_ZEROR");

        _updateOfferPrice(offer, price);
    
        emit UpdateOfferPrice(msg.sender, offer.offerId, offer.bid, price);

        offer.bid = price;
        offer.mt = block.timestamp;
    }

    function _refund(PayMethod payMethod, uint amount) internal {
        if(payMethod == PayMethod.PAY_BNB){
            payable(msg.sender).transfer(amount);
        } else if(payMethod == PayMethod.PAY_BUSD){
            busdContract.transferFrom(address(this), msg.sender, amount);
        } else {
            bibContract.transferFrom(address(this), msg.sender, amount);
        }
    }

    function _charge(PayMethod payMethod, uint amount) internal {
        if(payMethod == PayMethod.PAY_BNB){
            require(msg.value >= amount, "INSUFFICIENT_FUNDS");
            // refunds
            if(msg.value > amount){
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else if(payMethod == PayMethod.PAY_BUSD){
            busdContract.transferFrom(msg.sender, address(this), amount);
        } else {
            bibContract.transferFrom(msg.sender, address(this), amount);
        }
    }

    function updateOffer(uint offerId, PayMethod payMethod, uint price, uint expiration) 
    public override payable{
        Offer storage offer = offerTb[offerId];
        require(msg.sender == offer.buyer, "SHOULD_BE_OFFER_MAKER");
        require(expiration > block.timestamp, "EXPIRATION_TOO_EARLY");
        require(price > 0, "PRICE_NOT_BE_ZEROR");

        // update or charge
        if(payMethod == offer.payMethod){
            _updateOfferPrice(offer, price);
        } else {
            // refund 
            _refund(offer.payMethod, offer.bid);
     
            // recharge
            _charge(payMethod, price);
        }
        offer.payMethod = payMethod;
        offer.bid = price;
        offer.expiration = expiration;
        offer.mt = block.timestamp;

        emit UpdateOffer(msg.sender, offer.issuer, offer.tokenId, 
        offer.offerId, offer.payMethod, offer.bid, offer.mt, offer.expiration);
    }

    function _cancleOffer(uint offerId) internal {
        Offer storage offer = offerTb[offerId];

        // remove from token offer tb
        uint[] storage offers = tokenOffersTb[offer.issuer][offer.tokenId];
        for(uint i = 0; i < offers.length; i++){
           if(offerTb[offers[i]].offerId == offerId){
                offers[i] = offers[offers.length - 1];
                offers.pop();
                break;
           }
        }
        delete offerTb[offerId];

        // remove from user offers tb
        uint[] storage offerIds = userOffersTb[offer.buyer];
        for(uint i = 0; i < offerIds.length; i++){
           if(offerIds[i] == offerId){
                offerIds[i] = offerIds[offerIds.length - 1];
                offerIds.pop();
                break;
           }
        }

        emit CancelOffer(msg.sender, offerId);
    }

    // Buyer cancle the specific order
    function cancelOffer(uint offerId) public override whenNotPaused{
        Offer storage offer = offerTb[offerId];
        require(msg.sender == offer.buyer, "SHOULD_BE_OFFER_MAKER");

        if(offer.payMethod == PayMethod.PAY_BNB){
            payable(address(offer.buyer)).transfer(offer.bid);
        } else if(offer.payMethod == PayMethod.PAY_BUSD){
            busdContract.transfer(offer.buyer, offer.bid);
        } else {
            bibContract.transfer(offer.buyer, offer.bid);
        }

        _cancleOffer(offerId);
    }

    function cancelAllOffersByIssuer(address issuer)
    public override whenNotPaused {
        uint[] storage offerIds = userOffersTb[msg.sender];

        for(uint i = 0; i < offerIds.length;){
            Offer storage offer = offerTb[offerIds[i]];

            if(offer.issuer != issuer) {
                i++;
                continue;
            }

            // remove from offersByIssuer
            uint[] storage offersByIssuer = tokenOffersTb[offer.issuer][offer.tokenId];
            for(uint j = 0; j < offersByIssuer.length; j++){
                if(offersByIssuer[j] == offerIds[i]){
                    offersByIssuer[j] = offersByIssuer[offersByIssuer.length - 1];
                    offersByIssuer.pop();
                    break;
                }
            }

            // remove form offerTab
            delete offerTb[offerIds[i]];

            emit CancelOffer(msg.sender, offerIds[i]);

            // remove from userOffersTb
            offerIds[i] = offerIds[offerIds.length - 1];
            offerIds.pop();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/**
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    using SafeMath for uint;

    uint constant internal PRECISION = 1e18;

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function precisionDiv(uint256 a, uint256 b)internal pure returns (uint256) {
     a = a.mul(PRECISION);
     a = div(a, b);
     return div(a, PRECISION);
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }

  function exp(uint256 a, uint256 n) internal pure returns(uint256){
    require(n >= 0, "SafeMath: n less than 0");
    uint256 result = 1;
    for(uint256 i = 0; i < n; i++){
        result = result.mul(10);
    }
    return a.mul(result);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library SafeCast {
    uint internal constant MAX_UINT = uint(int(-1));
    function toInt(uint value) internal pure returns(int){
        require(value < MAX_UINT, "CONVERT_OVERFLOW");
        return int(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISoccerStarNft {

     struct SoccerStar {
        string name;
        string country;
        string position;
        // range [1,4]
        uint256 starLevel;
        // range [1,4]
        uint256 gradient;
    }

    // roud->timeInfo
    struct TimeInfo {
        uint startTime;
        uint endTime;
        uint revealTime;
    }

    enum BlindBoxesType {
        presale,
        normal,
        supers,
        legend
    }

    enum PayMethod{
        PAY_BIB,
        PAY_BUSD
    }

    event Mint(
        address newAddress, 
        uint rount,
        BlindBoxesType blindBoxes, 
        uint256 tokenIdSt, 
        uint256 quantity, 
        PayMethod payMethod, 
        uint sales);
        
    function updateStarlevel(uint tokenId, uint starLevel) external;

    // whitelist functions
    function addUserQuotaPreRoundBatch(address[] memory users,uint[] memory quotas) external;
    function setUserQuotaPreRound(address user, uint quota) external;
    function getUserRemainningQuotaPreRound(address user) external view returns(uint);
    function getUserQuotaPreRound(address user) external view returns(uint);

    function getCardProperty(uint256 tokenId) external view returns(SoccerStar memory);

    // BUSD quota
    function setBUSDQuotaPerPubRound(uint round, uint quota) external;
    function getBUSDQuotaPerPubRound(uint round) external view returns(uint);
    function getBUSDUsedQuotaPerPubRound(uint round) external view returns(uint);

    // only allow protocol related contract to mint
    function protocolMint() external returns(uint tokenId);

    // only allow protocol related contract to mint to burn
    function protocolBurn(uint tokenId) external;

    // only allow protocol related contract to bind star property
    function protocolBind(uint tokenId, SoccerStar memory soccerStar) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ISoccerStarNftMarket {

    struct Offer {
        uint offerId;
        // token issure
        address issuer;
        // token id
        uint tokenId;
        // buyer who make the offer
        address buyer;
        // pay method
        PayMethod payMethod;
        // the price buyer offer
        uint bid;
        // the time when the offer modified
        uint mt;
        // expiration deadline 
        uint expiration;
    }

    struct Order {
        uint orderId;
        // the contract which issue the token
        address issuer;
        uint tokenId;
        address owner;
        PayMethod payMethod;
        // the time when the offer modified
        uint mt;
        uint price;
        uint expiration;
    }

    enum PayMethod {
        PAY_BNB,
        PAY_BUSD,
        PAY_BIB
    }

    event OpenOrder(
    address sender, address issuer, uint orderId, 
    uint tokenId, PayMethod payMethod, uint price, 
    uint mt, uint expiration);

    event UpdateOrder(
    address sender, address issuer, uint orderId, 
    uint tokenId, PayMethod payMethod, uint price, 
    uint mt, uint expiration);

    event MakeDeal(
        address sender,
        address owner,
        address buyer,
        address issuer,
        uint tokenId,
        PayMethod payMethod,
        uint price,
        uint fee
    );

    event UpdateOrderPrice(address sender, uint orderId, uint oldPrice, uint newPrice);
    event UpdateOfferPrice(address sender, uint offerId, uint oldPrice, uint newPrice);

    event CloseOrder(address sender, uint orderId);
    event CancelOffer(address sender, uint offerId);

    event MakeOffer(address sender, address issuer, uint tokenId, uint offerId,
                    PayMethod payMethod, uint price, uint mt,uint expiration);
    event UpdateOffer(address sender, address issuer, uint tokenId, uint offerId,
                    PayMethod payMethod, uint price, uint mt,uint expiration);

    function setRoyaltyRatio(uint feeRatio) external;

    function setFeeRatio(uint feeRatio) external;

    function getBlockTime() external view returns(uint);

    function isOriginOwner(address issuer, uint tokenId, address owner) external view returns(bool);

    // user create a order
    function openOrder(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration) payable external;

    // check if a token has a order to connected
    function hasOrder(address issuer,  uint tokenId) external view returns(bool);

    // return the order opened to the tokenId
    function getOrder(address issuer,  uint tokenId) external view returns(Order memory);

    // Owner close the specific order if not dealed
    function closeOrder(uint orderId) external;

    // get user orders by page
    function getUserOrdersByPage(address user, uint pageSt, uint pageSz) 
    external view returns(Order[] memory);

    // Buyer accept the price and makes a deal with the sepcific order
    function acceptOrder(uint orderId) external payable;
    
    // Owner updates order price
    function updateOrderPrice(uint orderId, uint price) external payable;

    function updateOrder(uint orderId, PayMethod payMethod, uint price, uint expiration) external payable;

    // Buyer make a offer to the specific order
    function makeOffer(address issuer, uint tokenId, PayMethod payMethod, uint price, uint expiration) external payable;

    // Owner accept the offer and make a deal
    function acceptOffer(uint offerId) external payable;

    // Buyer udpate offer bid price
    function updateOfferPrice(uint offerId, uint price) external payable;

    function updateOffer(uint offerId, PayMethod payMethod, uint price, uint expiration) external payable;

    // Buyer cancle the specific offer
    function cancelOffer(uint offerId) external;

    // Buyer cancle the offers by the specific issuer
    function cancelAllOffersByIssuer(address issuer) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title IBIBOracle interface
 * @notice Interface for the BIB oracle.
 **/

interface IBIBOracle {
  function BASE_CURRENCY() external view returns (address);

  function BASE_CURRENCY_UNIT() external view returns (uint256);

  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

interface IFeeCollector {
    function handleCollectBIB(uint amount) external;

    function handleCollectBUSD(uint amount) external;

    function handleCollectBNB(uint amount) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author BIB, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 internal lastInitializedRevision = 0;

   /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        uint256 revision = getRevision();
        require(revision > lastInitializedRevision, "Contract instance has already been initialized");

        lastInitializedRevision = revision;

        _;

    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure virtual returns(uint256);


    // Reserved storage space to allow for BIBout changes in the future.
    uint256[50] private ______gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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