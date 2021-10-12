import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SomeToken is ERC20 {
    constructor() ERC20("My token", "MTK") {
        _mint(msg.sender, 100 * 10**18);
    }
}
