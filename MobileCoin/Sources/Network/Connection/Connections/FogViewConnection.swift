//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin

final class FogViewConnection: AttestedConnection, FogViewService {
    private let client: FogView_FogViewAPIClient

    init(
        url: FogViewUrl,
        attestation: Attestation,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?,
        rng: (@convention(c) (UnsafeMutableRawPointer?) -> UInt64)? = securityRNG,
        rngContext: Any? = nil
    ) {
        let channel = channelManager.channel(for: url)
        self.client = FogView_FogViewAPIClient(channel: channel)
        super.init(
            client: self.client,
            url: url,
            attestation: attestation,
            targetQueue: targetQueue,
            rng: rng,
            rngContext: rngContext)
    }

    func query(
        requestAad: FogView_QueryRequestAAD,
        request: FogView_QueryRequest,
        completion: @escaping (Result<FogView_QueryResponse, Error>) -> Void
    ) {
        performAttestedCall(
            EnclaveRequestCall(client: client),
            requestAad: requestAad,
            request: request,
            completion: completion)
    }
}

extension FogViewConnection {
    private struct EnclaveRequestCall: AttestedGrpcCallable {
        typealias InnerRequestAad = FogView_QueryRequestAAD
        typealias InnerRequest = FogView_QueryRequest
        typealias InnerResponse = FogView_QueryResponse

        let client: FogView_FogViewAPIClient

        func call(
            request: Attest_Message,
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<Attest_Message>) -> Void
        ) {
            let unaryCall = client.query(request, callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}

extension FogView_FogViewAPIClient: AuthGrpcCallableClient {}
