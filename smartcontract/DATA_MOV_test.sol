pragma solidity ^0.5.5;
import "./IDETERMINE_test.sol";
import "./IDATA_MOV_test.sol";
contract movitation is IDATA_MOV{
    /*****************/
	/*event未定义*/
	
	//交易或者是缴费请求
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
    mapping(uint=>Transaction) public transactions;//1
    uint  public transactionCount=0;//2
	//请求，指发起请求一方记录的请求
    uint8 public default_smallest = 13;
    struct request{
        address to;
        uint256 value;
        uint256 id;
        uint256 start_time;
        uint256 done_time;
        bool executed;
    }
    mapping(uint256=>request) public requests;//4
    uint256 public requests_count;
	//本合约交易id=>call_address中的请求id
	mapping(uint256=>uint256) public Transaction_to_request;
	
	//账本，记录收支
	struct Book{
	     address from;
		 address to;
		 uint256 value;
		 uint256 time;
	}
	mapping(uint256=>Book) public Books;
	uint256 public Books_count;
	
	//决策合约地址
	address public determin_address;
	//白名单，指可以发起请求的合约地址
    address[] public whitenames;
    mapping(address=>bool) public iswhitename;
	//数据描述，transactions为id0,requests为id1；
	string[2] num_of_data ;
	//定义数据的水平
	uint8[2] public datalevel;//3
	//定义每个地址的数据权限
    mapping(address=>uint8) open_to;
	//销毁合约资金去向
	address public autoaddress;
	//上一次转账发生时间
	uint256 the_last_time;
	//投资人
    address[] public Investors; 
    mapping(address=>bool) public isInvestor;
	//记录每个地址投进到这个合约的资金
    mapping(address=>uint256) public balance_of_address;
	//合约的金额，包括赚到的财富与及投资人的投资，并不包括非投资人的财富
    uint256 public wealth;
	//投资人所占wealth的比例
    uint8 public bili;
	//fn _transfer_Investors_or_client中的每次取款时间间隔
    uint256 public Withdrawal_time;
	//记录每个地址上一次取款时间
    mapping(address=>uint256) public the_last_Withdraw_time;
    //0地址
    address zero;
	//超级管理员预备人
	address public super_address;
	//超级管理员诞生时间条件
	uint256 public the_last_access_time;
	
	//判断调用者是否为决策合约
    modifier onlydetermin_address(address add){
        require(add == determin_address);
        _;
    }
	//判断数据访问者的权限是否足够
    modifier onlylevel(address add,uint8 id){
        require(open_to[add] >= datalevel[id]);
        _;
    }
	//_add:决策合约地址
	//_bili:bili
	//_Withdrawal_time:提款时间间隔
	//_Investors:投资人地址
    constructor(address add,uint8 _bili,uint256 _Withdrawal_time,address[] memory _Investors,address _autoaddress)public payable{
        require(isContract(add));
        determin_address = add;
        bili = _bili;
        Withdrawal_time = _Withdrawal_time;
        Investors = _Investors;
        for(uint i=0;i<Investors.length;i++)
          isInvestor[Investors[i]] = true;
        num_of_data[0] = "transactions";
        num_of_data[1] = "requests";
		datalevel[0] = 9;
		datalevel[1] = 9;
		open_to[add] = 9;
		autoaddress = _autoaddress;
		the_last_time = now;
		the_last_access_time = now;
    }
    //合约对外的转账地方
    function()external payable{
        require(msg.value != 0);
        balance_of_address[msg.sender] += msg.value;
		Books[Books_count] =Book ({
		     from:msg.sender,
			 to:address(this),
			 value:msg.value,
			 time:now
		});
        if(isInvestor[msg.sender])
        wealth += msg.value;
		if(the_last_time+3*365*1 days >= now)
            die();
		
		if(msg.sender != super_address&&the_last_access_time+3*365*1 days >= now){
		super_address = msg.sender;
		the_last_access_time = now;
		set_superaddress();
		}
		else if(msg.sender != super_address)
		{
		super_address = msg.sender;
		the_last_access_time = now;
		}
		else if(the_last_access_time+3*365*1 days >= now){
		 set_superaddress();
		}
    }
    //与决策合约的签名情况进行同步
	//add:决策管理人地址
	//isconfirmed:表示是否签名
	//id:transactions id;
    function confirmed_Synchronize(address add,bool isconfirmed,uint256 id)public onlydetermin_address(msg.sender)
    returns(bool)
    {
        transactions[id].confirmed[add] = isconfirmed;
        return true;
    }
	//白名单的修改
	function whitenames_add(address add)public onlydetermin_address(msg.sender)returns(bool){
        require(!iswhitename[add]);
		require(isContract(add));
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
	//数据权限的设定
	//id:指定数据，0为transactions,1为requests
	//level:数据等级，值越大，等级越高
	function set_datalevel(uint id,uint8 level)public onlydetermin_address(msg.sender)returns(bool){
        require(level < default_smallest && level>=0 );
        datalevel[id] = level;
		return true;
    }
	//数据权限的授予
    function _open_to(address add,uint8 level)public onlydetermin_address(msg.sender) returns(bool){
        open_to[add] = level;
		return true;
    }
	/*************************/
	/*发起请求
	/*************************/
	
	//发起请求
	//organ_address:发起请求的目标方
	//value:费用
	//_Description:请求描述
	//degree:要求签名比例
	function Initiate_a_request(address organ_address,uint256 value,string memory _Description,uint8 degree)public onlydetermin_address(msg.sender) returns(bool){
       require(isContract(organ_address));
       require(value > 0);
       //uint256 _id =0;
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
	//目标方得到交易id对应的请求id
	//id:交易id
	//id_request:请求id
    function request_id(uint256 id,uint256 id_request)public returns(bool){
        require(msg.sender == transactions[id]._call_address);
        Transaction_to_request[id] = id_request;
        return true;
    }
	//添加交易
	//value:交易金额
	//_Description:交易描述
	//destination:收钱地址（一般为movitation地址）
	//degree:要求的多签比例
    function addTransaction(uint256 value,string memory _Description,address destination,uint8 degree)
    public
    returns(uint256 id)
    {
        require(iswhitename[msg.sender]);
        require(value + 1>1);
        require(destination != zero);
        require(destination!= determin_address);
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
        if(the_last_time+3*365*1 days >= now)
            die();
			
		if(msg.sender != super_address&&the_last_access_time+3*365*1 days >= now){
		super_address = msg.sender;
		the_last_access_time = now;
		set_superaddress();
		}
		else if(msg.sender != super_address)
		{
		super_address = msg.sender;
		the_last_access_time = now;
		}
		else if(the_last_access_time+3*365*1 days >= now){
		 set_superaddress();
		}
    }
	/*********************************/
	/*处理交易
	/*********************************/
	
	//处理交易
	//transactionid:交易id
	function ex_affair(uint transactionid)public onlydetermin_address(msg.sender) returns(bool){
	    if(the_last_time+3*365*1 days >= now)
            die();
        require(this._transfer(transactions[transactionid].value,transactions[transactionid].destination));
        require(IDATA_MOV(transactions[transactionid]._call_address).Respond(Transaction_to_request[transactionid]),"5");
        transactions[transactionid].status = 2;
        transactions[transactionid].done_time = now;
        return true;
    }
	//发生转账
	//value:金额
	//destination:目的地址
    function _transfer(uint256 value,address destination)external payable returns(bool){
        require(iswhitename[msg.sender]);
        require(msg.sender == determin_address || msg.sender == address(this));
        require(wealth > value);
        require(value > 0);
        require(isContract(destination));
        bool success;
        bytes memory ssk;
        (success,ssk) = destination.call.gas(gasleft()).value(value)('');
        require(success);
        for(uint i=0;i<Investors.length;i++)
            balance_of_address[Investors[i]] -= value*balance_of_address[Investors[i]]/wealth;
        wealth -= value;
        //event
		the_last_time = now;
        return true;
    }
	//转账完成后，回应请求
	//requestid:请求id
    function Respond(uint requestid)public returns(bool){
        require(msg.sender == requests[requestid].to);
        require(balance_of_address[msg.sender] >= requests[requestid].value,"7");
        requests[requestid].executed = true;
        requests[requestid].done_time = now;
        balance_of_address[msg.sender] -= requests[requestid].value;
        uint256 ssk = requests[requestid].value;
        for(uint i=0;i<Investors.length;i++)
            balance_of_address[Investors[i]] += ssk*balance_of_address[Investors[i]]/wealth;
        wealth += requests[requestid].value;
        return true;
    }
    //判断是否为合约地址
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
	//转移决策合约地址：可以实现升级，此里应该还需要实现之前决策合约transactions的状态同步或者开放状态的获取,如get_twostatus
    function divert(address add)public onlydetermin_address(msg.sender)returns(bool){
        require(isContract(add));
        determin_address = add;
        return true;
    }
	//自毁合约，此为3年；
	function die()internal {
	    selfdestruct(address(uint160(autoaddress)));
	}
	//改变autoaddress
	//new_auto:new auto_addreess;
	function change_auto(address new_auto)public onlydetermin_address(msg.sender) returns(bool){
	   autoaddress = new_auto;
	   return true;
	}
	function get_twostatus(uint256 id)public view onlydetermin_address(msg.sender) returns(uint8 status,uint8 _bili){
       status = transactions[id].status;
       _bili = transactions[id].required;
	}
	//取款函数
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
		if(the_last_time+3*365*1 days >= now)
            die();		
    }
    //超级管理员诞生
	function set_superaddress()internal{
	    IDETERMINE(determin_address).set_superaddress(super_address);
	}
	
    /*****************message get*****************/
    function get_transaction1(uint id)public  view onlylevel(msg.sender,0)returns (
        uint8 status,  
        uint8 required,
        address destination,
        address contract_address
       )
    {
        status = transactions[id].status;
        required = transactions[id].required;
        destination = transactions[id].destination;
        contract_address = transactions[id]._call_address;
    }
   function get_transaction2(uint id)public  view onlylevel(msg.sender,0)returns (
        uint256 value,
        uint256 start_time,
        uint256 done_time,
        string memory Description
       )
    {
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
  function get_balance()public view returns(uint256 balances_){
    balances_ = address(this).balance;
   }
}
