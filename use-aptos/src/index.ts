import { AptosClient } from "aptos"
import { NODE_URL } from "./constants"

const main = async () => {
  const client = new AptosClient(NODE_URL)
  const [ledgerInfo, transactions] = await Promise.all([
    client.getLedgerInfo(),
    client.getTransactions()
  ])
  console.log(ledgerInfo)
  console.log(transactions)
}

main()
  .then(() => console.log("FINISHED"))
  .catch((e: any) => {
    console.log("ERROR")
    console.log(e)
  })