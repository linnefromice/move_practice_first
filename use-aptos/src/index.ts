import { AptosClient } from "aptos"
import { NODE_URL } from "./constants"

const main = async () => {
  const client = new AptosClient(NODE_URL)
  const results = await Promise.all([
    client.getChainId(),
    client.getLedgerInfo(),
    client.getTransactions()
  ])
  console.log(results[0])
  console.log(results[1])
  console.log(results[2])
}

main()
  .then(() => console.log("FINISHED"))
  .catch((e: any) => {
    console.log("ERROR")
    console.log(e)
  })