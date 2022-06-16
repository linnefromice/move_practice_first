import * as SHA3 from "js-sha3";
import * as Nacl from "tweetnacl";

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
