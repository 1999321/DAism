pragma solidity ^0.5.5;
import "./IDETERMINE.sol";
import "./IDATA_MOV.sol";
contract Determine is IDETERMINE{
    /************************************/
    /*                                  */
    /************************************/
    mapping(address=>bool) public isOwner;//Determine if it is the owner
    address[] public Owners;//owners
    int public max_owners_count = 50;//Maximum number of owners
    mapping(uint=>mapping(address=>bool)) public confirmed;//Confirmation
    mapping(uint=>uint8) private degree;//degree
    mapping(uint=>uint8) private status;
    uint private TransactionCount;
    
    uint256 public today;
    uint256 public today_spend;
    uint256 public today_limit;
    
    struct affair{
        bytes code;
        address caller;
        int status;
        uint256 value;
        address destination;
        uint8 which;
        uint8 required;
    }
    mapping(uint=>affair) public affairs;
    mapping(uint=>mapping(address=>bool)) public confirmed_affair;
    uint public affaircount = 0;
    address public movitation_address;
    uint8  public required;
   // bytes4 private change_require_code;
    
    struct inter_business{
        string names;
        bytes4 forth_code;
        uint8 required;
    }
    struct transfer_require{
        uint8 required;
        uint256 value_low;
        uint256 value_high;
    }
    mapping(uint8=>transfer_require) public single_affair;
    mapping(uint8=>transfer_require) public sum_affair;
    uint8 public single_affair_count;
    uint8 public sum_affair_count;
    
   
    
    mapping(uint8=>inter_business) public inter_businesses;
    uint8 public inter_businesses_count;
    
    modifier onlyWallet(address add){
        require(add == address(this));
        _;
    }
    modifier onlyowners(address add){
        require(isOwner[add]);
        _;
    }
    modifier transactionisOK(uint id,int which){
        if(which == 0)
        require(affairs[id].status == 0 && id<affaircount);
        else
        require(status[id] == 0 && id<TransactionCount);
        _;
    }
    modifier onlymovi_address(address add){
        require(add == movitation_address);
        _;
    }
    
    constructor(address[] memory _owners,uint8  _required)
        public
    {
        require(int(_owners.length)<=max_owners_count);
        address zero;
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != zero);
            isOwner[_owners[i]] = true;
        }
        Owners = _owners;
        required = _required;
        inter_businesses[0].names = "transfer";
        inter_businesses[1].names = "change_require(uint8)";
        inter_businesses[1].forth_code = bytes4(keccak256("change_require(uint8)"));
        inter_businesses[1].required = uint8(Owners.length);
        inter_businesses[2].names = "change_inter_business(uint8,string,uint8)";
        inter_businesses[2].forth_code = bytes4(keccak256("change_inter_business(uint8,string,uint8)"));
        inter_businesses[2].required = required;
    }
    
    
    
    function the_max(uint8 value1,uint8 value2) public view returns(uint8 max_value){
        if(value1>value2)
        max_value = value1;
        max_value = value2;
    }
    function find_require(uint256 _value)public view returns(uint8 required_){
        
        for(uint8 i=0;i<single_affair_count;i++){
            if(_value < single_affair[i].value_high && _value > single_affair[i].value_low)
            required_ = single_affair[i].required;
        }
        if(required_ == 0)
        required_ = required;
    }
    function find_require1(uint256 value)public view returns(uint8 required_){
        for(uint8 i=0;i<sum_affair_count;i++){
            if(value < sum_affair[i].value_high && value > sum_affair[i].value_low)
            required_ = sum_affair[i].required;
        }
        if(required_ == 0)
        required_ = required;
    }
    function find_sum_value(uint256 value)public  returns(uint256 sum_value){
        if(now > today + 1*1 days)
        {
            today = now;
            today_spend = value;
        }
        else
            today_spend += value;
        sum_value = today_spend;
    }
    function isthe_code(bytes memory _code,uint8 which)public view returns(bool ){
        for(uint i=0;i<4;i++)
        if(_code[i] != inter_businesses[which].forth_code[i])
        return false;
        return true;
    }
    function add_intertal_affair(bytes memory _code,uint8 which)public onlyowners(msg.sender)returns(bool success)
    {
        address zero;
        require(which >= 0 );
        uint8 required_affair;
        require(inter_businesses[which].forth_code.length != 0);
        require(isthe_code(_code,which));
        required_affair = inter_businesses[which].required;
        if(required_affair == 0)
        required_affair = required;
        affairs[affaircount] = affair({
            code:_code,
            caller:msg.sender,
            status:0,
            value:0,
            destination:zero,
            which:which,
            required:required_affair
        });
        affaircount += 1;
        success = true;
    }
    function add_transfer_affair(uint256 value,address destination)public onlyowners(msg.sender)returns(bool success)
    {
        require(value+affaircount>=affaircount);
        address zero;
        require(destination != zero);
        uint8 required_affair;
             required_affair = the_max(find_require(value),find_require1(find_sum_value(value)));
        if(required_affair == 0)
        required_affair = required;
        affairs[affaircount].value = value;
        affairs[affaircount].destination = destination;
        affaircount += 1;
        success = true;
    }
    function confirmTransaction(uint256 transactionId,int which)public onlyowners(msg.sender)
    transactionisOK(transactionId,which)
    {
        if(which == 0){
             require(!confirmed_affair[transactionId][msg.sender]);
             confirmed_affair[transactionId][msg.sender] = true;
             ex_transaction(transactionId,0);
        }
        else{
            require(!confirmed[transactionId][msg.sender]);
            confirmed[transactionId][msg.sender] = true;
            require(IDATA_MOV(movitation_address).confirmed_Synchronize(msg.sender,true,transactionId));
            ex_transaction(transactionId,1);
        }
    }
    function revokeConfirmation(uint256 transactionId,int which)public onlyowners(msg.sender)
        transactionisOK(transactionId,which)
    {
        if(which == 0){
             require(confirmed_affair[transactionId][msg.sender]);
             confirmed_affair[transactionId][msg.sender] = false;
             
        }
        else{
            require(confirmed[transactionId][msg.sender]);
            confirmed[transactionId][msg.sender] = false;
            require(IDATA_MOV(movitation_address).confirmed_Synchronize(msg.sender,false,transactionId));
        }
    }
    function isConfirmed(uint256 transactionId,int which)public view returns (bool)
    {
        uint8 count = 0;
        uint8 length = uint8(Owners.length);
        if(which !=0){
            require(status[transactionId]==0);
            for (uint i=0; i<Owners.length; i++) {
            if (confirmed[transactionId][msg.sender])
                count += 1;
            if (count >= length*degree[transactionId]/100 || count == int(Owners.length))
                 return true;
        }
        return false;
        }
        else
        {
             for (uint i=0; i<Owners.length; i++) {
            if (!confirmed_affair[transactionId][msg.sender])
                count += 1;
            if (count >= length*affairs[transactionId].required/100)
                 return true;
            }
            return false;
        }
    }
    function  ex_transaction(uint transactionId,uint8 which) 
    internal
    returns(bool success)
    {
       if(which == 0){
           success = isConfirmed(transactionId,0);
       if(success){
           if(affairs[transactionId].which != 0)
           address(this).call(affairs[transactionId].code);
           //ex_function(affairs[transactionId].code,address(this),0);
           else
           require(IDATA_MOV(movitation_address)._transfer(affairs[transactionId].value,affairs[transactionId].destination));
           affairs[transactionId].status = 2;
       }
       }
       
       else{
       success = isConfirmed(transactionId,1);
       if(success){
           require(IDATA_MOV(movitation_address).ex_affair(transactionId));
           status[transactionId] =2;
       }
       }
    }
    function test()public {
        string memory sk = "set_movitation_address(address)";
        IDETERMINE(address(this)).change_inter_business(8,sk,33);
    }
    function test1(bytes memory code)public returns(bool){
         address(this).call(code);
       //return address(this).call(bytes4(keccak256("change_inter_business(uint8,string,uint8)")),num,ooo,id);
    }
    function ex_function(bytes memory code,address destination,uint256 value) public  returns(uint answer){
        bool result;
        uint datalength = code.length;
        uint256 gasl = gasleft();
        assembly {
            // move pointer to free memory spot
          let ptr := mload(0x40)
          let d := add(code, 32) 
            result := call(
              15000, // gas limit
              destination,  // to addr. append var to _slot to access storage variable
              0, // not transfer any ether
              d, // Inputs are stored at location ptr
              datalength, // Inputs are  bytes long
              ptr,  //Store output over input
              0x20) //Outputs are 32 bytes long
            
            if eq(result, 0) {
                revert(0, 0)
            }
            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }
        require(result);
    }

    function revoke(uint transactionId) public {
        require(msg.sender == affairs[transactionId].caller);
        affairs[transactionId].status = 1;
    }
    //external
    function change_count(uint256 index)public onlymovi_address(msg.sender) returns(bool){
        TransactionCount = index;
        return true;
    }
    function change_exter_require(uint8 _required,uint256 id,uint256 value)public onlymovi_address(msg.sender)returns(uint8){
        degree[id] = the_max(find_require(value),_required);
        return degree[id];
    }
    //onlywallet
     function addOwner(address owner) public
    onlyWallet(msg.sender)
    {
        require(isOwner[owner]);
        require(int(Owners.length+1) <= max_owners_count);
        isOwner[owner] = true;
        Owners.push(owner);
        inter_businesses[1].required += 1;
    }
     function removeOwner(address owner) public
        onlyWallet(msg.sender)
        onlyowners(owner)
    {
        require(Owners.length>1);
        isOwner[owner] = false;
        for (uint i=0; i<Owners.length - 1; i++)
            if (Owners[i] == owner) {
                Owners[i] = Owners[Owners.length - 1];
                break;
            }
        Owners.length -= 1;
        inter_businesses[1].required -= 1;
    }
    function replaceOwner(address owner, address newOwner)public 
    onlyWallet(msg.sender)
    onlyowners(owner)
    {
        require(!isOwner[newOwner]);
        for (uint i=0; i<Owners.length; i++)
            if (Owners[i] == owner) {
                Owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
    }
    function change_inter_business(uint8 num,string memory names,uint8 required)public onlyWallet(msg.sender){
        require(num >2);
        inter_businesses[num].names = names;
        inter_businesses[num].required = required;
        inter_businesses[num].forth_code = bytes4(keccak256(bytes(names)));
    }
    function change_sigle(uint8 num,uint256 value_low,uint256 value_high,uint8 required)public onlyWallet(msg.sender){
        single_affair[num].value_low = value_low;
        single_affair[num].value_high = value_high;
        single_affair[num].required = required;
    }
    function change_sum(uint8 num,uint256 value_low,uint256 value_high,uint8 required)public onlyWallet(msg.sender){
        sum_affair[num].value_low = value_low;
        sum_affair[num].value_high = value_high;
        sum_affair[num].required = required;
    }
    function change_require(uint8 _required)public onlyWallet(msg.sender){
        required = _required;
        inter_businesses[2].required = required;
    }
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`对于没有代码的地址（合约地址），返回。。会因为合约代码不同而不同
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function set_movitation_address(address add)public onlyWallet(msg.sender){
        require(isContract(add));
        movitation_address = add;
    }
    function divert(address new_contract_address)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).divert(new_contract_address));
    }
    function opendata_to(address to ,uint8 which)public onlyWallet(msg.sender){
        IDATA_MOV(movitation_address)._open_to(to,which);
    }
    function Initiate_a_request(address organ_address,uint256 value,string memory _Description,uint8 degree)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).Initiate_a_request(organ_address,value,_Description,degree));
    }
    function whitenames_add(address add)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).whitenames_add(add));
    }
    function whitenames_delete(address add)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).whitenames_delete(add));
    }
    
}
