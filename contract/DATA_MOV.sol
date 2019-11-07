pragma solidity ^0.5.5;
import "./IDETERMINE.sol";
import "./IDATA_MOV.sol";
contract movitation is IDATA_MOV{
    struct  Transaction{
        uint8 status;  
        uint8 required;
        address destination;
        address _call_address;
        uint256 value;
        uint256 start_time;
        uint256 done_time;
        string Description;
        mapping(address=>bool) confirmed;
    }
    //balance //0
    mapping(uint=>Transaction) private transactions;//1
    uint  public transactionCount=0;//2
    mapping(uint256=>uint256) public Transaction_to_request;
    address public determin_address;
    address[] public whitenames;
    mapping(address=>bool) public iswhitename;
    uint8[3] public datalevel;//3
    mapping(address=>uint8) open_to;
    uint8 public default_smallest = 13;
    struct request{
        address to;
        uint256 value;
        uint256 id;
        uint256 start_time;
        uint256 done_time;
        bool executed;
    }
    mapping(uint256=>request) private requests;//4
    uint256 public requests_count;
    address[] public Investors; 
    mapping(address=>bool) public isInvestor;
    mapping(address=>uint256) public balance_of_address;
    uint256 public wealth;
    uint8 public bili;
    uint256 public Withdrawal_time;
    mapping(address=>uint256) the_last_Withdraw_time;
    string[2] num_of_data ;
    
    
    address zero;
    modifier onlydetermin_address(address add){
        require(add == determin_address);
        _;
    }
    modifier onlylevel(address add,uint8 id){
        require(open_to[add] < datalevel[id]);
        _;
    }
    constructor(address add,uint8 _bili,uint256 _Withdrawal_time,address[] memory _Investors)public payable{
        determin_address = add;
        bili = _bili;
        Withdrawal_time = _Withdrawal_time;
        Investors = _Investors;
        for(uint i=0;i<Investors.length;i++)
          isInvestor[Investors[i]] = true;
        num_of_data[0] = "transactions";
        num_of_data[1] = "requests";
    }
    
    function()external payable{
        require(msg.value != 0);
        balance_of_address[msg.sender] += msg.value;
        if(isInvestor[msg.sender])
        wealth += msg.value;
    }
    
    
    function confirmed_Synchronize(address add,bool isconfirmed,uint256 id)public onlydetermin_address(msg.sender)
    returns(bool)
    {
        transactions[id].confirmed[add] = isconfirmed;
        return true;
    }
    function _transfer(uint256 value,address destination)external payable returns(bool){
        require(msg.sender == determin_address || msg.sender == address(this));
        require(address(this).balance > value);
        require(value > 0);
        //address(uint160(destination)).transfer(value);
        for(uint i=0;i<Investors.length;i++)
            balance_of_address[Investors[i]] -= value*balance_of_address[Investors[i]]/wealth;
        wealth -= value;
        //event
        return true;
    }
    function addTransaction(uint256 value,string memory _Description,address destination,uint8 degree)
    public
    returns(uint256 id)
    {
        require(iswhitename[msg.sender]);
        require(value + 1>1);
        require(destination != zero);
        require(destination!=determin_address);
        uint8 sdegreee = degree;
        IDETERMINE(determin_address).change_count(transactionCount);
        sdegreee = IDETERMINE(determin_address).change_exter_require(sdegreee,transactionCount,value);
        transactions[transactionCount]=Transaction(
          {
        status:0,
        required:sdegreee,
        destination:destination,
        _call_address:msg.sender,
        value:value,
        start_time:now,
        done_time:0,
        Description:_Description
          });
        id = transactionCount;
        transactionCount+=1;
        
    }
    function ex_affair(uint transactionid)public onlydetermin_address(msg.sender) returns(bool){
        require(this._transfer(transactions[transactionid].value,transactions[transactionid].destination));
        require(IDATA_MOV(transactions[transactionid]._call_address).Respond(Transaction_to_request[transactionid]));
        transactions[transactionid].status = 2;
        transactions[transactionid].done_time = now;
    }
    function Respond(uint requestid)public returns(bool){
        require(msg.sender == requests[requestid].to);
        require(balance_of_address[msg.sender] >= requests[requestid].value);
        requests[requestid].executed = true;
        requests[requestid].done_time = now;
        balance_of_address[msg.sender] -= requests[requestid].value;
        uint256 ssk = requests[requestid].value;
        for(uint i=0;i<Investors.length;i++)
            balance_of_address[Investors[i]] += ssk*balance_of_address[Investors[i]]/wealth;
        wealth += requests[requestid].value;
        return true;
    }
    function whitenames_add(address add)public onlydetermin_address(msg.sender)returns(bool){
        require(!iswhitename[add]);
        iswhitename[add] = true;
        whitenames.push(add);
    }
    function whitenames_delete(address add)public onlydetermin_address(msg.sender)returns(bool){
        iswhitename[add] = false;
        for (uint i=0; i<whitenames.length - 1; i++)
            if (whitenames[i] == add) {
                whitenames[i] = whitenames[whitenames.length - 1];
                break;
            }
        whitenames.length -= 1;
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
    function divert(address add)public onlydetermin_address(msg.sender)returns(bool){
        require(isContract(add));
        determin_address = add;
        return true;
    }
    function set_datalevel(uint id,uint8 level)public onlydetermin_address(msg.sender){
        require(level < default_smallest && level>=0 );
        datalevel[id] = level;
    }
    function _open_to(address add,uint8 level)public onlydetermin_address(msg.sender){
        open_to[add] = level;
    }
    function Initiate_a_request(address organ_address,uint256 value,string memory _Description,uint8 degree)public onlydetermin_address(msg.sender) returns(bool){
       require(isContract(organ_address));
       require(value > 0);
       uint256 _id = IDATA_MOV(organ_address).addTransaction(value,_Description,address(this),degree);
       requests[requests_count] = request({
        to:organ_address,
        value:value,
        id:_id,
        start_time:now,
        done_time:0,
        executed:false
       });
       require(IDATA_MOV(organ_address).request_id(_id,requests_count));
       requests_count += 1;
       return true;
    }
    function request_id(uint256 id,uint256 id_request)public returns(bool){
        require(msg.sender == requests[id].to);
        Transaction_to_request[id] = id_request;
        return true;
    }
    function _transfer_Investors_or_client(uint256 value)public payable{
        require(balance_of_address[msg.sender] != 0);
        require(value > 0);
        require(now - the_last_Withdraw_time[msg.sender] > Withdrawal_time );
        the_last_Withdraw_time[msg.sender] = now;
        if(isInvestor[msg.sender])
        {
            require(value < (bili/100)*balance_of_address[msg.sender]);
            balance_of_address[msg.sender] -= value;
            wealth -= value;
            msg.sender.transfer(value);
        }
        else
        {
            require(value < balance_of_address[msg.sender]);
            balance_of_address[msg.sender] -= value;
            msg.sender.transfer(value);
        }
    }
    
    //message get
    function get_transaction(uint id)public  view onlylevel(msg.sender,0)returns (
        uint8 status,  
        uint8 required,
        address destination,
        address contract_address,
        uint256 value,
        uint256 start_time,
        uint256 done_time,
        string memory Description)
    {
        status = transactions[id].status;
        required = transactions[id].required;
        destination = transactions[id].destination;
        contract_address = transactions[id]._call_address;
        value = transactions[id].value;
        start_time = transactions[id].start_time;
        done_time = transactions[id].done_time;
        Description = transactions[id].Description;
    }
   function get_transaction_confirmed(uint256 id,address add)public view returns(bool){
       return transactions[id].confirmed[add];
   }
  function get_request(uint id)public view onlylevel(msg.sender,1)returns(
      address to,
        uint256 value,
        uint256 _id,
        uint256 start_time,
        uint256 done_time,
        bool executed)
    {
        to = requests[id].to;
        value = requests[id].value;
        _id = requests[id].id;
        start_time = requests[id].start_time;
        done_time = requests[id].done_time;
        executed = requests[id].executed;
    }
}
