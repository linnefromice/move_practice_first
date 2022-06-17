import { Account, RestClient } from "first-transaction";

export class HelloBlockchainClient extends RestClient {
  async publishModule(accountFrom: Account, moduleHex: string): Promise<string> {
    const payload = {
      type: "module_bundle_payload",
      modules: [{ bytecode: `0x${moduleHex}`}]
    }
    return await this.executeTransactionWithPayload(accountFrom, payload)
  }

  async getMessage(contractAddress: string, accountAddress: string): Promise<string> {
    const resource = await this.accountResource(accountAddress, `0x${contractAddress}::Message::MessageHolder`)
    if (resource == null) {
      return "";
    } else {
      return resource["data"]["message"]
    }
  }

  async setMessage(contractAddress: string, accountFrom: Account, message: string): Promise<string> {
    const payload: { function: string, arguments: string[], type: string, type_arguments: any[] } = {
      type: "script_function_payload",
      function: `0x${contractAddress}::Message::set_message`,
      type_arguments: [],
      arguments: [Buffer.from(message, "utf-8").toString()]
    }

    return await this.executeTransactionWithPayload(accountFrom, payload)
  }
}