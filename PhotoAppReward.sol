// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './libraries/Context.sol';
import "./interfaces/IERC20.sol";

contract PhotoAppReword is Context
{
    address private constant OBSR_CONTRACT = address(0x3cB6Be2Fc6677A63cB52B07AED523F93f5a06Cb4);
    //address private constant OBSR_CONTRACT = address(0xDe38B8287FB2556bE19767E8a6dD9Bd20cC15f75);
    IERC20 private _obsr_token;

    struct UserRPInfo
    {
        uint256         _myRP;
        uint256         _myReword;
    }

    struct RPInfo
	{
        uint256         _totalRP;
        uint256         _totalReword;
		mapping(address => UserRPInfo) _userRP;
	}
    mapping(uint64 => RPInfo) private _RPInfs;
    mapping(uint64 => address[]) private _RPInfsAccounts;

    address[] private _allow_address;

    event WriteRPInfo(address indexed from, uint64 date);

	constructor()
	{
        _obsr_token = IERC20(OBSR_CONTRACT);
        _allow_address.push(_msgSender());
    }

    function decimals() public pure returns (uint8) { return 8; }
    function decimalsOBSR() public view returns (uint8) { return _obsr_token.decimals(); }

    function transfer(address to, uint256 amount) public
    {
        require(_checkAllowAddress(_msgSender()), "Not Allow Address");
        require(amount > 0, "amount must be greater than zero");

        uint256 balance = _obsr_token.balanceOf(address(this));
        require(amount <= balance, "amount is greater than balance");

        _obsr_token.transfer(to, amount);
    }

    function transferReword(address[] memory accounts, uint256[] memory amounts) public
    {
        require(_checkAllowAddress(_msgSender()), "Not Allow Address");
        require(accounts.length > 0, "length of account is zero");
        require(accounts.length == amounts.length, "length of account and amount are different");

        uint256 balance = _obsr_token.balanceOf(address(this));
        uint256 currentSum = 0;

        for ( uint32 idx = 0; idx < accounts.length; idx++ )
        {
            require(amounts[idx] > 0, "amount must be greater than zero");
            unchecked {
                currentSum = currentSum + amounts[idx];
            }
            require(currentSum <= balance, "amounts is greater than balance");

            _obsr_token.transfer(accounts[idx], amounts[idx]);
        }
    }

    function writeRPInfo(uint64 date, uint256 totalRP, uint256 totalReword, address[] memory accounts, uint256[] memory myRP, uint256[] memory myReword) public
    {
        require(_checkAllowAddress(_msgSender()), "Not Allow Address");
        require(accounts.length > 0, "length of account is zero");
        require(accounts.length == myRP.length, "length of account and myRP are different");
        require(accounts.length == myReword.length, "length of account and myReword are different");

        _RPInfs[date]._totalRP = totalRP;
        _RPInfs[date]._totalReword = totalReword;
        for ( uint32 idx = 0; idx < accounts.length ; idx++ )
        {
            _RPInfs[date]._userRP[accounts[idx]] = UserRPInfo(myRP[idx], myReword[idx]);
            _RPInfsAccounts[date].push(accounts[idx]);
        }

        emit WriteRPInfo(_msgSender(), date);
    }

    function getRPInfo(uint64 date, address account) public view returns (uint256 totalRP, uint256 totalReword, uint256 myRP, uint256 myReword)
    {
        return (_RPInfs[date]._totalRP, _RPInfs[date]._totalReword, _RPInfs[date]._userRP[account]._myRP, _RPInfs[date]._userRP[account]._myReword);
    }

    function getRPAccountListFromDate(uint64 date) public view returns (address[] memory account)
    {
        return (_RPInfsAccounts[date]);
    }


    function addAllowAddress(address account) public
    {
        require(_checkAllowAddress(_msgSender()), "Not Allow Address");
        _allow_address.push(account);
    }

    function removeAllowAddress(address account) public
    {
        require(_checkAllowAddress(_msgSender()), "Not Allow Address");

        for ( uint8 i = 0 ; i < _allow_address.length ; i++ )
		{
			if ( _allow_address[i] == account )
			{
				_allow_address[i] = _allow_address[_allow_address.length-1];
				_allow_address.pop();
				break;
			}
		}
    }

    function getAllowAddress() public view returns (address[] memory)
    {
        return _allow_address;
    }

    function _checkAllowAddress(address account) private view returns (bool)
    {
        bool exist = false;
		for ( uint8 i = 0 ; i < _allow_address.length ; i++ )
		{
			if ( _allow_address[i] == account )
			{
				exist = true;
				break;
			}
		}
		return exist;
    }
}
