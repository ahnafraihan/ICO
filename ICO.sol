pragma solidity ^0.4.16;

contract Owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Token is Owned {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    address mintController;

    mapping (address => uint256) balances;

    event Mint (
        address indexed to,
        uint256 value
    );

    event Transfer (
        address indexed from,
        address indexed to,
        uint256 value
    );

    modifier onlyMintController () {
        require(msg.sender == mintController);
        _;
    }

    constructor (string nameIn, string symbolIn, uint8 decimalsIn, uint256 totalSupplyIn) Owned() public {
        name = nameIn;
        symbol = symbolIn;
        decimals = decimalsIn;
        totalSupply = totalSupplyIn;
        mintController = msg.sender;
        balances[msg.sender] = totalSupplyIn;
    }

    function () private {
        assert(false);
    }

    function mint (address addressIn, uint256 amountIn) public onlyMintController {
        balances[addressIn] += amountIn;
        totalSupply += amountIn;
        emit Mint(addressIn, amountIn);
    }

    function changeMinter (address addressIn) public onlyOwner {
        mintController = addressIn;
    }

    function transfer (address addressIn, uint256 amountIn) public {
        require(balances[addressIn] >= amountIn, "Error: Insufficient Funds");
        balances[msg.sender] -= amountIn;
        balances[addressIn] += amountIn;
        emit Transfer (msg.sender, addressIn, amountIn);
    }
}

contract Sale {
    address beneficiary;
    uint fundingGoal;
    uint deadline;
    uint pricePerToken;
    uint amountRaised;
    bool fundingGoalReached;
    bool crowdsaleClosed;
    Token token;

    mapping (address => uint256) contributions;

    modifier afterDeadline () {
        require(now > deadline);
        _;
    }

    constructor (address beneficiaryIn, uint fundingGoalIn, uint durationInMinutes, uint etherCostPerToken, address tokenAddress) public {
        beneficiary = beneficiaryIn;
        fundingGoal = fundingGoalIn * 1 ether;
        deadline = now + (durationInMinutes * 1 minutes);
        pricePerToken = etherCostPerToken * 1 ether;
        token = Token(tokenAddress);
    }

    function () private {
        assert(false);
    }

    function participate () public payable {
        require (now < deadline, "Error: Crowdsale is Closed");
        amountRaised += msg.value;
        contributions[msg.sender] += msg.value;
        token.mint(msg.sender, (msg.value / pricePerToken));
    }

    function checkGoalReached () public afterDeadline {
        crowdsaleClosed = true;
        if (amountRaised >= fundingGoal)
            fundingGoalReached = true;
    }

    function withdraw () public afterDeadline {
        require (crowdsaleClosed = true, "Error: Crowdsale may still be open");
        if (fundingGoalReached)
            beneficiary.transfer(amountRaised);
        else
            if (contributions[msg.sender] > 0)
                msg.sender.transfer(contributions[msg.sender]);
    }
}
