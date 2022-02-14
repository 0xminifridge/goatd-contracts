// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

interface IERC2981Royalties {
    function royaltyInfo(uint256 tokenID, uint256 value) external view returns(address receiver, uint256 royaltyAmount);
}

contract TraitDrops is ERC1155Supply, Ownable {
    using Strings for uint256;

    string private baseURI;
    string public name;
    string public symbol;
    address public treasuryWallet; 

    address private spotPfpContract; 
   
    mapping(uint256 => bool) public validDropTypes;

    event SetBaseURI(string indexed _baseURI);
    event AddDropType(uint256 _dropType);


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC1155(_baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        validDropTypes[0] = true;
        emit SetBaseURI(baseURI);
    }

    function addDropType(uint256 _dropType) external onlyOwner {
        validDropTypes[_dropType] = true;
        emit AddDropType(_dropType);
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }

    function airdropTokens(
        address[] memory to,
        uint256 typeId,
        uint256 amount
    ) public onlyOwner {
        require(validDropTypes[typeId], "TheSpotPFP: Invalid drop type");
        require(
            balanceOf(owner(), typeId) >= amount * to.length,
            "TheSpotPFP: Not enough to airdrop"
        );
        for (uint256 i = 0; i < to.length; i++) {
            safeTransferFrom(owner(), to[i], typeId, amount, "");
        }
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }
    // Junk adding updatable treasuryWallet address

    function setTreasuryWalletAddress(address _treasuryWallet)
        external
        onlyOwner
    {
        treasuryWallet = _treasuryWallet;
    }


    // only callable by the owner for security
    function setSpotPfpContractAddress(address _spotPfpContract)
        external
        onlyOwner
    {
        spotPfpContract = _spotPfpContract;
    }

    // this method will be called by the spot pfp contract
    // it will burn 1 spot drop token of a specifc type
    function burnSpotDrop(uint256 typeId, address burnTokenAddress) external {
        require(msg.sender == spotPfpContract, "Invalid burner address");
        require(validDropTypes[typeId], "Only light crystals are supported");
        // from -- burnTokenAddress (spotPfpcontract)
        // id -- typeId
        // amount -- 1
        _burn(burnTokenAddress, typeId, 1);
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(validDropTypes[typeId], "TheSpotDrops: Invalid drop type");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString(), ".json"))
                : "";
    }

    //royalties by xrpant/junk
    function supportsInterface(bytes4 interfaceID) public view override returns(bool) {
        return interfaceID == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceID);
    }

    function royaltyInfo(uint256, uint256 value) external view returns(address, uint256) {
        return (treasuryWallet, value * 300 / 10000);
    } 

    

}
