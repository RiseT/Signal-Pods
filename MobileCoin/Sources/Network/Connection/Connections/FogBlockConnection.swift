//
//  Copyright (c) 2020 MobileCoin. All rights reserved.
//

import Foundation
import GRPC
import LibMobileCoin

final class FogBlockConnection: Connection, FogBlockService {
    private let client: FogLedger_FogBlockAPIClient

    init(
        url: FogLedgerUrl,
        channelManager: GrpcChannelManager,
        targetQueue: DispatchQueue?
    ) {
        let channel = channelManager.channel(for: url)
        self.client = FogLedger_FogBlockAPIClient(channel: channel)
        super.init(url: url, targetQueue: targetQueue)
    }

    func getBlocks(
        request: FogLedger_BlockRequest,
        completion: @escaping (Result<FogLedger_BlockResponse, Error>) -> Void
    ) {
        performCall(GetBlocksCall(client: client), request: request, completion: completion)
    }
}

extension FogBlockConnection {
    private struct GetBlocksCall: GrpcCallable {
        let client: FogLedger_FogBlockAPIClient

        func call(
            request: FogLedger_BlockRequest,
            callOptions: CallOptions?,
            completion: @escaping (UnaryCallResult<FogLedger_BlockResponse>) -> Void
        ) {
            let unaryCall = client.getBlocks(request, callOptions: callOptions)
            unaryCall.callResult.whenSuccess(completion)
        }
    }
}