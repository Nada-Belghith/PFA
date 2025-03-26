// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CollectionContract {
    struct Collection {
        string trashBinId;
        uint256 bottleCount;
        uint256 amount;
        string date;
        string time;
    }

    Collection[] public collections;
    mapping(address => Collection[]) public collectorHistory;

    // Add privacy flag for Quorum
    bool private constant PRIVATE = true;

    event CollectionRecorded(
        address collector,
        string trashBinId,
        uint256 bottleCount,
        uint256 amount,
        string date,
        string time
    );

    function recordCollection(
        string memory _trashBinId,
        uint256 _bottleCount,
        uint256 _amount,
        string memory _date,
        string memory _time
    ) public {
        Collection memory newCollection = Collection(
            _trashBinId,
            _bottleCount,
            _amount,
            _date,
            _time
        );

        collections.push(newCollection);
        collectorHistory[msg.sender].push(newCollection);

        emit CollectionRecorded(
            msg.sender,
            _trashBinId,
            _bottleCount,
            _amount,
            _date,
            _time
        );
    }

    function getCollectionCount() public view returns (uint256) {
        return collections.length;
    }

    function getCollectorHistory(address _collector) public view returns (Collection[] memory) {
        return collectorHistory[_collector];
    }
}