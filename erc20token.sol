// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0; 

interface ERC20Interface {
    function totalSupply() external view returns (uint); 
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferForm(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens); 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptos is ERC20Interface {
    string public name = "Ted Token"; 
    string public symbol = "TED"; 
    uint public decimales = 0; //18 
    uint public override totalSupply;

    address public founder;   
    mapping(address => uint) public balances; 

    mapping(address => mapping(address => uint)) allowed; 

    // Ex 0x111 --- (owner) allows 0x222,,, (the spender) ---- 100 tokens
    // allowed[0x111][0x222] = 100;

    constructor() {
        totalSupply = 1000000;
        founder = msg.sender; 
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public virtual override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        balances[to] += tokens; 
        balances[founder] -= tokens; 
        emit Transfer(msg.sender, to, tokens);

        return true; 
    } 

     function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
         return allowed[tokenOwner][spender];
     }

      function approve(address spender, uint tokens) public override returns (bool success) {
          require(balances[msg.sender] >= tokens);
          require(tokens > 0); 

          allowed[msg.sender][spender] = tokens; 
          emit Approval(msg.sender, spender, tokens);
          return true; 
      }

      function transferForm(address from, address to, uint tokens) public virtual override returns (bool success) {
          require(allowed[from][to] >= tokens); 
          require(balances[from] >= tokens);

          balances[from] -= tokens;
          balances[to] += tokens;
          allowed[from][to] -= tokens;

          return true;
      }
}

// ICO Contract 
contract CryptosICO is Cryptos {
    address public admin; 
    // deposit eth directly to the address, its more safer than store eht in contract
    address payable public deposit; 
    uint tokenPrice = 0.001 ether; 
    uint public hardCap = 300 ether; 
    uint public raisedAmount; 
    uint public salesStart = block.timestamp;
    uint public salesEnd = block.timestamp + 604800;
    uint public tokenTradeStart = salesEnd + 604800;
    uint public maxInvestment = 5 ether; 
    uint public minInvestment = 0.1 ether; 

    enum State {beforeStart, running, afterEnd, halted }
    State public icoState;

    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function halt() public onlyAdmin {
        icoState = State.halted;
    }

    function resume() public onlyAdmin {
        icoState = State.running;
    }

    function changeDepositAddress(address payable newDeposit) public onlyAdmin {
        deposit = newDeposit;
    }

    function getCurrentState() public view returns(State) {
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < salesStart) {
            return State.beforeStart;
        } else if (block.timestamp <= salesEnd && block.timestamp >= salesStart) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    event Invest(address investor, uint value, uint tokens);

    function invest() payable public returns(bool) {
        icoState = getCurrentState(); 
        require(icoState == State.running);

        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require(raisedAmount <= hardCap);

        uint tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[founder] -= tokens; 
        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokens);

        return true; 
    }
    

    receive() payable external {
        invest();
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transfer(to, tokens);
        return true; 
    }

     function transferForm(address from, address to, uint tokens) public virtual override returns (bool success) {
        require(block.timestamp > tokenTradeStart);
        super.transferForm(from, to, tokens);
        return true;
     }

     function burn() public returns(bool) {
         icoState = getCurrentState(); 
         require(icoState == State.afterEnd);
         balances[founder] = 0;

         return true;
     }
}