// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LendingProtocol {
    // Addresses of lenders
    address[] public lenders;

    // Total amount of credit for each lender
    mapping (address => uint256) public lenderBalances;

    // Requests for borrowing credit
    Request[] public requests;

    // Function for lending credit
    function lend(address _borrower, uint256 _amount) public {
        require(_amount > 0, "Invalid amount");
        require(_borrower != address(0), "Invalid borrower address");
        require(!isLender(msg.sender), "Lender cannot lend");
        require(!isBorrower(_borrower), "Borrower cannot borrow again");

        lenders.push(msg.sender);
        lenderBalances[msg.sender] += _amount;

        // Add borrower to requests array if not already present
        if (!isBorrower(_borrower)) {
            requests.push(Request({
                borrower: _borrower,
                amount: 0,
                isClosed: false
            }));
        }
        
        // Update borrower balance in requests array
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].borrower == _borrower) {
                requests[i].amount += _amount;
                break;
            }
        }
    }

    // Function for requesting credit
    function requestLoan(uint256 _amount) public {
        require(_amount > 0, "Invalid amount");

        // Create a new request
        Request memory newRequest = Request({
            borrower: msg.sender,
            amount: _amount,
            isClosed: false
        });

        requests.push(newRequest);
    }

    // Function to get list of borrowing requests
    function getRequests() public view returns (Request[] memory) {
        return requests;
    }

    // Function to fulfill a borrowing request
    function fulfillRequest(uint256 _requestIndex) public {
        require(_requestIndex < requests.length, "Invalid request index");
        require(lenderBalances[msg.sender] >= requests[_requestIndex].amount, "Insufficient balance");

        // Close the borrowing request
        requests[_requestIndex].isClosed = true;

        // Transfer credit to borrower's account
        address borrower = requests[_requestIndex].borrower;
        uint256 amount = requests[_requestIndex].amount;
        lenderBalances[msg.sender] -= amount;
        payable(borrower).transfer(amount);
    }

    // Function to get list of lender addresses
    function getLenders() public view returns (address[] memory) {
        return lenders;
    }

    // Function to get list of borrower addresses
    function getBorrowers() public view returns (address[] memory) {
        address[] memory borrowersArray = new address[](requests.length);
        uint256 count = 0;
        for (uint256 i = 0; i < requests.length; i++) {
            if (!requests[i].isClosed) {
                borrowersArray[count] = requests[i].borrower;
                count++;
            }
        }
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = borrowersArray[i];
        }
        return result;
    }

    // Function to check if an address is a lender
    function isLender(address _lenderAddress) public view returns (bool) {
        for (uint256 i = 0; i < lenders.length; i++) {
            if (lenders[i] == _lenderAddress) {
                return true;
            }
        }
        return false;
    }

    // Function to check if an address is a borrower
    function isBorrower(address _borrowerAddress) public view returns (bool) {
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i].borrower == _borrowerAddress && !requests[i].isClosed) {
                return true;
            }
        }
        return false;
    }

    // Structure for borrowing requests
    struct Request {
        address borrower;
        uint256 amount;
        bool isClosed;
    }
}
