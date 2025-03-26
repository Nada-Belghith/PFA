const Web3 = require('web3');
const fs = require('fs');
const path = require('path');

// Connect to Quorum node
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:22000'));

async function deployContract() {
    const accounts = await web3.eth.getAccounts();
    const contractPath = path.join(__dirname, '../build/contracts/CollectionContract.json');
    const contractJson = JSON.parse(fs.readFileSync(contractPath));
    
    const contract = new web3.eth.Contract(contractJson.abi);
    const deploy = contract.deploy({
        data: contractJson.bytecode
    });

    const gas = await deploy.estimateGas();
    
    const deployedContract = await deploy.send({
        from: accounts[0],
        gas: gas,
        privateFor: ["ROAZBWtSacxXQrOe3FGAqJDyJjFePR5ce4TSIzmJ0Bc="]
    });

    console.log('Contract deployed at:', deployedContract.options.address);
    return deployedContract;
}

deployContract().catch(console.error);
