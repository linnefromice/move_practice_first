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
}
