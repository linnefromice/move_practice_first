import { AptosClient } from "aptos"
import { EOA_ADDRESS, NODE_URL } from "../constants"

const main = async () => {
  const client = new AptosClient(NODE_URL)
  const account = await client.getAccount(EOA_ADDRESS)
  // About account
  console.log(account.sequence_number)
  console.log(account.authentication_key)

  // About Resources
  const resources = await client.getAccountResources(EOA_ADDRESS)
  console.log(`> resources count: ${resources.length}`)
  const _resource = await client.getAccountResource(EOA_ADDRESS, "0x1::Coin::CoinStore<0x1::TestCoin::TestCoin>")
  console.dir(_resource, { depth: null });

  // About Modules
  const modules = await client.getAccountModules(EOA_ADDRESS)
  console.log(`> modules count: ${modules.length}`)
  const _module = await client.getAccountModule(EOA_ADDRESS, "MegaCoin")
  console.dir(_module, { depth: null });
}

main()
  .then(() => console.log("FINISHED"))
  .catch((e: any) => {
    console.log("ERROR")
    console.log(e)
  })