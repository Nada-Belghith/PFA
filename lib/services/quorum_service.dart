import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'dart:math';

class QuorumService {
  final String rpcUrl;
  final String privateKey;
  late Web3Client _client;
  late final DeployedContract _contract;

  QuorumService({
    required this.rpcUrl,
    required this.privateKey,
  }) {
    _client = Web3Client(rpcUrl, Client());
    _contract = DeployedContract(
      ContractAbi.fromJson(contractABI, 'CollectionContract'),
      EthereumAddress.fromHex('YOUR_CONTRACT_ADDRESS'),
    );
  }

  static const String contractABI = '''
[
  {
    "anonymous": false,
    "inputs": [
      {"indexed": false, "name": "collector", "type": "address"},
      {"indexed": false, "name": "trashBinId", "type": "string"},
      {"indexed": false, "name": "bottleCount", "type": "uint256"},
      {"indexed": false, "name": "amount", "type": "uint256"},
      {"indexed": false, "name": "date", "type": "string"},
      {"indexed": false, "name": "time", "type": "string"}
    ],
    "name": "CollectionRecorded",
    "type": "event"
  },
  {
    "inputs": [
      {"name": "_trashBinId", "type": "string"},
      {"name": "_bottleCount", "type": "uint256"},
      {"name": "_amount", "type": "uint256"},
      {"name": "_date", "type": "string"},
      {"name": "_time", "type": "string"}
    ],
    "name": "recordCollection",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getCollectionCount",
    "outputs": [{"name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [{"name": "_collector", "type": "address"}],
    "name": "getCollectorHistory",
    "outputs": [
      {
        "components": [
          {"name": "trashBinId", "type": "string"},
          {"name": "bottleCount", "type": "uint256"},
          {"name": "amount", "type": "uint256"},
          {"name": "date", "type": "string"},
          {"name": "time", "type": "string"}
        ],
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
''';

  static const String defaultRpcUrl = 'http://localhost:22000';
  // Remplacez par l'adresse obtenue lors du déploiement
  static const String defaultContractAddress =
      '0x...'; // L'adresse de votre contrat déployé

  Future<String> sendCollectionTransaction({
    required String trashBinId,
    required int bottleCount,
    required double amount,
    required String date,
    required String time,
  }) async {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final amountInWei = BigInt.from(amount * pow(10, 18));

      final function = _contract.function('recordCollection');

      final transaction = Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: [
          trashBinId,
          BigInt.from(bottleCount),
          amountInWei,
          date,
          time,
        ],
        maxGas: 2000000,
      );

      final result = await _client.sendTransaction(
        credentials,
        transaction,
        chainId: 10,
      );

      return result;
    } catch (e) {
      throw Exception('Transaction Error: $e');
    }
  }

  Future<List<CollectionRecord>> getCollectorTransactions(
      String address) async {
    try {
      final function = _contract.function('getCollectorHistory');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [EthereumAddress.fromHex(address)],
      );

      List<CollectionRecord> records = [];
      for (var record in result[0]) {
        records.add(CollectionRecord(
          trashBinId: record[0] as String,
          bottleCount: (record[1] as BigInt).toInt(),
          amount: (record[2] as BigInt).toDouble() / pow(10, 18),
          date: record[3] as String,
          time: record[4] as String,
        ));
      }

      return records;
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  Future<List<dynamic>> getCollectorHistory(String collectorAddress) async {
    try {
      final function = _contract.function('getCollectorHistory');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [EthereumAddress.fromHex(collectorAddress)],
      );
      return result[0];
    } catch (e) {
      throw Exception('Erreur lors de la lecture de l\'historique: $e');
    }
  }

  Future<BigInt> getCollectionCount() async {
    try {
      final function = _contract.function('getCollectionCount');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [],
      );
      return result[0] as BigInt;
    } catch (e) {
      throw Exception('Erreur lors de la lecture du compteur: $e');
    }
  }

  void dispose() {
    _client.dispose();
  }
}

class CollectionRecord {
  final String trashBinId;
  final int bottleCount;
  final double amount;
  final String date;
  final String time;

  CollectionRecord({
    required this.trashBinId,
    required this.bottleCount,
    required this.amount,
    required this.date,
    required this.time,
  });
}
