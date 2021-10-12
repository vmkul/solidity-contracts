// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    struct PersonalData {
        string first_name;
        string second_name;
        string phone;
        uint age;
        address addr;
    }
    
    mapping(address => PersonalData) data;
    PersonalData[] allData;
    address admin;

    constructor() {
        admin = msg.sender;
    }

    modifier requireAdmin() {
        require(msg.sender == admin);
        _;
    }

    function store(string memory first_name, string memory second_name, string memory phone, uint age) external {
        data[msg.sender] = PersonalData(first_name, second_name, phone, age, msg.sender);
        allData.push(data[msg.sender]);
    }

    function retrieveOwnData() external view returns (PersonalData memory) {
        return data[msg.sender];       
    }
    
    function retrieveDataByAddress(address addr) external view requireAdmin() returns (PersonalData memory) {
        return data[addr];
    }
    
    function retrieveAllData() external view requireAdmin() returns (PersonalData[] memory) {
        return allData;
    }
}
