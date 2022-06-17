import * as SHA3 from "js-sha3";
import * as Nacl from "tweetnacl";
import fetch from "cross-fetch";
import assert from "assert";

export type TxnRequest = Record<string, any> & { sequence_number: string };

export class Account {
  signingKey: Nacl.SignKeyPair;

  constructor(seed?: Uint8Array) {
    if (seed) {
      this.signingKey = Nacl.sign.keyPair.fromSeed(seed)
    } else {
      this.signingKey = Nacl.sign.keyPair()
    }
  }

  address(): string {
    return this.authKey();
  }

  authKey(): string {
    let hash = SHA3.sha3_256.create()
    hash.update(Buffer.from(this.signingKey.publicKey))
    hash.update("\x00")
    return hash.hex()
  }

  pubKey(): string {
    return Buffer.from(this.signingKey.publicKey).toString("hex")
  }
}

export class RestClient {
  url: string;

  constructor(url: string) {
    this.url = url;
  }

  /** Returns the sequence number and authentication key for an account */
  async account(accountAddress: string): Promise<Record<string, string> & { sequence_number: string }> {
    const response = await fetch(`${this.url}/accounts/${accountAddress}`, { method: "GET" })
    if (response.status != 200) {
      assert(response.status == 200, await response.text())
    }
    return await response.json()
  }

  /** Returns all resources associated with the account */
  async accountResource(accountAddress: string, resourceType: string): Promise<any> {
    const response = await fetch(
      `${this.url}/accounts/${accountAddress}/resource/${resourceType}`,
      { method: "GET" }
    )
    if (response.status == 404) {
      return null;
    }
    if (response.status != 200) {
      assert(response.status == 200, await response.text());
    }
    return await response.json();
  }

  /** Generates a transaction request that can be submitted to produce a raw transaction that can be signed, which upon being signed can be submitted to the blockchain. */
  async generateTransaction(sender: string, payload: Record<string, any>): Promise<TxnRequest> {
    const account = await this.account(sender)
    const seqNum = parseInt(account.sequence_number)
    return {
      sender: `0x${sender}`,
      sequence_number: seqNum.toString(),
      max_gas_amount: "2000",
      gas_unit_price: "1",
      expiration_timestamp_secs: (Math.floor(Date.now() / 1000) + 600).toString(), // unix timestamp, in seconds + 10 minutes
      payload: payload
    }
  }

  /** Converts a transaction request produced by `generate_transaction` into a properly signed transaction, which can then be submitted to the blockchain */
  async signTransaction(accountFrom: Account, txnRequest: TxnRequest): Promise<TxnRequest> {
    const response = await fetch(`${this.url}/transactions/signing_message`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(txnRequest)
    });
    if (response.status !== 200) {
      assert(response.status == 200, (await response.text()) + " - " + JSON.stringify(txnRequest))
    }
    const result: Record<string, any> & { message: string } = await response.json()
    const toSign = Buffer.from(result["message"].substring(2), "hex");
    const signature = Nacl.sign(toSign, accountFrom.signingKey.secretKey)
    const signatureHex = Buffer.from(signature).toString("hex").slice(0, 128)
    txnRequest["signature"] = {
      type: "ed25519_signature",
      public_key: `0x${accountFrom.pubKey()}`,
      signature: `0x${signatureHex}`
    }
    return txnRequest
  }

  /** Submits a signed transaction to the blockchain */
  async submitTransaction(txnRequest: TxnRequest): Promise<Record<string, any>> {
    const response = await fetch(`${this.url}/transactions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(txnRequest)
    });
    if (response.status != 202) {
      assert(response.status == 202, (await response.text()) + " - " + JSON.stringify(txnRequest))
    }
    return await response.json();
  }

  async executeTransactionWithPayload(accountFrom: Account, payload: Record<string, any>): Promise<string> {
    const txnRequest = await this.generateTransaction(accountFrom.address(), payload)
    const signedTxn = await this.signTransaction(accountFrom, txnRequest)
    const res = await this.submitTransaction(signedTxn)
    return res["hash"]
  }

  async transactionPending(txnHash: string): Promise<boolean> {
    const response = await fetch(`${this.url}/transactions/${txnHash}`, { method: "GET" })
    if (response.status == 404) {
      return true
    }
    if (response.status !== 200) {
      assert(response.status == 200, await response.text())
    }
    return (await response.json())["type"] == "pending_transaction"
  }

  /** Waits up to 10 seconds for a transaction to move past pending state */
  async waitForTransaction(txnHash: string) {
    let count = 0;
    while (await this.transactionPending(txnHash)) {
      assert(count < 10);
      await new Promise((resolve) => setTimeout(resolve, 1000))
      count += 1;
      if (count >= 10) {
        throw new Error(`Waiting for transaction ${txnHash} timed out!`)
      }
    }
  }
}
