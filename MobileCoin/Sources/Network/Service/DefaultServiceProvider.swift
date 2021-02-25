//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation

final class DefaultServiceProvider: ServiceProvider {
    private let targetQueue: DispatchQueue?
    private let channelManager = GrpcChannelManager()

    private let consensus: ConsensusConnection
    private let view: FogViewConnection
    private let merkleProof: FogMerkleProofConnection
    private let keyImage: FogKeyImageConnection
    private let block: FogBlockConnection
    private let untrustedTxOut: FogUntrustedTxOutConnection

    private var reportUrlToReportConnection: [GrpcChannelConfig: FogReportConnection] = [:]
    private var authorizationCredentials: BasicCredentials? {
        didSet {
            if let credentials = authorizationCredentials {
                consensus.setAuthorization(credentials: credentials)
                view.setAuthorization(credentials: credentials)
                merkleProof.setAuthorization(credentials: credentials)
                keyImage.setAuthorization(credentials: credentials)
                block.setAuthorization(credentials: credentials)
                untrustedTxOut.setAuthorization(credentials: credentials)
                for connection in reportUrlToReportConnection.values {
                    connection.setAuthorization(credentials: credentials)
                }
            }
        }
    }

    init(networkConfig: NetworkConfig, targetQueue: DispatchQueue?) {
        self.targetQueue = targetQueue
        self.consensus = ConsensusConnection(
            url: networkConfig.consensusUrl,
            attestation: networkConfig.consensusAttestation,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.view = FogViewConnection(
            url: networkConfig.fogViewUrl,
            attestation: networkConfig.fogViewAttestation,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.merkleProof = FogMerkleProofConnection(
            url: networkConfig.fogMerkleProofUrl,
            attestation: networkConfig.fogMerkleProofAttestation,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.keyImage = FogKeyImageConnection(
            url: networkConfig.fogKeyImageUrl,
            attestation: networkConfig.fogKeyImageAttestation,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.block = FogBlockConnection(
            url: networkConfig.fogBlockUrl,
            channelManager: channelManager,
            targetQueue: targetQueue)
        self.untrustedTxOut = FogUntrustedTxOutConnection(
            url: networkConfig.fogUntrustedTxOutUrl,
            channelManager: channelManager,
            targetQueue: targetQueue)
    }

    var consensusService: ConsensusService { consensus }
    var fogViewService: FogViewService { view }
    var fogMerkleProofService: FogMerkleProofService { merkleProof }
    var fogKeyImageService: FogKeyImageService { keyImage }
    var fogBlockService: FogBlockService { block }
    var fogUntrustedTxOutService: FogUntrustedTxOutConnection { untrustedTxOut }

    func fogReportService(for fogReportUrl: FogReportUrl) -> FogReportService {
        let config = GrpcChannelConfig(url: fogReportUrl)
        guard let reportConnection = reportUrlToReportConnection[config] else {
            let reportConnection = FogReportConnection(
                url: fogReportUrl,
                channelManager: channelManager,
                targetQueue: targetQueue)
            if let credentials = authorizationCredentials {
                reportConnection.setAuthorization(credentials: credentials)
            }
            reportUrlToReportConnection[config] = reportConnection
            return reportConnection
        }
        return reportConnection
    }

    func setAuthorization(credentials: BasicCredentials) {
        authorizationCredentials = credentials
    }
}
