// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title BLOCKALIAS
 * @dev A decentralized domain name system for blockchain addresses
 * @author BLOCKALIAS Team
 */
contract Project {
    
    // Struct to store alias information
    struct Alias {
        address owner;
        string aliasName;
        address targetAddress;
        uint256 registrationTime;
        uint256 expirationTime;
        bool isActive;
    }
    
    // Mappings
    mapping(string => Alias) public aliases;
    mapping(address => string[]) public userAliases;
    mapping(string => bool) public aliasExists;
    
    // Events
    event AliasRegistered(string indexed aliasName, address indexed owner, address indexed targetAddress);
    event AliasUpdated(string indexed aliasName, address indexed newTargetAddress);
    event AliasTransferred(string indexed aliasName, address indexed oldOwner, address indexed newOwner);
    
    // Constants
    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    uint256 public constant ALIAS_DURATION = 365 days;
    
    // Owner of the contract
    address public contractOwner;
    
    // Modifiers
    modifier onlyAliasOwner(string memory _aliasName) {
        require(aliases[_aliasName].owner == msg.sender, "Only alias owner can perform this action");
        _;
    }
    
    modifier aliasNotExists(string memory _aliasName) {
        require(!aliasExists[_aliasName], "Alias already exists");
        _;
    }
    
    modifier validAlias(string memory _aliasName) {
        require(bytes(_aliasName).length > 2 && bytes(_aliasName).length <= 32, "Alias must be 3-32 characters");
        _;
    }
    
    constructor() {
        contractOwner = msg.sender;
    }
    
    /**
     * @dev Register a new alias for a blockchain address
     * @param _aliasName The human-readable alias name
     * @param _targetAddress The blockchain address to map to
     */
    function registerAlias(string memory _aliasName, address _targetAddress) 
        external 
        payable 
        aliasNotExists(_aliasName) 
        validAlias(_aliasName) 
    {
        require(msg.value >= REGISTRATION_FEE, "Insufficient registration fee");
        require(_targetAddress != address(0), "Target address cannot be zero address");
        
        // Create new alias
        aliases[_aliasName] = Alias({
            owner: msg.sender,
            aliasName: _aliasName,
            targetAddress: _targetAddress,
            registrationTime: block.timestamp,
            expirationTime: block.timestamp + ALIAS_DURATION,
            isActive: true
        });
        
        // Update mappings
        aliasExists[_aliasName] = true;
        userAliases[msg.sender].push(_aliasName);
        
        emit AliasRegistered(_aliasName, msg.sender, _targetAddress);
    }
    
    /**
     * @dev Update the target address for an existing alias
     * @param _aliasName The alias to update
     * @param _newTargetAddress The new target address
     */
    function updateAlias(string memory _aliasName, address _newTargetAddress) 
        external 
        onlyAliasOwner(_aliasName) 
    {
        require(_newTargetAddress != address(0), "New target address cannot be zero address");
        require(aliases[_aliasName].expirationTime > block.timestamp, "Alias has expired");
        require(aliases[_aliasName].isActive, "Alias is not active");
        
        aliases[_aliasName].targetAddress = _newTargetAddress;
        
        emit AliasUpdated(_aliasName, _newTargetAddress);
    }
    
    /**
     * @dev Resolve an alias to get the mapped blockchain address
     * @param _aliasName The alias to resolve
     * @return The blockchain address mapped to the alias
     */
    function resolveAlias(string memory _aliasName) 
        external 
        view 
        returns (address) 
    {
        require(aliasExists[_aliasName], "Alias does not exist");
        require(aliases[_aliasName].expirationTime > block.timestamp, "Alias has expired");
        require(aliases[_aliasName].isActive, "Alias is not active");
        
        return aliases[_aliasName].targetAddress;
    }
    
    /**
     * @dev Transfer ownership of an alias to another address
     * @param _aliasName The alias to transfer
     * @param _newOwner The new owner address
     */
    function transferAlias(string memory _aliasName, address _newOwner) 
        external 
        onlyAliasOwner(_aliasName) 
    {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(aliases[_aliasName].expirationTime > block.timestamp, "Alias has expired");
        
        address oldOwner = aliases[_aliasName].owner;
        aliases[_aliasName].owner = _newOwner;
        
        // Update user aliases mapping
        userAliases[_newOwner].push(_aliasName);
        
        emit AliasTransferred(_aliasName, oldOwner, _newOwner);
    }
    
    /**
     * @dev Get all aliases owned by a specific address
     * @param _owner The owner address
     * @return Array of alias names
     */
    function getUserAliases(address _owner) 
        external 
        view 
        returns (string[] memory) 
    {
        return userAliases[_owner];
    }
    
    /**
     * @dev Get alias information
     * @param _aliasName The alias name
     * @return Alias struct information
     */
    function getAliasInfo(string memory _aliasName) 
        external 
        view 
        returns (Alias memory) 
    {
        require(aliasExists[_aliasName], "Alias does not exist");
        return aliases[_aliasName];
    }
    
    /**
     * @dev Check if an alias is available for registration
     * @param _aliasName The alias to check
     * @return True if available, false otherwise
     */
    function isAliasAvailable(string memory _aliasName) 
        external 
        view 
        returns (bool) 
    {
        return !aliasExists[_aliasName];
    }
    
    /**
     * @dev Withdraw contract balance (only contract owner)
     */
    function withdraw() external {
        require(msg.sender == contractOwner, "Only contract owner can withdraw");
        payable(contractOwner).transfer(address(this).balance);
    }
    
    /**
     * @dev Get contract balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
