pragma solidity ^0.5.5;
interface IDETERMINE {
    function isOwner(address add) external returns(bool);
    function add_intertal_affair(bytes calldata code,uint8 which)external returns(bool success);
    function add_transfer_affair(uint256 value,address destination)external returns(bool success);
    function confirmTransaction(uint256 transactionId,int which)external;
    function revokeConfirmation(uint256 transactionId,int which)external;
    function isConfirmed(uint256 transactionId,int which)external view returns (bool);
    function revoke(uint transactionId) external;
    function change_count(uint256 index)external  returns(bool);
    function change_exter_require(uint8 _required,uint256 id,uint256 value)external returns(uint8);
    function addOwner(address owner) external;
    function removeOwner(address owner) external;
    function replaceOwner(address owner, address newOwner)external; 
    function change_inter_business(uint8 num,string calldata names,uint8 required)external; 
    function change_sigle(uint8 num,uint256 value_low,uint256 value_high,uint8 required)external ;
    function change_sum(uint8 num,uint256 value_low,uint256 value_high,uint8 required)external ;
    function change_require(uint8 _required)external ;
    function set_movitation_address(address add)external;
    function divert(address new_contract_address)external;
    function opendata_to(address to ,uint8 which)external;
    function Initiate_a_request(address organ_address,uint256 value,string calldata _Description,uint8 degree)external;
    function whitenames_add(address add)external;
    function whitenames_delete(address add)external ;
}
