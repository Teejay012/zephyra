// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Local Imports
import { IZephyraStableCoin } from "src/interface/IZephyraStableCoin.sol";
import { OracleLib } from "./libraries/OracleLib.sol";

// OpenZeppelin Imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


// Chainlink Imports
import { AggregatorV3Interface } from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/*
 * @title ZephyraVault
 * @author Peace Teejay(EtherEngineer)
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our ZUSD system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the ZUSD.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming ZUSD, as well as depositing and withdrawing collateral.
 */



contract ZephyraVault is Ownable, ReentrancyGuard {

    // ══════════════════════════════════════════
    // ══ ERRORS
    // ══════════════════════════════════════════

    error ZephyraVault__InvalidZUSDContractAddress();
    error ZephyraVault__CollateralTokenAndPricefeedMismatch();
    error ZephyraVault__InvalidCollateralContractAddress();
    error ZephyraVault__AmountShouldBeGreaterThanZero();
    error ZephyraVault__NotApprovedToken();
    error ZephyraVault__TransferFailed();
    error ZephyraVault__BrokenHealthFactor(uint256 healthFactor);
    error ZephyraVault__MintFailed();
    error ZephyraVault__InvalidAddress();
    error ZephyraVault__InsufficientCollateral();
    error ZephyraVault__InsufficientBalance();
    error ZephyraVault__HealthFactorOkay(uint256 healthFactor);
    error ZephyraVault__HealthFactorNotOkay();
    error ZephyraVault__LiquidatorHealthFactorNotOkay(uint256 healthFactor);
    error ZephyraVault__DebtToCoverShouldNotBeGreaterThanBalance();
    error ZephyraVault__AmountGreaterThanBalance(uint256 amount, uint256 balance);


    // ══════════════════════════════════════════
    // ══ TYPES
    // ══════════════════════════════════════════

    using OracleLib for AggregatorV3Interface;



    // ══════════════════════════════════════════
    // ══ STATE VARIABLES
    // ══════════════════════════════════════════

    address[] private users;

    IZephyraStableCoin private immutable i_zusd;

    address[] private s_collateralTokenAddresses;

    mapping(address token => address priceFeed) private s_tokenToPriceFeed;
    mapping(address user => mapping(address token => uint256 amount)) private s_userToTokenDeposits;
    mapping(address user => uint256 zusdBalance) private s_userToZusdBalance;

    mapping(address user => bool isAdded) private s_userAdded;

    uint256 private constant MIN_HEALTH_FACTOR = 1e18; // 1.0 in 18 decimals
    uint256 private constant PRECISION = 1e18;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 50% liquidation threshold
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10;

    uint256 private s_zusdGains;

    // ══════════════════════════════════════════
    // ══ EVENTS
    // ══════════════════════════════════════════

    event CollateralDeposited(address indexed user, address indexed collateralToken, uint256 amount);
    event ZusdMinted(address indexed user, uint256 amount);
    event collateralRedeemed(address indexed from, address indexed to, address indexed collateralToken, uint256 amount);

    // ══════════════════════════════════════════
    // ══ MODIFIERS
    // ══════════════════════════════════════════

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert ZephyraVault__AmountShouldBeGreaterThanZero();
        }
        _;
    }

    modifier approvedCollateralToken(address _collateralTokenAddress) {
        if (_collateralTokenAddress == address(0)) {
            revert ZephyraVault__InvalidCollateralContractAddress();
        }
        if (s_tokenToPriceFeed[_collateralTokenAddress] == address(0)) {
            revert ZephyraVault__NotApprovedToken();
        }
        _;
    }


    // ══════════════════════════════════════════
    // ══ CONSTRUCTOR
    // ══════════════════════════════════════════

    constructor(IZephyraStableCoin _zusd, address[] memory _collateralTokenAddresses, address[] memory _priceFeeds) Ownable(msg.sender) {
        if(_collateralTokenAddresses.length != _priceFeeds.length) {
            revert ZephyraVault__CollateralTokenAndPricefeedMismatch();
        }

        for(uint256 i = 0; i < _collateralTokenAddresses.length; i++) {
            address token = _collateralTokenAddresses[i];
            address priceFeed = _priceFeeds[i];

            if (token == address(0) || priceFeed == address(0)) {
                revert ZephyraVault__InvalidCollateralContractAddress();
            }

            s_collateralTokenAddresses.push(token);
            s_tokenToPriceFeed[token] = priceFeed;
        }

        if (address(_zusd) == address(0)) {
            revert ZephyraVault__InvalidZUSDContractAddress();
        }
        i_zusd = _zusd;
    }

    // ══════════════════════════════════════════
    // ══ PUBLIC AND EXTERNAL FUNCTIONS
    // ══════════════════════════════════════════

    function depositCollateralAndMintZusd(address _collateralTokenAddress, uint256 _collateralAmount, uint256 _zusdAmount) 
        external 
        nonReentrant
    {
        depositCollateral(_collateralTokenAddress, _collateralAmount);
        mintZusd(_zusdAmount);
    }





    function depositCollateral(address _collateralTokenAddress, uint256 _amount) 
        public 
        moreThanZero(_amount)
        approvedCollateralToken(_collateralTokenAddress)
    {
        if (_collateralTokenAddress == address(0)) {
            revert ZephyraVault__InvalidCollateralContractAddress();
        }

        if (s_tokenToPriceFeed[_collateralTokenAddress] == address(0)) {
            revert ZephyraVault__CollateralTokenAndPricefeedMismatch();
        }

        s_userToTokenDeposits[msg.sender][_collateralTokenAddress] += _amount;

        emit CollateralDeposited(msg.sender, _collateralTokenAddress, _amount);

        // Check if the user is already added to the users array
        if (!s_userAdded[msg.sender]) {
            users.push(msg.sender);
            s_userAdded[msg.sender] = true;
        }

        bool success = IERC20(_collateralTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if(!success){
            revert ZephyraVault__TransferFailed();
        }
    }











    function redeemCollateralForZusd(address _collateralTokenAddress, uint256 _zusdAmount) 
        external 
        moreThanZero(_zusdAmount)
        approvedCollateralToken(_collateralTokenAddress)
    {
        uint256 collateralBalanceInUsd = getCollateralValue(msg.sender);
        uint256 collateralAmountFromUsd = getTokenAmountFromUsd(_collateralTokenAddress, _zusdAmount);

        if (collateralBalanceInUsd < _zusdAmount) {
            revert ZephyraVault__InsufficientBalance();
        }

        _burnZusd(_zusdAmount, msg.sender, msg.sender);
        redeemCollateral(_collateralTokenAddress, collateralAmountFromUsd);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function redeemCollateral(address _collateralTokenAddress, uint256 _collateralAmount) 
        public 
        moreThanZero(_collateralAmount)
        approvedCollateralToken(_collateralTokenAddress)
    {
        _redeemCollateral(_collateralTokenAddress, _collateralAmount, msg.sender, msg.sender);

        _revertIfHealthFactorIsBroken(msg.sender);
    }










    function mintZusd(uint256 _amount) public moreThanZero(_amount) nonReentrant {
        s_userToZusdBalance[msg.sender] += _amount;

        _revertIfHealthFactorIsBroken(msg.sender);

        emit ZusdMinted(msg.sender, _amount);

        bool success = i_zusd.mint(msg.sender, _amount);
        if (!success) {
            revert ZephyraVault__MintFailed();
        }
    }








    function burnZusd(uint256 _amount) public moreThanZero(_amount) nonReentrant {
        _burnZusd(_amount, msg.sender, msg.sender);

        _revertIfHealthFactorIsBroken(msg.sender);
    }


    




    function liquidate(address _collateralTokenAddress, address _user, uint256 _debtToCover) 
        public 
        moreThanZero(_debtToCover) 
        approvedCollateralToken(_collateralTokenAddress) 
        nonReentrant 
    {
        uint256 startingHealthFactor = _healthFactor(_user);
        uint256 liquidatorHealthFactor = _healthFactor(msg.sender);

        if (startingHealthFactor >= MIN_HEALTH_FACTOR) {
            revert ZephyraVault__HealthFactorOkay(startingHealthFactor);
        }

        if (liquidatorHealthFactor < MIN_HEALTH_FACTOR) {
            revert ZephyraVault__LiquidatorHealthFactorNotOkay(liquidatorHealthFactor);
        }

        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(_collateralTokenAddress, _debtToCover);

        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;

        uint256 userCollateralBalance = s_userToTokenDeposits[_user][_collateralTokenAddress];
        uint256 remainingCollateralBalance = userCollateralBalance - totalCollateralToRedeem;

        uint256 zusdGains = getUsdValue(_collateralTokenAddress, remainingCollateralBalance);

        s_zusdGains += remainingCollateralBalance;

        // s_userToTokenDeposits[msg.sender][_collateralTokenAddress] += totalCollateralToRedeem; // Error, adding collateral after transfering the amount

        if(s_userToZusdBalance[_user] < _debtToCover) {
            revert ZephyraVault__DebtToCoverShouldNotBeGreaterThanBalance();
        }

        _burnZusd(_debtToCover, _user, msg.sender);
        _redeemCollateralWithBonus(_collateralTokenAddress, totalCollateralToRedeem, _user, msg.sender);

        uint256 endingHealthFactor = _healthFactor(_user);
        if(endingHealthFactor < startingHealthFactor){
            revert ZephyraVault__HealthFactorNotOkay();
        }

        _revertIfHealthFactorIsBroken(_user);
    }




    function swapZusdToCollateral(address _collateralTokenAddress, uint256 _zusdAmount) 
        external 
        moreThanZero(_zusdAmount) 
        approvedCollateralToken(_collateralTokenAddress) 
        nonReentrant 
    {
        if (s_userToZusdBalance[msg.sender] < _zusdAmount) {
            revert ZephyraVault__InsufficientBalance();
        }

        uint256 collateralAmount = getTokenAmountFromUsd(_collateralTokenAddress, _zusdAmount);

        s_userToZusdBalance[msg.sender] -= _zusdAmount;
        s_userToTokenDeposits[msg.sender][_collateralTokenAddress] += collateralAmount;

        emit CollateralDeposited(msg.sender, _collateralTokenAddress, collateralAmount);

        bool success = i_zusd.transferFrom(msg.sender, address(this), _zusdAmount);

        if (!success) {
            revert ZephyraVault__TransferFailed();
        }

        i_zusd.burn(_zusdAmount);

    }






    function withdrawGains(address _to) external onlyOwner nonReentrant {
        if (_to == address(0)) {
            revert ZephyraVault__InvalidAddress();
        }
        if (s_zusdGains == 0) {
            revert ZephyraVault__InsufficientBalance();
        }

        s_zusdGains = 0;

        bool success = i_zusd.transfer(_to, s_zusdGains);

        if (!success) {
            revert ZephyraVault__TransferFailed();
        }

    }










    // ══════════════════════════════════════════
    // ══ INTERNAL FUNCTIONS
    // ══════════════════════════════════════════

    function _revertIfHealthFactorIsBroken(address _user) internal view {
        uint256 healthFactor = _healthFactor(_user);
        if (healthFactor < MIN_HEALTH_FACTOR) {
            revert ZephyraVault__BrokenHealthFactor(healthFactor);
        }
    }

    function _healthFactor(address _user) internal view returns (uint256) {
        (uint256 collateralAmountInUsd, uint256 totalZusdMinted) = _accountInformation(_user);

        if (totalZusdMinted == 0) {
            return type(uint256).max; // No debt, health factor is infinite
        }

        uint256 collateraAdjustedForThreshold = (collateralAmountInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateraAdjustedForThreshold * PRECISION) / totalZusdMinted;
    }

    function _accountInformation(address _user) internal view returns (uint256 totalCollateralValue, uint256 totalZusdMinted) {
        totalCollateralValue = getCollateralValue(_user);
        totalZusdMinted = s_userToZusdBalance[_user];
    }

    function _burnZusd(uint256 _amountZusdToBurn, address _onBehalfOf, address _zusdFrom) private {
        if (s_userToZusdBalance[_onBehalfOf] < _amountZusdToBurn) {
            revert ZephyraVault__AmountGreaterThanBalance(_amountZusdToBurn, s_userToZusdBalance[_onBehalfOf]);
        }
        s_userToZusdBalance[_onBehalfOf] -= _amountZusdToBurn;

        bool success = i_zusd.transferFrom(_zusdFrom, address(this), _amountZusdToBurn);
        // This conditional is hypothetically unreachable
        if (!success) {
            revert ZephyraVault__TransferFailed();
        }
        i_zusd.burn(_amountZusdToBurn);
    }

    function _redeemCollateral(address _tokenCollateralAddress, uint256 _collateralAmount, address _from, address _to) internal moreThanZero(_collateralAmount) approvedCollateralToken(_tokenCollateralAddress) {
        if (_from == address(0) || _to == address(0)) {
            revert ZephyraVault__InvalidAddress();
        }
        if (s_userToTokenDeposits[_to][_tokenCollateralAddress] < _collateralAmount) {
            revert ZephyraVault__InsufficientCollateral();
        }
        
        s_userToTokenDeposits[_from][_tokenCollateralAddress] -= _collateralAmount;

        emit collateralRedeemed(_from, _to, _tokenCollateralAddress, _collateralAmount);

        bool success = IERC20(_tokenCollateralAddress).transfer(_to, _collateralAmount);

        if (!success) {
            revert ZephyraVault__TransferFailed();
        }
    }

    function _redeemCollateralWithBonus(address _tokenCollateralAddress, uint256 _collateralAmount, address _from, address _to) internal moreThanZero(_collateralAmount) approvedCollateralToken(_tokenCollateralAddress) {
        if (_from == address(0) || _to == address(0)) {
            revert ZephyraVault__InvalidAddress();
        }
        if (s_userToTokenDeposits[_to][_tokenCollateralAddress] < _collateralAmount) {
            revert ZephyraVault__InsufficientCollateral();
        }


        if (s_userToTokenDeposits[_from][_tokenCollateralAddress] < _collateralAmount) {
            revert ZephyraVault__InsufficientCollateral();
        }
        
        s_userToTokenDeposits[_from][_tokenCollateralAddress] = 0;

        emit collateralRedeemed(_from, _to, _tokenCollateralAddress, _collateralAmount);

        bool success = IERC20(_tokenCollateralAddress).transfer(_to, _collateralAmount);

        if (!success) {
            revert ZephyraVault__TransferFailed();
        }
    }

    function _calculateHealthFactor(
        uint256 collateralValueInUsd,
        uint256 totalDscMinted
    )
        internal
        pure
        returns (uint256)
    {
        if (totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }



    // ══════════════════════════════════════════
    // ══ VIEW FUNCTIONS
    // ══════════════════════════════════════════

    function getCollateralValue(address _user) public view returns (uint256 tokenCollateralUsd) {
        for (uint256 i = 0; i < s_collateralTokenAddresses.length; i++) {
            address token = s_collateralTokenAddresses[i];
            // address priceFeed = s_tokenToPriceFeed[token];
            uint256 tokenAmount = s_userToTokenDeposits[_user][token];
            tokenCollateralUsd += getUsdValue(token, tokenAmount);
        }

        return tokenCollateralUsd;
    }

    function getUsdValue(address _token, uint256 _amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_tokenToPriceFeed[_token]);
        (, int256 price, , , ) = priceFeed.staleCheckLatestRoundData();
        return(uint256(price) * ADDITIONAL_FEED_PRECISION * _amount) / PRECISION;
    }

    function getTokenAmountFromUsd(address _token, uint256 _amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_tokenToPriceFeed[_token]);
        (, int256 price, , , ) = priceFeed.staleCheckLatestRoundData();
        return (_amount * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    // ══════════════════════════════════════════
    // ══ GETTERS
    // ══════════════════════════════════════════

    function getAccountInformation(address _user)
        public
        view
        returns (uint256 collateralAmountInUsd, uint256 totalUsdMinted)
    {
        (collateralAmountInUsd, totalUsdMinted) = _accountInformation(_user);
    }

    function getCalculatedHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValueInUsd
    )
        external
        pure
        returns (uint256)
    {
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }

    function getMintedZusd(address _user) external view returns (uint256) {
        return s_userToZusdBalance[_user];
    }

    function getHealthFactor(address _user) external view returns (uint256) {
        return _healthFactor(_user);
    }

    function getUserCollateralBalance(address _user, address _token) external view returns (uint256) {
        return s_userToTokenDeposits[_user][_token];
    }

    function getZusdGains() external view returns (uint256) {
        return s_zusdGains;
    }

    function getUsers() external view returns (address[] memory) {
        return users;
    }


    // ══════════════════════════════════════════
    // ══ TESTING FUNCTIONS
    // ══════════════════════════════════════════

    // They'll be commented out before deployment
    
    // function updateUserCollateralPrice(address _collateral, address _user, uint256 _amount) public {
    //     s_userToTokenDeposits[_user][_collateral] = _amount;
    // }

    // function updateMintedValue(address _user, uint256 _amount) public {
    //     s_userToZusdBalance[_user] = _amount;
    // }
}