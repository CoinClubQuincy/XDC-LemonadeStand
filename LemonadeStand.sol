pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT 
// "1000000000000000000"\

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./SHARE.sol";
import "hardhat/console.sol";

interface lemonadeStand_interface {
    function GlassOfLemonade(uint _amount)external payable returns(bool);
    function edit(string memory _description, uint _price, bool _OpenStatus)external returns(bool);
}

contract lemonadeStand is XRCSHARE{ 
    string public description;
    uint public editorToken;
    //juice Glassses sold
    uint public totalLemonadeSold;

    uint public price = 1000000000000000000;
    bool public openStatus = false;

    event sold(string _newSale, uint _total);

    //------------------- Token 1 
    constructor(string memory _name,string memory _description,string memory _symbol,uint _totalSupply,string memory _URI)XRCSHARE(_name,_symbol,_totalSupply,_URI){
        description = _description;
        editorToken = _totalSupply +1;
        totalLemonadeSold = _totalSupply + 2;
        console.log(address(this));
        //------------------- Token 2
        _mint(msg.sender,editorToken,3,"");
    }

    modifier OnlyEditor{
        require(balanceOf(msg.sender,editorToken) > 0, "only an editor and edit contract");
        _;
    }
    modifier status{
        require(openStatus == true, "the store is currently closed");
    _;
    }

    //------------------- Token 3
    function GlassOfLemonade(uint _amount)public payable status returns(bool){
        uint total_price = price*_amount;
        require(msg.value >= total_price, "need more funds");
        _mint(address(this),totalLemonadeSold,_amount,"");
        uint total = refund(payable(msg.sender),total_price,msg.value);
        redirectValue(total_price);

        emit sold("more lemonade sold", _amount);
        return true;
    }

    function refund(address payable _buyer, uint _total,uint _amount)internal returns(uint) {
        if(_amount > _total){
            _buyer.transfer(_amount - _total);
            return (_amount - _total);
        }
        return _amount;
    }

    function edit(string memory _description, uint _price, bool _OpenStatus)public OnlyEditor returns(bool){
        description =_description;
        price = _price;
        openStatus =_OpenStatus;

        return true;
    }

        //ERC1155Received fuctions
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}