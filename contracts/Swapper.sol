// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



contract Swapper {

    struct Order {
        address ownedToken;
        address destinationToken;
        uint256 amountOwned;
        uint256 amountExcepted;
        address owner;
        bool terminated;
    }

    Order[] public OrderBook;


    /// Contract didn't recieve token, make sure you have approved the contract address to spend your token
    error TransferFailed();

    /// You are not the owner of this transaction
    error NotYourTransaction();

    /// An errored occured while trying to send you token
    error SendingTokenFailed();

    /// Transaction has already been terminated
    error AlreadyTerminated();


    event OrderHasBeenPlaced(
        address _ownedToken,
        address _destinationToken,
        uint256 _amountToSwap,
        uint256 _amountExcepted,
        address _owner
    );

    event OrderTerminated(
        address _ownedToken,
        address _destinationToken,
        uint256 _amountToSwap,
        uint256 _amountExcepted,
        address _owner
    );

    event OrderExcecuted(
        address _ownedToken,
        address _destinationToken,
        uint256 _amountToSwap,
        uint256 _amountExcepted,
        address _owner
    );


    function placeOrder(
        address _ownedToken,
        address _destinationToken,
        uint256 _amountToSwap,
        uint256 _amountExcepted
    ) public {
        // creating struct
        Order memory co_ = Order(_ownedToken,_destinationToken,_amountToSwap,_amountExcepted,msg.sender,false);
        // Order storage  co = OrderBook[OrderBook.length];
        // co.ownedToken = _ownedToken;
        // co.destinationToken = _destinationToken;
        // co.amountOwned = _amountToSwap;
        // co.amountExcepted = _amountExcepted;
        // co.owner = msg.sender;
  

        // debiting the token from the owner
        bool tokenReceieved = IERC20(_ownedToken).transferFrom(msg.sender, address(this), _amountToSwap);

        if(!tokenReceieved) {
            revert TransferFailed();
        }

        OrderBook.push(co_);

        // emiting event 
        emit OrderHasBeenPlaced(
            _ownedToken,
            _destinationToken,
            _amountToSwap,
            _amountExcepted,
            msg.sender
        );
    }

    function terminateOrder(uint _transactionIndex) public {
        // obtaining transaction from the storage 
        Order storage  co = OrderBook[_transactionIndex];

        // check 
        if(co.owner != msg.sender) {
            revert NotYourTransaction();
        }

        if(co.terminated) {
            revert AlreadyTerminated();
        }

        // terminating
        co.terminated = false;

        // sending the token back to the owner 
        bool transfered = IERC20(co.ownedToken).transfer(msg.sender, co.amountOwned);

        if(!transfered) {
            revert SendingTokenFailed();
        }

        // emit event
        emit OrderTerminated(
            co.ownedToken,
            co.destinationToken,
            co.amountOwned,
            co.amountExcepted,
            msg.sender
        );
    }

    function peekMatchingTransaction(
        address _ownedToken,
        address _destinationToken,
        uint256 _amountToSwap,
        uint256 _amountExcepted
    ) public view returns(int256 orderIndex) {
        // scanning throgh the order book and returning match
        orderIndex = -1;
        for(uint i = 0; i < OrderBook.length; i++) {
            if(
                OrderBook[i].ownedToken == _destinationToken &&
                OrderBook[i].destinationToken == _ownedToken &&
                OrderBook[i].amountOwned == _amountExcepted && 
                OrderBook[i].amountExcepted == _amountToSwap && 
                OrderBook[i].terminated == false
            ) {
                orderIndex = int(i);
                break;
            }
        }
    }

    function excecuteMatchedOrder(uint _matchId) public {
        // obtaining order from state 
        Order storage  co = OrderBook[_matchId];

        // check
        if(co.terminated) {
            revert AlreadyTerminated();
        }

        // transfering tokens to the persen who placed the order
        bool transfered = IERC20(co.destinationToken).transferFrom(msg.sender, co.owner, co.amountExcepted);

        if(!transfered) {
            revert TransferFailed();
        }

        // transfer token to the order excecutor
        bool transfered2 = IERC20(co.ownedToken).transfer(msg.sender, co.amountOwned);

        if(!transfered2) {
            revert SendingTokenFailed();
        }

        // emit event
        emit OrderExcecuted(
            co.ownedToken,
            co.destinationToken,
            co.amountOwned,
            co.amountExcepted,
            msg.sender
        );
    }
}

// :)