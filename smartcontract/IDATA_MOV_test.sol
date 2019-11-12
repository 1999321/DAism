pragma solidity ^0.5.5;
interface IDATA_MOV{
    function isInvestor(address add)external returns(bool is_or_not);
    function Investors(uint256 id)external returns(address who);
    function balance_of_address(address add)external returns(uint256 balances);
    function wealth()external returns(uint256 wealth_);
    function confirmed_Synchronize(address add,bool isconfirmed,uint256 id)external returns(bool);
    function _transfer(uint256 value,address destination)external payable returns(bool);
    function addTransaction(uint256 value,string calldata _Description,address destination,uint8 degree)external returns(uint256 id);
    function ex_affair(uint transactionid)external returns(bool);
    function Respond(uint requestid)external returns(bool);
    function whitenames_add(address add)external returns(bool);
    function whitenames_delete(address add)external returns(bool);
    function set_datalevel(uint id,uint8 level)external returns(bool);
    function divert(address add)external returns(bool);
    function _open_to(address add,uint8 level)external returns(bool);
    function Initiate_a_request(address organ_address,uint256 value,string calldata _Description,uint8 degree)external  returns(bool);
    function request_id(uint256 id,uint256 id_request)external returns(bool);
    function _transfer_Investors_or_client(uint256 value)external payable;
    function get_transaction1(uint id)external view returns (
        uint8 status,  
        uint8 required,
        address destination,
        address contract_address);
    function get_transaction2(uint id)external view returns (
        uint256 value,
        uint256 start_time,
        uint256 done_time,
        string memory Description);
   function get_transaction_confirmed(uint256 id,address add)external view returns(bool);
   function get_request(uint id)external view returns(
       address to,
        uint256 value,
        uint256 _id,
        uint256 start_time,
        uint256 done_time,
        bool executed);
    
}