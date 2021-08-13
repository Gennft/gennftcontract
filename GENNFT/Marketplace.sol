// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./GenNFT.sol";


contract GEN {
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {}
    function approve(address spender, uint256 amount) public returns (bool) {}
    function transfer(address recipient, uint256 amount) public returns (bool) {}
    function allowance(address owner, address spender) public view returns (uint256) {}
}

contract Marketplace is AccessControl {

    address private _owner;
    address private genReceiver;

    int maxQuantity = 1;

    struct GenProd {
        address owner;
        string name;
        string description;
        uint256 price;
        int quantity;
        uint8 flag;
    }   
    
    bytes32 public constant PRODUCE_ROLE = keccak256("PRODUCE_ROLE");
    
    mapping (string => GenProd) public genProds;
    string [] hashes;
    
    GenNFT gt;
    GEN gen;
    
    constructor(GenNFT _gt, address _gen) {
        gt = _gt;
        gen = GEN(address(_gen));
        _setupRole(PRODUCE_ROLE, _msgSender());
        _owner = _msgSender();
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function setProduceRole(address _creator) external onlyOwner {
        _setupRole(PRODUCE_ROLE, _creator);
    }

    function removeProduceRole(address _creator) external onlyOwner {
        revokeRole(PRODUCE_ROLE, _creator);
    }
    
    function setGenReceiver(address payable _receiver) external onlyOwner {
        genReceiver = _receiver;
    }

    function getGenReceiver() public view returns (address) {
        return genReceiver;
    }

    function setMaxQuantity(int _quantity) public {
        maxQuantity = _quantity;
    }
    
    function getMaxQuantity() public view returns(int) {
        return maxQuantity;
    }
    
    function addNewProduction(string memory _name, string memory _description, uint256 _price, int _quantity, string memory _hash) public returns (bool) {
        require(hasRole(PRODUCE_ROLE, _msgSender()), "Must have produce role to mint");
        require(_quantity <= maxQuantity, "Quantity cannot be higher than the maximum quantity");
        require(genProds[_hash].flag != 1);
        genProds[_hash] = GenProd(_msgSender(), _name, _description, _price, _quantity, 1);
        hashes.push(_hash);
        return true;
    }
    
    function getProdList() public view returns(string[] memory){
        return hashes;
    }
    
    function getProdByHash(string memory _hash) public view returns(GenProd memory){
        return genProds[_hash];
    }
    
    function buy(address to, string memory _hash, uint256 _amount ) public payable returns (int) {
        require(genProds[_hash].quantity >= 1, "Must have quantity more than 1");
        require(_amount == genProds[_hash].price, "Amount should be same with price");
        require(gen.transferFrom(msg.sender, genProds[_hash].owner, _amount), "ERC20: transfer amount exceeds allowance");
        gt.mint(to, _hash);
        genProds[_hash].quantity = genProds[_hash].quantity - 1;
        return genProds[_hash].quantity;
    }
}