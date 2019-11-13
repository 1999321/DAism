pragma solidity ^0.5.5;
import "./IDETERMINE_test.sol";
import "./IDATA_MOV_test.sol";
contract Determine is IDETERMINE{
    /************************************/
    /*     event未定义                  */
    /************************************/
	//超级管理员
	address public super_address;
	//Owners
    mapping(address=>bool) public isOwner;//Determine if it is the owner
    address[] public Owners;//owners
	//限制最多50个owners
    int public max_owners_count = 50;//Maximum number of owners
	/****外部事务******/
	//签名情况
    mapping(uint=>mapping(address=>bool)) public confirmed;//Confirmation
	//要求的多签情况，应该反馈movitation
    mapping(uint=>uint8) public degree;//degree
	//交易的状态
    mapping(uint=>uint8) public status;
	//交易数量
    uint public TransactionCount;
	//状态
	enum affair_status{
	     not_done
		 revoke
		 done
	}
    /**********内部事务***********/
    struct affair{
        bytes code;
        address caller;
        affair_status status;
        uint256 value;
        address destination;
        uint8 which;
        uint8 required;
    }
    mapping(uint=>affair) public affairs;
    mapping(uint=>mapping(address=>bool)) public confirmed_affair;
    uint public affaircount = 0;
	//内部事务的表示形式，用于建立正确的内部事务
    struct inter_business{
        string names;
        bytes4 forth_code;
        uint8 required;
    }
	mapping(uint8=>inter_business) public inter_businesses;
    uint8 public inter_businesses_count;
	//定义消费规则，用于单人消费与及累计消费,与及请求/交易消费
	 struct transfer_require{
        uint8 required;
        uint256 value_low;
        uint256 value_high;
    }
    mapping(uint8=>transfer_require) public single_affair;
    mapping(uint8=>transfer_require) public sum_affair;
	mapping(uint8=>transfer_require) public transaction_affair;
    uint8 public single_affair_count;
    uint8 public sum_affair_count;
	uint8 public transaction_affair_count;
	//辅助于消费规则，如果是日消费限制，那么就today，如果是周消费限制，就week.本人认为，应该时间由owners设定，并且具有多种消费限制
    uint256 public today;
    uint256 public today_spend;
    uint256 public today_limit;
	//行动部的地址
    address public movitation_address;
	//基本的签名比例要求，用于未定义签名规则的内部事务，与及用于change_inter_business制定内部规则。
    uint8  public required;
	//零地址
	address constant ZERO_ADDRESS = address(0)
   // bytes4 private change_require_code;
    /**************************modifier***************************/
	//判断调用者是否为本身
    modifier onlyWallet(address add){
        require(add == address(this));
        _;
    }
	//判断是否为owner
    modifier onlyowners(address add){
        require(isOwner[add]);
        _;
    }
	//判断合约是否已经执行且id是否正确（越界）
    modifier transactionisOK(uint id,uint which){
        if(which == 0)
        require(affairs[id].status == affair_status.not_done && id<affaircount,"1");
        else
        require(status[id] == 0 && id<TransactionCount,"2");
        _;
    }
	//判断是否为行动地址
    modifier onlymovi_address(address add){
        require(add == movitation_address);
        _;
    }
    /*********************construactor**************************/
	//_owners:管理人地址
	//_required:基本多签比例
    constructor(address[] memory _owners,uint8  _required)
        public
    {
        require(int(_owners.length)<=max_owners_count);
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != ZERO_ADDRESS);
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
    /******************************************/
	/*添加内部事务
	/******************************************/
	//添加内部函数事务
	//_code:调用某函数的字节码
	//which:事务编号
    function add_intertal_affair(bytes memory _code,uint8 which)external onlyowners(msg.sender)returns(bool success)
    {
        uint8 required_affair;
        require(inter_businesses[which].forth_code.length != 0);
        require(isthe_code(_code,which));
        required_affair = inter_businesses[which].required;
        if(required_affair == 0)
        required_affair = required;
        affairs[affaircount] = affair({
            code:_code,
            caller:msg.sender,
            status:affair_status.not_done,
            value:0,
            destination:ZERO_ADDRESS,
            which:which,
            required:required_affair
        });
        affaircount += 1;
        success = true;
    }
	//添加内部支付事务
	//value:金额
	//destination:目标地址
    function add_transfer_affair(uint256 value,address destination)external onlyowners(msg.sender)returns(bool success)
    {
        require(destination != ZERO_ADDRESS);
        uint8 required_affair;
        required_affair = the_max(find_require(value),find_require1(find_sum_value(value)));
        if(required_affair == 0)
            required_affair = required;
        affairs[affaircount].value = value;
        affairs[affaircount].destination = destination;
        affaircount += 1;
        success = true;
    }
	//判断事务编号与_code是否对应
    function isthe_code(bytes memory _code,uint8 which)public view returns(bool ){
        for(uint i=0;i<4;i++)
        if(_code[i] != inter_businesses[which].forth_code[i])
            return false;
        return true;
    }
	//比较大小
    function the_max(uint8 value1,uint8 value2) public pure returns(uint8 max_value){
        if(value1>value2)
           max_value = value1;
        max_value = value2;
    }
	//sigle_affair
    function find_require(uint256 _value)public view returns(uint8 required_){
        
        for(uint8 i=0;i<single_affair_count;i++){
            if(_value < single_affair[i].value_high && _value > single_affair[i].value_low){
			    required_ = single_affair[i].required;
			    break;
			}
                
        }
        if(required_ == 0)
           required_ = required;
    }
	//mul_affair
    function find_require1(uint256 value)public view returns(uint8 required_){
        for(uint8 i=0;i<sum_affair_count;i++){
            if(value < sum_affair[i].value_high && value > sum_affair[i].value_low){
			    required_ = sum_affair[i].required;
				break;
			}
                
        }
        if(required_ == 0)
            required_ = required;
    }
	//计算日消费
    function find_sum_value(uint256 value)internal  returns(uint256 sum_value){
        if(now > today + 1*1 days)
        {
            today = now;
            today_spend = value;
        }
        else
            today_spend += value;
        sum_value = today_spend;
    }
	/**************************************/
	/*签名与取消签名
	/**************************************/
    //签名
	//transactionId:事务/交易 id
	//which:类型，0表示内部事务，1表示外部交易
    function confirmTransaction(uint256 transactionId,uint which)external onlyowners(msg.sender)
    transactionisOK(transactionId,which)
    {
        if(which == 0){
             require(!confirmed_affair[transactionId][msg.sender]);
             confirmed_affair[transactionId][msg.sender] = true;
             ex_transaction(transactionId,0);
        }
        else{
            require(!confirmed[transactionId][msg.sender],"3");
            confirmed[transactionId][msg.sender] = true;
            require(IDATA_MOV(movitation_address).confirmed_Synchronize(msg.sender,true,transactionId),"4");
            ex_transaction(transactionId,1);
        }
    }
	//取消签名
	//transactionId:事务/交易 id
	//which:类型，0表示内部事务，1表示外部交易
    function revokeConfirmation(uint256 transactionId,uint which)external onlyowners(msg.sender)
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
	/**********************************************/
	/*回退事务
	/**********************************************/
	function revoke(uint transactionId) public {
        require(msg.sender == affairs[transactionId].caller);
        affairs[transactionId].status = affair_status.revoke;
    }
	/*****************************************/
	/*执行事务/交易
	/*****************************************/
	//判断是否签名够数
	//transactionId:事务/交易 id
	//which:类型，0表示内部事务，1表示外部交易
    function isConfirmed(uint256 transactionId,uint which)public view returns (bool)
    {
        uint8 count = 0;
        uint8 length = uint8(Owners.length);
        if(which !=0){
            require(status[transactionId]==0);
            for (uint i=0; i<Owners.length; i++) {
            if (confirmed[transactionId][Owners[i]])
                count += 1;
            if (count >= length*degree[transactionId]/100 || count == length)
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
	//执行
	//transactionId:事务/交易 id
	//which:类型，0表示内部事务，1表示外部交易
    function  ex_transaction(uint transactionId,uint8 which) 
    internal
    returns(bool success)
    {
       if(which == 0){
           success = isConfirmed(transactionId,0);
       if(success){
           bytes memory ssk;
           if(affairs[transactionId].which != 0){
               (success,ssk) = address(this).call(affairs[transactionId].code);
               require(success);
           }
           
           //ex_function(affairs[transactionId].code,address(this),0);
           else
           require(IDATA_MOV(movitation_address)._transfer(affairs[transactionId].value,affairs[transactionId].destination));
           affairs[transactionId].status = affair_status.done;
       }
       }
       
       else{
           success = isConfirmed(transactionId,1);
           if(success){
               require(IDATA_MOV(movitation_address).ex_affair(transactionId),"6");
               status[transactionId] =2;
       }
       }
    }
   /* function test()public {
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
    }*/
    
    
    /*******************************external******************************/
	//改变TransactionCount
    function change_count(uint256 index)external onlymovi_address(msg.sender) returns(bool){
        TransactionCount = index+1;
        return true;
    }
	//改变degree[id]
    function change_exter_require(uint8 _required,uint256 id,uint256 value)external onlymovi_address(msg.sender)returns(uint8){
        degree[id] = the_max(find_require2(value),_required);
        return degree[id];
    }
	//transcation_affair required
	function find_require2(uint256 _value)public view returns(uint8 _required){
	    for(uint8 i=0;i<transaction_affair_count;i++){
            if(_value < transaction_affair[i].value_high && _value > transaction_affair[i].value_low)
            _required = transaction_affair[i].required;
        }
        if(_required == 0)
            _required = required;
	}
	/**************************************************/
	/*具体内部事务
	/**************************************************/
	//改变内部事务的形式，在部署合约时即定义相关信息
	//num:编号
	//names:内部事务的函数功能，如：addOwner(address);
	//required:内部事务对应的多签比例要求
	function change_inter_business(uint8 num,string memory names,uint8 _required)public onlyWallet(msg.sender){
        require(num >2);
        inter_businesses[num].names = names;
        inter_businesses[num].required = _required;
        inter_businesses[num].forth_code = bytes4(keccak256(bytes(names)));
    }
	//添加owner
	//owner:被添加的管理人地址
    function addOwner(address owner) public
    onlyWallet(msg.sender)
    {
        require(!isOwner[owner]);
        require(int(Owners.length+1) <= max_owners_count);
        isOwner[owner] = true;
        Owners.push(owner);
        inter_businesses[1].required += 1;
    }
	//移除管理人
	//owner:被移除管理人的地址
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
	//替代管理人
	//owner:被替代管理人地址
	//newOwner:替代管理人地址
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
	//设置/改变单笔交易的多签比例规则
	//num:编号
	//value_low：下限
	//value_high:上限
	//required:多签比例（百分比）要求
    function change_sigle(uint8 num,uint256 value_low,uint256 value_high,uint8 _required)public onlyWallet(msg.sender){
        single_affair[num].value_low = value_low;
        single_affair[num].value_high = value_high;
        single_affair[num].required = _required;
    }
	//设置/改变累计交易的多签比例规则
	//num:编号
	//value_low：下限
	//value_high:上限
	//required:多签比例（百分比）要求
    function change_sum(uint8 num,uint256 value_low,uint256 value_high,uint8 _required)public onlyWallet(msg.sender){
        sum_affair[num].value_low = value_low;
        sum_affair[num].value_high = value_high;
        sum_affair[num].required = _required;
    }
	//设置/改变外部交易的多签比例规则
	//num:编号
	//value_low：下限
	//value_high:上限
	//required:多签比例（百分比）要求
    function change_transaction(uint8 num,uint256 value_low,uint256 value_high,uint8 _required)public onlyWallet(msg.sender){
        transaction_affair[num].value_low = value_low;
        transaction_affair[num].value_high = value_high;
        transaction_affair[num].required = _required;
    }
	//改变基本的多签比例
	//_required:新的多签比例
    function change_require(uint8 _required)public onlyWallet(msg.sender){
        required = _required;
        inter_businesses[2].required = required;
    }
	//设置行动合约地址
	//add:行动合约地址
    function set_movitation_address(address add)public onlyWallet(msg.sender){
        require(isContract(add));
        movitation_address = add;
    }
	//转移
	//new_contract_address:新的决策合约
    function divert(address new_contract_address)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).divert(new_contract_address));
    }
	//数据权限的设定
	//id:指定数据，0为transactions,1为requests
	//level:数据等级，值越大，等级越高
	function set_datalevel(uint id,uint8 level)public onlyWallet(msg.sender){
       require(IDATA_MOV(movitation_address).set_datalevel(id,level));
    }
	//开放数据
	//to:开放人
	//which:数据编号
    function opendata_to(address to ,uint8 which)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address)._open_to(to,which));
    }//
	//发起请求
	//organ_address:发起请求的目标方
	//value:费用
	//_Description:请求描述
	//degree:要求签名比例
    function Initiate_a_request(address organ_address,uint256 value,string memory _Description,uint8 _degree)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).Initiate_a_request(organ_address,value,_Description,_degree));
    }
	//白名单修改
    function whitenames_add(address add)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).whitenames_add(add));
    }
    function whitenames_delete(address add)public onlyWallet(msg.sender){
        require(IDATA_MOV(movitation_address).whitenames_delete(add));
    }
	/*******************判断是否为合约********************************/
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
	/*********************message get***************************/
  function get_transaction1(uint _id)public view onlyowners(msg.sender)returns (
        uint8 _status,  
        uint8 _required,
        address destination,
        address contract_address)
    {
        (_status,_required,destination,contract_address) = IDATA_MOV(movitation_address).get_transaction1(_id);
    }
 function get_transaction2(uint id)public view onlyowners(msg.sender)returns (
        uint256 value,
        uint256 start_time,
        uint256 done_time,
        string memory Description)
    {
        (value,start_time,done_time,Description) = IDATA_MOV(movitation_address).get_transaction2(id);
    }
  function get_request(uint id)public view onlyowners(msg.sender)returns(
      address to,
        uint256 value,
        uint256 _id,
        uint256 start_time,
        uint256 done_time,
        bool executed)
    {
        (to,value,_id,start_time,done_time,executed) = IDATA_MOV(movitation_address).get_request(id);
    }
    function get_ownerlen()public view returns(uint256 len){
	    len = Owners.length;
	}
	/**********************未完成功能**********************/
	function set_superaddress(address add)public onlymovi_address(msg.sender) 
	{
	super_address = add;
	}
}