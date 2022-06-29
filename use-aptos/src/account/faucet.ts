import { AptosClient, FaucetClient } from "aptos"
import { EOA_ADDRESS, FAUCET_URL, NODE_URL } from "../constants"

const COIN_RESOURCE_NAME = "0x1::Coin::CoinStore<0x1::TestCoin::TestCoin>"
type DataInterface = {
  coin: { value: number }
}
const AMOUNT = 0
const main = async () => {
  const client = new AptosClient(NODE_URL)
  const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL)

  const preBalance = await client.getAccountResource(EOA_ADDRESS, COIN_RESOURCE_NAME)
  console.log(`before : ${(preBalance.data as DataInterface).coin.value}`)
  await faucetClient.fundAccount(EOA_ADDRESS, AMOUNT)
  const balance = await client.getAccountResource(EOA_ADDRESS, COIN_RESOURCE_NAME)
  console.log(`after : ${(balance.data as DataInterface).coin.value}`)
}

main()
  .then(() => console.log("FINISHED"))
  .catch((e: any) => {
    console.log("ERROR")
    console.log(e)
  })