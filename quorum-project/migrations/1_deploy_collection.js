const CollectionContract = artifacts.require("CollectionContract");

module.exports = function(deployer) {
  deployer.deploy(CollectionContract, { privateFor: ["ROAZBWtSacxXQrOe3FGAqJDyJjFePR5ce4TSIzmJ0Bc="] });
};
