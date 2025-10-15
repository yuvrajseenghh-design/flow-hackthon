// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CompletionBadgeNFT — minimal, import-free ERC-721 for course/task completion badges
/// @notice No imports, no constructors. Call initialize() once (no arguments) after deployment to set owner.
contract CompletionBadgeNFT {
    // --- ERC721 storage ---
    string public name = "CompletionBadge";
    string public symbol = "CBADGE";

    // token id tracker
    uint256 private _currentTokenId;

    // Mapping tokenId => owner
    mapping(uint256 => address) private _owners;

    // Mapping owner => balance
    mapping(address => uint256) private _balances;

    // Mapping tokenId => approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping owner => operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Metadata base URI (owner-changeable)
    string private baseURI = "https://example.com/metadata/"; // change to your metadata host

    // --- Access control ---
    address public owner;
    bool private _initialized;

    /// @notice Emitted when a token is transferred (including mint)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @notice Emitted when an approval is set on a token
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @notice Emitted when an operator is approved or disapproved for an owner
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Emitted when base URI is updated
    event BaseURIChanged(string newBaseURI);

    // --- Initialization (no constructor) ---
    /// @notice Initialize contract owner (callable once). No inputs by design.
    function initialize() external {
        require(!_initialized, "Already initialized");
        owner = msg.sender;
        _initialized = true;
    }

    modifier onlyOwner() {
        require(_initialized, "Not initialized");
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier exists(uint256 tokenId) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        _;
    }

    // --- ERC721 view helpers ---
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Zero address");
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view exists(tokenId) returns (address) {
        return _owners[tokenId];
    }

    /// @notice Returns token URI as baseURI + tokenId (decimal)
    function tokenURI(uint256 tokenId) public view exists(tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    // --- Approvals and transfers (ERC-721 basics) ---
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(to != tokenOwner, "Approval to current owner");
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "Not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view exists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address _owner, address operator) public view returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved nor owner");
        require(ownerOf(tokenId) == from, "From mismatch");
        require(to != address(0), "Transfer to zero");

        _transfer(from, to, tokenId);
    }

    /// @notice safeTransferFrom without data
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice safeTransferFrom with data
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved nor owner");
        require(ownerOf(tokenId) == from, "From mismatch");
        require(to != address(0), "Transfer to zero");

        _transfer(from, to, tokenId);

        // If recipient is a contract, call onERC721Received
        if (_isContract(to)) {
            bytes4 retval = _checkOnERC721Received(msg.sender, from, to, tokenId, data);
            require(retval == 0x150b7a02 /* ERC721_RECEIVED */, "ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    // --- Minting badges ---
    /// @notice Anyone can claim a badge for themselves. Mints next tokenId to msg.sender.
    function claimBadge() external returns (uint256) {
        _currentTokenId += 1;
        uint256 newId = _currentTokenId;
        _safeMint(msg.sender, newId);
        return newId;
    }

    /// @notice Owner-only mint to arbitrary address
    function adminMint(address to) external onlyOwner returns (uint256) {
        require(to != address(0), "Zero address");
        _currentTokenId += 1;
        uint256 newId = _currentTokenId;
        _safeMint(to, newId);
        return newId;
    }

    /// @notice Owner can change base URI for metadata hosting
    function setBaseURI(string calldata newBase) external onlyOwner {
        baseURI = newBase;
        emit BaseURIChanged(newBase);
    }

    // --- Internal helpers ---
    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);

        if (_isContract(to)) {
            bytes4 retval = _checkOnERC721Received(msg.sender, address(0), to, tokenId, "");
            require(retval == 0x150b7a02, "ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Mint to zero");
        require(_owners[tokenId] == address(0), "Token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view exists(tokenId) returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return (spender == tokenOwner || getApproved(tokenId) == spender || isApprovedForAll(tokenOwner, spender));
    }

    // Minimal contract check
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /// @dev Very small implementation of ERC-721Receiver call
    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory _data) internal returns (bytes4) {
        // Try calling onERC721Received, return default value on success, revert otherwise.
        // We do low-level call to avoid importing interfaces.
        bytes memory payload = abi.encodeWithSignature("onERC721Received(address,address,uint256,bytes)", operator, from, tokenId, _data);
        (bool success, bytes memory returndata) = to.call(payload);
        if (!success) {
            return bytes4(0);
        }
        if (returndata.length >= 32) {
            // first 4 bytes contain selector (left-padded in returned bytes)
            bytes4 returnedSelector;
            assembly {
                returnedSelector := mload(add(returndata, 32))
            }
            return returnedSelector;
        } else {
            return bytes4(0);
        }
    }

    // --- Utilities: uint -> string (decimal) ---
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OpenZeppelin's Strings.toString
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

    // --- Misc / ERC165 lightweight (supports only commonly used ERC-721 selector checks) ---
    /// @notice Very light supportsInterface — you can expand this if needed.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC165 (0x01ffc9a7), ERC721 (0x80ac58cd), ERC721Metadata (0x5b5e139f)
        return (interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f);
    }

    // --- Emergency / Owner helpers ---
    /// @notice Transfer ownership to a new address (no input? this one takes input: using because ownership transfer is important)
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    /// @notice Burn a token (only token owner or approved)
    function burn(uint256 tokenId) external {
        address tokenOwner = ownerOf(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved nor owner");

        // clear approvals
        _tokenApprovals[tokenId] = address(0);

        _balances[tokenOwner] -= 1;
        delete _owners[tokenId];

        emit Transfer(tokenOwner, address(0), tokenId);
    }
}
