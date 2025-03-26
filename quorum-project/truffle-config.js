module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 22000,
      network_id: "*",
      gasPrice: 0,
      gas: 4500000
    },
    quorum: {
      host: "127.0.0.1",
      port: 22000,
      network_id: "*",
      gasPrice: 0,
      gas: 4500000,
      type: "quorum"
    }
  },
  compilers: {
    solc: {
      version: "0.5.0"
    }
  }
};
