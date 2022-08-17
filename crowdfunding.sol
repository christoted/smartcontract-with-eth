// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0; 

/*
    The Logic will go 
    Problem 
    There're many crowfunding paltform that scam 

    so what's the solution, Blockchain come to solve this problem 
    1. when every time the manager/ admn who raised the money wanna spend their money
    he/she need to request first, and if the 50%+ of contributors approve it, the money can send

*/

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public admin; // Who raise the money 
    uint public noOfContributors; 
    uint public minContribution;
    uint public deadline;
    uint public goal; 
    uint public raisedAmount;

    struct Request {
        string description;
        address payable recipient;
        uint value; 
        bool completed; 
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests; 

    uint public numRequest; 

    constructor(uint _goal, uint _dealine) {
        goal = _goal;
        deadline = block.timestamp + _dealine;
        minContribution = 100 wei; 
        admin = msg.sender;
    }

    // Function for user contribute 
    function contribute() public payable {
        require(block.timestamp < deadline, "Deadline has passed!"); 
        require(msg.value >= minContribution, "Minimum contributon no met!");

        // First Time 
        if (contributors[msg.sender] == 0 ) {
            noOfContributors++;
        }
        
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    // Function get refund 
    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);

        address payable recipient = payable(msg.sender);
        recipient.transfer(contributors[msg.sender]);

        contributors[msg.sender] = 0;
    }


      // either receive() or fallback() is mandatory for the contract to receive ETH by 
    // sending ETH to the contract's address
    
    // declaring the receive() function that is executed when sending ETH to the contract address
    // it was introduced in Solidity 0.6 and a contract can have only one receive function, 
    // declared with this syntax (without the function keyword and without arguments). 
    // Receive -> for sending money to this contract, and can receive
    receive() payable external {
       contribute();
    }

    // declaring a fallback payable function that is called when msg.data is not empty or
    // when no other function matches

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }


    // Get Request Money 
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin can make this request");
        _;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numRequest];
        numRequest++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false; 
        newRequest.noOfVoters = 0;
    }
     
    // Vote the Reqeust 
    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, "You must a contributor");
        Request storage thisRequest = requests[_requestNo];
        
        require(thisRequest.voters[msg.sender] == false, "You have already voted!");
        thisRequest.voters[msg.sender] = true; 
        thisRequest.noOfVoters++;
    }

    // Make payment 
    function makePayment(uint _requestNo) public onlyAdmin {
        require(raisedAmount >= goal); 
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request has been completed!");
        require(thisRequest.noOfVoters > noOfContributors/2);

        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}